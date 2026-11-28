/// Domain models and pure helpers for the AI translation track.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/ids/enjoy_ids.dart';
import 'package:enjoy_player/core/utils/text_normalization.dart';
import 'package:enjoy_player/data/subtitle/subtitle_markup_parser.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';

/// Deterministic AI translation track id for a media + target language.
String autoTranslateAiTrackId({
  required String targetType,
  required String mediaId,
  required String targetLanguage,
}) => enjoyTranscriptId(
  targetType: targetType,
  targetId: mediaId,
  language: targetLanguage,
  source: 'ai',
);

/// Whether [aiLines] no longer matches [primaryLines] timings/count or [primaryId].
bool isAutoTranslateTimelineStale({
  required String? referencePrimaryId,
  required String primaryId,
  required List<TranscriptLine> primaryLines,
  required List<TranscriptLine> aiLines,
}) {
  if (referencePrimaryId != primaryId) return true;
  if (primaryLines.length != aiLines.length) return true;
  for (var i = 0; i < primaryLines.length; i++) {
    if (primaryLines[i].startMs != aiLines[i].startMs ||
        primaryLines[i].durationMs != aiLines[i].durationMs) {
      return true;
    }
  }
  return false;
}

/// Builds a skeleton timeline mirroring primary timings with empty text.
List<TranscriptLine> buildAutoTranslateSkeleton(
  List<TranscriptLine> primaryLines,
) {
  return primaryLines
      .map(
        (p) => TranscriptLine(
          text: '',
          startMs: p.startMs,
          durationMs: p.durationMs,
        ),
      )
      .toList();
}

/// Normalizes primary cue text for translation cache identity.
String normalizeAutoTranslateSourceText(String raw) {
  final plain = plainTextFromSubtitleMarkup(raw).trim();
  if (plain.isEmpty) return '';
  return collapseWhitespace(plain);
}

/// Content key for a primary cue + language pair (truncated SHA-256 hex).
String autoTranslateSourceKey({
  required String primaryText,
  required String sourceLanguage,
  required String targetLanguage,
}) {
  final normalized = normalizeAutoTranslateSourceText(primaryText);
  final src = workerLanguageBase(sourceLanguage);
  final tgt = workerLanguageBase(targetLanguage);
  final payload = '$normalized|$src|$tgt';
  return sha256.convert(utf8.encode(payload)).toString().substring(0, 32);
}

typedef _SourceKeyEntry = ({String source, String target, String key});

/// Expected source keys memoized per primary line instance.
///
/// Weak keys: an entry dies with the line it was derived from, so no
/// eviction policy is needed. [TranscriptLine.text] is final, so a cached
/// key stays valid for the instance's lifetime.
final Expando<_SourceKeyEntry> _sourceKeyMemo = Expando<_SourceKeyEntry>(
  'autoTranslateSourceKeyForLine',
);

/// Number of keys derived rather than read from [_sourceKeyMemo].
@visibleForTesting
int autoTranslateSourceKeyDerivationCount = 0;

String _sourceKeyForPrimaryLine(
  TranscriptLine primaryLine,
  String sourceLanguage,
  String targetLanguage,
) {
  final memoized = _sourceKeyMemo[primaryLine];
  if (memoized != null &&
      memoized.source == sourceLanguage &&
      memoized.target == targetLanguage) {
    return memoized.key;
  }
  final key = autoTranslateSourceKey(
    primaryText: primaryLine.text,
    sourceLanguage: sourceLanguage,
    targetLanguage: targetLanguage,
  );
  _sourceKeyMemo[primaryLine] = (
    source: sourceLanguage,
    target: targetLanguage,
    key: key,
  );
  autoTranslateSourceKeyDerivationCount++;
  return key;
}

/// Secondary text for AI overlay at [lineIndex], or null when empty / soft-stale.
///
/// Uses primary index (not time matching). When [sourceLanguage] and
/// [targetLanguage] are set, requires [TranscriptLine.sourceKey] to match.
String? resolveAutoTranslateSecondaryText({
  required List<TranscriptLine> primaryLines,
  required List<TranscriptLine> aiLines,
  required int lineIndex,
  String? sourceLanguage,
  String? targetLanguage,
}) {
  if (lineIndex < 0 || lineIndex >= primaryLines.length) return null;
  if (lineIndex >= aiLines.length) return null;
  final slot = aiLines[lineIndex];
  final text = slot.text.trim();
  if (text.isEmpty) return null;

  final src = sourceLanguage;
  final tgt = targetLanguage;
  if (src != null && src.isNotEmpty && tgt != null && tgt.isNotEmpty) {
    final expected = _sourceKeyForPrimaryLine(
      primaryLines[lineIndex],
      src,
      tgt,
    );
    final stored = slot.sourceKey;
    if (stored == null || stored != expected) return null;
  }
  return slot.text;
}

/// Window from the first buffered translated line to the row flush
/// (issue #810 D1). A hard kill loses at most this much translated text;
/// a normal screen exit flushes everything pending immediately.
const Duration kAutoTranslateFlushInterval = Duration(milliseconds: 1000);

// --- Full-video manual batch translation (ADR-0106 §5, 2026-11-27 decision).

/// Lines merged into ONE translation request. Merging cuts request count by
/// this factor (344 lines → 18 requests) and gives the model cross-line
/// context so terminology and person naming stay consistent.
const kFullTranslateBatchSize = 20;

/// Batch requests in flight simultaneously. The old per-line path ran at
/// concurrency 2 with one request per line — the measured cause of slow
/// full-video translation. Batch-level concurrency 6 targets ~1–2 min for a
/// 344-line episode over a cloud LLM.
const kFullTranslateConcurrency = 6;

/// Phases of the manual full-video translation job (banner drives off this).
enum FullTranslatePhase {
  /// No run yet for this media (banner shows the call-to-action).
  idle,

  /// Batches in flight; [FullTranslateUiState.translatedCount] grows per
  /// persisted batch.
  running,

  /// Stopped before completion (user cancel / batches failed) — cached
  /// progress stays usable, "continue translation" resumes from the first
  /// untranslated line.
  paused,

  /// Every line has cached text; reopening the media shows translations
  /// directly.
  done,
}

/// Why a full-video translation run is paused / refused. UI maps these to
/// l10n strings — the controller carries no user-facing text.
enum FullTranslateBlockReason {
  /// No LLM configured (cloud) or capability unavailable.
  noLlm,

  /// Guard failures: no native language, no primary track, same language.
  noTranslatableSource,

  /// Track creation failed.
  trackFailed,

  /// Some batches failed; [FullTranslateUiState.failedCount] says how many.
  partialFailure,

  /// User stopped the run; continue translation resumes.
  stopped,
}

/// UI state for the full-video translation banner. Progress is derived from
/// the AI track itself (empty text = untranslated, non-empty = cached), so a
/// crash or force-kill never loses more than the batch in flight.
class FullTranslateUiState {
  const FullTranslateUiState({
    this.phase = FullTranslatePhase.idle,
    this.translatedCount = 0,
    this.totalCount = 0,
    this.lastTranslatedStartMs = 0,
    this.failedCount = 0,
    this.blockReason,
  });

  final FullTranslatePhase phase;
  final int translatedCount;
  final int totalCount;

  /// Start position of the furthest translated line — powers the
  /// "已翻译到视频第 X 分钟" meta line without re-reading the DB per batch.
  final int lastTranslatedStartMs;

  final int failedCount;
  final FullTranslateBlockReason? blockReason;

  bool get isComplete =>
      phase == FullTranslatePhase.done ||
      (totalCount > 0 && translatedCount >= totalCount);

  FullTranslateUiState copyWith({
    FullTranslatePhase? phase,
    int? translatedCount,
    int? totalCount,
    int? lastTranslatedStartMs,
    int? failedCount,
    FullTranslateBlockReason? blockReason,
    bool clearBlockReason = false,
  }) {
    return FullTranslateUiState(
      phase: phase ?? this.phase,
      translatedCount: translatedCount ?? this.translatedCount,
      totalCount: totalCount ?? this.totalCount,
      lastTranslatedStartMs:
          lastTranslatedStartMs ?? this.lastTranslatedStartMs,
      failedCount: failedCount ?? this.failedCount,
      blockReason: clearBlockReason ? null : (blockReason ?? this.blockReason),
    );
  }
}
