/// Shared UI entry point for local-file ASR generation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/media_registry_provider.dart';
import 'package:enjoy_player/data/db/media_target_resolver.dart';
import 'package:enjoy_player/features/asr/application/asr_failure_messages.dart';
import 'package:enjoy_player/features/asr/application/asr_generation_controller.dart';
import 'package:enjoy_player/features/asr/application/asr_generation_job.dart';
import 'package:enjoy_player/features/asr/application/asr_long_media_dialog.dart';
import 'package:enjoy_player/features/asr/data/asr_audio_extractor.dart';
import 'package:enjoy_player/features/library/domain/media.dart'
    as library_media;
import 'package:enjoy_player/features/player/domain/playable_source.dart';
import 'package:enjoy_player/core/errors/ai_failure_messages.dart';
import 'package:enjoy_player/features/transcript/presentation/import_subtitle_language_dialog.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Starts ASR only for a local library file and surfaces the terminal outcome.
///
/// Unmount safety: the menu sheet that calls this closes while the language /
/// long-media dialogs are up, and by the time generation finishes the sheet's
/// widget is long gone. Everything derived from [ref] is therefore captured
/// **before the first await** — providers, the generation controller notifier,
/// and the [AppLocalizations] instance — and terminal notices go through the
/// global messenger ([AppNotice.successGlobal] etc.). Using `ref` after
/// unmount used to throw "Bad state: Using ref when a widget is about to or
/// has been unmounted" and the whole generation died silently before starting.
Future<void> launchAsrGeneration(
  BuildContext context,
  WidgetRef ref, {
  required String mediaId,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final db = ref.read(appDatabaseProvider);
  final registry = ref.read(mediaRegistryProvider);
  final controller = ref.read(
    asrGenerationControllerProvider(mediaId).notifier,
  );

  final media = await registry.getById(mediaId);
  final source = await resolvePlayableSource(db, mediaId);
  if (media == null || source is! LocalFilePlayableSource) {
    if (context.mounted) {
      AppNotice.error(context, l10n.asrErrorUnsupportedSource);
    } else {
      AppNotice.errorGlobal(l10n.asrErrorUnsupportedSource);
    }
    return;
  }

  final kind = media.kind == library_media.MediaKind.video
      ? MediaKind.video
      : MediaKind.audio;
  final storedLanguage = media.language;
  if (!context.mounted) return;
  final language = await showAsrLanguageDialog(
    context,
    initialLanguage: storedLanguage,
  );
  if (language == null) return;
  if (!context.mounted) return;
  final refreshed = await registry.getById(mediaId);
  if (refreshed == null) {
    AppNotice.errorGlobal(l10n.asrErrorUnsupportedSource);
    return;
  }
  final durationSeconds = refreshed.durationMs ~/ 1000;
  if (!context.mounted) return;
  final confirmed = await showAsrLongMediaConfirmDialog(
    context,
    mediaDurationSeconds: durationSeconds,
  );
  if (confirmed != true) return;

  // Terminal outcome: returned by the controller above — no `ref` access
  // needed, the sheet that started this is unmounted by now.
  final job = await controller.generateTranscript(
    mediaSourceUri: source.uri,
    kind: kind,
    language: language.language,
    autoDetect: language.language == null,
  );

  if (job?.phase == AsrGenerationPhase.success) {
    AppNotice.successGlobal(l10n.asrStatusSuccess);
  } else if (job?.phase == AsrGenerationPhase.error) {
    final failure = job!.creditsFailure;
    AppNotice.errorGlobal(
      failure != null && failure.requiredCredits != null
          ? creditsFailureMessage(failure, l10n)
          : asrMessageForKey(l10n, job.errorMessage),
    );
  }
}
