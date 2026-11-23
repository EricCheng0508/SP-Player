/// Transport-side batching decorator for the translation capability.
library;

import 'dart:async';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/batch_translation_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/translation_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/translation_result.dart';
import 'package:enjoy_player/features/ai/domain/prompts/translation_prompt.dart';

/// How long concurrent per-line calls are collected before one batched LLM
/// call fires. Short enough to be invisible, long enough for the controller's
/// viewport burst (all visible cues request within one frame's microtasks) to
/// land in the same batch.
const kAutoTranslateBatchWindow = Duration(milliseconds: 15);

/// Coalesces concurrent single-line [TranslationCapability.translate] calls
/// into one numbered-list LLM call.
///
/// The auto-translate controller submits lines one at a time (viewport-
/// driven). This decorator groups whatever is concurrently in flight — up to
/// [kAutoTranslateBatchMaxLines] lines / [kAutoTranslateBatchMaxChars] chars —
/// so the system prompt and the HTTP round trip amortize over a whole
/// screenful instead of repeating per cue. Controller-side caching, staleness
/// checks, retry loops and block reasons stay untouched: every coalesced
/// line keeps its own future, its own result and its own error.
///
/// A `forceRefresh` request (user re-translate) never joins a batch: it goes
/// straight to the single-line capability.
class BatchingTranslationCapability implements TranslationCapability {
  BatchingTranslationCapability(this._inner, this._batch);

  final TranslationCapability _inner;
  final BatchTranslationCapability _batch;
  final Map<String, _BatchGroup> _groups = {};

  @override
  Future<TranslationResult> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    bool? forceRefresh,
  }) {
    if (forceRefresh == true) {
      return _inner.translate(
        text: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        forceRefresh: true,
      );
    }
    final key =
        '${workerLanguageBase(sourceLanguage)}>'
        '${workerLanguageBase(targetLanguage)}';
    final group = _groups.putIfAbsent(
      key,
      () => _BatchGroup(
        outer: this,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      ),
    );
    final entry = _PendingEntry(text);
    group.pending.add(entry);
    if (group.pending.length >= kAutoTranslateBatchMaxLines ||
        group.pendingChars >= kAutoTranslateBatchMaxChars) {
      group.flush();
    } else {
      group.timer ??= Timer(kAutoTranslateBatchWindow, group.flush);
    }
    return entry.completer.future;
  }
}

class _PendingEntry {
  _PendingEntry(this.text);

  final String text;
  final completer = Completer<TranslationResult>();
}

class _BatchGroup {
  _BatchGroup({
    required this.outer,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  final BatchingTranslationCapability outer;
  final String sourceLanguage;
  final String targetLanguage;

  final List<_PendingEntry> pending = <_PendingEntry>[];
  Timer? timer;

  int get pendingChars {
    var total = 0;
    for (final e in pending) {
      total += e.text.length;
    }
    return total;
  }

  /// Slices up to the batch caps off [pending] and fires one LLM call.
  /// Leftovers stay pending with a fresh window, so a burst larger than the
  /// caps spills into follow-up batches.
  void flush() {
    timer?.cancel();
    timer = null;
    if (pending.isEmpty) return;

    final slice = <_PendingEntry>[];
    var chars = 0;
    while (pending.isNotEmpty &&
        slice.length < kAutoTranslateBatchMaxLines &&
        chars < kAutoTranslateBatchMaxChars) {
      final candidate = pending.first;
      if (slice.isNotEmpty &&
          chars + candidate.text.length > kAutoTranslateBatchMaxChars) {
        break;
      }
      chars += candidate.text.length;
      slice.add(pending.removeAt(0));
    }
    if (pending.isNotEmpty) {
      timer ??= Timer(kAutoTranslateBatchWindow, flush);
    }

    unawaited(_runSlice(slice));
  }

  Future<void> _runSlice(List<_PendingEntry> slice) async {
    try {
      final results = await outer._batch.translateLines(
        lines: [for (final entry in slice) entry.text],
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      for (var i = 0; i < slice.length; i++) {
        final text = results[i]?.trim();
        if (text == null || text.isEmpty) {
          // The model skipped this line — rescue it with a single call
          // rather than surfacing a failure for the whole batch.
          unawaited(_runFallback(slice[i]));
        } else if (!slice[i].completer.isCompleted) {
          slice[i].completer.complete(
            TranslationResult(
              translatedText: text,
              sourceLanguage: workerLanguageBase(sourceLanguage),
              targetLanguage: workerLanguageBase(targetLanguage),
            ),
          );
        }
      }
    } on Object catch (error, stackTrace) {
      for (final entry in slice) {
        if (!entry.completer.isCompleted) {
          entry.completer.completeError(error, stackTrace);
        }
      }
    }
  }

  Future<void> _runFallback(_PendingEntry entry) async {
    try {
      final result = await outer._inner.translate(
        text: entry.text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      if (!entry.completer.isCompleted) entry.completer.complete(result);
    } on Object catch (error, stackTrace) {
      if (!entry.completer.isCompleted) {
        entry.completer.completeError(error, stackTrace);
      }
    }
  }
}
