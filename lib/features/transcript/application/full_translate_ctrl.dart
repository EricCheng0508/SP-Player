/// Manual full-video batch translation (ADR-0106 §5, 2026-11-27 decision).
///
/// Replaces the follow-playback per-line auto translate as the primary
/// translation path: the user explicitly clicks「翻译全片」and every line is
/// translated in merged batches (one request per ~20 lines, 6 in flight).
///
/// Progress is DERIVED, never stored separately: the AI track's lines are the
/// source of truth (empty text = untranslated, non-empty = cached), so a
/// crash or force-kill loses at most the batch in flight and reopening the
/// media shows cached translations immediately. Resume = re-run with
/// [force=false]; the scheduler receives whatever is still untranslated.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/application/app_language_catalog.dart';
import '../../../core/application/app_preferences_provider.dart';
import '../../../core/config/local_mode.dart';
import '../../../core/logging/log.dart';
import '../../../core/riverpod/async_value_x.dart';
import '../../../data/db/app_database.dart';
import '../../../data/subtitle/subtitle_markup_parser.dart';
import '../../../data/subtitle/transcript_line.dart';
import '../../ai/application/ai_capability_providers.dart';
import '../../ai/data/byok/batch_translation.dart';
import '../../ai/data/byok/byok_translation_capability.dart';
import '../../ai/data/stub_ai_capabilities.dart';
import '../../ai/domain/capabilities/llm_capability.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import 'transcript_repository_provider.dart';
import '../domain/auto_translate.dart';
import 'full_translate_scheduler.dart';

part 'full_translate_ctrl.g.dart';

final Logger _log = logNamed('full_translate');

@riverpod
class FullTranslateCtrl extends _$FullTranslateCtrl {
  bool _running = false;
  bool _cancelRequested = false;
  final _flushHookRepos = <TranscriptRepository>[];

  /// Repository access (mirrors AutoTranslateCtrl._repo): every distinct
  /// instance is registered for the disposal flush of its pending buffered
  /// writes — a force-kill loses at most the debounce window.
  TranscriptRepository _repo() {
    final repo = ref.read(transcriptRepositoryProvider);
    if (_flushHookRepos.isEmpty) {
      ref.onDispose(_flushRegisteredRepos);
    }
    if (!_flushHookRepos.contains(repo)) {
      _flushHookRepos.add(repo);
    }
    return repo;
  }

  void _flushRegisteredRepos() {
    for (final repo in _flushHookRepos) {
      unawaited(repo.flushAutoTranslateWrites());
    }
  }

  @override
  FullTranslateUiState build(String mediaId) {
    ref.onDispose(() => _cancelRequested = true);
    unawaited(_hydrateProgress());
    return const FullTranslateUiState();
  }

  /// Reads cached progress from the AI track (if any) so reopening a media
  /// shows「翻译完成」or「上次中断 n / total」without a new run.
  Future<void> _hydrateProgress() async {
    try {
      final repo = _repo();
      final primaryRow = await repo.primaryTranscriptRowForMedia(mediaId);
      if (!ref.mounted || primaryRow == null) return;
      final rows = await repo.transcriptRowsForMedia(mediaId);
      if (!ref.mounted) return;
      TranscriptRow? aiRow;
      for (final row in rows) {
        if (row.source == 'ai' && row.referenceId == primaryRow.id) {
          aiRow = row;
          break;
        }
      }
      if (aiRow == null) return;
      final aiLines = repo.linesForRow(aiRow);
      if (aiLines.isEmpty) return;
      state = _progressFrom(aiLines, FullTranslatePhase.idle);
    } on Object catch (e, st) {
      _log.warning('hydrate progress failed: $e', e, st);
    }
  }

  FullTranslateUiState _progressFrom(
    List<TranscriptLine> aiLines,
    FullTranslatePhase phase,
  ) {
    var translated = 0;
    var lastStartMs = 0;
    for (final line in aiLines) {
      if (line.text.trim().isNotEmpty) {
        translated++;
        if (line.startMs > lastStartMs) lastStartMs = line.startMs;
      }
    }
    return FullTranslateUiState(
      phase: translated >= aiLines.length
          ? FullTranslatePhase.done
          : phase,
      translatedCount: translated,
      totalCount: aiLines.length,
      lastTranslatedStartMs: lastStartMs,
    );
  }

  /// One-shot full-video translation. Safe to re-enter while running (no-op);
  /// resuming after an interruption just calls it again — untranslated lines
  /// are recomputed from the DB.
  Future<void> translateAll({bool force = false}) async {
    if (_running) return;
    _cancelRequested = false;

    // Guards mirror AutoTranslateCtrl.selectAutoTranslate.
    if (!kLocalOfflineMode) {
      final auth = ref.read(authCtrlProvider).valueOrNull;
      if (auth is! AuthSignedIn) {
        state = state.copyWith(
          phase: FullTranslatePhase.paused,
          blockReason: FullTranslateBlockReason.auth,
        );
        return;
      }
    }
    final native = ref
        .read(appPreferencesCtrlProvider)
        .valueOrNull
        ?.effectiveNativeLanguage;
    if (native == null || native.isEmpty) {
      state = state.copyWith(
        phase: FullTranslatePhase.paused,
        blockReason: FullTranslateBlockReason.noTranslatableSource,
      );
      return;
    }

    final repo = _repo();
    final primaryRow = await repo.primaryTranscriptRowForMedia(mediaId);
    if (!ref.mounted || primaryRow == null) {
      state = state.copyWith(
        phase: FullTranslatePhase.paused,
        blockReason: FullTranslateBlockReason.noTranslatableSource,
      );
      return;
    }
    final primaryLines = repo.linesForRow(primaryRow);
    if (primaryLines.isEmpty) {
      state = state.copyWith(
        phase: FullTranslatePhase.paused,
        blockReason: FullTranslateBlockReason.noTranslatableSource,
      );
      return;
    }
    final sourceLanguage = primaryRow.language;
    if (workerLanguageBase(sourceLanguage) == workerLanguageBase(native)) {
      state = state.copyWith(
        phase: FullTranslatePhase.paused,
        blockReason: FullTranslateBlockReason.noTranslatableSource,
      );
      return;
    }

    final aiId = await repo.ensureAutoTranslateTrack(
      mediaId: mediaId,
      primaryTranscriptId: primaryRow.id,
      targetLanguage: native,
      primaryLines: primaryLines,
    );
    if (!ref.mounted || aiId == null) {
      state = state.copyWith(
        phase: FullTranslatePhase.paused,
        blockReason: FullTranslateBlockReason.trackFailed,
      );
      return;
    }
    final aiRow = await repo.transcriptRowById(aiId);
    if (!ref.mounted || aiRow == null) {
      state = state.copyWith(
        phase: FullTranslatePhase.paused,
        blockReason: FullTranslateBlockReason.trackFailed,
      );
      return;
    }
    final aiLines = repo.linesForRow(aiRow);
    if (aiLines.isEmpty) {
      state = state.copyWith(
        phase: FullTranslatePhase.paused,
        blockReason: FullTranslateBlockReason.trackFailed,
      );
      return;
    }

    // Batch translation rides the same LLM the per-line capability resolved
    // (cloud LLM or local llama-server), keeping one config surface.
    final LlmCapability? llm;
    final capability = ref.read(translationCapabilityProvider);
    if (capability is ByokTranslationCapability) {
      llm = capability.llm;
    } else {
      llm = null;
    }
    if (llm == null || llm is ByokNotConfiguredLlmCapability) {
      state = state.copyWith(
        phase: FullTranslatePhase.paused,
        blockReason: FullTranslateBlockReason.noLlm,
      );
      return;
    }
    // Promote once: closures below cannot rely on flow-analysis promotion
    // of the nullable local, so bind the engine to a fresh non-null name.
    final LlmCapability engine = llm;

    // Untranslated indexes derive from the track itself (resume semantics).
    final untranslated = <int>[];
    var translatedCount = 0;
    var lastStartMs = 0;
    for (var i = 0; i < aiLines.length; i++) {
      final hasText = aiLines[i].text.trim().isNotEmpty;
      if (!hasText || force) {
        untranslated.add(i);
      } else {
        translatedCount++;
        if (aiLines[i].startMs > lastStartMs) {
          lastStartMs = aiLines[i].startMs;
        }
      }
    }
    if (untranslated.isEmpty) {
      state = FullTranslateUiState(
        phase: FullTranslatePhase.done,
        translatedCount: aiLines.length,
        totalCount: aiLines.length,
        lastTranslatedStartMs: lastStartMs,
      );
      return;
    }

    var failedCount = 0;
    _running = true;
    state = FullTranslateUiState(
      phase: FullTranslatePhase.running,
      translatedCount: translatedCount,
      totalCount: aiLines.length,
      lastTranslatedStartMs: lastStartMs,
    );
    _log.info(
      'translateAll: total=${aiLines.length} todo=${untranslated.length} '
      'force=$force',
    );

    final scheduler = FullTranslateScheduler(
      batches: chunkTranslateBatches(untranslated, kFullTranslateBatchSize),
      shouldCancel: () => _cancelRequested || !ref.mounted,
      translateBatch: (indexes, texts) =>
          translateLinesBatch(
            llm: engine,
            lines: texts,
            sourceLanguage: sourceLanguage,
            targetLanguage: native,
          ),
      onBatchTranslated: (indexes, translations) {
        if (!ref.mounted) return;
        for (var i = 0; i < indexes.length && i < translations.length; i++) {
          final index = indexes[i];
          final sourceKey = autoTranslateSourceKey(
            primaryText: primaryLines[index].text,
            sourceLanguage: sourceLanguage,
            targetLanguage: native,
          );
          // Write buffer debounces the row rewrite (issue #810 D1); reads
          // via linesForRow see buffered text immediately.
          unawaited(
            repo.updateAutoTranslateLineText(
              aiTranscriptId: aiId,
              lineIndex: index,
              text: translations[i],
              sourceKey: sourceKey,
            ),
          );
          final startMs = primaryLines[index].startMs;
          if (startMs > lastStartMs) lastStartMs = startMs;
        }
        translatedCount += indexes.length;
        state = state.copyWith(
          translatedCount: math.min(translatedCount, aiLines.length),
          lastTranslatedStartMs: lastStartMs,
        );
      },
      onBatchFailed: (indexes) {
        failedCount += indexes.length;
        if (!ref.mounted) return;
        state = state.copyWith(failedCount: failedCount);
      },
    );

    try {
      await scheduler.run(textsFor: (indexes) async {
        return [
          for (final i in indexes)
            plainTextFromSubtitleMarkup(primaryLines[i].text).trim(),
        ];
      });
      // Persist everything pending now — the debounce timer is for scattered
      // per-line writes, a batch run wants the durable write immediately.
      await repo.flushAutoTranslateWrites();
    } on Object catch (e, st) {
      _log.warning('translateAll failed: $e', e, st);
    } finally {
      _running = false;
    }

    if (!ref.mounted) return;
    final complete = translatedCount >= aiLines.length;
    state = state.copyWith(
      phase: complete ? FullTranslatePhase.done : FullTranslatePhase.paused,
      blockReason: complete
          ? null
          : (failedCount > 0
                ? FullTranslateBlockReason.partialFailure
                : FullTranslateBlockReason.stopped),
      clearBlockReason: complete,
    );
    _log.info(
      'translateAll finished: translated=$translatedCount '
      'total=${aiLines.length} failed=$failedCount cancelled=$_cancelRequested',
    );
  }

  /// Stops starting NEW batches; in-flight ones finish and persist.
  void cancel() {
    if (_running) _cancelRequested = true;
  }
}
