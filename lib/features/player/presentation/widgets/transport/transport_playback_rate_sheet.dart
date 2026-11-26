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
import 'package:enjoy_player/core/window/window_fullscreen_provider.dart';
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
  final topLeft = topLeftOf(anchorBox, overlay);
  final bottomRight = anchorBox
      .localToGlobal(anchorBox.size.bottomRight(Offset.zero), ancestor: overlay);
  final anchorRect = Rect.fromPoints(topLeft, bottomRight);
  final rate = ref.read(
    playerPreferencesCtrlProvider.select((p) => p.playbackRate),
  );
  // Over the OS-fullscreen video the chrome family is dark translucent (same
  // as the fullscreen transport bar); in the windowed dock it is paper. The
  // provider reports false on mobile, so this is a no-op there.
  final dark = ref.read(windowFullscreenProvider);
  final l10n = AppLocalizations.of(anchor)!;
  final picked = await Navigator.of(anchor, rootNavigator: true).push(
    _AnchoredRateMenuRoute(
      anchorRect: anchorRect,
      rate: rate,
      l10n: l10n,
      dark: dark,
    ),
  );
  if (picked != null) {
    await ref
        .read(playerPreferencesCtrlProvider.notifier)
        .setPlaybackRate(picked);
  }
}

Offset topLeftOf(RenderBox box, RenderBox ancestor) =>
    box.localToGlobal(Offset.zero, ancestor: ancestor);

/// Themed anchored rate menu — same visual language as the player's popover
/// family (paper panel, brand check) with a soft fade + rise transition, in
/// place of the stock PopupMenu's flat white sheet and stiff fade. Over the
/// fullscreen video it switches to the dark translucent chrome family shared
/// with the fullscreen transport bar.
class _AnchoredRateMenuRoute extends PopupRoute<double> {
  _AnchoredRateMenuRoute({
    required this.anchorRect,
    required this.rate,
    required this.l10n,
    required this.dark,
  }) : super();

  final Rect anchorRect;
  final double rate;
  final AppLocalizations l10n;
  final bool dark;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => l10n.speed;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 160);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 120);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return CustomSingleChildLayout(
      delegate: _RateMenuLayout(anchorRect: anchorRect),
      child: _RateMenuPanel(dark: dark),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }
}

/// Places the menu right above the speed chip, right-aligned with it,
/// clamped into the overlay bounds.
class _RateMenuLayout extends SingleChildLayoutDelegate {
  _RateMenuLayout({required this.anchorRect});

  final Rect anchorRect;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      maxWidth: kRateMenuMaxWidth,
      maxHeight: constraints.maxHeight * 0.9,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final dx = (anchorRect.right - childSize.width).clamp(
      8.0,
      math.max(8.0, size.width - childSize.width - 8),
    ).toDouble();
    final dy = (anchorRect.top - childSize.height - 8).clamp(
      8.0,
      math.max(8.0, size.height - childSize.height - 8),
    ).toDouble();
    return Offset(dx, dy);
  }

  @override
  bool shouldRelayout(_RateMenuLayout old) => old.anchorRect != anchorRect;
}

const double kRateMenuMaxWidth = 168;

class _RateMenuPanel extends StatelessWidget {
  const _RateMenuPanel({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final route =
        ModalRoute.of(context)! as _AnchoredRateMenuRoute;
    final t = EnjoyThemeTokens.of(context);
    final color = dark ? Colors.black.withValues(alpha: 0.72) : t.paper;
    final borderColor = dark
        ? Colors.white.withValues(alpha: 0.14)
        : t.line;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final option in kPlaybackRatePresets)
              _RateMenuEntry(
                route: route,
                option: option,
                selected: playbackRatesEqual(option, route.rate),
                dark: dark,
              ),
          ],
        ),
      ),
    );
  }
}

class _RateMenuEntry extends StatelessWidget {
  const _RateMenuEntry({
    required this.route,
    required this.option,
    required this.selected,
    required this.dark,
  });

  final _AnchoredRateMenuRoute route;
  final double option;
  final bool selected;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    // Dark variant mirrors the fullscreen transport bar: white monochrome on
    // translucent black. Paper variant keeps brand ink on paper.
    final checkColor = dark ? Colors.white : t.brandInk;
    final labelColor = dark
        ? (selected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.72))
        : (selected ? t.ink : t.ink2);
    return InkWell(
      onTap: () => Navigator.of(context).pop(option),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: selected
                  ? Icon(EnjoyIcons.check, size: 16, color: checkColor)
                  : null,
            ),
            Text(
              route.l10n.playbackRateTimes(formatRateCore(option)),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
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
