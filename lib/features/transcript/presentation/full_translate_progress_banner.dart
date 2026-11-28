/// Full-video translation banner (ADR-0106 §5).
///
/// Rendered above the transcript panel body, next to the ASR generation
/// banner. Three visible states:
/// - idle with cached progress < total: call-to-action「翻译全片」(+ cached
///   readout so「上次中断 n/total」is obvious),
/// - running: determinate bar + translated-count title + "已翻译到第 X 分钟",
/// - paused (cancel / failed / config missing): resume action + reason.
/// Complete hides the banner — reopening the media shows translations
/// directly (no banner noise for a finished job).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/transcript/application/full_translate_ctrl.dart';
import 'package:enjoy_player/features/transcript/domain/auto_translate.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class FullTranslateProgressBanner extends ConsumerStatefulWidget {
  const FullTranslateProgressBanner({required this.mediaId, super.key});

  final String mediaId;

  @override
  ConsumerState<FullTranslateProgressBanner> createState() =>
      _FullTranslateProgressBannerState();
}

class _FullTranslateProgressBannerState
    extends ConsumerState<FullTranslateProgressBanner> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Heartbeat while running so the "已翻译到第 X 分钟" readout keeps pace
    // with persisted batches even without controller state churn.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String? _pausedMessage(FullTranslateUiState state, AppLocalizations l10n) {
    switch (state.blockReason) {
      case FullTranslateBlockReason.noLlm:
        return l10n.fullTranslateBannerErrorConfig;
      case FullTranslateBlockReason.partialFailure:
        return l10n.fullTranslateBannerPausedFailure(state.failedCount);
      case FullTranslateBlockReason.stopped:
        return l10n.fullTranslateBannerPausedStopped;
      case FullTranslateBlockReason.auth:
      case FullTranslateBlockReason.noTranslatableSource:
      case FullTranslateBlockReason.trackFailed:
        return l10n.fullTranslateBannerErrorGeneric;
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fullTranslateCtrlProvider(widget.mediaId));
    if (state.totalCount == 0) return const SizedBox.shrink();
    // 完成态不出横幅：打开直接有译文（ADR-0106 进度持久化语义）。
    if (state.phase == FullTranslatePhase.done) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final running = state.phase == FullTranslatePhase.running;
    final progress = state.totalCount == 0
        ? null
        : (state.translatedCount / state.totalCount).clamp(0.0, 1.0);
    final minute = state.lastTranslatedStartMs ~/ 60000;

    final title = running
        ? l10n.fullTranslateBannerRunningTitle(
            state.translatedCount,
            state.totalCount,
          )
        : l10n.fullTranslateBannerCachedProgress(
            state.translatedCount,
            state.totalCount,
          );
    final message = running
        ? (minute > 0 ? l10n.fullTranslateBannerReachedMinute(minute) : null)
        : _pausedMessage(state, l10n);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (running)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (running) const SizedBox(width: 12),
                Expanded(child: Text(title, style: theme.textTheme.bodyMedium)),
                if (message != null && !running)
                  Flexible(
                    child: Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(width: 8),
                if (running)
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).cancelButtonLabel,
                    icon: const Icon(EnjoyIcons.close, size: 20),
                    onPressed: () => ref
                        .read(
                          fullTranslateCtrlProvider(widget.mediaId).notifier,
                        )
                        .cancel(),
                  )
                else
                  TextButton(
                    onPressed: () => ref
                        .read(
                          fullTranslateCtrlProvider(widget.mediaId).notifier,
                        )
                        .translateAll(),
                    child: Text(
                      state.translatedCount == 0
                          ? l10n.fullTranslateBannerCta
                          : l10n.fullTranslateBannerContinue,
                    ),
                  ),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress, minHeight: 3),
            ],
            if (running && minute > 0) ...[
              const SizedBox(height: 4),
              Text(
                l10n.fullTranslateBannerReachedMinute(minute),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
