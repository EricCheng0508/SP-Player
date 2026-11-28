/// The Download transcript… flow shared by the player's ⋯ More menu and the
/// phone Subtitles & display sheet: SRT is the only format (ADR-0106 — no
/// VTT, no picker), so tapping the menu item saves the file directly.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/platform/file_share_export.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/subtitle/subtitle_filename.dart';
import 'package:enjoy_player/data/subtitle/subtitle_serializer.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../application/active_transcript_provider.dart';
import '../application/all_transcripts_provider.dart';
import '../application/transcript_lines_provider.dart';

/// Resolves the lines of the active primary transcript for a media id.
typedef TranscriptLinesLoad = Future<List<TranscriptLine>> Function();

/// Writes the serialized bytes via the platform save / share surface.
typedef TranscriptExportSave =
    Future<FileShareOutcome> Function({
      required Uint8List bytes,
      required String fileName,
      required String mimeType,
      required String dialogTitle,
    });

/// Downloads the active primary transcript of [mediaId] directly as SRT.
///
/// Shows the empty notice when no primary transcript is active, then hands
/// the serialized bytes to the platform save dialog (desktop) or share sheet
/// (mobile) — no intermediate format picker.
Future<void> downloadActiveTranscript(
  BuildContext context,
  WidgetRef ref,
  String mediaId, {
  TranscriptLinesLoad? loadLines,
  TranscriptExportSave? saveFile,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final resolveLines =
      loadLines ??
      () => ref.read(transcriptLinesForMediaProvider(mediaId).future);
  final lines = await resolveLines();
  if (!context.mounted) return;
  if (lines.isEmpty) {
    AppNotice.error(context, l10n.transcriptDownloadEmpty);
    return;
  }

  // ADR-0106 export gate: exporting the AI (translated) track requires the
  // full-video translation to be complete — partial tracks would serialize
  // empty cues. English tracks are unaffected.
  final activeId = ref.read(activeTranscriptIdProvider(mediaId)).value;
  final tracks = ref.read(allTranscriptsForMediaProvider(mediaId)).valueOrNull;
  final activeSource = tracks
      ?.where((track) => track.id == activeId)
      .firstOrNull
      ?.source;
  if (activeSource == 'ai') {
    final remaining = lines.where((l) => l.text.trim().isEmpty).length;
    if (remaining > 0) {
      AppNotice.error(context, l10n.fullTranslateExportIncomplete(remaining));
      return;
    }
  }

  const format = SubtitleExportFormat.srt;
  final title = ref.read(playerControllerProvider)?.mediaTitle ?? '';
  final fileName = '${transcriptExportBaseName(title)}.${format.fileExtension}';
  final bytes = utf8.encode(format.serialize(lines));

  final save = saveFile ?? saveOrShareBytes;
  final outcome = await save(
    bytes: bytes,
    fileName: fileName,
    mimeType: format.mimeType,
    dialogTitle: l10n.transcriptDownloadDialogTitle,
  );
  if (!context.mounted) return;
  switch (outcome) {
    case FileShareOutcome.saved:
    case FileShareOutcome.shared:
      AppNotice.success(context, l10n.transcriptDownloadSuccess);
    case FileShareOutcome.failed:
      AppNotice.error(context, l10n.transcriptDownloadError);
    case FileShareOutcome.cancelled:
      break;
  }
}
