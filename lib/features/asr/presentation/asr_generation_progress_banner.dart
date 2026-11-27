/// Live progress banner for an in-flight ASR generation pass.
///
/// ADR-0106 §5: instead of a bare spinner the pipeline renders as a stage
/// breadcrumb — 提取音频 → 识别 → 对齐 → 断句 — with a determinate bar
/// during audio extraction, an engine/elapsed info line and a cancel
/// action, pinned above the transcript panel body. The elapsed readout
/// matters for the local sidecar pipeline: a 22-minute episode transcribes
/// in minutes with no incremental progress, and without a ticking clock it
/// looks hung.
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
    if (phase == null || !_activePhases.contains(phase)) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final progress = job!.progress;
    // Numeric progress is only meaningful during audio extraction; every
    // other phase is a single long-running step → indeterminate, with the
    // info line standing in for missing granularity.
    final determinate = phase == AsrGenerationPhase.extracting &&
        progress != null &&
        progress > 0;
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
              value: determinate ? progress.clamp(0.0, 1.0) : null,
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
