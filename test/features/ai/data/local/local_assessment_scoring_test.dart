import 'dart:convert';

import 'package:azure_speech/azure_speech.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/ai/data/local/local_assessment_scoring.dart';

void main() {
  group('normalizeAssessmentWord', () {
    test('lowercases and strips punctuation', () {
      expect(normalizeAssessmentWord('Hello,'), 'hello');
      expect(normalizeAssessmentWord("Everyone's"), "everyone's");
      expect(normalizeAssessmentWord('Hard-Time.'), 'hardtime');
    });
  });

  group('wordSimilarity', () {
    test('identical words score 1', () {
      expect(wordSimilarity('time', 'time'), 1);
    });

    test('typos keep high similarity', () {
      expect(wordSimilarity('everyone', 'everyon'), greaterThan(0.8));
    });

    test('unrelated words score low', () {
      expect(wordSimilarity('problem', 'banana'), lessThan(0.2));
    });
  });

  group('assessLocalPronunciation', () {
    test('perfect read scores 100 across the board', () {
      final r = assessLocalPronunciation(
        referenceWords: ['yeah', 'everyone', 'having', 'a', 'hard', 'time'],
        spokenWords: [
          (word: 'Yeah', startMs: 0, endMs: 300),
          (word: 'everyone', startMs: 320, endMs: 800),
          (word: 'having', startMs: 830, endMs: 1200),
          (word: 'a', startMs: 1220, endMs: 1300),
          (word: 'hard', startMs: 1320, endMs: 1600),
          (word: 'time', startMs: 1620, endMs: 1900),
        ],
      );
      expect(r.accuracyScore, 100);
      expect(r.completenessScore, 100);
      expect(r.fluencyScore, 100);
      expect(r.pronScore, 100);
      expect(r.words.every((w) => w.errorType == 'None'), isTrue);
    });

    test('skipped reference words become omissions', () {
      final r = assessLocalPronunciation(
        referenceWords: ['yeah', 'everyone', 'having', 'a', 'hard', 'time'],
        spokenWords: [
          (word: 'yeah', startMs: 0, endMs: 300),
          (word: 'having', startMs: 330, endMs: 700),
          (word: 'hard', startMs: 730, endMs: 1000),
          (word: 'time', startMs: 1030, endMs: 1300),
        ],
      );
      final omitted = r.words
          .where((w) => w.errorType == 'Omission')
          .map((w) => normalizeAssessmentWord(w.displayWord))
          .toList();
      expect(omitted, ['everyone', 'a']);
      expect(r.completenessScore, lessThan(100));
      expect(r.accuracyScore, lessThan(100));
    });

    test('extra spoken words become insertions in timeline order', () {
      final r = assessLocalPronunciation(
        referenceWords: ['good', 'morning'],
        spokenWords: [
          (word: 'good', startMs: 0, endMs: 300),
          (word: 'very', startMs: 320, endMs: 500),
          (word: 'morning', startMs: 530, endMs: 900),
        ],
      );
      final kinds = r.words.map((w) => w.errorType).toList();
      expect(kinds, contains('Insertion'));
      final insertion = r.words.firstWhere((w) => w.errorType == 'Insertion');
      expect(normalizeAssessmentWord(insertion.displayWord), 'very');
      expect(insertion.startMs, 320);
    });

    test('mispronounced word keeps a reduced accuracy score', () {
      final r = assessLocalPronunciation(
        referenceWords: ['think'],
        spokenWords: [(word: 'thank', startMs: 0, endMs: 400)],
      );
      expect(r.words.single.errorType, 'Mispronunciation');
      final s = r.words.single.accuracyScore;
      expect(s, greaterThan(50));
      expect(s, lessThan(100));
    });

    test('long mid-sentence pauses reduce fluency', () {
      final steady = assessLocalPronunciation(
        referenceWords: ['one', 'two', 'three'],
        spokenWords: [
          (word: 'one', startMs: 0, endMs: 300),
          (word: 'two', startMs: 320, endMs: 600),
          (word: 'three', startMs: 620, endMs: 900),
        ],
      );
      final stalled = assessLocalPronunciation(
        referenceWords: ['one', 'two', 'three'],
        spokenWords: [
          (word: 'one', startMs: 0, endMs: 300),
          (word: 'two', startMs: 2200, endMs: 2500),
          (word: 'three', startMs: 4400, endMs: 4700),
        ],
      );
      expect(stalled.fluencyScore, lessThan(steady.fluencyScore));
    });

    test('nothing recognized → all reference words omitted', () {
      final r = assessLocalPronunciation(
        referenceWords: ['good', 'morning'],
        spokenWords: [],
      );
      expect(r.words.every((w) => w.errorType == 'Omission'), isTrue);
      expect(r.accuracyScore, 0);
      expect(r.pronScore, 0);
    });
  });

  group('synthesizeAzureStyleAssessmentJson', () {
    test('output parses back into Azure result with matching scores', () {
      final alignment = assessLocalPronunciation(
        referenceWords: ['yeah', 'everyone', 'having', 'a', 'hard', 'time'],
        spokenWords: [
          (word: 'Yeah', startMs: 0, endMs: 300),
          (word: 'everyone', startMs: 320, endMs: 800),
          (word: 'having', startMs: 830, endMs: 1200),
          (word: 'a', startMs: 1220, endMs: 1300),
          (word: 'hard', startMs: 1320, endMs: 1600),
          (word: 'time', startMs: 1620, endMs: 1900),
        ],
      );
      final json = synthesizeAzureStyleAssessmentJson(
        alignment: alignment,
        referenceText: 'Yeah, everyone having a hard time.',
        durationMs: 1900,
      );

      // Round-trips through real storage paths (jsonEncode → fromJson).
      final parsed = AzurePronunciationAssessmentResult.fromJson(
        jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
      );
      final ps = parsed.primaryScores!;
      expect(ps.accuracyScore, alignment.accuracyScore.toDouble());
      expect(ps.fluencyScore, alignment.fluencyScore.toDouble());
      expect(ps.completenessScore, alignment.completenessScore.toDouble());
      expect(ps.pronScore, alignment.pronScore.toDouble());
      expect(parsed.displayText, 'Yeah, everyone having a hard time.');
      expect(parsed.nBest.single.words, hasLength(alignment.words.length));
      // Ticks are 100-ns units: 300 ms → 3,000,000.
      expect(parsed.nBest.single.words.first.offset, 0);
      expect(parsed.nBest.single.words.first.duration, 3000000);
    });

    test('omission words carry zero duration (not clip-eligible)', () {
      final alignment = assessLocalPronunciation(
        referenceWords: ['good', 'morning'],
        spokenWords: [(word: 'good', startMs: 0, endMs: 300)],
      );
      final json = synthesizeAzureStyleAssessmentJson(
        alignment: alignment,
        referenceText: 'good morning',
        durationMs: 300,
      );
      final words = json['NBest'][0]['Words'] as List<dynamic>;
      final omission = words.firstWhere(
        (w) => w['PronunciationAssessment']['ErrorType'] == 'Omission',
      );
      expect(omission['Duration'], 0);
    });
  });
}
