import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('PlaylistDao', () {
    test('create + watchPlaylists reports item counts', () async {
      final p = await db.playlistDao.create('我的列表');
      expect(p.name, '我的列表');

      final seen = <List<PlaylistWithCount>>[];
      final sub = db.playlistDao.watchPlaylists().listen(seen.add);
      await db.playlistDao.addItem(
        playlistId: p.id,
        targetType: 'Video',
        targetId: 'video-1',
      );
      await db.playlistDao.addItem(
        playlistId: p.id,
        targetType: 'Video',
        targetId: 'video-1',
      ); // duplicate — ignored
      await db.playlistDao.addItem(
        playlistId: p.id,
        targetType: 'Audio',
        targetId: 'audio-1',
      );
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(seen, isNotEmpty);
      final last = seen.last;
      expect(last, hasLength(1));
      expect(last.single.playlist.name, '我的列表');
      expect(last.single.itemCount, 2);
    });

    test('removeItem keeps positions dense', () async {
      final p = await db.playlistDao.create('list');
      for (final id in ['a', 'b', 'c']) {
        await db.playlistDao.addItem(
          playlistId: p.id,
          targetType: 'Video',
          targetId: id,
        );
      }
      var items = await db.playlistDao.itemsOnce(p.id);
      expect(items.map((i) => i.position), [0, 1, 2]);

      // remove middle
      await db.playlistDao.removeItem(items[1].id);
      items = await db.playlistDao.itemsOnce(p.id);
      expect(items.map((i) => i.targetId), ['a', 'c']);
      expect(items.map((i) => i.position), [0, 1]);
    });

    test('moveItem swaps neighbours', () async {
      final p = await db.playlistDao.create('list');
      for (final id in ['a', 'b', 'c']) {
        await db.playlistDao.addItem(
          playlistId: p.id,
          targetType: 'Video',
          targetId: id,
        );
      }
      final items = await db.playlistDao.itemsOnce(p.id);
      await db.playlistDao.moveItem(items[0].id, up: false);

      final moved = await db.playlistDao.itemsOnce(p.id);
      expect(moved.map((i) => i.targetId), ['b', 'a', 'c']);
      expect(moved.map((i) => i.position), [0, 1, 2]);
    });

    test('delete removes items too', () async {
      final p = await db.playlistDao.create('doomed');
      await db.playlistDao.addItem(
        playlistId: p.id,
        targetType: 'Video',
        targetId: 'v',
      );
      await db.playlistDao.deletePlaylist(p.id);

      expect(await db.playlistDao.byId(p.id), isNull);
      expect(await db.playlistDao.itemsOnce(p.id), isEmpty);
    });
  });
}
