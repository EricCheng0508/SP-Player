import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:enjoy_player/features/library/application/library_repository_provider.dart';
import 'package:enjoy_player/features/library/data/library_repository.dart';
import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';
import 'package:enjoy_player/features/player/application/player_open_side_effects.dart';
import 'package:enjoy_player/features/transcript/application/transcript_fetch_controller.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_fetch_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_player_engine.dart';

/// Records calls to [resolveOnOpen] without touching real DB / network.
class _FakeTranscriptFetchCtrl extends TranscriptFetchCtrl {
  static int resolveCalls = 0;
  static Object? throwError;

  static void reset() {
    resolveCalls = 0;
    throwError = null;
  }

  @override
  TranscriptFetchUiState build(String mediaId) {
    return const TranscriptFetchUiState();
  }

  @override
  Future<void> resolveOnOpen() async {
    resolveCalls++;
    if (throwError != null) throw throwError!;
  }
}

/// Records refresh calls without touching real DB / network.
class _FakeMediaLibraryRepository extends MediaLibraryRepository {
  _FakeMediaLibraryRepository(AppDatabase db) : super(db, FileStorage());

  static List<String> refreshCalls = [];
  static Object? throwError;

  static void reset() {
    refreshCalls = [];
    throwError = null;
  }

  @override
  Future<YoutubeMetadataPatch?> refreshYoutubeMetadataIfNeeded(
    String mediaId,
  ) async {
    refreshCalls.add(mediaId);
    if (throwError != null) throw throwError!;
    return null;
  }
}

/// Captures a [Ref] from the container so top-level functions that accept
/// [Ref] can be called in tests.
final _refCapture = Provider<Ref>((ref) => ref);

ProviderContainer _container(AppDatabase db) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      playerEngineTestDoubleProvider.overrideWithValue(FakePlayerEngine()),
      mediaLibraryRepositoryProvider.overrideWithValue(
        _FakeMediaLibraryRepository(db),
      ),
      // ignore: deprecated_member_use
      transcriptFetchCtrlProvider.overrideWith(_FakeTranscriptFetchCtrl.new),
    ],
  );
}

Ref _ref(ProviderContainer container) => container.read(_refCapture);

/// Schedules the refresh with [engine] plus host-style freshness callbacks,
/// mirroring what [runPlayerOpen] passes — the helper itself must never read
/// `playerControllerProvider` (issue #676).
void _scheduleYoutubeRefresh(
  ProviderContainer container, {
  required String mediaId,
  int openGeneration = 1,
  PlayerEngine? engine,
  int Function()? currentOpenGeneration,
  String? Function()? currentSessionMediaId,
}) {
  scheduleYoutubeMetadataRefresh(
    _ref(container),
    mediaId: mediaId,
    openGeneration: openGeneration,
    engine: engine ?? FakePlayerEngine(),
    currentOpenGeneration: currentOpenGeneration ?? () => openGeneration,
    currentSessionMediaId: currentSessionMediaId ?? () => mediaId,
  );
}

/// Emits `buffering=false` repeatedly for a short window so the helper
/// catches it whenever it subscribes (its first DB read yields past the
/// schedule call), then lets the whole side effect drain.
Future<void> _driveYoutubeRefreshReady(FakePlayerEngine engine) async {
  for (var i = 0; i < 20; i++) {
    engine.emitBuffering(false);
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  await pumpEventQueue();
}

Future<void> _insertVideoRow(
  AppDatabase db, {
  required String id,
  required String vid,
  required String provider,
  required String title,
  String? thumbnailUrl,
}) async {
  final now = DateTime.now();
  await db.videoDao.insertRow(
    VideoRow(
      id: id,
      vid: vid,
      provider: provider,
      title: title,
      description: null,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: 120,
      language: 'en',
      source: null,
      localUri: null,
      md5: null,
      size: null,
      mediaUrl: null,
      syncStatus: null,
      serverUpdatedAt: null,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    _FakeTranscriptFetchCtrl.reset();
    _FakeMediaLibraryRepository.reset();
  });

  tearDown(() async {
    await pumpEventQueue();
    await db.close();
  });

  group('schedulePlayerOpenSideEffects', () {
    test('resolves transcript on open', () async {
      final container = _container(db);
      addTearDown(container.dispose);

      schedulePlayerOpenSideEffects(
        _ref(container),
        openGeneration: 1,
        isStale: () => false,
        mediaId: 'media-1',
      );

      await pumpEventQueue();

      expect(_FakeTranscriptFetchCtrl.resolveCalls, 1);
    });

    test('stale open skips the transcript resolve', () async {
      final container = _container(db);
      addTearDown(container.dispose);

      schedulePlayerOpenSideEffects(
        _ref(container),
        openGeneration: 1,
        isStale: () => true,
        mediaId: 'media-3',
      );

      await pumpEventQueue();

      expect(_FakeTranscriptFetchCtrl.resolveCalls, 0);
    });

    test('transcript error is caught and does not propagate', () async {
      _FakeTranscriptFetchCtrl.throwError = StateError('transcript_boom');
      final container = _container(db);
      addTearDown(container.dispose);

      schedulePlayerOpenSideEffects(
        _ref(container),
        openGeneration: 1,
        isStale: () => false,
        mediaId: 'media-4',
      );

      await pumpEventQueue();

      expect(_FakeTranscriptFetchCtrl.resolveCalls, 1);
    });
  });

  group('scheduleYoutubeMetadataRefresh', () {
    test('early return when video row is null', () async {
      final container = _container(db);
      addTearDown(container.dispose);

      _scheduleYoutubeRefresh(container, mediaId: 'missing-id');

      await pumpEventQueue();
      expect(_FakeMediaLibraryRepository.refreshCalls, isEmpty);
    });

    test('early return when provider is not youtube', () async {
      await _insertVideoRow(
        db,
        id: 'v-user',
        vid: 'abc123',
        provider: 'user',
        title: 'YouTube video abc123',
      );
      final container = _container(db);
      addTearDown(container.dispose);

      _scheduleYoutubeRefresh(container, mediaId: 'v-user');

      await pumpEventQueue();
      expect(_FakeMediaLibraryRepository.refreshCalls, isEmpty);
    });

    test('early return when metadata does not need refresh', () async {
      await _insertVideoRow(
        db,
        id: 'v-complete',
        vid: 'dQw4w9WgXcQ',
        provider: 'youtube',
        title: 'Real YouTube Title',
        thumbnailUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
      );
      final container = _container(db);
      addTearDown(container.dispose);

      _scheduleYoutubeRefresh(container, mediaId: 'v-complete');

      await pumpEventQueue();
      expect(_FakeMediaLibraryRepository.refreshCalls, isEmpty);
    });

    test('proceeds when title is placeholder (needs refresh)', () async {
      await _insertVideoRow(
        db,
        id: 'v-placeholder',
        vid: 'dQw4w9WgXcQ',
        provider: 'youtube',
        title: 'YouTube video dQw4w9WgXcQ',
        thumbnailUrl: null,
      );
      final container = _container(db);
      addTearDown(container.dispose);

      final engine = FakePlayerEngine();
      _scheduleYoutubeRefresh(
        container,
        mediaId: 'v-placeholder',
        engine: engine,
      );
      await _driveYoutubeRefreshReady(engine);
      expect(_FakeMediaLibraryRepository.refreshCalls, ['v-placeholder']);
    });

    test('proceeds when thumbnail is empty string (needs refresh)', () async {
      await _insertVideoRow(
        db,
        id: 'v-empty-thumb',
        vid: 'dQw4w9WgXcQ',
        provider: 'youtube',
        title: 'Real Title',
        thumbnailUrl: '   ',
      );
      final container = _container(db);
      addTearDown(container.dispose);

      final engine = FakePlayerEngine();
      _scheduleYoutubeRefresh(
        container,
        mediaId: 'v-empty-thumb',
        engine: engine,
      );
      await _driveYoutubeRefreshReady(engine);
      expect(_FakeMediaLibraryRepository.refreshCalls, ['v-empty-thumb']);
    });

    test('skips refresh when open generation went stale', () async {
      await _insertVideoRow(
        db,
        id: 'v-stale',
        vid: 'dQw4w9WgXcQ',
        provider: 'youtube',
        title: 'YouTube video dQw4w9WgXcQ',
      );
      final container = _container(db);
      addTearDown(container.dispose);

      final engine = FakePlayerEngine();
      scheduleYoutubeMetadataRefresh(
        _ref(container),
        mediaId: 'v-stale',
        openGeneration: 1,
        engine: engine,
        currentOpenGeneration: () => 2,
        currentSessionMediaId: () => 'v-stale',
      );
      await _driveYoutubeRefreshReady(engine);
      expect(_FakeMediaLibraryRepository.refreshCalls, isEmpty);
    });

    test('repository error is caught and does not escape', () async {
      await _insertVideoRow(
        db,
        id: 'v-boom',
        vid: 'dQw4w9WgXcQ',
        provider: 'youtube',
        title: 'YouTube video dQw4w9WgXcQ',
      );
      _FakeMediaLibraryRepository.throwError = StateError('oembed_boom');
      final container = _container(db);
      addTearDown(container.dispose);

      final engine = FakePlayerEngine();
      _scheduleYoutubeRefresh(container, mediaId: 'v-boom', engine: engine);
      await _driveYoutubeRefreshReady(engine);
      expect(_FakeMediaLibraryRepository.refreshCalls, ['v-boom']);
    });
  });
}
