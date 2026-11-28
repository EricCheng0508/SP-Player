/// One seam over the `videos` / `audios` table split (issues #593, #723).
///
/// The library persists media in two sibling tables, but callers think in
/// terms of a single `Media`. [MediaRegistry] hides the video-then-audio
/// probe, the row→[Media] mapping, and the per-table write dispatch so each
/// branch exists once — callers and tests cross the same interface instead
/// of re-probing or writing both DAOs (ADR-0002 keeps the queries in the
/// data layer).
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:enjoy_player/core/utils/stream_combine_latest.dart';
import 'package:enjoy_player/core/utils/stream_distinct.dart';
import 'package:enjoy_player/features/library/domain/media.dart';

import 'app_database.dart';
import 'media_library_row.dart';

part 'media_registry_mapping.dart';
part 'media_registry_reads.dart';
part 'media_registry_streams.dart';
part 'media_registry_writes.dart';

/// Unified read + write seam over the `videos` / `audios` split.
///
/// Video wins when the same id exists in both tables (defensive; production
/// never inserts one id into both — see `media_target_resolver_test.dart`).
///
/// Writes are thin dispatch choke points: callers hand over a row or a field
/// patch and get back the [MediaKind] they touched instead of branching per
/// table themselves. Transaction and GC policy stay with the callers.
class MediaRegistry
    with MediaRegistryReads, MediaRegistryStreams, MediaRegistryWrites {
  const MediaRegistry(this._db);

  @override
  final AppDatabase _db;
}
