/// Scaffold bodies for [ExpandedPlayerScreen] (loading, error, main chrome).
library;

import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:enjoy_player/core/platform/linux_platform_availability.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/player/application/player_engine_provider.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/presentation/layouts/audio_player_layout.dart';
import 'package:enjoy_player/features/player/presentation/layouts/video_player_layout.dart';
import 'package:enjoy_player/features/player/presentation/widgets/youtube_unavailable_message.dart';
import 'package:enjoy_player/features/transcript/application/video_row_for_media_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import 'package:enjoy_player/features/player/application/player_collapse.dart';
import 'package:enjoy_player/features/player/application/player_surface_registry.dart';
import 'package:enjoy_player/features/player/application/youtube_open_preview_provider.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_margin.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_surface_target.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_top_bar.dart';
import 'package:enjoy_player/features/player/presentation/widgets/youtube_loading_video_stage.dart';

import 'package:enjoy_player/features/transcript/presentation/transcript_panel.dart';

/// Centered loading indicator while [openMediaActionProvider] resolves.
class ExpandedPlayerLoadingBody extends ConsumerWidget {
  const ExpandedPlayerLoadingBody({
    super.key,
    required this.colorScheme,
    required this.mediaId,
  });

  final ColorScheme colorScheme;
  final String mediaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(youtubeOpenPreviewProvider(mediaId));
    final isYoutube = preview.maybeWhen(
      data: (p) => p != null,
      orElse: () => false,
    );
    final videoRow = ref.watch(videoRowForMediaProvider(mediaId));
    final isLocalVideo = videoRow.maybeWhen(
      data: (row) => row != null,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _LoadingTopBar(),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (isYoutube)
                  Align(
                    alignment: Alignment.topCenter,
                    child: YoutubeLoadingVideoStage(
                      mediaId: mediaId,
                      overlayBuilder: (_) => const SizedBox.shrink(),
                    ),
                  )
                else if (isLocalVideo)
                  const _LocalLoadingSplitBody()
                else
                  const Center(child: SkeletonAppBootstrap()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The 60px top-bar slot with only the collapse chevron while the session
/// is still opening.
class _LoadingTopBar extends ConsumerWidget {
  const _LoadingTopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    return Container(
      height: t.playerTopBarHeight,
      decoration: BoxDecoration(
        color: t.paper,
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(EnjoyIcons.back, size: 20),
          color: t.ink2,
          onPressed: () => unawaited(collapseExpandedPlayer(ref, context)),
        ),
      ),
    );
  }
}

/// Local-video loading body that mirrors the chrome split geometry.
///
/// The surface target occupies the exact video-panel rect the chrome body will
/// claim, so the loading → chrome hand-off never reflows (no layout jump — the
/// historical "flash" on open). The media's thumbnail shows through until the
/// native surface paints its first frame, then the video fades in over it.
class _LocalLoadingSplitBody extends ConsumerWidget {
  const _LocalLoadingSplitBody();

  /// Width of the invisible splitter strip — must match
  /// `VideoPlayerLayout._kSplitterHitWidth`.
  static const double _splitterHitWidth = 12;

  /// No poster here on purpose: a video still that later dissolves into the
  /// live picture reads as a "fake frame flashing away" (user report). The
  /// loading stage is a plain black panel + skeleton; the video surface fades
  /// in over it when the first frame lands.
  Widget _stageChild() {
    return PlayerSurfaceTarget(
      id: PlayerSurfaceIds.expandedPlayer,
      overlayBuilder: (_) => const SizedBox.shrink(),
      child: const ColoredBox(
        color: Colors.black,
        child: Center(child: SkeletonAppBootstrap()),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitPx = ref.watch(
      playerPreferencesCtrlProvider.select(
        (p) => p.videoTranscriptSplitWidthPx,
      ),
    );
    final t = EnjoyThemeTokens.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useSideBySide = constraints.maxWidth > constraints.maxHeight;
        if (!useSideBySide) {
          // Narrow: keep the historical 16:9 portal.
          return Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              top: true,
              bottom: false,
              left: false,
              right: false,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _stageChild(),
              ),
            ),
          );
        }

        final total = constraints.maxWidth;
        final tw = transcriptColumnWidthFor(context, total, splitPx);
        final vw = math.max(0.0, total - tw - _splitterHitWidth);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: vw,
              child: SafeArea(
                top: true,
                bottom: false,
                left: false,
                right: false,
                child: ColoredBox(
                  color: t.video,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomInset),
                    child: _stageChild(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: _splitterHitWidth),
            SizedBox(
              width: tw,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.ground,
                  border: Border(
                    left: BorderSide(color: t.line, width: 1),
                  ),
                ),
                child: const Center(child: SkeletonAppBootstrap()),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Non-relocate open failure (generic message; no raw exception text).
class ExpandedPlayerGenericErrorBody extends StatelessWidget {
  const ExpandedPlayerGenericErrorBody({super.key, required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.playerOpenGenericError, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

/// YouTube open on a device without a usable playback runtime (specs/047):
/// localized notice + "open in browser" fallback when the video URL is known.
class ExpandedPlayerYoutubeUnavailableBody extends StatelessWidget {
  const ExpandedPlayerYoutubeUnavailableBody({
    super.key,
    required this.colorScheme,
    this.youtubeUrl,
    this.reason,
  });

  final ColorScheme colorScheme;

  final String? youtubeUrl;

  final YouTubeUnavailableReason? reason;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final youtubeUrl = this.youtubeUrl;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _LoadingTopBar(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      youtubeUnavailableMessage(l10n, reason),
                      textAlign: TextAlign.center,
                    ),
                    if (youtubeUrl != null) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => _openInBrowser(context, youtubeUrl),
                        icon: const Icon(EnjoyIcons.link, size: 18),
                        label: Text(l10n.youtubeOpenInBrowser),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInBrowser(BuildContext context, String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.playerOpenGenericError),
          ),
        );
      }
    }
  }
}

/// Main expanded player: Duet top bar over the video/audio layout.
class ExpandedPlayerChromeBody extends ConsumerWidget {
  const ExpandedPlayerChromeBody({
    super.key,
    required this.mediaId,
    required this.chrome,
  });

  final String mediaId;
  final PlaybackChrome chrome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVideo = chrome.mediaType == 'video';
    final engine = ref.watch(playerEngineProvider);
    final splitPx = ref.watch(
      playerPreferencesCtrlProvider.select(
        (p) => p.videoTranscriptSplitWidthPx,
      ),
    );
    final transcript = TranscriptPanel(mediaId: mediaId);

    final mediaBody = isVideo
        ? VideoPlayerLayout(
            engine: engine,
            transcript: transcript,
            initialTranscriptSplitWidthPx: splitPx,
            onTranscriptSplitWidthCommitted: (w) => ref
                .read(playerPreferencesCtrlProvider.notifier)
                .setVideoTranscriptSplitWidthPx(w),
          )
        : AudioPlayerLayout(transcript: transcript);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlayerTopBar(mediaId: mediaId),
          Expanded(child: PlayerMarginLayout(child: mediaBody)),
        ],
      ),
    );
  }
}
