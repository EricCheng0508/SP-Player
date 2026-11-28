/// Shared import flow for Home / Library.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/config/local_mode.dart';
import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/data/files/media_resolver.dart';
import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/platform/mobile_platform.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/theme/widgets/sheet_drag_handle.dart';
import 'package:enjoy_player/features/library/application/library_media_provider.dart';
import 'package:enjoy_player/features/library/application/library_repository_provider.dart';
import 'package:enjoy_player/features/library/presentation/widgets/content_language_picker.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

final _importUiLog = logNamed('library.importUi');

/// Blocking progress dialog shown on the root navigator while a file or YouTube
/// import is in flight. [label] resolves to the localized status string from
/// the [AppLocalizations] exposed inside the dialog's own [BuildContext], so
/// callers pass `(l10n) => l10n.importingMedia` (file) or
/// `(l10n) => l10n.youtubeImporting` (YouTube).
///
/// The dialog's own [BuildContext] is captured into [dialogContextCompleter]
/// so [_dismissImportDialog] can pop the route from the dialog side — the
/// dismissal must not depend on the *caller's* context (which may unmount
/// during a long import, e.g. the home page rebuilding after the library
/// provider refreshes, which previously left the spinner stuck forever).
Future<void> _showImportProgressDialog(
  BuildContext context,
  String Function(AppLocalizations) label, {
  required Completer<BuildContext> dialogContextCompleter,
}) {
  return showEnjoyDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (dialogContext) {
      if (!dialogContextCompleter.isCompleted) {
        dialogContextCompleter.complete(dialogContext);
      }
      final l10n = AppLocalizations.of(dialogContext)!;
      return PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: 24),
              Expanded(child: Text(label(l10n))),
            ],
          ),
        ),
      );
    },
  );
}

/// Pops the blocking import dialog and waits until its route has fully left
/// the navigator so follow-up navigation (e.g. [openPlayerRoute]) cannot hit
/// `!_debugLocked`.
///
/// Pops from the dialog's own captured [BuildContext] instead of the caller's:
/// the dialog lives on the root navigator, so its own context is the most
/// reliable handle and works even when the caller's context has unmounted.
/// [dialogFuture] is the future returned by [showEnjoyDialog]; it completes
/// when the route is removed. A 2s timeout keeps navigation moving even if
/// the future never settles (logged for diagnosis).
Future<void> _dismissImportDialog({
  required Future<void> dialogFuture,
  required Completer<BuildContext> dialogContextCompleter,
  required String phase,
}) async {
  if (!dialogContextCompleter.isCompleted) {
    _importUiLog.warning(
      'import dialog[$phase]: dialog context never captured; cannot pop',
    );
    return;
  }
  final dialogContext = await dialogContextCompleter.future;
  if (!dialogContext.mounted) {
    _importUiLog.warning('import dialog[$phase]: dialog route already gone');
    return;
  }
  _importUiLog.info('import dialog[$phase]: popping dialog route');
  Navigator.of(dialogContext).pop();
  try {
    await dialogFuture.timeout(const Duration(seconds: 2));
  } on Object catch (e) {
    _importUiLog.warning(
      'import dialog[$phase]: dialog future did not settle: $e',
    );
    return;
  }
  _importUiLog.info('import dialog[$phase]: dialog route removed');
}

/// Runs [import] behind the shared blocking-progress scaffold: shows the
/// progress dialog, waits a frame, then dismisses the dialog and either
/// opens the player or surfaces an error notice.
Future<void> _runBlockingImport(
  BuildContext context, {
  required String Function(AppLocalizations) progressLabel,
  required Future<String> Function(String signedInUserId) import,
  required String Function(AppLocalizations) importFailureLabel,
  required String unsupportedFileLabel,
}) async {
  final l10n = AppLocalizations.of(context)!;
  const sessionUserId = kLocalSessionId;
  final dialogContextCompleter = Completer<BuildContext>();
  _importUiLog.info('blocking import: showing dialog');
  final dialogFuture = _showImportProgressDialog(
    context,
    progressLabel,
    dialogContextCompleter: dialogContextCompleter,
  );
  await WidgetsBinding.instance.endOfFrame;

  Future<void> dismiss(String phase) => _dismissImportDialog(
    dialogFuture: dialogFuture,
    dialogContextCompleter: dialogContextCompleter,
    phase: phase,
  );

  try {
    final id = await import(sessionUserId);
    _importUiLog.info(
      'blocking import: import finished id=$id, dismissing dialog',
    );
    await dismiss('success');
    if (!context.mounted) {
      _importUiLog.warning(
        'blocking import: caller context unmounted, skip navigation',
      );
      return;
    }
    _importUiLog.info('blocking import: opening player $id');
    openPlayerRoute(context, id);
  } on AppFailure catch (e) {
    _importUiLog.warning(
      'blocking import failed[${e.runtimeType}]: ${e.message}',
    );
    await dismiss('failure');
    if (!context.mounted) return;
    AppNotice.error(
      context,
      e is UnsupportedImportFileFailure ? unsupportedFileLabel : e.message,
    );
  } catch (e, st) {
    _importUiLog.warning('blocking import crashed: $e', e, st);
    await dismiss('crash');
    if (!context.mounted) return;
    AppNotice.error(context, importFailureLabel(l10n));
  }
}

Future<void> importMediaFromPicker(BuildContext context, WidgetRef ref) async {
  final pick = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: kFilePickerLocalImportExtensions,
  );
  if (pick == null) return;
  final path = pick.path;
  if (path == null) return;
  if (!context.mounted) return;

  final contentLanguage = await showContentLanguagePicker(
    context: context,
    ref: ref,
  );
  if (contentLanguage == null || !context.mounted) return;

  final repository = ref.read(mediaLibraryRepositoryProvider);
  await _runBlockingImport(
    context,
    progressLabel: (d) => d.importingMedia,
    import: (userId) => repository.importMedia(
      XFile(path),
      signedInUserId: userId,
      contentLanguage: contentLanguage,
    ),
    importFailureLabel: (l10n) => l10n.importMediaFailed,
    unsupportedFileLabel: AppLocalizations.of(
      context,
    )!.importUnsupportedFileType,
  );
}

Future<void> confirmAndDeleteMedia(
  BuildContext context,
  WidgetRef ref,
  Media media,
) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showEnjoyConfirmDialog(
    context: context,
    title: l10n.libraryDeleteMediaTitle,
    message: l10n.libraryDeleteMediaMessage(media.title),
    confirmLabel: MaterialLocalizations.of(context).deleteButtonTooltip,
    destructive: true,
  );
  if (confirmed != true || !context.mounted) return;
  try {
    final session = ref.read(playerControllerProvider);
    await ref.read(mediaLibraryRepositoryProvider).deleteMedia(media.id);
    if (!context.mounted) return;
    if (session?.mediaId == media.id) {
      await ref.read(playerControllerProvider.notifier).clear();
    }
    if (!context.mounted) return;
    final openId = GoRouterState.of(context).pathParameters['mediaId'];
    if (openId == media.id) {
      context.pop();
    }
    if (!context.mounted) return;
    AppNotice.success(context, l10n.libraryMediaDeleted);
  } catch (_) {
    if (context.mounted) {
      AppNotice.error(context, l10n.libraryDeleteFailed);
    }
  }
}

/// Import chooser: file, YouTube URL, or Craft. Desktop windows with an
/// [anchor] (the Import button) get a menu dropped under it; otherwise a
/// bottom sheet.
Future<void> showImportChooser(
  BuildContext context,
  WidgetRef ref, {
  BuildContext? anchor,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final options = <(IconData, String, VoidCallback)>[
    (
      EnjoyIcons.folder,
      l10n.importFromFile,
      () => unawaited(importMediaFromPicker(context, ref)),
    ),
    (
      EnjoyIcons.videoLibrary,
      l10n.importFromYoutube,
      () => unawaited(importYoutubeFromDialog(context, ref)),
    ),
    (
      EnjoyIcons.sparkle,
      l10n.importCraftFromText,
      () => unawaited(context.push('/craft')),
    ),
  ];

  final anchorBox = anchor?.findRenderObject();
  if (!isMobilePlatform && anchorBox is RenderBox && anchorBox.hasSize) {
    final overlay =
        Navigator.of(anchor!).overlay!.context.findRenderObject()! as RenderBox;
    final topLeft = anchorBox.localToGlobal(
      Offset(0, anchorBox.size.height + 6),
      ancestor: overlay,
    );
    final bottomRight = anchorBox.localToGlobal(
      anchorBox.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );
    final picked = await showMenu<int>(
      context: anchor,
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
      position: RelativeRect.fromLTRB(
        bottomRight.dx,
        topLeft.dy,
        overlay.size.width - bottomRight.dx,
        overlay.size.height - topLeft.dy,
      ),
      items: [
        for (final (i, (icon, label, _)) in options.indexed)
          PopupMenuItem<int>(
            value: i,
            child: Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 12),
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
      ],
    );
    if (picked != null) options[picked].$3();
    return;
  }

  await showEnjoySheet<void>(
    context: context,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PaddedSheetDragHandle(),
            for (final (icon, label, onTap) in options)
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                onTap: () {
                  Navigator.pop(ctx);
                  onTap();
                },
              ),
          ],
        ),
      );
    },
  );
}

Future<void> importYoutubeFromDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController();

  final submitted = await showEnjoyAlertDialog<String>(
    context: context,
    title: Text(l10n.youtubeImportTitle),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(hintText: l10n.youtubeImportHint),
            autofocus: true,
            maxLines: 3,
            minLines: 1,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                final clip = await Clipboard.getData('text/plain');
                final t = clip?.text;
                if (t != null && t.isNotEmpty) {
                  controller.text = t;
                }
              },
              icon: const Icon(EnjoyIcons.paste, size: 18),
              label: Text(l10n.youtubePasteFromClipboard),
            ),
          ),
        ],
      ),
    ),
    actionsBuilder: (ctx) => [
      EnjoyButton.secondary(
        onPressed: () => Navigator.pop(ctx),
        child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
      ),
      EnjoyButton.brand(
        onPressed: () => Navigator.pop(ctx, controller.text.trim()),
        child: Text(l10n.actionImport),
      ),
    ],
  );

  if (submitted == null || submitted.isEmpty) return;
  if (!context.mounted) return;

  final contentLanguage = await showContentLanguagePicker(
    context: context,
    ref: ref,
  );
  if (contentLanguage == null || !context.mounted) return;

  final repository = ref.read(mediaLibraryRepositoryProvider);
  final container = ProviderScope.containerOf(context, listen: false);
  await _runBlockingImport(
    context,
    progressLabel: (d) => d.youtubeImporting,
    import: (userId) async {
      final id = await repository.importYoutubeVideo(
        submitted,
        contentLanguage: contentLanguage,
      );
      container.invalidate(libraryMediaProvider);
      container.invalidate(libraryHomeRecentsProvider);
      return id;
    },
    importFailureLabel: (l10n) => l10n.youtubeImportInvalid,
    unsupportedFileLabel: AppLocalizations.of(context)!.youtubeImportInvalid,
  );
}

Future<void> editMediaLanguage(
  BuildContext context,
  WidgetRef ref,
  Media media,
) async {
  final l10n = AppLocalizations.of(context)!;
  final repository = ref.read(mediaLibraryRepositoryProvider);
  final container = ProviderScope.containerOf(context, listen: false);
  final picked = await showContentLanguagePicker(
    context: context,
    ref: ref,
    selectedValue: media.language,
    title: l10n.mediaEditLanguage,
  );
  if (picked == null || !context.mounted) return;
  if (tagsEqual(picked, media.language)) return;

  try {
    await repository.updateMediaLanguage(media.id, picked);
    final session = container.read(playerControllerProvider);
    if (session?.mediaId == media.id) {
      container
          .read(playerControllerProvider.notifier)
          .applySessionPatch(session!.copyWith(language: picked));
    }
    if (!context.mounted) return;
    AppNotice.success(context, l10n.mediaLanguageUpdated);
  } catch (_) {
    if (context.mounted) {
      AppNotice.error(context, l10n.mediaLanguageUpdateFailed);
    }
  }
}
