/// The dock's playback-rate preset bottom sheet and the desktop anchored
/// hover menu.
library;

import 'dart:async';

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

/// Single-flight state for the anchored hover menu: only one instance shows
/// at a time, and the previous one is closed when a new one opens.
OverlayPortalController? _activeRateMenu;
void Function()? _activeRateMenuCloser;

/// Anchored rate menu host for desktop speed controls: the menu shows while
/// the pointer rests on the control or the panel (same hover idiom as the
/// volume slider), click pins it open, click outside dismisses. Unlike the
/// old PopupRoute version there is NO modal barrier — the barrier blocked
/// hit-testing below and made the anchor's MouseRegion flap open/close every
/// time the pointer moved ("menu keeps jumping").
///
/// Wrap the speed control ([child]) with this; the child may keep its own
/// tap handler calling [showPlaybackRatePicker], which becomes a no-op while
/// the menu is open.
class RateMenuHoverRegion extends ConsumerStatefulWidget {
  const RateMenuHoverRegion({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<RateMenuHoverRegion> createState() =>
      _RateMenuHoverRegionState();
}

class _RateMenuHoverRegionState extends ConsumerState<RateMenuHoverRegion> {
  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  Timer? _hideTimer;
  bool _hovering = false;
  bool _pinned = false;

  void _cancelHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  void _syncPopup() {
    final visible = _hovering || _pinned;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (visible) {
        if (!_portal.isShowing) {
          // Close any other instance's menu first — one menu at a time.
          if (_activeRateMenu != null && !identical(_activeRateMenu, _portal)) {
            _activeRateMenuCloser?.call();
          }
          _activeRateMenu = _portal;
          _activeRateMenuCloser = _hideNow;
          _portal.show();
        }
      } else if (_portal.isShowing) {
        _portal.hide();
        if (identical(_activeRateMenu, _portal)) {
          _activeRateMenu = null;
          _activeRateMenuCloser = null;
        }
      }
    });
  }

  void _onPointerInside(bool inside) {
    _hovering = inside;
    if (inside) {
      _cancelHideTimer();
      _syncPopup();
    } else if (!_pinned) {
      _cancelHideTimer();
      _hideTimer = Timer(const Duration(milliseconds: 260), () {
        if (!mounted || _hovering || _pinned) return;
        _syncPopup();
      });
    }
  }

  void _togglePin() {
    _cancelHideTimer();
    setState(() => _pinned = !_pinned);
    _syncPopup();
  }

  void _dismissPinned() {
    if (!_pinned) return;
    setState(() => _pinned = false);
    _syncPopup();
  }

  void _hideNow() {
    _cancelHideTimer();
    _hovering = false;
    _pinned = false;
    if (_portal.isShowing) _portal.hide();
    if (identical(_activeRateMenu, _portal)) {
      _activeRateMenu = null;
      _activeRateMenuCloser = null;
    }
  }

  @override
  void dispose() {
    _cancelHideTimer();
    if (identical(_activeRateMenu, _portal)) {
      _activeRateMenu = null;
      _activeRateMenuCloser = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (overlayCtx) {
        // Over the OS-fullscreen video the menu joins the dark translucent
        // chrome family (same as the fullscreen transport bar); in the
        // windowed dock it is paper.
        final dark = ref.read(windowFullscreenProvider);
        final panel = CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.topRight,
          followerAnchor: Alignment.bottomRight,
          offset: const Offset(0, -6),
          child: _RateMenuPanel(
            dark: dark,
            rate: ref.read(playerPreferencesCtrlProvider).playbackRate,
            onHover: _onPointerInside,
            onPick: (option) {
              unawaited(
                ref
                    .read(playerPreferencesCtrlProvider.notifier)
                    .setPlaybackRate(option),
              );
              _hideNow();
            },
          ),
        );
        return Stack(
          children: [
            if (_pinned)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _dismissPinned,
                ),
              ),
            panel,
          ],
        );
      },
      child: CompositedTransformTarget(
        link: _link,
        child: MouseRegion(
          onEnter: (_) => _onPointerInside(true),
          onExit: (_) => _onPointerInside(false),
          // Click the control to pin/unpin. Translucent so the inner press
          // ripple still plays; the inner onTap's [showPlaybackRatePicker]
          // no-ops while the menu is open.
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _togglePin(),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Speed presets picker: on desktop the anchored hover menu (owned by the
/// enclosing [RateMenuHoverRegion]) — this is a no-op while it is open; on
/// mobile falls back to the bottom sheet.
Future<void> showPlaybackRatePicker({
  required BuildContext context,
  required WidgetRef ref,
  required BuildContext anchor,
}) async {
  if (!isMobilePlatform) return;
  await showPlaybackRateSheet(context: context, ref: ref);
}

/// Height of the compact rate menu: 6 x 24 px rows + 8 px vertical padding =
/// 152 px, matching the volume slider popup for one popover silhouette.
const double kRateMenuHeight = 152;

const double kRateMenuWidth = 120;

class _RateMenuPanel extends StatelessWidget {
  const _RateMenuPanel({
    required this.dark,
    required this.rate,
    required this.onHover,
    required this.onPick,
  });

  final bool dark;
  final double rate;
  final void Function(bool inside) onHover;
  final void Function(double option) onPick;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    // 88% opaque: translucent panels read as washed grey over bright video
    // content; near-solid keeps the popover uniform over any background.
    final color = dark ? Colors.black.withValues(alpha: 0.88) : t.paper;
    final borderColor = dark
        ? Colors.white.withValues(alpha: 0.14)
        : t.line;
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      // The elevation draws the drop shadow OUTSIDE the surface. A Container
      // boxShadow cannot be used here: without a color of its own it paints
      // the blurred shadow OVER the Material's surface and turns the white
      // panel muddy grey (35% black over white = rgb 166).
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        child: Container(
          width: kRateMenuWidth,
          height: kRateMenuHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final option in kPlaybackRatePresets)
                _RateMenuEntry(
                  option: option,
                  selected: playbackRatesEqual(option, rate),
                  dark: dark,
                  onPick: onPick,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RateMenuEntry extends StatelessWidget {
  const _RateMenuEntry({
    required this.option,
    required this.selected,
    required this.dark,
    required this.onPick,
  });

  final double option;
  final bool selected;
  final bool dark;
  final void Function(double option) onPick;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    // Dark variant mirrors the fullscreen transport bar: white monochrome on
    // translucent black. Paper variant keeps brand ink on paper.
    final checkColor = dark ? Colors.white : t.brandInk;
    final labelColor = dark
        ? (selected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.78))
        : (selected ? t.ink : t.ink2);
    return InkWell(
      onTap: () => onPick(option),
      child: SizedBox(
        height: 24,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: selected
                    ? Icon(EnjoyIcons.check, size: 13, color: checkColor)
                    : null,
              ),
              Text(
                '${formatRateCore(option)}×',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  letterSpacing: 0.3,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: labelColor,
                ),
              ),
            ],
          ),
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
