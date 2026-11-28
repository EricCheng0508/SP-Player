/// Playlist providers (local-only curation, backed by Drift).
///
/// Manual providers — mirrors `library_media_provider.dart` in avoiding the
/// riverpod_generator + Drift stream edge case.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/library/application/library_media_provider.dart';
import 'package:enjoy_player/features/library/domain/media.dart';

final playlistDaoProvider = Provider<PlaylistDao>(
  (ref) => PlaylistDao(ref.watch(appDatabaseProvider)),
);

final playlistsProvider = StreamProvider<List<PlaylistWithCount>>(
  (ref) => ref.watch(playlistDaoProvider).watchPlaylists(),
);

final playlistItemsProvider =
    StreamProvider.family<List<PlaylistItemRow>, String>(
      (ref, playlistId) =>
          ref.watch(playlistDaoProvider).watchItems(playlistId),
    );

/// Title lookup for playlist items: resolves `(targetType, targetId)` against
/// the media registry; deleted media resolve to null.
final playlistMediaResolverProvider = Provider.family<Media?, (String, String)>(
  (ref, args) {
    final (targetType, targetId) = args;
    final media = ref.watch(libraryMediaProvider).value ?? const <Media>[];
    final kind = targetType == 'Video' ? MediaKind.video : MediaKind.audio;
    for (final m in media) {
      if (m.kind == kind && m.id == targetId) return m;
    }
    return null;
  },
);
