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
      transcriptPlaybackHighlightProvider(
        mediaId,
      ).select((h) => h.visibleCueIndex),
    );

    final lines =
        ref.watch(transcriptLinesForMediaProvider(mediaId)).value ??
        const [];
    final secondary =
        ref.watch(secondaryTranscriptLinesForMediaProvider(mediaId)).value ??
        const [];
    final translationText = cue >= 0 && cue < secondary.length
        ? secondary[cue].text.trim()
        : '';
    final originalText = cue >= 0 && cue < lines.length
        ? lines[cue].text.trim()
        : '';
    final hasTranslation = translationText.isNotEmpty;

    final showOriginal =
        mode == CaptionOverlayMode.original || mode == CaptionOverlayMode.both;
    final showTranslation =
        mode == CaptionOverlayMode.translation ||
        mode == CaptionOverlayMode.both;

    final hasContent =
        cue >= 0 && (originalText.isNotEmpty || hasTranslation);

    final List<Shadow> outline = [
      for (final offsets in const [
        Offset(-2.5, -2.5),
        Offset(2.5, -2.5),
        Offset(-2.5, 2.5),
        Offset(2.5, 2.5),
        Offset(-2.5, 0),
        Offset(2.5, 0),
        Offset(0, -2.5),
        Offset(0, 2.5),
      ])
        Shadow(color: Colors.black, offset: offsets, blurRadius: 2),
    ];

    Widget captionText(String text, double size, Color color) => Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        inherit: false,
        fontSize: size,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: color,
        decoration: TextDecoration.none,
        shadows: outline,
      ),
    );

    final content = hasContent
        ? KeyedSubtree(
            key: ValueKey('caption-$cue'),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 14),
                child: IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showOriginal && originalText.isNotEmpty)
                        captionText(originalText, 30, Colors.white),
                      if (showTranslation && hasTranslation) ...[
                        if (showOriginal && originalText.isNotEmpty)
                          const SizedBox(height: 6),
                        captionText(
                          translationText,
                          23,
                          Colors.white.withValues(alpha: 0.94),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          )
        : const SizedBox.shrink(key: ValueKey('caption-hidden'));

    // 150ms 淡入淡出：同一句显示期间 child 不变（完全稳定）；
    // 句子说完或换句时才触发过渡——淡出只会发生在语音结束之后。
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: content,
    );
  }
}
