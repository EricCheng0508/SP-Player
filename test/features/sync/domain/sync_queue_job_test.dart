/// Tests for [sync_queue_job.dart] — the typed enqueue seam (issue #718).
///
/// Pins both halves of the seam contract:
///   * `decode` owns row interpretation: every persisted `(entityType,
///     action)` pair maps to exactly one variant (or null when the row is
///     undecodable — dropped by the drain).
///   * `encode` reproduces the pre-seam wire columns byte-for-byte, so rows
///     written before/after the seam are indistinguishable.
library;

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/youtube_subscription_source.dart';
import 'package:enjoy_player/features/sync/domain/sync_queue_job.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';
import 'package:flutter_test/flutter_test.dart';

SyncQueueRow _row({
  required String entityType,
  required String entityId,
  required String action,
  String? payloadJson,
}) => SyncQueueRow(
  id: 1,
  entityType: entityType,
  entityId: entityId,
  action: action,
  payloadJson: payloadJson,
  retryCount: 0,
  lastAttempt: null,
  error: null,
  createdAt: DateTime.utc(2026, 9, 16),
);

void main() {
  group('SyncQueueJob.decode', () {
    test('maps every delete wire pair to its Delete variant', () {
      expect(
        SyncQueueJob.decode(
          _row(entityType: 'audio', entityId: 'a1', action: 'delete'),
        ),
        isA<SyncAudioDelete>().having((j) => j.id, 'id', 'a1'),
      );
      expect(
        SyncQueueJob.decode(
          _row(entityType: 'video', entityId: 'v1', action: 'delete'),
        ),
        isA<SyncVideoDelete>().having((j) => j.id, 'id', 'v1'),
      );
      expect(
        SyncQueueJob.decode(
          _row(entityType: 'recording', entityId: 'r1', action: 'delete'),
        ),
        isA<SyncRecordingDelete>().having((j) => j.id, 'id', 'r1'),
      );
      expect(
        SyncQueueJob.decode(
          _row(
            entityType: 'youtube_subscription',
            entityId: 'ch-1',
            action: 'delete',
          ),
        ),
        isA<SyncYoutubeSubscriptionDelete>().having(
          (j) => j.channelId,
          'channelId',
          'ch-1',
        ),
      );
      expect(
        SyncQueueJob.decode(
          _row(
            entityType: 'vocabulary_item',
            entityId: 'vi1',
            action: 'delete',
          ),
        ),
        isA<SyncVocabularyItemDelete>().having((j) => j.id, 'id', 'vi1'),
      );
      expect(
        SyncQueueJob.decode(
          _row(
            entityType: 'vocabulary_context',
            entityId: 'vc1',
            action: 'delete',
          ),
        ),
        isA<SyncVocabularyContextDelete>().having((j) => j.id, 'id', 'vc1'),
      );
    });

    test('maps every upsert wire pair to its Upsert variant', () {
      for (final action in [SyncAction.create, SyncAction.update]) {
        expect(
          SyncQueueJob.decode(
            _row(entityType: 'audio', entityId: 'a1', action: action.wireName),
          ),
          isA<SyncAudioUpsert>()
              .having((j) => j.id, 'id', 'a1')
              .having((j) => j.action, 'action', action),
        );
        expect(
          SyncQueueJob.decode(
            _row(entityType: 'video', entityId: 'v1', action: action.wireName),
          ),
          isA<SyncVideoUpsert>()
              .having((j) => j.id, 'id', 'v1')
              .having((j) => j.action, 'action', action),
        );
        expect(
          SyncQueueJob.decode(
            _row(
              entityType: 'recording',
              entityId: 'r1',
              action: action.wireName,
            ),
          ),
          isA<SyncRecordingUpsert>()
              .having((j) => j.id, 'id', 'r1')
              .having((j) => j.action, 'action', action),
        );
        expect(
          SyncQueueJob.decode(
            _row(
              entityType: 'youtube_subscription',
              entityId: 'ch-1',
              action: action.wireName,
            ),
          ),
          isA<SyncYoutubeSubscriptionUpsert>()
              .having((j) => j.channelId, 'channelId', 'ch-1')
              .having((j) => j.action, 'action', action),
        );
        expect(
          SyncQueueJob.decode(
            _row(
              entityType: 'vocabulary_item',
              entityId: 'vi1',
              action: action.wireName,
            ),
          ),
          isA<SyncVocabularyItemUpsert>()
              .having((j) => j.id, 'id', 'vi1')
              .having((j) => j.action, 'action', action),
        );
        expect(
          SyncQueueJob.decode(
            _row(
              entityType: 'vocabulary_context',
              entityId: 'vc1',
              action: action.wireName,
            ),
          ),
          isA<SyncVocabularyContextUpsert>()
              .having((j) => j.id, 'id', 'vc1')
              .having((j) => j.action, 'action', action),
        );
      }
    });

    test('unknown entityType or action is undecodable (null)', () {
      expect(
        SyncQueueJob.decode(
          _row(entityType: 'bogus', entityId: 'x', action: 'create'),
        ),
        isNull,
      );
      expect(
        SyncQueueJob.decode(
          _row(entityType: 'audio', entityId: 'x', action: 'bogus'),
        ),
        isNull,
      );
    });

    test(
      'delete wins over a youtube_upload payload (payload only rides upserts)',
      () {
        final job = SyncQueueJob.decode(
          _row(
            entityType: 'video',
            entityId: 'v-gone',
            action: 'delete',
            payloadJson: jsonEncode({
              'kind': 'youtube_upload',
              'videoId': 'v',
              'language': 'en',
              'source': 'official',
              'timeline': [
                {'text': 'hello', 'start': 0, 'duration': 1000},
              ],
            }),
          ),
        );
        expect(job, isA<SyncVideoDelete>());
      },
    );
  });

  group('SyncQueueJob.encode', () {
    test('upsert variants reproduce the pre-seam wire columns', () {
      expect(
        const SyncAudioUpsert(
          id: 'a1',
          action: SyncAction.create,
          payloadJson: '{"id":"a1"}',
        ).encode(),
        const SyncQueueJobWire(
          entityType: 'audio',
          entityId: 'a1',
          action: 'create',
          payloadJson: '{"id":"a1"}',
        ),
      );
      expect(
        const SyncVocabularyContextUpsert(
          id: 'vc1',
          action: SyncAction.update,
        ).encode(),
        const SyncQueueJobWire(
          entityType: 'vocabulary_context',
          entityId: 'vc1',
          action: 'update',
        ),
      );
    });

    test('delete variants emit a null payload', () {
      for (final wire in [
        const SyncAudioDelete(id: 'a1'),
        const SyncVideoDelete(id: 'v1'),
        const SyncRecordingDelete(id: 'r1'),
        const SyncYoutubeSubscriptionDelete(channelId: 'ch1'),
        const SyncVocabularyItemDelete(id: 'vi1'),
        const SyncVocabularyContextDelete(id: 'vc1'),
      ]) {
        final encoded = wire.encode();
        expect(encoded.action, 'delete', reason: wire.runtimeType.toString());
        expect(
          encoded.payloadJson,
          isNull,
          reason: wire.runtimeType.toString(),
        );
      }
    });

    test('upsert constructors reject delete actions (loud, not silent)', () {
      expect(
        () => SyncAudioUpsert(id: 'a1', action: SyncAction.delete),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('SyncQueueJob.deleteFor', () {
    test('builds a null-payload delete job for every entity type', () {
      final cases = <SyncEntityType, Matcher>{
        SyncEntityType.audio: isA<SyncAudioDelete>(),
        SyncEntityType.video: isA<SyncVideoDelete>(),
        SyncEntityType.recording: isA<SyncRecordingDelete>(),
        SyncEntityType.youtubeSubscription:
            isA<SyncYoutubeSubscriptionDelete>(),
        SyncEntityType.vocabularyItem: isA<SyncVocabularyItemDelete>(),
        SyncEntityType.vocabularyContext: isA<SyncVocabularyContextDelete>(),
      };
      cases.forEach((type, matcher) {
        final job = SyncQueueJob.deleteFor(type, 'entity-1');
        expect(job, matcher, reason: type.name);
        expect(job.encode().payloadJson, isNull, reason: type.name);
        expect(job.encode().action, 'delete', reason: type.name);
        expect(job.encode().entityId, 'entity-1', reason: type.name);
      });
    });
  });

  group('SyncQueueJob.snapshotUpsert (absorbed enqueuePendingSync)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    Future<AudioRow> insertAudio(String id) async {
      final now = DateTime.utc(2026, 9, 16);
      final row = AudioRow(
        id: id,
        aid: id,
        provider: 'user',
        title: 't',
        description: null,
        thumbnailUrl: null,
        durationSeconds: 1,
        language: 'en',
        translationKey: null,
        sourceText: null,
        voice: null,
        source: null,
        localUri: null,
        md5: null,
        size: null,
        localMtimeMs: null,
        mediaUrl: null,
        syncStatus: 'synced',
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      );
      await db.audioDao.insertRow(row);
      return row;
    }

    test('missing row returns null (caller must not enqueue)', () async {
      expect(
        await SyncQueueJob.snapshotUpsert(
          db,
          SyncEntityType.audio,
          'missing',
          SyncAction.create,
        ),
        isNull,
      );
      expect(await db.select(db.syncQueue).get(), isEmpty);
    });

    test(
      'flips syncStatus to pending without serializing a snapshot payload',
      () async {
        await insertAudio('aud-1');

        final job = await SyncQueueJob.snapshotUpsert(
          db,
          SyncEntityType.audio,
          'aud-1',
          SyncAction.update,
        );

        expect(job, isA<SyncAudioUpsert>());
        final wire = job!.encode();
        expect(wire.entityType, 'audio');
        expect(wire.entityId, 'aud-1');
        expect(wire.action, 'update');
        expect(wire.payloadJson, isNull);

        final row = await db.audioDao.getById('aud-1');
        expect(row!.syncStatus, 'pending');
      },
    );

    test('youtube_subscription snapshots without a status flip', () async {
      final now = DateTime.utc(2026, 9, 16);
      await db.youtubeChannelSubscriptionDao.upsert(
        YoutubeChannelSubscriptionRow(
          channelId: 'ch-1',
          displayName: 'd',
          thumbnailUrl: null,
          source: YoutubeSubscriptionSource.user,
          sourceType: YoutubeSourceType.channel,
          feedUrl: null,
          language: 'en',
          subscribedAt: now,
          lastFetchedAt: null,
        ),
      );

      final job = await SyncQueueJob.snapshotUpsert(
        db,
        SyncEntityType.youtubeSubscription,
        'ch-1',
        SyncAction.create,
      );

      expect(job, isA<SyncYoutubeSubscriptionUpsert>());
      final payload =
          jsonDecode(job!.encode().payloadJson!) as Map<String, dynamic>;
      expect(payload['channelId'], 'ch-1');
    });
  });
}
