/// Leave-player policy: stop live playback off `/player/` (spec 044).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart'
    show ProviderListenable;

import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session.dart';

/// Whether a live [PlayerController] session should be cleared for [path].
bool shouldClearLiveSessionOnRouteChange({
  required bool onPlayerRoute,
  required bool hasLiveSession,
  required bool practiceOwnsVideoStage,
}) {
  return hasLiveSession && !onPlayerRoute && !practiceOwnsVideoStage;
}

/// Flushes and [PlayerController.clear]s when the learner left the player.
///
/// Widget-tree entry point (`collapseExpandedPlayer`). Router-side callers —
/// the route observer and the mid-launch safety net in `app_router.dart` —
/// have a provider [Ref] and use [clearLivePlaybackSession].
Future<void> clearLivePlaybackSessionIfNeeded(
  WidgetRef ref, {
  required bool onPlayerRoute,
}) {
  return _clearLiveSession(
    onPlayerRoute: onPlayerRoute,
    hasLiveSession: ref.read(playerControllerProvider) != null,
    practiceOwnsVideoStage: ref
        .read(vocabularyReviewSessionProvider)
        .practiceOwnsVideoStage,
    clear: () => ref.read(playerControllerProvider.notifier).clear(),
  );
}

/// [Ref] variant of [clearLivePlaybackSessionIfNeeded] for teardowns that run
/// outside the widget tree (never on a player route when it is called).
Future<void> clearLivePlaybackSession(Ref ref) {
  return _clearLiveSession(
    onPlayerRoute: false,
    hasLiveSession: ref.read(playerControllerProvider) != null,
    practiceOwnsVideoStage: ref
        .read(vocabularyReviewSessionProvider)
        .practiceOwnsVideoStage,
    clear: () => ref.read(playerControllerProvider.notifier).clear(),
  );
}

/// Reader variant of [clearLivePlaybackSession] for callers that hold neither
/// a [WidgetRef] nor a [Ref] — e.g. the hotkey command interface, which reads
/// through a plain `read` function. Never called on a player route.
Future<void> clearLivePlaybackSessionWith(
  T Function<T>(ProviderListenable<T> provider) read,
) {
  return _clearLiveSession(
    onPlayerRoute: false,
    hasLiveSession: read(playerControllerProvider) != null,
    practiceOwnsVideoStage: read(
      vocabularyReviewSessionProvider,
    ).practiceOwnsVideoStage,
    clear: () => read(playerControllerProvider.notifier).clear(),
  );
}

Future<void> _clearLiveSession({
  required bool onPlayerRoute,
  required bool hasLiveSession,
  required bool practiceOwnsVideoStage,
  required Future<void> Function() clear,
}) async {
  if (!shouldClearLiveSessionOnRouteChange(
    onPlayerRoute: onPlayerRoute,
    hasLiveSession: hasLiveSession,
    practiceOwnsVideoStage: practiceOwnsVideoStage,
  )) {
    return;
  }
  await clear();
}

/// Deferred leave-player teardown: pauses immediately (audio stops while the
/// last video frame stays on screen), then clears after the player route's
/// exit transition finishes.
///
/// Clearing synchronously at pop time tears the video texture down mid-fade,
/// so the outgoing player page fades out as a full-black stage before the
/// shell appears. Waiting out the ~180 ms reverse transition keeps the fade
/// showing the frozen frame instead.
Future<void> clearLivePlaybackSessionDeferred(
  Ref ref, {
  Duration delay = const Duration(milliseconds: 240),
}) {
  return _clearLiveSessionDeferred(ref.read, delay: delay);
}

/// [T Function<T>]-based variant of [clearLivePlaybackSessionDeferred] for
/// callers outside the widget tree (router observers, hotkey interface).
Future<void> clearLivePlaybackSessionDeferredWith(
  T Function<T>(ProviderListenable<T> provider) read, {
  Duration delay = const Duration(milliseconds: 240),
}) {
  return _clearLiveSessionDeferred(read, delay: delay);
}

Future<void> _clearLiveSessionDeferred(
  T Function<T>(ProviderListenable<T> provider) read, {
  required Duration delay,
}) async {
  final session = read(playerControllerProvider);
  if (session == null) return;
  final leavingMediaId = session.mediaId;

  // Stop audio right away; the video stage keeps showing its last frame
  // until the deferred teardown below.
  try {
    await read(playerControllerProvider.notifier).activeEngine.pause();
  } catch (_) {}

  await Future<void>.delayed(delay);

  // Guard: if something else opened a different media during the delay
  // (rapid navigation), do not tear down the new session.
  final current = read(playerControllerProvider);
  if (current == null || current.mediaId != leavingMediaId) return;

  await _clearLiveSession(
    onPlayerRoute: false,
    hasLiveSession: true,
    practiceOwnsVideoStage: read(
      vocabularyReviewSessionProvider,
    ).practiceOwnsVideoStage,
    clear: () => read(playerControllerProvider.notifier).clear(),
  );
}
