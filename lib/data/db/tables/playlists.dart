/// Drift table: user-curated playlists (local-only, not synced).
library;

import 'package:drift/drift.dart';

@DataClassName('PlaylistRow')
class Playlists extends Table {
  @override
  String get tableName => 'playlists';

  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One media entry in a playlist; [position] defines play order.
@DataClassName('PlaylistItemRow')
class PlaylistItems extends Table {
  @override
  String get tableName => 'playlist_items';

  TextColumn get id => text()();
  TextColumn get playlistId => text()();

  /// Weapp `TargetType` (`Video` | `Audio`).
  TextColumn get targetType => text()();
  TextColumn get targetId => text()();

  /// Play order within the playlist (dense 0..n-1; reordered on remove/move).
  IntColumn get position => integer()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
