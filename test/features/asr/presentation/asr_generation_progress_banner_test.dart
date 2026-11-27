import 'package:enjoy_player/features/ai/application/ai_capability_providers.dart';
import 'package:enjoy_player/features/ai/data/local_subgen_asr_capability.dart';
import 'package:enjoy_player/features/asr/application/asr_generation_controller.dart';
import 'package:enjoy_player/features/asr/application/asr_generation_job.dart';
import 'package:enjoy_player/features/asr/presentation/asr_generation_progress_banner.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the controller in one phase so the banner renders deterministically.
class _PinnedAsrGenerationCtrl extends AsrGenerationController {
  _PinnedAsrGenerationCtrl(this.job);

  final AsrGenerationJob? job;

  @override
  AsyncValue<AsrGenerationJob?> build(String mediaId) =>
      AsyncValue.data(job);
}

/// Local Whisper sidecar stub → banner shows the transitional engine label.
final _whisperStub = LocalSubgenAsrCapability();

Widget _wrap({
  required ProviderContainer container,
  required AsrGenerationJob job,
  required bool alignInstalled,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AsrGenerationProgressBanner(
          mediaId: 'm1',
          alignInstalledProbe: () => alignInstalled,
        ),
      ),
    ),
  );
}

ProviderContainer _container(AsrGenerationJob job) => ProviderContainer(
      overrides: [
        asrCapabilityProvider.overrideWithValue(_whisperStub),
        asrGenerationControllerProvider(
          'm1',
        ).overrideWith(() => _PinnedAsrGenerationCtrl(job)),
      ],
    );

void main() {
  testWidgets('recognizing → breadcrumb shows 提取音频 done + 识别 active, engine info',
      (tester) async {
    final job = AsrGenerationJob(
      mediaId: 'm1',
      language: 'en',
      phase: AsrGenerationPhase.recognizing,
      startedAt: DateTime.now(),
    );
    final container = _container(job);
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(
      container: container,
      job: job,
      alignInstalled: false,
    ));

    expect(find.text('Extract audio'), findsOneWidget);
    expect(find.text('Recognize'), findsOneWidget);
    expect(find.text('Segment'), findsOneWidget);
    // Aligner not installed → align chip hidden entirely.
    expect(find.text('Align'), findsNothing);
    // Info line: engine label of the transitional Whisper fallback.
    expect(find.textContaining('Whisper large-v3-turbo'), findsOneWidget);
    // Cancel affordance present.
    expect(find.byIcon(EnjoyIcons.close), findsOneWidget);
  });

  testWidgets('persisting with aligner installed → 对齐 chip shown as done',
      (tester) async {
    final job = AsrGenerationJob(
      mediaId: 'm1',
      language: 'en',
      phase: AsrGenerationPhase.persisting,
      startedAt: DateTime.now(),
    );
    final container = _container(job);
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(
      container: container,
      job: job,
      alignInstalled: true,
    ));

    expect(find.text('Align'), findsOneWidget);
    expect(find.text('Segment'), findsOneWidget);
    // Done stages carry a check icon (extract/recognize/align = 3 checks).
    expect(find.byIcon(EnjoyIcons.check), findsNWidgets(3));
  });

  testWidgets('terminal phases render nothing', (tester) async {
    final job = AsrGenerationJob(
      mediaId: 'm1',
      language: 'en',
      phase: AsrGenerationPhase.success,
      startedAt: DateTime.now(),
    );
    final container = _container(job);
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(
      container: container,
      job: job,
      alignInstalled: true,
    ));

    expect(find.text('Recognize'), findsNothing);
  });
}
