/// Scheduling pool for manual full-video batch translation (ADR-0106 §5).
///
/// Pure Dart with injected callbacks — mirrors [AutoTranslateLineQueue]'s
/// testability contract. Batches are precomputed chunks of untranslated line
/// indexes; [run] keeps up to [kFullTranslateConcurrency] requests in flight,
/// reports each persisted batch, and stops starting new work when the
/// injected cancel check flips true (in-flight batches finish so their
/// translations are never lost).
library;

import 'dart:async';

import 'package:enjoy_player/features/transcript/domain/auto_translate.dart';

/// Chunks ordered line indexes into consecutive batches of [batchSize].
/// Pure — resume semantics fall out for free: the caller passes whatever is
/// still untranslated after a crash and this produces the remaining batches.
List<List<int>> chunkTranslateBatches(List<int> indexes, int batchSize) {
  final batches = <List<int>>[];
  for (var i = 0; i < indexes.length; i += batchSize) {
    final end = (i + batchSize).clamp(i + 1, indexes.length);
    batches.add(indexes.sublist(i, end));
  }
  return batches;
}

class FullTranslateScheduler {
  FullTranslateScheduler({
    required this.batches,
    required this.translateBatch,
    required this.onBatchTranslated,
    required this.onBatchFailed,
    this.shouldCancel,
  });

  /// Untranslated line indexes grouped into consecutive batches.
  final List<List<int>> batches;

  /// One LLM request for the batch. Returns per-line translations in the
  /// same order, or null when the batch reply was unparseable.
  final Future<List<String>?> Function(
    List<int> indexes,
    List<String> texts,
  )
  translateBatch;

  /// Called after translations for [indexes] persisted (write buffer enqueued).
  final void Function(List<int> indexes, List<String> translations)
  onBatchTranslated;

  /// Called when the batch failed (transport error or unparseable reply).
  /// Failed lines keep empty text — a later run picks them up as resume work.
  final void Function(List<int> indexes) onBatchFailed;

  /// When true, no NEW batch starts (in-flight ones finish).
  final bool Function()? shouldCancel;

  /// Runs the pool; completes when every batch is done, failed or skipped.
  Future<void> run({
    required Future<List<String>> Function(List<int> indexes) textsFor,
  }) async {
  var next = 0;

    Future<void> worker() async {
      while (true) {
        if (shouldCancel?.call() ?? false) return;
        final current = next++;
        if (current >= batches.length) return;
        final indexes = batches[current];
        try {
          final texts = await textsFor(indexes);
          final translations = await translateBatch(indexes, texts);
          if (translations == null) {
            onBatchFailed(indexes);
          } else {
            onBatchTranslated(indexes, translations);
          }
        } on Object {
          onBatchFailed(indexes);
        }
      }
    }

    final workers = List.generate(
      batches.length.clamp(0, kFullTranslateConcurrency),
      (_) => worker(),
    );
    await Future.wait(workers);
  }
}
