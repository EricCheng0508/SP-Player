import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:cross_file/cross_file.dart';
import 'package:drift/native.dart';
import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/config/local_mode.dart';
import 'package:enjoy_player/core/ids/enjoy_ids.dart';
import 'package:enjoy_player/core/utils/youtube_video_identity.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/media_registry.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:enjoy_player/features/library/data/library_repository.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../support/test_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MediaLibraryRepository additional coverage', () {
    late PathProviderPlatform original;
    late Directory root;
    late AppDatabase db;
    late MediaLibraryRepository repo;

    setUp(() {
      original = PathProviderPlatform.instance;
      root = Directory.systemTemp.createTempSync('enjoy_lib_repo_extra_test');
      PathProviderPlatform.instance = TestPathProvider(root.path);
      db = AppDatabase(executor: NativeDatabase.memory());
      repo = MediaLibraryRepository(db, FileStorage());
    });

    tearDown(() async {
      PathProviderPlatform.instance = original;
      await db.close();
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    group('getById', () {
      test('returns audio media when row is audio', () async {
        final now = DateTime.now();
        const id = 'audio-1';
        await db.audioDao.insertRow(
          AudioRow(
            id: id,
            aid: 'aid-1',
            provider: 'user',
            title: 'Song',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 30,
            language: 'en-US',
            translationKey: null,
            sourceText: null,
            voice: null,
            source: null,
            localUri: 'file:///song.mp3',
            md5: null,
            size: 500,
            mediaUrl: null,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );

        final media = await MediaRegistry(db).getById(id);
        expect(media, isNotNull);
        expect(media!.kind, MediaKind.audio);
        expect(media.title, 'Song');
        expect(media.durationMs, 30_000);
        expect(media.fileSize, 500);
        expect(media.contentHash, 'aid-1');
      });

      test('returns null when neither video nor audio exists', () async {
        final media = await MediaRegistry(db).getById('nonexistent-id');
        expect(media, isNull);
      });

      test(
        'maps mediaUrl fallback for sourceUri when localUri is null',
        () async {
          final now = DateTime.now();
          const id = 'remote-vid';
          await db.videoDao.insertRow(
            VideoRow(
              id: id,
              vid: 'v1',
              provider: 'youtube',
              title: 'Remote',
              description: null,
              thumbnailUrl: null,
              durationSeconds: 0,
              language: 'und',
              source: 'youtube',
              localUri: null,
              md5: null,
              size: null,
              mediaUrl: 'https://www.youtube.com/watch?v=abc',
              syncStatus: null,
              serverUpdatedAt: null,
              createdAt: now,
              updatedAt: now,
            ),
          );

          final media = await MediaRegistry(db).getById(id);
          expect(media!.sourceUri, 'https://www.youtube.com/watch?v=abc');
          expect(media.mediaUrl, 'https://www.youtube.com/watch?v=abc');
          expect(media.fileSize, 0);
        },
      );
    });

    group('importMedia video', () {
      test('imports video file and returns deterministic id', () async {
        final bytes = utf8.encode('video-content-bytes');
        final hash = sha256.convert(bytes).toString();
        final expectedVid = enjoyLocalVideoVid(
          contentHashHex: hash,
          userId: kLocalSessionId,
        );
        final expectedId = enjoyVideoId(vid: expectedVid);

        final src = File(p.join(root.path, 'clip.mp4'));
        await src.writeAsBytes(bytes);

        final id = await repo.importMedia(
          XFile(src.path),
          signedInUserId: kLocalSessionId,
        );
        expect(id, expectedId);

        final media = await MediaRegistry(db).getById(id);
        expect(media, isNotNull);
        expect(media!.kind, MediaKind.video);
      });

      test('re-importing same video reuses row id', () async {
        final bytes = utf8.encode('same-video-twice');
        final src = File(p.join(root.path, 'same.mp4'));
        await src.writeAsBytes(bytes);

        final id1 = await repo.importMedia(
          XFile(src.path, name: 'same.mp4'),
          signedInUserId: kLocalSessionId,
        );
        final id2 = await repo.importMedia(
          XFile(src.path, name: 'same.mp4'),
          signedInUserId: kLocalSessionId,
        );
        expect(id1, id2);
        expect(await db.videoDao.watchAll().first, hasLength(1));
      });
    });

    group('importYoutubeVideo', () {
      test('throws FileFailure for invalid URL', () async {
        await expectLater(
          repo.importYoutubeVideo('not-a-valid-url'),
          throwsA(isA<FileFailure>()),
        );
      });

      test('throws FileFailure for empty input', () async {
        await expectLater(
          repo.importYoutubeVideo(''),
          throwsA(isA<FileFailure>()),
        );
      });

      test('uses oEmbed title when no prefetched title', () async {
        const vid = 'dQw4w9WgXcQ';
        final oembedClient = MockClient((request) async {
          return http.Response(
            '{"title":"OEmbed Title","thumbnail_url":"https://i.ytimg.com/vi/$vid/hq.jpg"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final ytRepo = MediaLibraryRepository(
          db,
          FileStorage(),
          oembedClient: oembedClient,
        );

        final id = await ytRepo.importYoutubeVideo(vid);
        final row = await db.videoDao.getById(id);
        expect(row!.title, 'OEmbed Title');
        expect(row.thumbnailUrl, 'https://i.ytimg.com/vi/$vid/hq.jpg');
      });

      test(
        'falls back to placeholder when oEmbed fails and no prefetched',
        () async {
          const vid = 'dQw4w9WgXcQ';
          final oembedClient = MockClient((_) async => http.Response('', 500));

          final ytRepo = MediaLibraryRepository(
            db,
            FileStorage(),
            oembedClient: oembedClient,
          );

          final id = await ytRepo.importYoutubeVideo(vid);
          final row = await db.videoDao.getById(id);
          expect(row!.title, youtubeImportPlaceholderTitle(vid));
        },
      );

      test('ignores prefetched title that is a placeholder', () async {
        const vid = 'dQw4w9WgXcQ';
        final oembedClient = MockClient((_) async {
          return http.Response(
            '{"title":"Real From OEmbed","thumbnail_url":"https://thumb.jpg"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final ytRepo = MediaLibraryRepository(
          db,
          FileStorage(),
          oembedClient: oembedClient,
        );

        final id = await ytRepo.importYoutubeVideo(
          vid,
          prefetchedTitle: youtubeImportPlaceholderTitle(vid),
        );
        final row = await db.videoDao.getById(id);
        expect(row!.title, 'Real From OEmbed');
      });

      test(
        'duplicate import patches metadata when title is placeholder',
        () async {
          const vid = 'dQw4w9WgXcQ';
          final mediaId = enjoyVideoId(provider: 'youtube', vid: vid);
          final now = DateTime.now();

          await db.videoDao.insertRow(
            VideoRow(
              id: mediaId,
              vid: vid,
              provider: 'youtube',
              title: youtubeImportPlaceholderTitle(vid),
              description: null,
              thumbnailUrl: null,
              durationSeconds: 0,
              language: 'und',
              source: 'youtube',
              localUri: null,
              md5: null,
              size: null,
              mediaUrl: 'https://www.youtube.com/watch?v=$vid',
              syncStatus: 'pending',
              serverUpdatedAt: null,
              createdAt: now,
              updatedAt: now,
            ),
          );

          final oembedClient = MockClient((_) async {
            return http.Response(
              '{"title":"Patched Title","thumbnail_url":"https://patched.jpg"}',
              200,
              headers: {'content-type': 'application/json'},
            );
          });

          final ytRepo = MediaLibraryRepository(
            db,
            FileStorage(),
            oembedClient: oembedClient,
          );

          final id = await ytRepo.importYoutubeVideo(vid);
          expect(id, mediaId);

          final row = await db.videoDao.getById(mediaId);
          expect(row!.title, 'Patched Title');
          expect(row.thumbnailUrl, 'https://patched.jpg');
        },
      );

      test(
        'duplicate import does not patch when metadata is complete',
        () async {
          const vid = 'dQw4w9WgXcQ';
          final mediaId = enjoyVideoId(provider: 'youtube', vid: vid);
          final now = DateTime.now();

          await db.videoDao.insertRow(
            VideoRow(
              id: mediaId,
              vid: vid,
              provider: 'youtube',
              title: 'Good Title',
              description: null,
              thumbnailUrl: 'https://good-thumb.jpg',
              durationSeconds: 120,
              language: 'und',
              source: 'youtube',
              localUri: null,
              md5: null,
              size: null,
              mediaUrl: 'https://www.youtube.com/watch?v=$vid',
              syncStatus: 'pending',
              serverUpdatedAt: null,
              createdAt: now,
              updatedAt: now,
            ),
          );

          final oembedClient = MockClient((_) async {
            fail('oEmbed should not be called for complete metadata');
          });

          final ytRepo = MediaLibraryRepository(
            db,
            FileStorage(),
            oembedClient: oembedClient,
          );

          final id = await ytRepo.importYoutubeVideo(vid);
          expect(id, mediaId);

          final row = await db.videoDao.getById(mediaId);
          expect(row!.title, 'Good Title');
          expect(row.thumbnailUrl, 'https://good-thumb.jpg');
        },
      );

      test('accepts full youtube watch URL', () async {
        const vid = 'dQw4w9WgXcQ';
        final ytRepo = MediaLibraryRepository(
          db,
          FileStorage(),
          oembedClient: MockClient((_) async => http.Response('', 500)),
        );

        final id = await ytRepo.importYoutubeVideo(
          'https://www.youtube.com/watch?v=$vid',
          prefetchedTitle: 'From URL',
        );
        final row = await db.videoDao.getById(id);
        expect(row!.vid, vid);
      });
    });

    group('touchMediaUpdatedAt', () {
      test('bumps audio row', () async {
        final oldUpdated = DateTime.utc(2024, 1, 1);
        const id = 'audio-touch';
        await db.audioDao.insertRow(
          AudioRow(
            id: id,
            aid: 'a-touch',
            provider: 'user',
            title: 'Audio',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'und',
            translationKey: null,
            sourceText: null,
            voice: null,
            source: null,
            localUri: null,
            md5: null,
            size: null,
            mediaUrl: null,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: oldUpdated,
            updatedAt: oldUpdated,
          ),
        );

        await repo.touchMediaUpdatedAt(id);
        final row = await db.audioDao.getById(id);
        expect(row!.updatedAt.isAfter(oldUpdated), isTrue);
      });

      test('does not throw for non-existent id', () async {
        await expectLater(
          repo.touchMediaUpdatedAt('does-not-exist'),
          completes,
        );
      });
    });

    group('deleteMedia', () {
      test('removes the video row', () async {
        final now = DateTime.now();
        const id = 'vid-del';
        await db.videoDao.insertRow(
          VideoRow(
            id: id,
            vid: 'v-del',
            provider: 'user',
            title: 'Delete me',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'und',
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

        await repo.deleteMedia(id);
        expect(await MediaRegistry(db).getById(id), isNull);
      });

      test('removes the audio row', () async {
        final now = DateTime.now();
        const id = 'aud-del';
        await db.audioDao.insertRow(
          AudioRow(
            id: id,
            aid: 'a-del',
            provider: 'user',
            title: 'Delete audio',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'und',
            translationKey: null,
            sourceText: null,
            voice: null,
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

        await repo.deleteMedia(id);
        expect(await MediaRegistry(db).getById(id), isNull);
      });

      test('no-op for non-existent id', () async {
        await expectLater(repo.deleteMedia('ghost-id'), completes);
      });
    });

    group('updateMediaLanguage', () {
      test('updates the audio row language and bumps updatedAt', () async {
        final now = DateTime(2026, 7, 1, 12);
        const id = 'aud-lang';
        await db.audioDao.insertRow(
          AudioRow(
            id: id,
            aid: 'a-lang',
            provider: 'user',
            title: 'Audio lang',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'und',
            translationKey: null,
            sourceText: null,
            voice: null,
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

        await repo.updateMediaLanguage(id, 'ja');
        final row = await db.audioDao.getById(id);
        expect(row!.language, 'ja-JP');
        expect(row.updatedAt.isAfter(now), isTrue);
      });

      test('skips update when language is already the same', () async {
        final now = DateTime(2026, 7, 1, 12);
        const id = 'vid-same-lang';
        await db.videoDao.insertRow(
          VideoRow(
            id: id,
            vid: 'v-same',
            provider: 'user',
            title: 'Same lang',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'ja-JP',
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

        await repo.updateMediaLanguage(id, 'ja');
        final row = await db.videoDao.getById(id);
        expect(row!.language, 'ja-JP');
        expect(row.updatedAt, now);
      });

      test('skips audio update when language is already the same', () async {
        final now = DateTime(2026, 7, 1, 12);
        const id = 'aud-same-lang';
        await db.audioDao.insertRow(
          AudioRow(
            id: id,
            aid: 'a-same',
            provider: 'user',
            title: 'Same',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'en-US',
            translationKey: null,
            sourceText: null,
            voice: null,
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

        await repo.updateMediaLanguage(id, 'en');
        final row = await db.audioDao.getById(id);
        expect(row!.language, 'en-US');
        expect(row.updatedAt, now);
      });

      test('throws FileFailure for non-existent media', () async {
        await expectLater(
          repo.updateMediaLanguage('missing-id', 'fr'),
          throwsA(isA<FileFailure>()),
        );
      });
    });

    group('updateMediaTitle', () {
      test('updates the video row title', () async {
        final now = DateTime(2026, 7, 1, 12);
        const id = 'vid-title';
        await db.videoDao.insertRow(
          VideoRow(
            id: id,
            vid: 'v-title',
            provider: 'user',
            title: 'Old title',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'en-US',
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

        await repo.updateMediaTitle(id, 'New title');
        final row = await db.videoDao.getById(id);
        expect(row!.title, 'New title');
        expect(row.updatedAt.isAfter(now), isTrue);
      });

      test('updates the audio row title', () async {
        final now = DateTime(2026, 7, 1, 12);
        const id = 'aud-title';
        await db.audioDao.insertRow(
          AudioRow(
            id: id,
            aid: 'a-title',
            provider: 'user',
            title: 'Old title',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'und',
            translationKey: null,
            sourceText: null,
            voice: null,
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

        await repo.updateMediaTitle(id, 'Renamed audio');
        final row = await db.audioDao.getById(id);
        expect(row!.title, 'Renamed audio');
        expect(row.updatedAt.isAfter(now), isTrue);
      });

      test('trims the title before writing', () async {
        final now = DateTime.now();
        const id = 'vid-trim';
        await db.videoDao.insertRow(
          VideoRow(
            id: id,
            vid: 'v-trim',
            provider: 'user',
            title: 'Padded ',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'en-US',
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

        await repo.updateMediaTitle(id, '  Padded');
        final row = await db.videoDao.getById(id);
        expect(row!.title, 'Padded');
      });

      test('skips update when the title is unchanged', () async {
        final now = DateTime(2026, 7, 1, 12);
        const id = 'vid-same-title';
        await db.videoDao.insertRow(
          VideoRow(
            id: id,
            vid: 'v-same-title',
            provider: 'user',
            title: 'Same title',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'en-US',
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

        await repo.updateMediaTitle(id, 'Same title');
        final row = await db.videoDao.getById(id);
        expect(row!.title, 'Same title');
        expect(row.updatedAt, now);
      });

      test('throws FileFailure for a blank title', () async {
        await expectLater(
          repo.updateMediaTitle('any-id', '   '),
          throwsA(isA<FileFailure>()),
        );
      });

      test('throws FileFailure for non-existent media', () async {
        await expectLater(
          repo.updateMediaTitle('missing-id', 'New title'),
          throwsA(isA<FileFailure>()),
        );
      });
    });

    group('relocateLocalFile', () {
      test('relocates audio file when hash matches', () async {
        final bytes = utf8.encode('audio-relocate-body');
        final hash = sha256.convert(bytes).toString();
        final id = enjoyAudioId(aid: hash);
        final src = File(p.join(root.path, 'track.mp3'));
        await src.writeAsBytes(bytes);

        final now = DateTime.now();
        await db.audioDao.insertRow(
          AudioRow(
            id: id,
            aid: hash,
            provider: 'user',
            title: 'Track',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'und',
            translationKey: null,
            sourceText: null,
            voice: null,
            source: null,
            localUri: null,
            md5: hash,
            size: bytes.length,
            mediaUrl: null,
            syncStatus: 'synced',
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );

        await repo.relocateLocalFile(
          mediaId: id,
          picked: XFile(src.path, name: 'track.mp3'),
        );

        final row = await db.audioDao.getById(id);
        expect(row!.localUri, Uri.file(src.path).toString());
        expect(row.size, bytes.length);
      });

      test('throws FileFailure for non-existent media', () async {
        final src = File(p.join(root.path, 'any.mp4'));
        await src.writeAsBytes([1, 2, 3]);

        await expectLater(
          repo.relocateLocalFile(
            mediaId: 'no-such-media',
            picked: XFile(src.path, name: 'any.mp4'),
          ),
          throwsA(isA<FileFailure>()),
        );
      });

      test('throws FileFailure when md5 is null', () async {
        final now = DateTime.now();
        const id = 'no-hash';
        await db.videoDao.insertRow(
          VideoRow(
            id: id,
            vid: 'v-nohash',
            provider: 'user',
            title: 'No hash',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'und',
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

        final src = File(p.join(root.path, 'x.mp4'));
        await src.writeAsBytes([1]);

        await expectLater(
          repo.relocateLocalFile(
            mediaId: id,
            picked: XFile(src.path, name: 'x.mp4'),
          ),
          throwsA(isA<FileFailure>()),
        );
      });

      test('throws FileFailure when md5 is empty string', () async {
        final now = DateTime.now();
        const id = 'empty-hash';
        await db.audioDao.insertRow(
          AudioRow(
            id: id,
            aid: 'a-empty',
            provider: 'user',
            title: 'Empty hash',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'und',
            translationKey: null,
            sourceText: null,
            voice: null,
            source: null,
            localUri: null,
            md5: '',
            size: null,
            mediaUrl: null,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );

        final src = File(p.join(root.path, 'y.mp3'));
        await src.writeAsBytes([2]);

        await expectLater(
          repo.relocateLocalFile(
            mediaId: id,
            picked: XFile(src.path, name: 'y.mp3'),
          ),
          throwsA(isA<FileFailure>()),
        );
      });

      test('cleans previous app-managed file on relocation', () async {
        final mediaDir = Directory(p.join(root.path, 'media'))
          ..createSync(recursive: true);
        final managed = File(p.join(mediaDir.path, 'old-copy.mp3'));
        final bytes = utf8.encode('relocate-cleanup-body');
        await managed.writeAsBytes(bytes);
        final oldUri = Uri.file(managed.path).toString();

        final hash = sha256.convert(bytes).toString();
        final id = enjoyAudioId(aid: hash);
        final src = File(p.join(root.path, 'new-location.mp3'));
        await src.writeAsBytes(bytes);

        final now = DateTime.now();
        await db.audioDao.insertRow(
          AudioRow(
            id: id,
            aid: hash,
            provider: 'user',
            title: 'Cleanup',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'und',
            translationKey: null,
            sourceText: null,
            voice: null,
            source: null,
            localUri: oldUri,
            md5: hash,
            size: bytes.length,
            mediaUrl: null,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );

        await repo.relocateLocalFile(
          mediaId: id,
          picked: XFile(src.path, name: 'new-location.mp3'),
        );

        final row = await db.audioDao.getById(id);
        expect(row!.localUri, Uri.file(src.path).toString());
        expect(managed.existsSync(), isFalse);
      });
    });

    group('watchAll', () {
      test('merges video and audio sorted by createdAt descending', () async {
        final older = DateTime.utc(2024, 1, 1);
        final newer = DateTime.utc(2024, 6, 15);

        await db.videoDao.insertRow(
          VideoRow(
            id: 'v-old',
            vid: 'v1',
            provider: 'user',
            title: 'Old Video',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'und',
            source: null,
            localUri: null,
            md5: null,
            size: null,
            mediaUrl: null,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: older,
            updatedAt: older,
          ),
        );
        await db.audioDao.insertRow(
          AudioRow(
            id: 'a-new',
            aid: 'a1',
            provider: 'user',
            title: 'New Audio',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'und',
            translationKey: null,
            sourceText: null,
            voice: null,
            source: null,
            localUri: null,
            md5: null,
            size: null,
            mediaUrl: null,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: newer,
            updatedAt: newer,
          ),
        );

        final emissions = <List<Media>>[];
        final sub = MediaRegistry(db).watchAll().listen(emissions.add);
        await Future<void>.delayed(const Duration(milliseconds: 80));

        expect(emissions, isNotEmpty);
        final merged = emissions.last;
        expect(merged, hasLength(2));
        expect(merged.first.title, 'New Audio');
        expect(merged.last.title, 'Old Video');

        await sub.cancel();
      });
    });

    group('refreshYoutubeMetadataIfNeeded', () {
      test('returns null for non-youtube provider', () async {
        final now = DateTime.now();
        const id = 'user-vid';
        await db.videoDao.insertRow(
          VideoRow(
            id: id,
            vid: 'v-user',
            provider: 'user',
            title: youtubeImportPlaceholderTitle('v-user'),
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'und',
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

        final result = await repo.refreshYoutubeMetadataIfNeeded(id);
        expect(result, isNull);
      });

      test('returns null for non-existent media id', () async {
        final result = await repo.refreshYoutubeMetadataIfNeeded('missing');
        expect(result, isNull);
      });

      test('returns null when oEmbed request fails', () async {
        const vid = 'dQw4w9WgXcQ';
        final mediaId = enjoyVideoId(provider: 'youtube', vid: vid);
        final now = DateTime.now();

        await db.videoDao.insertRow(
          VideoRow(
            id: mediaId,
            vid: vid,
            provider: 'youtube',
            title: youtubeImportPlaceholderTitle(vid),
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'und',
            source: 'youtube',
            localUri: null,
            md5: null,
            size: null,
            mediaUrl: 'https://www.youtube.com/watch?v=$vid',
            syncStatus: 'pending',
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );

        final ytRepo = MediaLibraryRepository(
          db,
          FileStorage(),
          oembedClient: MockClient((_) async => http.Response('', 404)),
        );

        final result = await ytRepo.refreshYoutubeMetadataIfNeeded(mediaId);
        expect(result, isNull);
      });

      test('refreshes when thumbnail is empty string', () async {
        const vid = 'dQw4w9WgXcQ';
        final mediaId = enjoyVideoId(provider: 'youtube', vid: vid);
        final now = DateTime.now();

        await db.videoDao.insertRow(
          VideoRow(
            id: mediaId,
            vid: vid,
            provider: 'youtube',
            title: 'Good Title',
            description: null,
            thumbnailUrl: '  ',
            durationSeconds: 60,
            language: 'und',
            source: 'youtube',
            localUri: null,
            md5: null,
            size: null,
            mediaUrl: 'https://www.youtube.com/watch?v=$vid',
            syncStatus: 'pending',
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );

        final oembedClient = MockClient((_) async {
          return http.Response(
            '{"title":"Good Title","thumbnail_url":"https://new-thumb.jpg"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final ytRepo = MediaLibraryRepository(
          db,
          FileStorage(),
          oembedClient: oembedClient,
        );

        final patch = await ytRepo.refreshYoutubeMetadataIfNeeded(mediaId);
        expect(patch, isNotNull);
        expect(patch!.thumbnailUrl, 'https://new-thumb.jpg');
      });
    });

    group('importMedia error wrapping', () {
      test('wraps unexpected errors in FileFailure', () async {
        final src = File(p.join(root.path, 'nonexistent_dir', 'gone.mp3'));

        await expectLater(
          repo.importMedia(
            XFile(src.path, name: 'gone.mp3'),
            signedInUserId: kLocalSessionId,
          ),
          throwsA(isA<FileFailure>()),
        );
      });
    });

    group('importMedia re-import field preservation', () {
      test(
        're-importing video and audio preserves server-linked and existing fields',
        () async {
          final createdAt = DateTime.utc(2024, 1, 1);
          final serverUpdatedAt = DateTime.utc(2024, 2, 1);

          final videoBytes = utf8.encode('preserve-video-bytes');
          final videoHash = sha256.convert(videoBytes).toString();
          final vid = enjoyLocalVideoVid(
            contentHashHex: videoHash,
            userId: kLocalSessionId,
          );
          final videoId = enjoyVideoId(vid: vid);
          await db.videoDao.insertRow(
            VideoRow(
              id: videoId,
              vid: vid,
              provider: 'user',
              title: 'Old Video',
              description: 'Video desc',
              thumbnailUrl: 'https://example.com/v.jpg',
              durationSeconds: 180,
              language: 'und',
              source: 'cloud',
              localUri: null,
              md5: videoHash,
              size: videoBytes.length,
              mediaUrl: 'https://cdn.example.com/v.mp4',
              syncStatus: 'synced',
              serverUpdatedAt: serverUpdatedAt,
              createdAt: createdAt,
              updatedAt: createdAt,
            ),
          );

          final videoFile = File(p.join(root.path, 'preserved.mp4'));
          await videoFile.writeAsBytes(videoBytes);
          await repo.importMedia(
            XFile(videoFile.path, name: 'preserved.mp4'),
            signedInUserId: kLocalSessionId,
            contentLanguage: 'en-US',
          );

          final updatedVideo = await db.videoDao.getById(videoId);
          expect(updatedVideo, isNotNull);
          expect(updatedVideo!.description, 'Video desc');
          expect(updatedVideo.thumbnailUrl, 'https://example.com/v.jpg');
          expect(updatedVideo.durationSeconds, 180);
          expect(updatedVideo.source, 'cloud');
          expect(updatedVideo.mediaUrl, 'https://cdn.example.com/v.mp4');
          expect(
            updatedVideo.serverUpdatedAt!.isAtSameMomentAs(serverUpdatedAt),
            isTrue,
          );
          expect(updatedVideo.createdAt.isAtSameMomentAs(createdAt), isTrue);
          expect(updatedVideo.syncStatus, 'pending');

          final audioBytes = utf8.encode('preserve-audio-bytes');
          final audioHash = sha256.convert(audioBytes).toString();
          final aid = enjoyLocalAudioAid(
            contentHashHex: audioHash,
            userId: kLocalSessionId,
          );
          final audioId = enjoyAudioId(aid: aid);
          await db.audioDao.insertRow(
            AudioRow(
              id: audioId,
              aid: aid,
              provider: 'user',
              title: 'Old Audio',
              description: 'Audio desc',
              thumbnailUrl: 'https://example.com/a.jpg',
              durationSeconds: 240,
              language: 'und',
              translationKey: 'tk-1',
              sourceText: 'hello world',
              voice: 'alloy',
              source: 'craft',
              localUri: null,
              md5: audioHash,
              size: audioBytes.length,
              mediaUrl: 'https://cdn.example.com/a.mp3',
              syncStatus: 'synced',
              serverUpdatedAt: serverUpdatedAt,
              createdAt: createdAt,
              updatedAt: createdAt,
            ),
          );

          final audioFile = File(p.join(root.path, 'preserved.mp3'));
          await audioFile.writeAsBytes(audioBytes);
          await repo.importMedia(
            XFile(audioFile.path, name: 'preserved.mp3'),
            signedInUserId: kLocalSessionId,
            contentLanguage: 'en-US',
          );

          final updatedAudio = await db.audioDao.getById(audioId);
          expect(updatedAudio, isNotNull);
          expect(updatedAudio!.description, 'Audio desc');
          expect(updatedAudio.thumbnailUrl, 'https://example.com/a.jpg');
          expect(updatedAudio.durationSeconds, 240);
          expect(updatedAudio.translationKey, 'tk-1');
          expect(updatedAudio.sourceText, 'hello world');
          expect(updatedAudio.voice, 'alloy');
          expect(updatedAudio.source, 'craft');
          expect(updatedAudio.mediaUrl, 'https://cdn.example.com/a.mp3');
          expect(
            updatedAudio.serverUpdatedAt!.isAtSameMomentAs(serverUpdatedAt),
            isTrue,
          );
          expect(updatedAudio.createdAt.isAtSameMomentAs(createdAt), isTrue);
          expect(updatedAudio.syncStatus, 'pending');
        },
      );
    });
  });
}
