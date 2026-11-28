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
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/player/application/caption_overlay_settings.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';
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

    // 盲听模式（transcript 模糊）联动：覆盖字幕一并隐藏，避免漏答案。
    if (ref.watch(transcriptBlurModeProvider)) return const SizedBox.shrink();

    final chrome = ref.watch(playerControllerProvider.select(playbackChromeOf));
    final mediaId = chrome?.mediaId;
    if (mediaId == null || mediaId.isEmpty) return const SizedBox.shrink();

    final cue = ref.watch(
      transcriptPlaybackHighlightProvider(
        mediaId,
      ).select((h) => h.visibleCueIndex),
    );

    final lines =
        ref.watch(transcriptLinesForMediaProvider(mediaId)).value ?? const [];
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

    final hasContent = cue >= 0 && (originalText.isNotEmpty || hasTranslation);

    // Classic hard-edged video subtitle stroke: stack 8 black copies of the
    // text offset around the white original — crisper than soft Shadows,
    // matching the look of burned-in player subs.
    Widget captionText(String text, double size, Color color) {
      const stroke = 2.2;
      const offsets = [
        Offset(-stroke, -stroke),
        Offset(stroke, -stroke),
        Offset(-stroke, stroke),
        Offset(stroke, stroke),
        Offset(-stroke, 0),
        Offset(stroke, 0),
        Offset(0, -stroke),
        Offset(0, stroke),
      ];
      final base = TextStyle(
        inherit: false,
        fontFamily: 'Microsoft YaHei UI',
        fontSize: size,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: color,
        decoration: TextDecoration.none,
      );
      return Stack(
        alignment: Alignment.center,
        children: [
          for (final _ in offsets)
            Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: base.copyWith(
                color: Colors.black,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    offset: const Offset(0, 1.5),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: base,
          ),
        ],
      );
    }

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

    // 淡入淡出走统一 motionFast token：同一句显示期间 child 不变（完全稳定）；
    // 句子说完或换句时才触发过渡——淡出只会发生在语音结束之后。
    return AnimatedSwitcher(
      duration: EnjoyThemeTokens.of(context).motionFast,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: content,
    );
  }
}
