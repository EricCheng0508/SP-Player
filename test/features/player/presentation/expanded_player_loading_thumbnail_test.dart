import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/player/application/local_thumbnail_provider.dart';
import 'package:enjoy_player/features/player/application/player_surface_registry.dart';
import 'package:enjoy_player/features/player/presentation/expanded_player_widgets.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_surface_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _onePixelPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

void main() {
  late AppDatabase db;
  late Directory tempDir;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    tempDir = Directory.systemTemp.createTempSync('loading_thumb_test_');
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget wrap(ProviderContainer container, Widget child) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets(
    'local loading stage is a plain black panel — no thumbnail decodes',
    (tester) async {
      final now = DateTime(2026, 1, 1);
      await db.videoDao.insertRow(
        VideoRow(
          id: 'm1',
          vid: 'vid-1',
          provider: 'user',
          title: 'Local video',
          durationSeconds: 0,
          language: 'und',
          source: null,
          localUri: '/tmp/foo.mp4',
          bookmarkData: null,
          md5: 'deadbeef',
          size: 1024,
          localMtimeMs: now.millisecondsSinceEpoch,
          mediaUrl: null,
          createdAt: now,
          updatedAt: now,
          thumbnailUrl: null,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          deviceGlobalAppDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        wrap(
          container,
          ExpandedPlayerLoadingBody(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            mediaId: 'm1',
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(Image), findsNothing);
      final target = tester.widget<PlayerSurfaceTarget>(
        find.byType(PlayerSurfaceTarget),
      );
      expect(target.id, PlayerSurfaceIds.expandedPlayer);
    },
  );

  test('provider resolves a path once and memoizes the file per key', () async {
    final thumb = File('${tempDir.path}/thumb.png');
    thumb.writeAsBytesSync(base64Decode(_onePixelPng));
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen(
      localThumbnailFileProvider(thumb.path),
      (_, _) {},
    );
    addTearDown(subscription.close);

    final first = await container.read(
      localThumbnailFileProvider(thumb.path).future,
    );
    final second = await container.read(
      localThumbnailFileProvider(thumb.path).future,
    );
    expect(first, isNotNull);
    expect(
      identical(first, second),
      isTrue,
      reason: 'One resolution per path — a rebuild must not re-stat',
    );

    final other = await container.read(localThumbnailFileProvider(null).future);
    expect(other, isNull);
  });
}
