import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:enjoy_player/features/library/application/library_search_provider.dart';
import 'package:enjoy_player/features/library/data/library_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('librarySearchProvider debounce', () {
    test('setQuery commits after the debounce window', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(librarySearchProvider.notifier);

      notifier.setQuery('alpha');
      expect(container.read(librarySearchProvider), '');

      await Future<void>.delayed(
        kLibrarySearchDebounce + const Duration(milliseconds: 50),
      );
      expect(container.read(librarySearchProvider), 'alpha');
    });

    test('rapid setQuery calls only commit the last value', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(librarySearchProvider.notifier);

      notifier.setQuery('a');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      notifier.setQuery('ab');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      notifier.setQuery('abc');

      expect(container.read(librarySearchProvider), '');

      await Future<void>.delayed(
        kLibrarySearchDebounce + const Duration(milliseconds: 50),
      );
      expect(container.read(librarySearchProvider), 'abc');
    });

    test('commit() flushes the pending value immediately', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(librarySearchProvider.notifier);

      notifier.setQuery('hello');
      notifier.commit();

      expect(container.read(librarySearchProvider), 'hello');
    });

    test('setQuery trims whitespace', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(librarySearchProvider.notifier);

      notifier.setQuery('  hello world  ');
      notifier.commit();
      expect(container.read(librarySearchProvider), 'hello world');
    });

    test('clear() during a pending debounce resets to empty', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(librarySearchProvider.notifier);

      notifier.setQuery('alpha');
      notifier.clear();
      expect(container.read(librarySearchProvider), '');

      await Future<void>.delayed(
        kLibrarySearchDebounce + const Duration(milliseconds: 50),
      );
      expect(container.read(librarySearchProvider), '');
    });

    test('clear() after a committed non-empty state resets to empty', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(librarySearchProvider.notifier);

      notifier.setQuery('hello');
      notifier.commit();
      expect(container.read(librarySearchProvider), 'hello');

      notifier.clear();
      expect(container.read(librarySearchProvider), '');
    });
  });

  group('MediaLibraryRepository.deleteMedia', () {
    test('removes the row', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final repo = MediaLibraryRepository(db, FileStorage());

      const id = 'v1';
      await db.videoDao.insertRow(_videoRow(id, 'V1', 'hash-1'));
      await repo.deleteMedia(id);

      expect(await db.videoDao.getById(id), isNull);
    });

    test('delete on an unknown id is a no-op', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final repo = MediaLibraryRepository(db, FileStorage());
      await expectLater(repo.deleteMedia('does-not-exist'), completes);
    });
  });
}

VideoRow _videoRow(String id, String title, String md5) => VideoRow(
  id: id,
  vid: md5,
  provider: 'user',
  title: title,
  description: null,
  thumbnailUrl: null,
  durationSeconds: 0,
  language: 'und',
  source: null,
  localUri: 'file:///x.mp4',
  md5: md5,
  size: 0,
  mediaUrl: null,
  syncStatus: null,
  serverUpdatedAt: null,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);
