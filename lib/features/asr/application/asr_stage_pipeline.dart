/// Stage breadcrumb model for the ASR generation banner (ADR-0106 §5).
///
/// The banner renders the pipeline as four named stages — 提取音频 → 识别 →
/// 对齐 → 断句 — instead of a bare spinner. The alignment stage only exists
/// in the shown pipeline when the aligner component is installed (ADR-0106
/// §2: alignment is optional; the plain path goes straight from recognition
/// to segmentation/persist). Pure function + pure data so the mapping is
/// unit-testable without pumping widgets.
library;

import 'package:enjoy_player/features/asr/application/asr_generation_job.dart';

/// The four display stages of the local generation pipeline.
enum AsrStage { extract, recognize, align, segment }

enum AsrStageState { pending, active, done }

/// One breadcrumb chip: which stage and its current state.
final class AsrStageView {
  const AsrStageView(this.stage, this.state);

  final AsrStage stage;
  final AsrStageState state;
}

/// Builds the breadcrumb for [phase]. [alignInstalled] hides the alignment
/// stage when the CTC aligner component is absent — a stage that can never
/// run must not render as "pending".
List<AsrStageView> asrStageViews(
  AsrGenerationPhase phase, {
  required bool alignInstalled,
}) {
  List<AsrStageView> all(AsrStageState extract, AsrStageState recognize,
      AsrStageState align, AsrStageState segment) {
    final views = <AsrStageView>[
      AsrStageView(AsrStage.extract, extract),
      AsrStageView(AsrStage.recognize, recognize),
      if (alignInstalled) AsrStageView(AsrStage.align, align),
      AsrStageView(AsrStage.segment, segment),
    ];
    return views;
  }

  switch (phase) {
    case AsrGenerationPhase.extracting:
      return all(AsrStageState.active, AsrStageState.pending,
          AsrStageState.pending, AsrStageState.pending);
    case AsrGenerationPhase.uploading:
    case AsrGenerationPhase.polling:
    case AsrGenerationPhase.recognizing:
      // Uploading/polling are transport sub-phases of recognition — the
      // breadcrumb pins on the recognition stage while they run.
      return all(AsrStageState.done, AsrStageState.active,
          AsrStageState.pending, AsrStageState.pending);
    case AsrGenerationPhase.aligning:
      return all(AsrStageState.done, AsrStageState.done, AsrStageState.active,
          AsrStageState.pending);
    case AsrGenerationPhase.persisting:
      // 断句 + 落库 share the final stage (buildAsrTranscriptLines runs
      // right before the upsert).
      return all(
        AsrStageState.done,
        AsrStageState.done,
        alignInstalled ? AsrStageState.done : AsrStageState.pending,
        AsrStageState.active,
      );
    case AsrGenerationPhase.idle:
    case AsrGenerationPhase.success:
    case AsrGenerationPhase.error:
    case AsrGenerationPhase.cancelled:
      // Terminal states never render the banner; return a fully-done row
      // so callers without the active-phase guard still get a sane row.
      return all(AsrStageState.done, AsrStageState.done,
          alignInstalled ? AsrStageState.done : AsrStageState.pending,
          AsrStageState.done);
  }
}

/// Human-readable engine name for the banner info line.
///
/// Mirrors [resolveAsrCapability]'s local fallback order: Qwen sidecar
/// installed → Qwen3-ASR; otherwise the transitional faster-whisper sidecar.
String localAsrEngineLabel({required bool qwenInstalled}) =>
    qwenInstalled ? 'Qwen3-ASR' : 'Whisper large-v3-turbo';
