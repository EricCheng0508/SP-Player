import 'package:enjoy_player/features/asr/application/asr_generation_job.dart';
import 'package:enjoy_player/features/asr/application/asr_stage_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('asrStageViews', () {
    test('extracting → only extract active', () {
      final views = asrStageViews(
        AsrGenerationPhase.extracting,
        alignInstalled: false,
      );
      expect(views.map((v) => v.stage), [
        AsrStage.extract,
        AsrStage.recognize,
        AsrStage.segment,
      ]);
      expect(views.map((v) => v.state), [
        AsrStageState.active,
        AsrStageState.pending,
        AsrStageState.pending,
      ]);
    });

    test('recognition stages (uploading/polling/recognizing) share one chip', () {
      for (final phase in {
        AsrGenerationPhase.uploading,
        AsrGenerationPhase.polling,
        AsrGenerationPhase.recognizing,
      }) {
        final views = asrStageViews(phase, alignInstalled: false);
        expect(views[0].stage, AsrStage.extract);
        expect(views[0].state, AsrStageState.done);
        expect(views[1].stage, AsrStage.recognize);
        expect(views[1].state, AsrStageState.active);
        expect(views[2].state, AsrStageState.pending);
      }
    });

    test('aligning → align active with prior stages done', () {
      final views = asrStageViews(
        AsrGenerationPhase.aligning,
        alignInstalled: true,
      );
      expect(views.map((v) => v.stage), [
        AsrStage.extract,
        AsrStage.recognize,
        AsrStage.align,
        AsrStage.segment,
      ]);
      expect(views[0].state, AsrStageState.done);
      expect(views[1].state, AsrStageState.done);
      expect(views[2].state, AsrStageState.active);
      expect(views[3].state, AsrStageState.pending);
    });

    test('align stage hidden when aligner not installed', () {
      final views = asrStageViews(
        AsrGenerationPhase.aligning,
        alignInstalled: false,
      );
      expect(views.map((v) => v.stage), isNot(contains(AsrStage.align)));
    });

    test('persisting → segment active, everything shown done', () {
      final views = asrStageViews(
        AsrGenerationPhase.persisting,
        alignInstalled: true,
      );
      expect(views[0].state, AsrStageState.done);
      expect(views[1].state, AsrStageState.done);
      expect(views[2].state, AsrStageState.done);
      expect(views[3].state, AsrStageState.active);
    });

    test('persisting without aligner → segment still active', () {
      final views = asrStageViews(
        AsrGenerationPhase.persisting,
        alignInstalled: false,
      );
      expect(views[2].stage, AsrStage.segment);
      expect(views[2].state, AsrStageState.active);
    });
  });

  group('localAsrEngineLabel', () {
    test('qwen installed → Qwen3-ASR', () {
      expect(localAsrEngineLabel(qwenInstalled: true), 'Qwen3-ASR');
    });

    test('qwen missing → transitional Whisper label', () {
      expect(localAsrEngineLabel(qwenInstalled: false), 'Whisper large-v3-turbo');
    });
  });
}
