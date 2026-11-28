part of '../app_database.dart';

/// Drift DAO: playlists + playlist items (local-only curation).
@DriftAccessor(tables: [Playlists, PlaylistItems])
class PlaylistDao extends DatabaseAccessor<AppDatabase> {
  PlaylistDao(super.db);

  AppDatabase get _db => db as AppDatabase;

  /// All playlists in creation order, with item counts (GROUP BY single query).
  Stream<List<PlaylistWithCount>> watchPlaylists() {
    final count = _db.playlistItems.id.count();
    final query = _db.selectOnly(_db.playlists)
      ..addColumns([
        _db.playlists.id,
        _db.playlists.name,
        _db.playlists.createdAt,
        _db.playlists.updatedAt,
        count,
      ])
      ..join([
        leftOuterJoin(
          _db.playlistItems,
          _db.playlistItems.playlistId.equalsExp(_db.playlists.id),
        ),
      ])
      ..groupBy([_db.playlists.id])
      ..orderBy([OrderingTerm.asc(_db.playlists.createdAt)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => PlaylistWithCount(
              playlist: PlaylistRow(
                id: row.read(_db.playlists.id)!,
                name: row.read(_db.playlists.name)!,
                createdAt: row.read(_db.playlists.createdAt)!,
                updatedAt: row.read(_db.playlists.updatedAt)!,
              ),
              itemCount: row.read(count) ?? 0,
            ),
          )
          .toList(),
    );
  }

  Future<PlaylistRow?> byId(String id) => (_db.select(
    _db.playlists,
  )..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<PlaylistRow> create(String name) async {
    final now = DateTime.now();
    final row = PlaylistRow(
      id: const Uuid().v4(),
      name: name,
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.playlists).insert(row);
    return row;
  }

  Future<void> rename(String id, String name) async {
    await (_db.update(_db.playlists)..where((p) => p.id.equals(id))).write(
      PlaylistsCompanion(name: Value(name), updatedAt: Value(DateTime.now())),
    );
  }

  Future<void> deletePlaylist(String id) async {
    await (_db.delete(
      _db.playlistItems,
    )..where((i) => i.playlistId.equals(id))).go();
    await (_db.delete(_db.playlists)..where((p) => p.id.equals(id))).go();
  }

  /// Items in play order, joined with nothing — callers resolve titles via
  /// the media registry.
  Stream<List<PlaylistItemRow>> watchItems(String playlistId) =>
      (_db.select(_db.playlistItems)
            ..where((i) => i.playlistId.equals(playlistId))
            ..orderBy([(i) => OrderingTerm.asc(i.position)]))
          .watch();

  Future<List<PlaylistItemRow>> itemsOnce(String playlistId) =>
      (_db.select(_db.playlistItems)
            ..where((i) => i.playlistId.equals(playlistId))
            ..orderBy([(i) => OrderingTerm.asc(i.position)]))
          .get();

  /// Appends [targetType]/[targetId] unless already present; returns whether
  /// a new row was written.
  Future<bool> addItem({
    required String playlistId,
    required String targetType,
    required String targetId,
  }) async {
    final existing =
        await (_db.select(_db.playlistItems)..where(
              (i) =>
                  i.playlistId.equals(playlistId) &
                  i.targetType.equals(targetType) &
                  i.targetId.equals(targetId),
            ))
            .getSingleOrNull();
    if (existing != null) return false;

    final maxPosRow =
        await (_db.selectOnly(_db.playlistItems)
              ..addColumns([_db.playlistItems.position.max()])
              ..where(_db.playlistItems.playlistId.equals(playlistId)))
            .getSingleOrNull();
    final maxPos = maxPosRow?.read(_db.playlistItems.position.max()) ?? -1;
    await _db
        .into(_db.playlistItems)
        .insert(
          PlaylistItemRow(
            id: const Uuid().v4(),
            playlistId: playlistId,
            targetType: targetType,
            targetId: targetId,
            position: maxPos + 1,
            addedAt: DateTime.now(),
          ),
        );
    await _touch(playlistId);
    return true;
  }

  /// Removes the item and compacts the remaining positions back to dense
  /// 0..n-1 order.
  Future<void> removeItem(String itemId) async {
    final item = await (_db.select(
      _db.playlistItems,
    )..where((i) => i.id.equals(itemId))).getSingleOrNull();
    if (item == null) return;
    await (_db.delete(
      _db.playlistItems,
    )..where((i) => i.id.equals(itemId))).go();
    await _compact(item.playlistId);
    await _touch(item.playlistId);
  }

  /// Moves [itemId] up/down by swapping positions with its neighbour.
  Future<void> moveItem(String itemId, {required bool up}) async {
    final item = await (_db.select(
      _db.playlistItems,
    )..where((i) => i.id.equals(itemId))).getSingleOrNull();
    if (item == null) return;
    final rows = await itemsOnce(item.playlistId);
    final index = rows.indexWhere((r) => r.id == itemId);
    final neighbourIndex = up ? index - 1 : index + 1;
    if (neighbourIndex < 0 || neighbourIndex >= rows.length) return;
    final neighbour = rows[neighbourIndex];
    await _db.batch((batch) {
      batch.update(
        _db.playlistItems,
        PlaylistItemsCompanion(position: Value(neighbour.position)),
        where: (i) => i.id.equals(item.id),
      );
      batch.update(
        _db.playlistItems,
        PlaylistItemsCompanion(position: Value(item.position)),
        where: (i) => i.id.equals(neighbour.id),
      );
    });
    await _touch(item.playlistId);
  }

  Future<void> _compact(String playlistId) async {
    final rows = await itemsOnce(playlistId);
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].position != i) {
        await (_db.update(_db.playlistItems)
              ..where((r) => r.id.equals(rows[i].id)))
            .write(PlaylistItemsCompanion(position: Value(i)));
      }
    }
  }

  Future<void> _touch(String playlistId) async {
    await (_db.update(_db.playlists)..where((p) => p.id.equals(playlistId)))
        .write(PlaylistsCompanion(updatedAt: Value(DateTime.now())));
  }
}

/// Playlist row plus its item count, for the library playlists tab.
class PlaylistWithCount {
  const PlaylistWithCount({required this.playlist, required this.itemCount});

  final PlaylistRow playlist;
  final int itemCount;
}
