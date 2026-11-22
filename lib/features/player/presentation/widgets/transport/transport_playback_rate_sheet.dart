/// The dock's playback-rate preset bottom sheet.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/platform/mobile_platform.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/theme/widgets/sheet_drag_handle.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_dock_primitives.dart'
    show formatRateCore;
import 'package:enjoy_player/features/player/presentation/widgets/transport/transport_playback_rate.dart'
    show kPlaybackRatePresets, playbackRatesEqual;
import 'package:enjoy_player/l10n/app_localizations.dart';

const double kMenuItemHeight = 40;

/// Speed presets picker: on desktop a small popup menu anchored right at the
/// speed button (one tap switches, no big dialog); on mobile falls back to
/// the bottom sheet. [anchor] is the [BuildContext] of the speed button.
Future<void> showPlaybackRatePicker({
  required BuildContext context,
  required WidgetRef ref,
  required BuildContext anchor,
}) async {
  if (!isMobilePlatform) {
    final anchorBox = anchor.findRenderObject();
    if (anchorBox is RenderBox && anchorBox.hasSize) {
      await _showAnchoredRateMenu(context, ref, anchor, anchorBox);
      return;
    }
  }
  await showPlaybackRateSheet(context: context, ref: ref);
}

Future<void> _showAnchoredRateMenu(
  BuildContext context,
  WidgetRef ref,
  BuildContext anchor,
  RenderBox anchorBox,
) async {
  final overlay =
      Navigator.of(anchor).overlay!.context.findRenderObject()! as RenderBox;
  final topLeft = anchorBox.localToGlobal(Offset.zero, ancestor: overlay);
  final bottomRight = anchorBox
      .localToGlobal(anchorBox.size.bottomRight(Offset.zero), ancestor: overlay);
  // The dock sits at the bottom of the screen: ask for the menu *above* the
  // button (bottom aligned with the button top). showMenu clamps the position
  // back into the screen if the estimate misses.
  final estimatedMenuHeight =
      kPlaybackRatePresets.length * kMenuItemHeight + 16;
  final wantedTop = math.max(0.0, topLeft.dy - estimatedMenuHeight);
  final rate = ref.read(
    playerPreferencesCtrlProvider.select((p) => p.playbackRate),
  );
  final t = EnjoyThemeTokens.of(context);
  final l10n = AppLocalizations.of(anchor)!;
  final picked = await showMenu<double>(
    context: anchor,
    position: RelativeRect.fromLTRB(
      topLeft.dx,
      wantedTop,
      overlay.size.width - bottomRight.dx,
      overlay.size.height - bottomRight.dy,
    ),
    constraints: const BoxConstraints(minWidth: 130, maxWidth: 200),
    items: [
      for (final option in kPlaybackRatePresets)
        PopupMenuItem<double>(
          value: option,
          height: kMenuItemHeight,
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: playbackRatesEqual(option, rate)
                    ? Icon(EnjoyIcons.check, size: 16, color: t.brandInk)
                    : null,
              ),
              Text(l10n.playbackRateTimes(formatRateCore(option))),
            ],
          ),
        ),
    ],
  );
  if (picked != null) {
    await ref
        .read(playerPreferencesCtrlProvider.notifier)
        .setPlaybackRate(picked);
  }
}

/// Opens the speed-preset sheet; resolves when the sheet closes.
Future<void> showPlaybackRateSheet({
  required BuildContext context,
  required WidgetRef ref,
}) {
  final t = EnjoyThemeTokens.of(context);
  return showEnjoySheet<void>(
    context: context,
    builder: (sheetCtx) {
      final rate = ref.read(
        playerPreferencesCtrlProvider.select((p) => p.playbackRate),
      );
      final l10n = AppLocalizations.of(sheetCtx)!;
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PaddedSheetDragHandle(),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  t.space20,
                  t.space4,
                  t.space20,
                  t.space8,
                ),
                child: Text(
                  l10n.speed,
                  style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final option in kPlaybackRatePresets)
                ListTile(
                  title: Text(l10n.playbackRateTimes(formatRateCore(option))),
                  trailing: playbackRatesEqual(option, rate)
                      ? Icon(EnjoyIcons.check, color: t.brandInk)
                      : null,
                  onTap: () {
                    unawaited(
                      ref
                          .read(playerPreferencesCtrlProvider.notifier)
                          .setPlaybackRate(option),
                    );
                    Navigator.pop(sheetCtx);
                  },
                ),
              SizedBox(height: t.space16),
            ],
          ),
        ),
      );
    },
  );
}
