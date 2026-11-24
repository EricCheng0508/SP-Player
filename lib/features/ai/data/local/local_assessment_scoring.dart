/// Pure scoring for the local pronunciation-assessment pipeline.
///
/// Pipeline: faster-whisper transcribes the take with word timestamps, the
/// recognized words are sequence-aligned against the reference sentence, and
/// per-word verdicts (None / Mispronunciation / Omission / Insertion) roll up
/// into Azure-shaped scores. Output JSON mirrors the Azure Speech result
/// schema (PascalCase keys, 100-ns ticks) so the existing assessment UI and
/// the stored `assessmentJson` keep working unchanged.
library;

import 'dart:math' as math;

/// Similarity threshold above which an aligned word pair reads as "spoken".
const double kLocalSpokenThreshold = 0.72;

/// Word accuracy floor contribution when aligned but very dissimilar.
const int kLocalMispronunciationFloor = 0;

/// Extra pause (ms) between adjacent spoken words that starts counting as a
/// disfluency (mid-sentence hesitation).
const int kLocalPauseThresholdMs = 350;

/// Per-pause cap (ms) so one long stall cannot zero the fluency score.
const int kLocalPauseCapMs = 1500;

/// Normalizes a word for alignment: lowercase, strip punctuation.
String normalizeAssessmentWord(String raw) {
  final s = raw.toLowerCase().trim();
  final sb = StringBuffer();
  for (final rune in s.runes) {
    final ch = String.fromCharCode(rune);
    final isLetterOrDigit =
        (rune >= 0x30 && rune <= 0x39) ||
        (rune >= 0x41 && rune <= 0x5A) ||
        (rune >= 0x61 && rune <= 0x7A) ||
        rune == 0x27 || // apostrophe inside contractions
        rune >= 0x80; // keep non-latin scripts
    if (isLetterOrDigit) sb.write(ch);
  }
  return sb.toString();
}

/// Levenshtein-based similarity in [0, 1].
double wordSimilarity(String a, String b) {
  if (a == b) return 1;
  if (a.isEmpty || b.isEmpty) return 0;
  final maxLen = math.max(a.length, b.length);
  return 1 - _levenshtein(a, b) / maxLen;
}

int _levenshtein(String a, String b) {
  final m = a.length, n = b.length;
  var prev = List<int>.generate(n + 1, (i) => i);
  var curr = List<int>.filled(n + 1, 0);
  for (var i = 1; i <= m; i++) {
    curr[0] = i;
    for (var j = 1; j <= n; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      curr[j] = math.min(
        math.min(curr[j - 1] + 1, prev[j] + 1),
        prev[j - 1] + cost,
      );
    }
    final tmp = prev;
    prev = curr;
    curr = tmp;
  }
  return prev[n];
}

/// One aligned reference word with its spoken counterpart (when present).
final class LocalWordAssessment {
  const LocalWordAssessment({
    required this.displayWord,
    required this.errorType,
    required this.accuracyScore,
    this.spokenWord,
    this.startMs,
    this.endMs,
  });

  /// Reference word (omission) or spoken word (all other kinds).
  final String displayWord;
  final String errorType; // None | Mispronunciation | Omission | Insertion
  final int accuracyScore;
  final String? spokenWord;
  final int? startMs;
  final int? endMs;

  bool get isSpoken => errorType != 'Omission';
}

/// Outcome of aligning the reference words against the recognized words.
final class LocalAlignmentResult {
  const LocalAlignmentResult({
    required this.words,
    required this.accuracyScore,
    required this.completenessScore,
    required this.fluencyScore,
    required this.pronScore,
    required this.spokenText,
  });

  /// Final word sequence in timeline order (insertions inline, omissions at
  /// their aligned position).
  final List<LocalWordAssessment> words;
  final int accuracyScore;
  final int completenessScore;
  final int fluencyScore;
  final int pronScore;
  final String spokenText;
}

final class _SpokenWord {
  const _SpokenWord({
    required this.normalized,
    required this.display,
    required this.startMs,
    required this.endMs,
  });

  final String normalized;
  final String display;
  final int startMs;
  final int endMs;
}

/// Aligns [referenceWords] against recognized [spokenWords] (with timings in
/// ms) and rolls the verdicts up into scores.
///
/// Alignment is Needleman–Wunsch over word-similarity: matched pairs score
/// their similarity, skipped reference words (omissions) and skipped spoken
/// words (insertions) pay fixed penalties so the walk prefers matching.
LocalAlignmentResult assessLocalPronunciation({
  required List<String> referenceWords,
  required List<({String word, int startMs, int endMs})> spokenWords,
  int pauseThresholdMs = kLocalPauseThresholdMs,
  int pauseCapMs = kLocalPauseCapMs,
}) {
  final spoken = spokenWords
      .map(
        (w) => _SpokenWord(
          normalized: normalizeAssessmentWord(w.word),
          display: w.word,
          startMs: w.startMs,
          endMs: w.endMs,
        ),
      )
      .toList();
  final reference = referenceWords.map(normalizeAssessmentWord).toList();

  const omissionPenalty = -0.3;
  const insertionPenalty = -0.15;

  final n = reference.length, m = spoken.length;
  final dp = List.generate(
    n + 1,
    (_) => List<double>.filled(m + 1, 0),
    growable: false,
  );
  for (var i = 1; i <= n; i++) {
    dp[i][0] = dp[i - 1][0] + omissionPenalty;
  }
  for (var j = 1; j <= m; j++) {
    dp[0][j] = dp[0][j - 1] + insertionPenalty;
  }
  for (var i = 1; i <= n; i++) {
    for (var j = 1; j <= m; j++) {
      final match = dp[i - 1][j - 1] + wordSimilarity(reference[i - 1], spoken[j - 1].normalized);
      final omit = dp[i - 1][j] + omissionPenalty;
      final insert = dp[i][j - 1] + insertionPenalty;
      dp[i][j] = math.max(match, math.max(omit, insert));
    }
  }

  // Walk back the optimal path, collecting pairs in reverse.
  final pairs = <(int, int, double)>[]; // (refIndex, spokenIndex, sim)
  final omissions = <int>[]; // refIndex
  final insertions = <int>[]; // spokenIndex
  var i = n, j = m;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0) {
      final sim = wordSimilarity(reference[i - 1], spoken[j - 1].normalized);
      if ((dp[i][j] - sim - dp[i - 1][j - 1]).abs() < 1e-9) {
        pairs.add((i - 1, j - 1, sim));
        i--;
        j--;
        continue;
      }
    }
    if (i > 0 && (dp[i][j] - omissionPenalty - dp[i - 1][j]).abs() < 1e-9) {
      omissions.add(i - 1);
      i--;
      continue;
    }
    if (j > 0) {
      insertions.add(j - 1);
      j--;
      continue;
    }
    break;
  }

  final pairByRef = {for (final p in pairs) p.$1: p.$3};
  final spokenByRef = <int, _SpokenWord>{};
  for (final entry in pairs) {
    spokenByRef[entry.$1] = spoken[entry.$2];
  }

  // Per-reference-word verdicts.
  final assessments = <LocalWordAssessment>[];
  var accuracySum = 0.0;
  var spokenCount = 0;
  for (var r = 0; r < n; r++) {
    final sim = pairByRef[r];
    if (sim == null) {
      assessments.add(
        LocalWordAssessment(
          displayWord: referenceWords[r],
          errorType: 'Omission',
          accuracyScore: 0,
        ),
      );
      continue;
    }
    final sp = spokenByRef[r]!;
    final score = math.max(
      kLocalMispronunciationFloor,
      (sim * 100).round(),
    );
    final kind = sim >= 0.999 ? 'None' : 'Mispronunciation';
    assessments.add(
      LocalWordAssessment(
        displayWord: referenceWords[r],
        errorType: kind,
        accuracyScore: score,
        spokenWord: sp.display,
        startMs: sp.startMs,
        endMs: sp.endMs,
      ),
    );
    accuracySum += score;
    if (sim >= kLocalSpokenThreshold) spokenCount++;
  }

  // Insertions merged in timeline order.
  final insertionSet = insertions.toSet();
  final insertionWords = insertionSet
      .map((k) => spoken[k])
      .toList()
    ..sort((a, b) => a.startMs.compareTo(b.startMs));
  for (final sp in insertionWords) {
    var idx = assessments.lastIndexWhere(
      (w) => w.startMs != null && w.startMs! <= sp.startMs,
    );
    if (idx < 0) idx = -1;
    assessments.insert(
      idx + 1,
      LocalWordAssessment(
        displayWord: sp.display,
        errorType: 'Insertion',
        accuracyScore: 0,
        spokenWord: sp.display,
        startMs: sp.startMs,
        endMs: sp.endMs,
      ),
    );
  }

  final accuracyScore = n == 0 ? 0 : (accuracySum / n).round();
  final completenessScore = n == 0
      ? 0
      : (spokenCount * 100 / n).round();

  // Fluency: speech time vs mid-sentence pauses between adjacent spoken
  // (aligned) words. Timings unavailable → fall back to accuracy.
  final aligned = assessments
      .where((w) => w.isSpoken && w.startMs != null && w.endMs != null)
      .toList()
    ..sort((a, b) => a.startMs!.compareTo(b.startMs!));
  var speechMs = 0, pauseMs = 0;
  for (final w in aligned) {
    speechMs += math.max(0, w.endMs! - w.startMs!);
  }
  for (var k = 1; k < aligned.length; k++) {
    final gap = aligned[k].startMs! - aligned[k - 1].endMs!;
    if (gap > pauseThresholdMs) {
      pauseMs += math.min(gap, pauseCapMs);
    }
  }
  final fluencyScore = speechMs <= 0
      ? (aligned.isEmpty ? 0 : accuracyScore)
      : (100 * speechMs / (speechMs + pauseMs)).round();

  final pronScore = (0.5 * accuracyScore + 0.25 * fluencyScore + 0.25 * completenessScore)
      .round();

  final spokenText = aligned.map((w) => w.displayWord).join(' ');

  return LocalAlignmentResult(
    words: assessments,
    accuracyScore: accuracyScore,
    completenessScore: completenessScore,
    fluencyScore: fluencyScore,
    pronScore: pronScore,
    spokenText: spokenText,
  );
}

/// Splits a reference sentence into alignment-ready words.
List<String> splitReferenceWords(String referenceText) =>
    referenceText
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .toList();

/// Synthesizes an Azure-Speech-shaped result JSON (PascalCase keys, 100-ns
/// ticks) so the existing assessment UI and storage consume it unchanged.
Map<String, dynamic> synthesizeAzureStyleAssessmentJson({
  required LocalAlignmentResult alignment,
  required String referenceText,
  required int durationMs,
}) {
  final wordsJson = alignment.words.map((w) {
    final startMs = w.startMs ?? 0;
    final endMs = w.endMs ?? startMs;
    return <String, dynamic>{
      'Word': w.displayWord,
      'Offset': startMs * 10000,
      'Duration': math.max(0, endMs - startMs) * 10000,
      'PronunciationAssessment': <String, dynamic>{
        'AccuracyScore': w.accuracyScore,
        'ErrorType': w.errorType,
      },
    };
  }).toList();

  return <String, dynamic>{
    'RecognitionStatus': 'Success',
    'Offset': 0,
    'Duration': math.max(durationMs, 0) * 10000,
    'DisplayText': referenceText,
    'NBest': <Map<String, dynamic>>[
      <String, dynamic>{
        'Confidence': 0.9,
        'Lexical': alignment.spokenText,
        'ITN': alignment.spokenText,
        'MaskedITN': alignment.spokenText,
        'Display': alignment.spokenText,
        'PronunciationAssessment': <String, dynamic>{
          'AccuracyScore': alignment.accuracyScore,
          'FluencyScore': alignment.fluencyScore,
          'CompletenessScore': alignment.completenessScore,
          'PronScore': alignment.pronScore,
        },
        'Words': wordsJson,
      },
    ],
  };
}
