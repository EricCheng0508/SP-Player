/// Collapse expanded player chrome and pop the player route.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart'
    show ProviderListenable;

import 'package:enjoy_player/core/window/window_fullscreen_provider.dart';
import 'package:enjoy_player/features/player/application/leave_player_session.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';

Future<void> collapseExpandedPlayer(WidgetRef ref, BuildContext context) =>
    collapseExpandedPlayerWith(
      // The deferred teardown keeps reading providers across the exit
      // transition (~240 ms), by which time the player widget that passed its
      // `ref.read` tear-off may already be unmounted — reading through a dead
      // WidgetRef throws and, uncaught in the release zone, kills the process
      // (the "app exits seconds after opening" report). A provider container
      // outlives the widget, so read through it instead.
      ProviderScope.containerOf(context, listen: false).read,
      context,
    );

/// Reader-based variant of [collapseExpandedPlayer] for callers outside the
/// widget tree (the hotkey command interface): [read] is a `ref.read` /
/// `ProviderContainer.read` tear-off.
Future<void> collapseExpandedPlayerWith(
  T Function<T>(ProviderListenable<T> provider) read,
  BuildContext context,
) async {
  final router = GoRouter.of(context);
  if (router.state.uri.path.startsWith('/player/')) {
    router.pop();
  }
  await read(windowFullscreenProvider.notifier).setFullscreen(false);
  if (read(playerControllerProvider) == null) {
    read(playerControllerProvider.notifier).abandonPendingOpen();
  } else {
    // Deferred clear: the pop above starts the exit fade; tearing the engine
    // down now would blank the stage mid-transition. Pause happens inside
    // immediately, so audio stops right away.
    await clearLivePlaybackSessionDeferredWith(read);
  }
}
