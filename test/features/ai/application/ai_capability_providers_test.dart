import 'package:enjoy_player/features/ai/application/ai_capability_providers.dart';
import 'package:enjoy_player/features/ai/application/ai_modality_configs.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_translation_capability.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('translationCapabilityProvider returns ByokTranslationCapability', () {
    final container = ProviderContainer(
      overrides: [
        aiModalityConfigsProvider.overrideWithValue(AiModalityConfigs.defaults),
      ],
    );
    addTearDown(container.dispose);

    final capability = container.read(translationCapabilityProvider);

    expect(
      capability,
      isA<ByokTranslationCapability>(),
      reason:
          'FullTranslateCtrl extracts the LLM via '
          '`capability is ByokTranslationCapability`; wrapping this provider '
          'in a decorator silently breaks manual full-video translation.',
    );
  });
}
