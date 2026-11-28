/// Live progress banner for an in-flight ASR generation pass.
///
/// ADR-0106 §5: instead of a bare spinner the pipeline renders as a stage
/// breadcrumb — 提取音频 → 识别 → 对齐 → 断句 — with a determinate bar, an
/// engine/elapsed info line and a cancel action, pinned above the transcript
/// panel body. Extraction gets no real fraction from the ffmpeg CLI, so it
/// shows an indeterminate bar; the local recognition step rides the
/// controller's wall-clock estimate (`AsrRecognitionProgress`) — a
/// 22-minute episode transcribing in ~2–3 minutes used to look hung behind
/// a spinner and a ticking clock alone. Terminal transitions surface a
/// transient 完成/取消/失败 note that auto-dismisses.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/ai/application/ai_capability_providers.dart';
import 'package:enjoy_player/features/ai/data/local_qwen_asr_capability.dart';
import 'package:enjoy_player/features/ai/data/local_subgen_asr_capability.dart';
import 'package:enjoy_player/features/asr/application/asr_failure_messages.dart';
import 'package:enjoy_player/features/asr/application/asr_generation_controller.dart';
import 'package:enjoy_player/features/asr/application/asr_generation_job.dart';
import 'package:enjoy_player/features/asr/application/asr_stage_pipeline.dart';
import 'package:enjoy_player/features/local_components/data/component_store.dart';
import 'package:enjoy_player/features/local_components/domain/component_catalog.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Phases worth showing a live banner for (everything before a terminal one).
const _activePhases = {
  AsrGenerationPhase.extracting,
  AsrGenerationPhase.uploading,
  AsrGenerationPhase.recognizing,
  AsrGenerationPhase.aligning,
  AsrGenerationPhase.polling,
  AsrGenerationPhase.persisting,
};

class AsrGenerationProgressBanner extends ConsumerStatefulWidget {
  const AsrGenerationProgressBanner({
    required this.mediaId,
    this.alignInstalledProbe,
    super.key,
  });

  final String mediaId;

  /// Injectable aligner-install probe (tests); null → real component store.
  final bool Function()? alignInstalledProbe;

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
      _noteIcon = EnjoyIcons.checkCircle;
    } else if (phase == AsrGenerationPhase.cancelled) {
      _note = l10n.asrStatusCancelled;
      _noteColor = null;
      _noteIcon = EnjoyIcons.info;
    } else {
      _note = asrMessageForKey(l10n, job.errorMessage);
      _noteColor = Theme.of(context).colorScheme.error;
      _noteIcon = EnjoyIcons.error;
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

  /// Engine label for the info line — local capabilities only; cloud BYOK
  /// paths hide the row rather than lie about which engine is running.
  String? _engineLabel() {
    final capability = ref.read(asrCapabilityProvider);
    if (capability is LocalQwenAsrCapability) {
      return localAsrEngineLabel(qwenInstalled: true);
    }
    if (capability is LocalSubgenAsrCapability) {
      return localAsrEngineLabel(qwenInstalled: false);
    }
    return null;
  }

  bool _alignerInstalled() {
    final store = ComponentStore(rootOverride: null);
    return store.isInstalled(specOf(ComponentKind.ctcAlignerRuntime)) &&
        store.isInstalled(specOf(ComponentKind.ctcAlignerModel));
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
    final stages = asrStageViews(
      phase,
      alignInstalled:
          widget.alignInstalledProbe?.call() ?? _alignerInstalled(),
    );

    final infoParts = <String>[
      if (elapsed != null) '${l10n.asrBannerElapsed} ${_formatElapsed(elapsed)}',
      if (_engineLabel() case final engine?) l10n.asrBannerEngine(engine),
      if (percent != null) percent,
      phaseText,
    ];

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
                Expanded(child: _StageBreadcrumb(stages: stages)),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.asrLongMediaConfirmCancel,
                  icon: const Icon(EnjoyIcons.close, size: 20),
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
            const SizedBox(height: 6),
            Text(
              infoParts.join('  ·  '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

/// 提取音频 → 识别 → 对齐 → 断句 chips with done/active/pending styling.
class _StageBreadcrumb extends StatelessWidget {
  const _StageBreadcrumb({required this.stages});

  final List<AsrStageView> stages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    Widget chip(AsrStageView view) {
      final label = switch (view.stage) {
        AsrStage.extract => l10n.asrStageExtract,
        AsrStage.recognize => l10n.asrStageRecognize,
        AsrStage.align => l10n.asrStageAlign,
        AsrStage.segment => l10n.asrStageSegment,
      };
      final active = view.state == AsrStageState.active;
      final color = active
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurfaceVariant;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (view.state == AsrStageState.done) ...[
            Icon(EnjoyIcons.check, size: 13, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 2,
      children: [
        for (final view in stages) ...[
          if (view != stages.first)
            Icon(
              EnjoyIcons.chevronRight,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          chip(view),
        ],
      ],
    );
  }
}
