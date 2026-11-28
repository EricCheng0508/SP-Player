/// Application shell: adaptive navigation + page stack + player-route transport.
library;

import 'dart:async';

import 'package:flutter/services.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/notices/root_shell_bottom_inset.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/app_background.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_bottom_nav.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_chrome_icon.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/core/window/window_fullscreen_provider.dart';
import 'package:enjoy_player/features/onboarding/presentation/onboarding_showcase_host.dart';
import 'package:enjoy_player/features/live_captions/application/live_captions_controller.dart';
import 'package:enjoy_player/features/live_captions/presentation/live_captions_screen.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/presentation/widgets/fullscreen_transport_bar.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_dock.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/update/application/update_controller.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import 'widgets/app_sidebar.dart';
import 'widgets/player_surface_host.dart';

class RootShell extends ConsumerStatefulWidget {
  const RootShell({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  static const _navHome = 0;
  static const _navDiscover = 1;
  static const _navLibrary = 2;
  static const _navSettings = 3;

  /// Fullscreen dock auto-reveal: idle delay before the floating dock slides
  /// away again after a mouse move.
  static const Duration _dockAutoHideDelay = Duration(seconds: 1);

  Timer? _dockHideTimer;
  bool _dockVisible = true;
  bool _keyRevealHandlerActive = false;
  bool _pointerOverDock = false;

  /// While in video fullscreen, any key press reveals the dock (standard
  /// fullscreen UX: mouse move OR keyboard). Returns false so hotkeys and
  /// player shortcuts keep working untouched.
  bool _handleKeyReveal(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) _pokeDock();
    return false;
  }

  void _setKeyRevealHandler(bool active) {
    if (active == _keyRevealHandlerActive) return;
    final keyboard = HardwareKeyboard.instance;
    if (active) {
      keyboard.addHandler(_handleKeyReveal);
    } else {
      keyboard.removeHandler(_handleKeyReveal);
    }
    _keyRevealHandlerActive = active;
  }

  @override
  void dispose() {
    _dockHideTimer?.cancel();
    _setKeyRevealHandler(false);
    super.dispose();
  }

  /// Engine transport snapshot — the same source the video surface uses, so
  /// it always agrees with what is actually on screen (the playerIsPlaying
  /// stream has been observed to lag reality during playback).
  bool _enginePlaying() =>
      ref
          .read(playerControllerProvider.notifier)
          .engineIdentity
          .resolveOrNull()
          ?.transportSnapshot
          .playing ??
      false;

  /// Idle timer fired: hide only while actually playing. Paused video keeps
  /// the dock visible (standard fullscreen UX); the next poke re-arms.
  void _hideDockIfPlaying() {
    if (!_enginePlaying()) return;
    if (mounted) setState(() => _dockVisible = false);
  }

  /// Pointer moved / pressed over the fullscreen stage: show the dock, arm
  /// the idle hide. Hovering the dock itself never hides it.
  void _pokeDock() {
    _dockHideTimer?.cancel();
    if (_pointerOverDock) return; // hovering the dock itself: never hide
    if (!_dockVisible && mounted) setState(() => _dockVisible = true);
    _dockHideTimer = Timer(_dockAutoHideDelay, _hideDockIfPlaying);
  }

  static const _settingsTabPrefixes = {'/settings', '/vocabulary'};

  int _navIndexForPath(String path) {
    if (_settingsTabPrefixes.any(path.startsWith)) return _navSettings;
    if (path.startsWith('/library')) {
      return _navLibrary;
    }
    if (path.startsWith('/discover')) return _navDiscover;
    return _navHome;
  }

  void _goNavIndex(BuildContext context, int index) {
    switch (index) {
      case _navHome:
        context.go('/');
        return;
      case _navDiscover:
        context.go('/discover');
        return;
      case _navLibrary:
        context.go('/library');
        return;
      case _navSettings:
        context.go('/settings');
        return;
      default:
        context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(discoverFeedRefreshSchedulerProvider);
    final chrome = ref.watch(playerControllerProvider.select(playbackChromeOf));
    final sessionActive = chrome != null;
    final updateBadge = ref.watch(updateAvailableBadgeProvider);
    final l10n = AppLocalizations.of(context)!;
    final path = GoRouterState.of(context).uri.path;
    final onPlayer = path.startsWith('/player/');
    final onReview = path.startsWith('/vocabulary/review');

    // True video fullscreen: dock floats over the stage and auto-hides after
    // idle (mouse move reveals it again). The listen must live in the build
    // body — Riverpod forbids listen inside a LayoutBuilder callback, which
    // runs during layout, not build.
    ref.listen(windowFullscreenProvider, (prev, next) {
      if (!onPlayer || !isDesktop || prev == next) return;
      _dockHideTimer?.cancel();
      _setKeyRevealHandler(next);
      if (mounted) setState(() => _dockVisible = true);
      if (next && _enginePlaying()) {
        _dockHideTimer = Timer(_dockAutoHideDelay, _hideDockIfPlaying);
      }
    });

    return OnboardingShowcaseHost(
      child: Builder(
        builder: (context) => LayoutBuilder(
          builder: (context, constraints) {
            final tokens = EnjoyThemeTokens.of(context);
            final useSidebar =
                constraints.maxWidth >= tokens.breakpointRail &&
                !onPlayer &&
                !onReview;

            final bottomNav = (!useSidebar && !onPlayer && !onReview)
                ? EnjoyBottomNav(
                    selectedIndex: _navIndexForPath(path),
                    onDestinationSelected: (i) => _goNavIndex(context, i),
                    destinations: [
                      EnjoyBottomNavDestination(
                        icon: EnjoyIcons.home,
                        selectedIcon: EnjoyIcons.homeFill,
                        iconWidget: const EnjoyChromeIcon(
                          EnjoyChromeGlyph.home,
                        ),
                        selectedIconWidget: const EnjoyChromeIcon(
                          EnjoyChromeGlyph.home,
                          filled: true,
                        ),
                        label: l10n.homeTitle,
                      ),
                      EnjoyBottomNavDestination(
                        icon: EnjoyIcons.compass,
                        selectedIcon: EnjoyIcons.compassFill,
                        iconWidget: const EnjoyChromeIcon(
                          EnjoyChromeGlyph.compass,
                        ),
                        selectedIconWidget: const EnjoyChromeIcon(
                          EnjoyChromeGlyph.compass,
                          filled: true,
                        ),
                        label: l10n.discoverTitle,
                      ),
                      EnjoyBottomNavDestination(
                        icon: EnjoyIcons.library,
                        selectedIcon: EnjoyIcons.library,
                        iconWidget: const EnjoyChromeIcon(
                          EnjoyChromeGlyph.library,
                        ),
                        selectedIconWidget: const EnjoyChromeIcon(
                          EnjoyChromeGlyph.library,
                          filled: true,
                        ),
                        label: l10n.libraryTitle,
                      ),
                      EnjoyBottomNavDestination(
                        icon: EnjoyIcons.gear,
                        selectedIcon: EnjoyIcons.gearFill,
                        iconWidget: const EnjoyChromeIcon(
                          EnjoyChromeGlyph.gear,
                        ),
                        selectedIconWidget: const EnjoyChromeIcon(
                          EnjoyChromeGlyph.gear,
                          filled: true,
                        ),
                        label: l10n.settingsTitle,
                        showBadge: updateBadge,
                        semanticsLabel: updateBadge
                            ? '${l10n.settingsTitle}, ${l10n.updateAvailableBadgeSemantics}'
                            : null,
                      ),
                    ],
                  )
                : null;

            /// `/player/...` nests a [Scaffold] inside the route. Keeping transport in a
            /// [Column] + [Expanded] sibling can yield **zero** body height on some mobile
            /// frames (nested scaffold / safe-area constraint propagation), which pins the
            /// bar under the status bar and hides video + transcript. [Scaffold] reserves
            /// space via [bottomNavigationBar] instead.
            // The dock slot is held for the whole player route: while the
            // session is still opening a placeholder of the dock's exact
            // height stands in (a plain SizedBox — no provider reads, so
            // the engine-identity lazy allocation is not triggered). A dock
            // that appears mid-open resizes a *playing* video — the "flash
            // on open" report.
            final playerWithTransport = onPlayer;

            final videoFullscreen =
                playerWithTransport &&
                isDesktop &&
                ref.watch(windowFullscreenProvider);

            final bottomClearance = !useSidebar && !onPlayer && !onReview
                ? rootShellBottomNavClearance(context)
                : 0.0;

            // Notices must clear the player dock on the player route too —
            // without this [AppNotice] floats at the window bottom and the
            // dock covers it (unreadable dark-on-dark strip).
            final noticeBottomClearance = onPlayer
                ? kRootShellTransportSnackClearance
                : bottomClearance;

            Widget mobileShellScaffold() {
              if (playerWithTransport) {
                Widget playerBody = SafeArea(
                  bottom: false,
                  child: SizedBox.expand(child: widget.child),
                );
                Widget? bottomDock = sessionActive
                    ? PlayerDock(chrome: chrome)
                    : const PlayerDockSkeleton();
                if (videoFullscreen) {
                  // The floating dock is NOT rendered here: the engine video
                  // surface paints above this entire scaffold
                  // (PlayerSurfaceHost is the root Stack's top layer), which
                  // would cover any in-shell overlay. RootShell mounts the
                  // dock ABOVE the surface host instead — see the root Stack
                  // below. Fullscreen just drops the dock slot so the stage
                  // owns the full height.
                  return RootShellBottomInset(
                    bottomClearance: noticeBottomClearance,
                    child: Scaffold(
                      backgroundColor: Colors.transparent,
                      extendBody: true,
                      body: playerBody,
                    ),
                  );
                }
                return RootShellBottomInset(
                  bottomClearance: noticeBottomClearance,
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    extendBody: true,
                    body: playerBody,
                    bottomNavigationBar: Material(
                      type: MaterialType.transparency,
                      // Hard swap skeleton → real dock (same slot, same
                      // height). A crossfade here superimposes skeleton
                      // ghosts on the live controls for its duration.
                      child: bottomDock,
                    ),
                  ),
                );
              }
              return Scaffold(
                backgroundColor: Colors.transparent,
                extendBody: bottomNav != null,
                body: SafeArea(
                  bottom: false,
                  child: Padding(
                    key: const ValueKey<String>('root-shell-content'),
                    padding: EdgeInsets.only(bottom: bottomClearance),
                    child: widget.child,
                  ),
                ),
                bottomNavigationBar: bottomNav == null
                    ? null
                    : Material(
                        type: MaterialType.transparency,
                        child: bottomNav,
                      ),
              );
            }

            final shell = useSidebar
                ? RootShellBottomInset(
                    bottomClearance: noticeBottomClearance,
                    child: ColoredBox(
                      color: tokens.canvas,
                      child: Scaffold(
                        backgroundColor: Colors.transparent,
                        body: SafeArea(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Semantics(
                                container: true,
                                label: l10n.navMainLabel,
                                child: AppSidebar(
                                  collapsed: ref.watch(
                                    sidebarCollapsedProvider,
                                  ),
                                  onToggleCollapse: () =>
                                      ref
                                          .read(
                                            sidebarCollapsedProvider.notifier,
                                          )
                                          .state = !ref.watch(
                                        sidebarCollapsedProvider,
                                      ),
                                ),
                              ),
                              Expanded(child: widget.child),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : RootShellBottomInset(
                    // mobileShellScaffold provides its own player-route
                    // clearance; non-player routes use the nav clearance.
                    bottomClearance: playerWithTransport
                        ? 0.0
                        : noticeBottomClearance,
                    child: AppBackground(child: mobileShellScaffold()),
                  );

            final parkSurface =
                path.startsWith('/youtube/login') ||
                (onPlayer &&
                    GoRouterState.of(context).uri.pathSegments.length > 2);
            final fullscreen =
                playerWithTransport && ref.watch(windowFullscreenProvider);
            return Stack(
              fit: StackFit.expand,
              children: [
                shell,
                // Engine video surface paints above the shell — any
                // fullscreen chrome must stack ABOVE it to be visible.
                PlayerSurfaceHost(forcePark: parkSurface),
                // Floating captions mini-window covers everything while on.
                if (ref.watch(floatCaptionsModeProvider))
                  const Positioned.fill(child: FloatCaptionsHost()),
                // Fullscreen reveal layer: pointer move / press over the
                // video wakes the dock. translucent + non-opaque so video
                // gestures and hotkeys keep working.
                if (fullscreen)
                  Positioned.fill(
                    child: MouseRegion(
                      opaque: false,
                      cursor: _dockVisible
                          ? MouseCursor.defer
                          : SystemMouseCursors.none,
                      onHover: (_) => _pokeDock(),
                      child: Listener(
                        behavior: HitTestBehavior.translucent,
                        onPointerDown: (_) => _pokeDock(),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                // Floating fullscreen dock, above the video surface.
                if (fullscreen && sessionActive)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AnimatedSlide(
                      offset: _dockVisible ? Offset.zero : const Offset(0, 1),
                      duration: tokens.motionMedium,
                      curve: Curves.easeOutCubic,
                      child: MouseRegion(
                        onEnter: (_) {
                          _pointerOverDock = true;
                          _dockHideTimer?.cancel();
                        },
                        onExit: (_) {
                          _pointerOverDock = false;
                          _pokeDock();
                        },
                        child: FullscreenTransportBar(chrome: chrome),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
