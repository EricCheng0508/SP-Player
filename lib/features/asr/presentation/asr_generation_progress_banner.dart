/// Live progress banner for an in-flight ASR generation pass.
///
/// The controller streams phase updates; this banner renders the active
/// phase with a progress bar, a percentage when one is available, an
/// elapsed-time readout and a cancel action, pinned above the transcript
/// panel body. Extraction has a real fraction; the local recognition step
/// has none from the service, so the controller hands us a wall-clock
/// estimate (`AsrRecognitionProgress`) rather than leaving the bar
/// indeterminate — a 22-minute episode transcribing in ~2–3 minutes used to
/// look hung behind a spinner and a ticking clock alone.
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
    // Extraction reports its own fraction; recognition rides a wall-clock
    // estimate (the local service has no incremental progress). Both are
    // worth a determinate bar; upload/poll/persist are single steps with no
    // fraction and stay indeterminate.
    final determinate =
        progress != null &&
        (phase == AsrGenerationPhase.extracting ||
            phase == AsrGenerationPhase.recognizing);
    final percent = determinate ? '${(progress * 100).round()}%' : null;
    final startedAt = job.startedAt;
    final elapsed = startedAt == null
        ? null
        : DateTime.now().difference(startedAt);
    final phaseText = asrMessageForKey(l10n, asrPhaseMessageKey(phase));
    final statusText = [
      phaseText,
      if (percent != null) percent,
      if (elapsed != null) _formatElapsed(elapsed),
    ].join('  ');

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
                    statusText,
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
