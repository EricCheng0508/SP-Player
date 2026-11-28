import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/transcript/application/full_translate_scheduler.dart';
import 'package:enjoy_player/features/transcript/domain/auto_translate.dart';

void main() {
  group('chunkTranslateBatches', () {
    test('splits ordered indexes into consecutive groups', () {
      final batches = chunkTranslateBatches([
        0,
        1,
        2,
        3,
        4,
        5,
        6,
      ], kFullTranslateBatchSize);
      // 7 lines < batch size → one batch covering all.
      expect(batches.length, 1);
      expect(batches.single, [0, 1, 2, 3, 4, 5, 6]);
    });

    test('resume naturally: only untranslated indexes are chunked', () {
      // After a crash at line 178 of 200: lines 0..177 cached, rest to do.
      final remaining = List<int>.generate(22, (i) => 178 + i);
      final batches = chunkTranslateBatches(remaining, 20);
      expect(batches.length, 2);
      expect(batches[0].length, 20);
      expect(batches[1].length, 2);
      expect(batches[1].first, 198);
    });

    test('empty input produces no batches', () {
      expect(chunkTranslateBatches(const [], 20), isEmpty);
    });
  });

  group('FullTranslateScheduler', () {
    test(
      'runs batches up to the concurrency limit and reports success',
      () async {
        var inFlight = 0;
        var maxInFlight = 0;
        final persisted = <int>[];
        final failed = <int>[];

        // Twelve single-line batches: enough work to saturate the pool.
        final batches = [
          for (var i = 0; i < 12; i++) [i],
        ];
        final scheduler = FullTranslateScheduler(
          batches: batches,
          translateBatch: (indexes, texts) async {
            inFlight++;
            maxInFlight = maxInFlight > inFlight ? maxInFlight : inFlight;
            await Future<void>.delayed(const Duration(milliseconds: 5));
            inFlight--;
            return [for (final _ in indexes) '译文'];
          },
          onBatchTranslated: (indexes, _) => persisted.addAll(indexes),
          onBatchFailed: failed.addAll,
        );

        await scheduler.run(
          textsFor: (indexes) async {
            return [for (final _ in indexes) 'text'];
          },
        );

        expect(persisted, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);
        expect(failed, isEmpty);
        expect(maxInFlight, kFullTranslateConcurrency);
      },
    );

    test(
      'failed batches do not stop the run and report their indexes',
      () async {
        final persisted = <int>[];
        final failed = <int>[];
        final scheduler = FullTranslateScheduler(
          batches: [
            [0, 1],
            [2, 3],
          ],
          translateBatch: (indexes, texts) async {
            if (indexes.first == 0) return null; // unparseable reply
            throw StateError('transport down');
          },
          onBatchTranslated: (indexes, _) => persisted.addAll(indexes),
          onBatchFailed: failed.addAll,
        );

        await scheduler.run(textsFor: (indexes) async => ['a', 'b']);

        expect(persisted, isEmpty);
        expect(failed, [0, 1, 2, 3]);
      },
    );

    test('cancel stops NEW batches but finishes in-flight ones', () async {
      final persisted = <int>[];
      final failed = <int>[];
      var cancel = false;
      final started = <int>[];

      final scheduler = FullTranslateScheduler(
        batches: [
          for (var i = 0; i < 12; i++) [i],
        ],
        shouldCancel: () => cancel,
        translateBatch: (indexes, texts) async {
          started.add(indexes.first);
          // The first batch flips cancel so no NEW batch starts after it.
          if (indexes.first == 0) cancel = true;
          return [for (final _ in indexes) '译文'];
        },
        onBatchTranslated: (indexes, _) => persisted.addAll(indexes),
        onBatchFailed: failed.addAll,
      );

      await scheduler.run(textsFor: (indexes) async => ['x']);

      // Batch 0 always starts and persists; the pool has 6 workers so some
      // early batches race past the flag, but most of the 12 never start.
      expect(started.first, 0);
      expect(persisted, contains(0));
      expect(started.length, lessThan(12));
      expect(failed, isEmpty);
    });
  });

  group('FullTranslateUiState', () {
    test('isComplete derives from counts', () {
      const done = FullTranslateUiState(
        phase: FullTranslatePhase.running,
        translatedCount: 344,
        totalCount: 344,
      );
      expect(done.isComplete, isTrue);

      const partial = FullTranslateUiState(
        phase: FullTranslatePhase.running,
        translatedCount: 178,
        totalCount: 344,
      );
      expect(partial.isComplete, isFalse);
    });

    test('copyWith clearBlockReason resets to null', () {
      const blocked = FullTranslateUiState(
        phase: FullTranslatePhase.paused,
        blockReason: FullTranslateBlockReason.noLlm,
      );
      final cleared = blocked.copyWith(
        phase: FullTranslatePhase.done,
        clearBlockReason: true,
      );
      expect(cleared.phase, FullTranslatePhase.done);
      expect(cleared.blockReason, isNull);
    });
  });
}
