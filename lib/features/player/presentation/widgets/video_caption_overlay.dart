/// Transparent subtitle line rendered over the bottom of the video area.
///
/// Mirrors classic player captions: white text with a dark outline, no
/// background box. Display mode (off / original / translation / both) comes
/// from [captionOverlaySettingsProvider]; the active line follows the same
/// playback highlight the transcript side panel uses, so auto-translate
/// merged secondary lines show up here too.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/player/application/caption_overlay_settings.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_playback_highlight_provider.dart';

class VideoCaptionOverlay extends ConsumerWidget {
  const VideoCaptionOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode =
        ref.watch(captionOverlaySettingsProvider).valueOrNull ??
        CaptionOverlayMode.off;
    if (mode == CaptionOverlayMode.off) return const SizedBox.shrink();

    final chrome = ref.watch(playerControllerProvider.select(playbackChromeOf));
    final mediaId = chrome?.mediaId;
    if (mediaId == null || mediaId.isEmpty) return const SizedBox.shrink();

    final cue = ref.watch(
      transcriptPlaybackHighlightProvider(mediaId).select((h) => h.cueIndex),
    );
    if (cue < 0) return const SizedBox.shrink();

    final lines =
        ref.watch(transcriptLinesForMediaProvider(mediaId)).value ??
        const [];
    if (cue >= lines.length) return const SizedBox.shrink();

    final showOriginal =
        mode == CaptionOverlayMode.original || mode == CaptionOverlayMode.both;
    final showTranslation =
        mode == CaptionOverlayMode.translation ||
        mode == CaptionOverlayMode.both;

    final secondary =
        ref.watch(secondaryTranscriptLinesForMediaProvider(mediaId)).value ??
        const [];
    final translationText = cue < secondary.length
        ? secondary[cue].text.trim()
        : '';
    final hasTranslation = translationText.isNotEmpty;

    final originalText = lines[cue].text.trim();
    if (originalText.isEmpty && !hasTranslation) {
      return const SizedBox.shrink();
    }

    final List<Shadow> outline = [
      for (final offsets in const [
        Offset(-1.5, -1.5),
        Offset(1.5, -1.5),
        Offset(-1.5, 1.5),
        Offset(1.5, 1.5),
        Offset(-1.5, 0),
        Offset(1.5, 0),
        Offset(0, -1.5),
        Offset(0, 1.5),
      ])
        Shadow(color: Colors.black, offset: offsets, blurRadius: 1),
    ];

    Widget captionText(String text, double size, Color color) => Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: size,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: color,
        shadows: outline,
      ),
    );

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 14),
        child: IgnorePointer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showOriginal && originalText.isNotEmpty)
                captionText(originalText, 24, Colors.white),
              if (showTranslation && hasTranslation) ...[
                if (showOriginal && originalText.isNotEmpty)
                  const SizedBox(height: 4),
                captionText(translationText, 18, Colors.white.withValues(alpha: 0.92)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
