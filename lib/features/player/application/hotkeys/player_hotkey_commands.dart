/// Session-gated player hotkey commands (issue #719).
///
/// One command per `player.*` action the old listener if-chain gated behind
/// `session != null`; each command's `canExecute` absorbs that gate (plus the
/// platform / media-type checks fullscreen used to inline). The commands live
/// here, next to the player logic they call.
library;

import 'dart:async';

import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/core/window/window_fullscreen_provider.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkey_command.dart';
import 'package:enjoy_player/features/player/application/hotkeys/playback_rate_commands.dart';
import 'package:enjoy_player/features/player/application/player_collapse.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_search_controller.dart';

/// `player.togglePlay` — play / pause the live session.
class TogglePlayHotkeyCommand extends HotkeyCommand {
  const TogglePlayHotkeyCommand();

  @override
  String get actionId => 'player.togglePlay';

  @override
  bool canExecute(HotkeyCtx ctx) => ctx.read(playerControllerProvider) != null;

  @override
  void execute(HotkeyCtx ctx) {
    unawaited(ctx.read(playerControllerProvider.notifier).togglePlay());
  }
}

/// `player.toggleExpand` — collapse the expanded player when on a player
/// route, open it otherwise.
class ToggleExpandHotkeyCommand extends HotkeyCommand {
  const ToggleExpandHotkeyCommand();

  @override
  String get actionId => 'player.toggleExpand';

  @override
  bool canExecute(HotkeyCtx ctx) => ctx.read(playerControllerProvider) != null;

  @override
  void execute(HotkeyCtx ctx) {
    final session = ctx.read(playerControllerProvider);
    if (session == null) return;
    if (ctx.path.startsWith('/player/')) {
      final navCtx = ctx.routerNavigatorContext ?? ctx.listenerContext;
      if (navCtx == null) return;
      unawaited(collapseExpandedPlayerWith(ctx.read, navCtx));
    } else {
      openPlayerRoute(ctx.listenerContext!, session.mediaId);
    }
  }
}

/// `player.toggleFullscreen` — desktop video only (the old chain's
/// `isDesktop && mediaType == 'video'` gate).
class ToggleFullscreenHotkeyCommand extends HotkeyCommand {
  const ToggleFullscreenHotkeyCommand();

  @override
  String get actionId => 'player.toggleFullscreen';

  @override
  bool canExecute(HotkeyCtx ctx) {
    if (!isDesktop) return false;
    final session = ctx.read(playerControllerProvider);
    return session != null && session.mediaType == 'video';
  }

  @override
  void execute(HotkeyCtx ctx) {
    unawaited(ctx.read(windowFullscreenProvider.notifier).toggle());
  }
}

/// `player.searchTranscript` — opens the transcript-panel search bar
/// (Ctrl+F). Pure UI toggle; no-op without a live session.
class SearchTranscriptHotkeyCommand extends HotkeyCommand {
  const SearchTranscriptHotkeyCommand();

  @override
  String get actionId => 'player.searchTranscript';

  @override
  bool canExecute(HotkeyCtx ctx) => ctx.read(playerControllerProvider) != null;

  @override
  void execute(HotkeyCtx ctx) {
    ctx.read(transcriptSearchOpenProvider.notifier).open();
  }
}

/// Line / echo commands delegated to [PlayerInteractions]. Gated on a live
/// session; echo-window gating itself lives inside the service (unchanged).
class PlayerInteractionsHotkeyCommand extends HotkeyCommand {
  const PlayerInteractionsHotkeyCommand(this.actionId, this.invoke);

  @override
  final String actionId;

  final Future<void> Function(PlayerInteractions interactions) invoke;

  @override
  bool canExecute(HotkeyCtx ctx) => ctx.read(playerControllerProvider) != null;

  @override
  void execute(HotkeyCtx ctx) {
    unawaited(invoke(ctx.read(playerInteractionsProvider)));
  }
}

/// Relative seek (`player.seekBack` / `player.seekForward`) — nudges the
/// playhead by [delta] seconds, clamped to the media duration. Playback
/// state (playing/paused) is preserved.
class SeekRelativeHotkeyCommand extends HotkeyCommand {
  const SeekRelativeHotkeyCommand(this.actionId, this.delta);

  @override
  final String actionId;

  final double delta;

  @override
  bool canExecute(HotkeyCtx ctx) => ctx.read(playerControllerProvider) != null;

  @override
  void execute(HotkeyCtx ctx) {
    final session = ctx.read(playerControllerProvider);
    if (session == null) return;
    final duration = session.durationSeconds > 0
        ? session.durationSeconds
        : double.infinity;
    final target = (session.currentTimeSeconds + delta).clamp(0.0, duration);
    unawaited(ctx.read(playerControllerProvider.notifier).seekToSeconds(target));
  }
}

/// Volume step (`player.volumeUp` / `player.volumeDown`) — ±5% persisted
/// volume, clamped to `[0, 1]`. Uses [PlayerPreferences.setVolume] (not the
/// transient variant) so the level survives restarts like slider changes do.
class VolumeStepHotkeyCommand extends HotkeyCommand {
  const VolumeStepHotkeyCommand(this.actionId, this.delta);

  @override
  final String actionId;

  final double delta;

  @override
  bool canExecute(HotkeyCtx ctx) => ctx.read(playerControllerProvider) != null;

  @override
  void execute(HotkeyCtx ctx) {
    final prefs = ctx.read(playerPreferencesCtrlProvider);
    final target = (prefs.volume + delta).clamp(0.0, 1.0);
    unawaited(ctx.read(playerPreferencesCtrlProvider.notifier).setVolume(target));
  }
}

/// `player.toggleMute` — remembers the pre-mute level for restore.
class ToggleMuteHotkeyCommand extends HotkeyCommand {
  const ToggleMuteHotkeyCommand();

  static double _lastNonZeroVolume = 1.0;

  @override
  String get actionId => 'player.toggleMute';

  @override
  bool canExecute(HotkeyCtx ctx) => ctx.read(playerControllerProvider) != null;

  @override
  void execute(HotkeyCtx ctx) {
    final prefs = ctx.read(playerPreferencesCtrlProvider);
    if (prefs.volume > 0.01) {
      _lastNonZeroVolume = prefs.volume;
      unawaited(ctx.read(playerPreferencesCtrlProvider.notifier).setVolume(0));
    } else {
      unawaited(
        ctx.read(
          playerPreferencesCtrlProvider.notifier,
        ).setVolume(_lastNonZeroVolume),
      );
    }
  }
}

/// Session-gated player commands in dispatch order — the exact order of the
/// old listener chain's `session != null` block (rate commands included at
/// their original position between the line hotkeys and the echo brackets).
final List<HotkeyCommand> playerHotkeyCommands = [
  const TogglePlayHotkeyCommand(),
  const ToggleExpandHotkeyCommand(),
  const ToggleFullscreenHotkeyCommand(),
  const SearchTranscriptHotkeyCommand(),
  const SeekRelativeHotkeyCommand('player.seekBack', -3),
  const SeekRelativeHotkeyCommand('player.seekForward', 3),
  const VolumeStepHotkeyCommand('player.volumeDown', -0.05),
  const VolumeStepHotkeyCommand('player.volumeUp', 0.05),
  const ToggleMuteHotkeyCommand(),
  PlayerInteractionsHotkeyCommand('player.prevLine', (i) => i.prevLine()),
  PlayerInteractionsHotkeyCommand('player.nextLine', (i) => i.nextLine()),
  PlayerInteractionsHotkeyCommand('player.replayLine', (i) => i.replayLine()),
  PlayerInteractionsHotkeyCommand(
    'player.toggleEchoMode',
    (i) => i.toggleEcho(),
  ),
  PlayerInteractionsHotkeyCommand(
    'player.toggleBlurPractice',
    (i) => i.toggleBlur(),
  ),
  ...playbackRateHotkeyCommands,
  PlayerInteractionsHotkeyCommand(
    'player.expandEchoBackward',
    (i) => i.expandEchoBackward(),
  ),
  PlayerInteractionsHotkeyCommand(
    'player.expandEchoForward',
    (i) => i.expandEchoForward(),
  ),
  PlayerInteractionsHotkeyCommand(
    'player.shrinkEchoBackward',
    (i) => i.shrinkEchoBackward(),
  ),
  PlayerInteractionsHotkeyCommand(
    'player.shrinkEchoForward',
    (i) => i.shrinkEchoForward(),
  ),
];
