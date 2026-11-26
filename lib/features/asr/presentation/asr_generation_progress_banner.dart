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
  Timer? _noteTimer;
  String? _note;
  Color? _noteColor;
  IconData? _noteIcon;

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
    _noteTimer?.cancel();
    super.dispose();
  }

  /// Shows a transient terminal note ("已完成" / cancelled / error) that
  /// auto-dismisses after a few seconds — the live banner used to vanish
  /// without any completion feedback.
  void _showNote(AsrGenerationJob job) {
    final l10n = AppLocalizations.of(context)!;
    final phase = job.phase;
    _noteTimer?.cancel();
    if (phase == AsrGenerationPhase.success) {
      _note = l10n.asrStatusSuccess;
      _noteColor = const Color(0xFF176B3A);
      _noteIcon = Icons.check_circle_outline;
    } else if (phase == AsrGenerationPhase.cancelled) {
      _note = l10n.asrStatusCancelled;
      _noteColor = null;
      _noteIcon = Icons.info_outline;
    } else {
      _note = asrMessageForKey(l10n, job.errorMessage);
      _noteColor = Theme.of(context).colorScheme.error;
      _noteIcon = Icons.error_outline;
    }
    _noteTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _note = null;
        _noteColor = null;
        _noteIcon = null;
      });
    });
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

    // Terminal-phase transition → transient completion note. Observed via
    // listen so the note only appears for runs seen from this banner (not
    // when reopening a page whose job finished long ago).
    ref.listen(asrGenerationControllerProvider(widget.mediaId),
        (previous, next) {
      final prevPhase = previous?.valueOrNull?.phase;
      final nextPhase = next.valueOrNull?.phase;
      if (nextPhase == null || identical(prevPhase, nextPhase)) return;
      if (nextPhase == AsrGenerationPhase.success ||
          nextPhase == AsrGenerationPhase.cancelled ||
          nextPhase == AsrGenerationPhase.error) {
        _showNote(next.valueOrNull!);
      }
    });

    if (phase == null || !_activePhases.contains(phase)) {
      return _buildNote();
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final progress = job!.progress;
    // Recognition rides a wall-clock estimate (determinate); extraction gets
    // no real fraction from the ffmpeg CLI (0 → 100 with nothing between), so
    // it shows an indeterminate bar instead of a lying percentage. Upload/
    // poll/persist are single steps and stay indeterminate too.
    final determinate =
        progress != null && phase == AsrGenerationPhase.recognizing;
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
              value: determinate ? progress!.clamp(0.0, 1.0) : null,
              minHeight: 3,
            ),
          ],
        ),
      ),
    );
  }

  /// The transient terminal note, or nothing.
  Widget _buildNote() {
    final note = _note;
    if (note == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            if (_noteIcon != null) ...[
              Icon(_noteIcon, size: 16, color: _noteColor),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                note,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _noteColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
