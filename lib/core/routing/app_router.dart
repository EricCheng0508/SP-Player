/// go_router configuration with persistent shell (mini player).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/analytics/analytics.dart';
import 'package:enjoy_player/core/analytics/analytics_provider.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/player/player_surface_overlay_coordinator.dart';
import 'package:enjoy_player/core/player/player_surface_overlay_navigator_observer.dart';
import 'package:enjoy_player/core/routing/auth_redirect.dart';
import 'package:enjoy_player/core/routing/auth_router_tick.dart';
import 'package:enjoy_player/core/routing/not_found_screen.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/features/ai/presentation/ai_playground_screen.dart';
import 'package:enjoy_player/features/ai/presentation/settings/ai_providers_screen.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/craft/presentation/craft_history_screen.dart';
import 'package:enjoy_player/features/craft/presentation/craft_screen.dart';
import 'package:enjoy_player/core/routing/library_source.dart';
import 'package:enjoy_player/features/discover/presentation/channel_feed_screen.dart';
import 'package:enjoy_player/features/discover/presentation/discover_screen.dart';
import 'package:enjoy_player/features/library/presentation/home_screen.dart';
import 'package:enjoy_player/features/library/presentation/library_screen.dart';
import 'package:enjoy_player/features/live_captions/presentation/live_captions_screen.dart';
import 'package:enjoy_player/features/player/application/leave_player_route_observer.dart';
import 'package:enjoy_player/features/player/application/leave_player_session.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/domain/player_launch_request.dart';
import 'package:enjoy_player/features/player/presentation/expanded_player_screen.dart';
import 'package:enjoy_player/features/player/presentation/root_shell.dart';
import 'package:enjoy_player/features/player/presentation/youtube_login_screen.dart';
import 'package:enjoy_player/features/settings/domain/settings_search_entry.dart';
import 'package:enjoy_player/features/settings/presentation/hotkeys_settings_screen.dart';
import 'package:enjoy_player/features/settings/presentation/settings_screen.dart';
import 'package:enjoy_player/features/settings/presentation/settings_section_page.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_editor_screen.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_review_session_screen.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_screen.dart';

part 'app_router.g.dart';

/// Nested navigator owned by the app [ShellRoute] (profile pushes, sheets).
final GlobalKey<NavigatorState> enjoyShellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

CustomTransitionPage<void> _shellPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Staggered fade-through (mirrors Material's FadeThroughTransition):
      // the covered route fades OUT during the FIRST half, the incoming one
      // fades IN during the SECOND half — never simultaneously. A
      // simultaneous crossfade superimposes both pages mid-transition and
      // reads as ghosting (user report). The opaque fill behind the child
      // also guarantees the outgoing content can never bleed through.
      final inCurve = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      );
      final outCurve = CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      );
      return ColoredBox(
        color: EnjoyThemeTokens.of(context).canvas,
        child: FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.0).animate(outCurve),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(inCurve),
            child: child,
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 140),
  );
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final authTick = ref.watch(authRouterTickProvider);
  PlayerSurfaceOverlayCoordinator coordinator() =>
      ref.read(playerSurfaceOverlayCoordinatorProvider.notifier);
  final rootOverlayObserver = PlayerSurfaceOverlayNavigatorObserver(
    coordinator: coordinator,
  );
  final shellOverlayObserver = PlayerSurfaceOverlayNavigatorObserver(
    coordinator: coordinator,
  );
  final leavePlayerObserver = LeavePlayerRouteObserver(
    onLeftPlayerRoute: () => scheduleMicrotask(
      // Deferred: pause now, teardown after the exit fade — an immediate
      // clear blanks the video stage mid-transition.
      () => unawaited(clearLivePlaybackSessionDeferredWith(ref.read)),
    ),
  );
  final rootScreenObserver = AnalyticsScreenObserver(
    ref.read(analyticsProvider),
  );
  final shellScreenObserver = AnalyticsScreenObserver(
    ref.read(analyticsProvider),
  );
  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: authTick,
    observers: [rootOverlayObserver, rootScreenObserver],
    errorBuilder: (context, state) => NotFoundScreen(uri: state.uri),
    redirect: (context, state) {
      final checkoutRedirect = resolveCheckoutReturnRedirect(
        matchedLocation: state.matchedLocation,
        uri: state.uri,
        auth: ref.read(authCtrlProvider),
      );
      if (checkoutRedirect != null) return checkoutRedirect;

      final loc = isNativeAuthCallbackArtifact(state.matchedLocation)
          ? '/'
          : state.matchedLocation;

      if (kReleaseMode && loc.startsWith('/settings/ai-playground')) {
        return '/settings';
      }
      if (kReleaseMode && loc.startsWith('/settings/developer')) {
        return '/settings';
      }
      if (loc.startsWith('/settings/keyboard') && !isDesktop) {
        return '/settings';
      }
      if (loc == '/cloud' || loc.startsWith('/cloud/')) {
        return libraryRouteForSource(LibrarySource.cloud);
      }
      if (loc == '/settings' &&
          state.uri.queryParameters['section'] == 'keyboard') {
        return isDesktop ? '/settings/keyboard' : null;
      }

      final auth = ref.read(authCtrlProvider);
      return resolveAuthRedirect(matchedLocation: loc, auth: auth);
    },
    routes: [
      ShellRoute(
        navigatorKey: enjoyShellNavigatorKey,
        observers: [
          shellOverlayObserver,
          leavePlayerObserver,
          shellScreenObserver,
        ],
        builder: (context, state, child) => RootShell(child: child),
        routes: [
          GoRoute(
            name: 'home',
            path: '/',
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey<String>('shell-home'),
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            name: 'discover',
            path: '/discover',
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey<String>('shell-discover'),
              child: const DiscoverScreen(),
            ),
            routes: [
              GoRoute(
                name: 'discover-channel',
                path: 'channel/:channelId',
                builder: (context, state) {
                  final channelId = state.pathParameters['channelId']!;
                  return ChannelFeedScreen(channelId: channelId);
                },
              ),
            ],
          ),
          GoRoute(
            name: 'library',
            path: '/library',
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey<String>('shell-library'),
              child: const LibraryScreen(),
            ),
          ),
          GoRoute(
            path: '/player/:mediaId',
            pageBuilder: (context, state) {
              final id = state.pathParameters['mediaId']!;
              final launch = PlayerLaunchRequest.fromUri(
                state.uri,
                mediaId: id,
              );
              return CustomTransitionPage<void>(
                key: const ValueKey('player-page'),
                name: state.matchedLocation,
                child: ExpandedPlayerScreen(launch: launch),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                        child: child,
                      );
                    },
                // Zero-duration in both directions: the split video+transcript
                // stage must appear in a single frame. A 220 ms fade-in over
                // the page's dark backdrop reads as a full-black flash before
                // the layout settles; on pop the fade blanks the stage too.
                // Audio keeps playing through the instant swap either way.
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              );
            },
            routes: [
              GoRoute(
                name: 'player-edit-transcript',
                path: 'edit-transcript',
                builder: (context, state) => TranscriptEditorScreen(
                  mediaId: state.pathParameters['mediaId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            name: 'youtube-login',
            path: '/youtube/login',
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey<String>('shell-youtube-login'),
              child: const YoutubeLoginScreen(),
            ),
          ),
          GoRoute(
            name: 'craft',
            path: '/craft',
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey<String>('shell-craft'),
              child: const CraftScreen(),
            ),
          ),
          GoRoute(
            name: 'craft-history',
            path: '/craft/history',
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey<String>('shell-craft-history'),
              child: const CraftHistoryScreen(),
            ),
          ),
          GoRoute(
            name: 'live-captions',
            path: '/live-captions',
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey<String>('shell-live-captions'),
              child: const LiveCaptionsScreen(),
            ),
          ),
          GoRoute(
            name: 'settings',
            path: '/settings',
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey<String>('shell-settings'),
              child: const SettingsScreen(),
            ),
          ),
          GoRoute(
            name: 'settings-keyboard',
            path: '/settings/keyboard',
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey<String>('shell-settings-keyboard'),
              child: const HotkeysSettingsScreen(),
            ),
          ),
          GoRoute(
            name: 'settings-ai-providers',
            path: '/settings/ai-providers',
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey<String>('shell-settings-ai-providers'),
              child: const AiProvidersScreen(),
            ),
          ),
          GoRoute(
            name: 'settings-appearance-language',
            path: '/settings/appearance-language',
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey<String>('shell-settings-appearance-language'),
              child: const SettingsSectionPageScreen(
                sectionId: SettingsSectionIds.appearanceLanguage,
              ),
            ),
          ),
          GoRoute(
            name: 'settings-recording',
            path: '/settings/recording',
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey<String>('shell-settings-recording'),
              child: const SettingsSectionPageScreen(
                sectionId: SettingsSectionIds.recording,
              ),
            ),
          ),
          GoRoute(
            name: 'settings-developer',
            path: '/settings/developer',
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey<String>('shell-settings-developer'),
              child: const SettingsSectionPageScreen(
                sectionId: SettingsSectionIds.developer,
              ),
            ),
          ),
          GoRoute(
            name: 'settings-about',
            path: '/settings/about',
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey<String>('shell-settings-about'),
              child: const SettingsSectionPageScreen(
                sectionId: SettingsSectionIds.about,
              ),
            ),
          ),
          GoRoute(
            name: 'settings-ai-playground',
            path: '/settings/ai-playground',
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey<String>('shell-settings-ai-playground'),
              child: const AiPlaygroundScreen(),
            ),
          ),
          GoRoute(
            name: 'vocabulary',
            path: '/vocabulary',
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey<String>('shell-vocabulary'),
              child: const VocabularyScreen(),
            ),
          ),
          GoRoute(
            name: 'vocabulary-review',
            path: '/vocabulary/review',
            onExit: (context, state) {
              final session = ProviderScope.containerOf(
                context,
              ).read(vocabularyReviewSessionProvider.notifier);
              if (session.hasActiveSession) {
                session.clear();
              }
              return true;
            },
            pageBuilder: (context, state) => _shellPage(
              key: const ValueKey<String>('shell-vocabulary-review'),
              child: const VocabularyReviewSessionScreen(),
            ),
          ),
        ],
      ),
    ],
  );

  ref.listen<bool>(
    playerControllerProvider.select((session) => session != null),
    (previous, sessionActive) {
      if (!sessionActive) return;
      if (router.state.uri.path.startsWith('/player/')) return;
      scheduleMicrotask(() => unawaited(clearLivePlaybackSession(ref)));
    },
  );
  return router;
}
