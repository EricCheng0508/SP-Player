/// Duet player dock (ADR-0093) — a solid paper bar under the player: the
/// sentence ruler row over a controls row, in Listen / Echo / Recording
/// variants.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/features/onboarding/application/practice_tip_trigger.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/features/player/application/player_state_providers.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_dock_echo_controls.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_dock_listen_controls.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_dock_recording_controls.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/sentence_ruler.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/transport_playback_rate_sheet.dart';

/// Height reserved for the dock's control row on wide layouts.
///
/// The listen row is 60 px and the echo / recording rows are 76 px. The video
/// stage absorbs whatever height is left, so a dock that grows by 16 px under
/// the picture shrinks it by ~28 px once `BoxFit.contain` letterboxes. Holding
/// the slot at the tallest row keeps the picture size stable across modes.
const double kDockControlsHeight = 64;

/// Total desktop dock height, derived from the dock's own structure: top
/// border 1 + ruler row (8 padding + 34 `rulerHitHeight`) + controls row
/// (4 + `kDockControlsHeight` + 12). The root shell holds a placeholder of
/// exactly this height while the session is still opening, so the video stage
/// keeps one geometry from the first frame — a dock that appears late resizes
/// a *playing* video (the "flash on open" report). Keep in sync with the
/// paddings in [PlayerDock.build].
const double kDockPlaceholderHeight =
    1 + 8 + 34 + 4 + kDockControlsHeight + 12;

/// The Duet dock. Mounted by [RootShell] on `/player/:id` while a session is
/// active.
class PlayerDock extends ConsumerStatefulWidget {
  const PlayerDock({required this.chrome, super.key});

  final PlaybackChrome chrome;

  @override
  ConsumerState<PlayerDock> createState() => _PlayerDockState();
}

class _PlayerDockState extends ConsumerState<PlayerDock> {
  late final TransportPracticeTips _practiceTips;

  @override
  void initState() {
    super.initState();
    _practiceTips = ref.read(practiceTipTriggerProvider).transportBar();
  }

  void _openPlaybackRatePicker(BuildContext anchor) {
    unawaited(
      showPlaybackRatePicker(context: context, ref: ref, anchor: anchor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final chrome = widget.chrome;
    final echoActive = ref.watch(echoModeProvider.select((e) => e.active));
    final recording = ref.watch(
      shadowReadingHotkeyBusProvider.select((b) => b.isRecordingActive),
    );
    final playing = ref.watch(playerIsPlayingProvider).value ?? false;
    final buffering = ref.watch(playerIsBufferingProvider).value ?? false;
    final hasLines =
        ref.watch(transcriptHasLinesForMediaProvider(chrome.mediaId)).value ??
        false;
    final playbackRate = ref.watch(
      playerPreferencesCtrlProvider.select((p) => p.playbackRate),
    );

    final routePath = GoRouterState.of(context).uri.path;
    if (hasLines && chrome.mediaId.isNotEmpty) {
      _practiceTips.schedule(
        routePath: routePath,
        mediaId: chrome.mediaId,
        echoActive: echoActive,
      );
    }

    final interactions = ref.read(playerInteractionsProvider);
    final showFullscreen = isDesktop && chrome.mediaType == 'video';

    return Container(
      decoration: BoxDecoration(
        color: t.paper,
        border: Border(top: BorderSide(color: t.line)),
      ),
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final phone = constraints.maxWidth < t.breakpointCompact;
            final showLineMeta = constraints.maxWidth >= 980;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 3, 20, 0),
                  child: RepaintBoundary(child: SentenceRuler(chrome: chrome)),
                ),
                Padding(
                  padding: phone
                      ? const EdgeInsets.fromLTRB(12, 4, 12, 8)
                      : const EdgeInsets.fromLTRB(20, 2, 20, 8),
                  // The three control rows are 60 px (listen) and 76 px
                  // (echo, recording). The video stage takes whatever height
                  // the dock leaves, and `BoxFit.contain` turns a 16 px taller
                  // dock into a ~28 px narrower picture — that resize is the
                  // "video width jumps when I switch modes" report. Hold the
                  // slot at the tallest row so the picture keeps its size; the
                  // shorter row simply centres inside it.
                  child: SizedBox(
                    height: phone ? null : kDockControlsHeight,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : t.motionMedium,
                        child: recording
                            ? DockRecordingControls(
                                key: ValueKey<bool>(recording),
                                mediaId: chrome.mediaId,
                                phone: phone,
                                showLineMeta: showLineMeta,
                                playbackRate: playbackRate,
                                onSpeed: _openPlaybackRatePicker,
                                onCancel: () => ref
                                    .read(
                                      shadowReadingHotkeyBusProvider.notifier,
                                    )
                                    .pulseRecordingCancel(),
                                onStop: () => ref
                                    .read(
                                      shadowReadingHotkeyBusProvider.notifier,
                                    )
                                    .pulseRecording(),
                              )
                            : echoActive
                            ? DockEchoControls(
                                key: ValueKey<bool>(echoActive),
                                mediaId: chrome.mediaId,
                                phone: phone,
                                recording: recording,
                                showLineMeta: showLineMeta,
                                playbackRate: playbackRate,
                                playing: playing,
                                onPrev: interactions.prevLine,
                                onNext: interactions.nextLine,
                                onReplay: interactions.replayLine,
                                onTogglePlay: () => ref
                                    .read(playerControllerProvider.notifier)
                                    .togglePlay(),
                                onRecord: () => ref
                                    .read(
                                      shadowReadingHotkeyBusProvider.notifier,
                                    )
                                    .pulseRecording(),
                                onSpeed: _openPlaybackRatePicker,
                              )
                            : DockListenControls(
                                key: ValueKey<bool>(echoActive),
                                mediaId: chrome.mediaId,
                                phone: phone,
                                recording: recording,
                                showLineMeta: showLineMeta,
                                echoAvailable: hasLines || echoActive,
                                playing: playing,
                                buffering: buffering,
                                playbackRate: playbackRate,
                                showFullscreen: showFullscreen,
                                onPrev: interactions.prevLine,
                                onNext: interactions.nextLine,
                                onReplay: interactions.replayLine,
                                onTogglePlay: () => ref
                                    .read(playerControllerProvider.notifier)
                                    .togglePlay(),
                                onSpeed: _openPlaybackRatePicker,
                              ),
                      ),
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

/// Visual-only dock shown while the open is still in flight: identical
/// structure and height to [PlayerDock] (135 logical px on desktop — top
/// border 1 + ruler row 8+34 + controls row 4+76+12) with shimmer
/// placeholders instead of live controls.
///
/// Deliberately has **zero provider reads**: a mount-time visual must never
/// touch the engine graph (reading `activeEngine` from a dock that mounts
/// before the swap allocates an un-armed engine into the identity slot — the
/// historical black-open race). The real dock replaces this the moment the
/// session lands, so the bottom of the player page is occupied — and visually
/// a dock — from the very first frame.
class PlayerDockSkeleton extends StatelessWidget {
  const PlayerDockSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final timeStyle = enjoyMonoStyle(context, size: 12.5, color: t.ink3);
    return Container(
      decoration: BoxDecoration(
        color: t.paper,
        border: Border(top: BorderSide(color: t.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: SizedBox(
              height: t.rulerHitHeight,
              child: Row(
                children: [
                  Text('0:00', style: timeStyle),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Skeleton.line(width: 200, height: 6),
                  ),
                  const SizedBox(width: 10),
                  Text('0:00', style: timeStyle),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: SizedBox(
              height: kDockControlsHeight,
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Skeleton.line(width: 110, height: 12),
                    ),
                  ),
                  Skeleton.circle(diameter: 52),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 12,
                        children: [
                          Skeleton.circle(diameter: 28),
                          Skeleton.circle(diameter: 28),
                          Skeleton.circle(diameter: 28),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
