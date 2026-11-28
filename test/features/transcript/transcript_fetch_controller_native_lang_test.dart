import 'dart:async';

import 'package:drift/native.dart';
import 'package:enjoy_player/core/analytics/analytics.dart';
import 'package:enjoy_player/core/analytics/analytics_provider.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_fetch_controller.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_fetch_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NativePrefsCtrl extends AppPreferencesCtrl {
  @override
  Future<AppPreferencesState> build() async => const AppPreferencesState(
    locale: kAppDefaultDisplayLocale,
    learningLanguage: 'en-US',
    nativeLanguage: 'zh-CN',
  );
}

class _RecordingRepo extends TranscriptRepository {
  _RecordingRepo(super.db);

  final List<
    ({
      bool forceCloud,
      bool fetchCloud,
      String? nativeLanguage,
      String? learningLanguage,
    })
  >
  calls = [];

  Completer<TranscriptResolveResult>? gate;

  @override
  Future<TranscriptResolveResult> resolveOnOpen(
    String mediaId, {
    bool forceCloud = false,
    bool fetchCloud = true,
    String? nativeLanguage,
    String? learningLanguage,
  }) {
    calls.add((
      forceCloud: forceCloud,
      fetchCloud: fetchCloud,
      nativeLanguage: nativeLanguage,
      learningLanguage: learningLanguage,
    ));
    final pending = gate;
    if (pending != null) {
      return pending.future;
    }
    return Future<void>.value().then(
      (_) => const TranscriptResolveResult(hasTracks: false),
    );
  }
}

void main() {
  group('TranscriptFetchCtrl native language', () {
    late AppDatabase db;
    late ProviderContainer container;
    late _RecordingRepo repo;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
      repo = _RecordingRepo(db);
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          transcriptRepositoryProvider.overrideWithValue(repo),
          appPreferencesCtrlProvider.overrideWith(_NativePrefsCtrl.new),
          analyticsProvider.overrideWithValue(const NoopAnalytics()),
        ],
      );
    });

    tearDown(() async {
      for (var i = 0; i < 8; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      container.dispose();
      await db.close();
    });

    test(
      'T009: resolveOnOpen forwards the preference languages locally',
      () async {
        await container.read(appPreferencesCtrlProvider.future);

        const mediaId = 'media-native-open';
        final ctrl = container.read(
          transcriptFetchCtrlProvider(mediaId).notifier,
        );
        await ctrl.resolveOnOpen();

        expect(repo.calls, hasLength(1));
        expect(repo.calls.single.fetchCloud, isFalse);
        expect(repo.calls.single.forceCloud, isFalse);
        expect(repo.calls.single.nativeLanguage, 'zh-CN');
        expect(repo.calls.single.learningLanguage, 'en-US');
      },
    );

    test(
      'T014: refreshFromCloud sets loading first and forces cloud (FR-010)',
      () async {
        await container.read(appPreferencesCtrlProvider.future);

        const mediaId = 'media-native-refresh';
        repo.gate = Completer<TranscriptResolveResult>();
        final ctrl = container.read(
          transcriptFetchCtrlProvider(mediaId).notifier,
        );

        final pending = ctrl.refreshFromCloud();
        await Future<void>.delayed(Duration.zero);

        expect(repo.calls, hasLength(1));
        expect(
          container.read(transcriptFetchCtrlProvider(mediaId)).status,
          TranscriptFetchStatus.loading,
        );

        repo.gate!.complete(const TranscriptResolveResult(hasTracks: false));
        await pending;

        expect(repo.calls.single.fetchCloud, isTrue);
        expect(repo.calls.single.forceCloud, isTrue);
        expect(repo.calls.single.nativeLanguage, 'zh-CN');
        expect(repo.calls.single.learningLanguage, 'en-US');
        expect(
          container.read(transcriptFetchCtrlProvider(mediaId)).status,
          TranscriptFetchStatus.empty,
        );
      },
    );
  });
}
