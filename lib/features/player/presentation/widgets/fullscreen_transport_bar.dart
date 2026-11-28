/// Compact single-row transport bar for OS fullscreen — the standard
/// "controls pinned to the bottom edge" every desktop player ships.
///
/// Deliberately minimal (play, progress ruler, rate, volume, fullscreen
/// exit): the learning-focused rows live in the windowed [PlayerDock].
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/features/player/application/player_state_providers.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/sentence_ruler.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/transport_play_ring_button.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/transport_playback_rate_sheet.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/transport_volume_button.dart';
import 'package:enjoy_player/core/window/window_fullscreen_provider.dart';

class FullscreenTransportBar extends ConsumerWidget {
  const FullscreenTransportBar({required this.chrome, super.key});

  final PlaybackChrome chrome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(playerIsPlayingProvider).value ?? false;
    final buffering = ref.watch(playerIsBufferingProvider).value ?? false;
    final playbackRate = ref.watch(
      playerPreferencesCtrlProvider.select((p) => p.playbackRate),
    );

    final rateLabel =
        '${playbackRate == playbackRate.roundToDouble() ? playbackRate.toStringAsFixed(1) : playbackRate.toString()}倍';

    // Material ancestor: this bar mounts directly in the shell Stack with no
    // Scaffold above it — without a Material (which provides the ambient
    // DefaultTextStyle) every Text here renders Flutter's yellow
    // double-underline "missing default style" debug decoration.
    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: 52,
        color: Colors.black.withValues(alpha: 0.55),
        padding: const EdgeInsets.fromLTRB(14, 4, 10, 6),
        child: Row(
          children: [
            TransportPlayRingButton(
              playing: playing,
              buffering: buffering,
              tooltip: playing ? '暂停' : '播放',
              onPressed: () => ref
                  .read(playerControllerProvider.notifier)
                  .togglePlay(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: SentenceRuler(chrome: chrome, bright: true),
              ),
            ),
            _RateChip(label: rateLabel, rate: playbackRate),
            const TransportVolumeButton(),
            IconButton(
              tooltip: '退出全屏',
              icon: const Icon(EnjoyIcons.fullscreenExit, size: 20),
              color: Colors.white,
              onPressed: () =>
                  ref.read(windowFullscreenProvider.notifier).toggle(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text chip opening the playback-rate sheet, mirroring the dock's speed
/// control in a fullscreen-friendly size.
class _RateChip extends ConsumerWidget {
  const _RateChip({required this.label, required this.rate});

  final String label;
  final double rate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool rateEquals(double a, double b) => (a - b).abs() < 0.01;
    return Tooltip(
      message: '倍速',
      child: RateMenuHoverRegion(
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => showPlaybackRatePicker(
            context: context,
            ref: ref,
            anchor: context,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: rateEquals(rate, 1.0) ? Colors.white70 : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
