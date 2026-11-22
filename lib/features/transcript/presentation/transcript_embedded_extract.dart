/// Shared embedded-subtitle extraction for local video (sheet + empty state).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart' as mk;

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/media_target_resolver.dart';
import 'package:enjoy_player/features/player/application/player_engine_capabilities.dart';
import 'package:enjoy_player/features/player/application/player_engine_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Demuxes embedded subtitle streams via ffmpeg / media_kit metadata.
///
/// Unmount safety: the sheet that triggers extraction can close mid-run
/// (extraction takes seconds), so providers and [AppLocalizations] are
/// captured before the first await and terminal notices go through the
/// global messenger. Using `ref` after unmount throws and the extract
/// result is never surfaced.
Future<void> runEmbeddedSubtitleExtract({
  required BuildContext context,
  required WidgetRef ref,
  required String mediaId,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final db = ref.read(appDatabaseProvider);
  final repo = ref.read(transcriptRepositoryProvider);
  final engine = ref.read(playerEngineProvider);
  final uri = await resolvePlayableSourceUri(db, mediaId);
  if (uri == null) {
    if (context.mounted) {
      AppNotice.error(context, l10n.subtitlesNoPlayableUri);
    } else {
      AppNotice.errorGlobal(l10n.subtitlesNoPlayableUri);
    }
    return;
  }

  final SubtitleTrackControl? subtitles = switch (engine) {
    SubtitleTrackControl control => control,
    _ => null,
  };
  final tracksStream = subtitles?.mkTracksStream;
  var playerSubs = <mk.SubtitleTrack>[];
  if (tracksStream != null) {
    try {
      final t = await tracksStream
          .firstWhere((e) => e.subtitle.isNotEmpty)
          .timeout(const Duration(seconds: 2));
      playerSubs = t.subtitle;
    } on TimeoutException {} // ignore: empty_catches
  }

  final count = await repo.extractEmbeddedTracks(
    mediaId: mediaId,
    sourceUri: uri,
    playerSubtitleTracks: playerSubs,
  );

  if (count == 0) {
    AppNotice.warningGlobal(l10n.subtitlesExtractNoTracks);
  } else {
    AppNotice.successGlobal(l10n.subtitlesExtractedCount(count));
  }
}
