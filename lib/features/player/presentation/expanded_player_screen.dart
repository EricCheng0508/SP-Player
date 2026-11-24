/// Full-screen player: Duet top bar + video/audio chrome.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/player/application/open_media_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/domain/media_relocate_exception.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/domain/player_launch_request.dart';
import 'package:enjoy_player/features/player/domain/youtube_playback_unavailable_exception.dart';

import 'expanded_player_widgets.dart';
import 'locate_media_screen.dart';

class ExpandedPlayerScreen extends ConsumerStatefulWidget {
  const ExpandedPlayerScreen({required this.launch, super.key});

  final PlayerLaunchRequest launch;

  String get mediaId => launch.mediaId;

  @override
  ConsumerState<ExpandedPlayerScreen> createState() =>
      _ExpandedPlayerScreenState();
}

class _ExpandedPlayerScreenState extends ConsumerState<ExpandedPlayerScreen> {
  @override
  Widget build(BuildContext context) {
    final open = ref.watch(openMediaLaunchProvider(widget.launch));
    final chrome = ref.watch(playerControllerProvider.select(playbackChromeOf));
    final cs = Theme.of(context).colorScheme;
    final mediaId = widget.mediaId;

    Widget body;
    var isChrome = false;
    if (chrome != null && chrome.mediaId == mediaId) {
      isChrome = true;
      body = ExpandedPlayerChromeBody(mediaId: mediaId, chrome: chrome);
    } else if (open.hasError) {
      final err = open.error;
      if (err is MediaNeedsRelocateException) {
        return LocateMediaScreen(info: err);
      }
      if (err is YouTubePlaybackUnavailableException) {
        return ExpandedPlayerYoutubeUnavailableBody(
          colorScheme: cs,
          youtubeUrl: err.youtubeUrl,
          reason: err.reason,
        );
      }
      return ExpandedPlayerGenericErrorBody(colorScheme: cs);
    } else {
      body = ExpandedPlayerLoadingBody(colorScheme: cs, mediaId: mediaId);
    }

    // Crossfade loading ↔ chrome instead of a hard swap. Both bodies share
    // the same geometry (the loading split mirrors the chrome split and the
    // dock slot is always reserved), so the dissolve reads as the skeleton
    // and poster morphing into the live content — the hard swap was the
    // "flash this frame on open" report.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: KeyedSubtree(
        key: ValueKey('player-body-$isChrome'),
        child: body,
      ),
    );
  }
}
