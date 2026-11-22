/// Live progress banner for an in-flight ASR generation pass.
///
/// The controller streams phase updates; this banner renders the active
/// phase with a progress bar, an elapsed-time readout and a cancel action,
/// pinned above the transcript panel body. The elapsed readout matters for
/// the local subgen pipeline: a 22-minute episode transcribes in ~2–3
/// minutes as ONE long `recognizing` step with no incremental progress, and
/// without a ticking clock it looks hung.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/asr/application/asr_failure_messages.dart';
import 'package:enjoy_player/features/asr/application/asr_generation_controller.dart';
import 'package:enjoy_player/features/asr/application/asr_generation_job.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Phases worth showing a live banner for (everything before a terminal one).
const _activePhases = {
  AsrGenerationPhase.extracting,
  AsrGenerationPhase.uploading,
  AsrGenerationPhase.recognizing,
  AsrGenerationPhase.polling,
  AsrGenerationPhase.persisting,
};

class AsrGenerationProgressBanner extends ConsumerStatefulWidget {
  const AsrGenerationProgressBanner({required this.mediaId, super.key});

  final String mediaId;

  @override
  ConsumerState<AsrGenerationProgressBanner> createState() =>
      _AsrGenerationProgressBannerState();
}

class _AsrGenerationProgressBannerState
    extends ConsumerState<AsrGenerationProgressBanner> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // One-second heartbeat so the elapsed readout ticks even when the
    // controller state itself does not change during a long phase.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatElapsed(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final job = ref
        .watch(asrGenerationControllerProvider(widget.mediaId))
        .valueOrNull;
    final phase = job?.phase;
    if (phase == null || !_activePhases.contains(phase)) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final progress = job!.progress;
    // Numeric progress is only meaningful during audio extraction; every
    // other phase is a single long-running step → indeterminate, with the
    // elapsed readout standing in for missing granularity.
    final determinate = phase == AsrGenerationPhase.extracting &&
        progress != null &&
        progress > 0;
    final startedAt = job.startedAt;
    final elapsed = startedAt == null
        ? null
        : DateTime.now().difference(startedAt);
    final phaseText = asrMessageForKey(l10n, asrPhaseMessageKey(phase));

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
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    elapsed == null
                        ? phaseText
                        : '$phaseText  ${_formatElapsed(elapsed)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.asrLongMediaConfirmCancel,
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => ref
                      .read(asrGenerationControllerProvider(widget.mediaId).notifier)
                      .cancel(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: determinate ? progress.clamp(0.0, 1.0) : null,
              minHeight: 3,
            ),
          ],
        ),
      ),
    );
  }
}
