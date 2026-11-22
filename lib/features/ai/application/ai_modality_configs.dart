import 'package:flutter/foundation.dart';

import 'package:enjoy_player/features/ai/domain/ai_provider.dart';
import 'package:enjoy_player/features/ai/domain/ai_service_config.dart';

/// Per-modality [AIServiceConfig]. Replace via [AiModalityConfigs] override later.
@immutable
final class AiModalityConfigs {
  const AiModalityConfigs({
    required this.asr,
    required this.tts,
    required this.llm,
    required this.translation,
    required this.dictionary,
    required this.assessment,
  });

  // 本地版：所有模态只走用户自备端点，Enjoy 云端已删除。
  static const AiModalityConfigs defaults = AiModalityConfigs(
    asr: AIServiceConfig(provider: AIProvider.byok),
    tts: AIServiceConfig(provider: AIProvider.byok),
    llm: AIServiceConfig(provider: AIProvider.byok),
    translation: AIServiceConfig(provider: AIProvider.byok),
    dictionary: AIServiceConfig(provider: AIProvider.byok),
    assessment: AIServiceConfig(provider: AIProvider.byok),
  );

  final AIServiceConfig asr;
  final AIServiceConfig tts;
  final AIServiceConfig llm;
  final AIServiceConfig translation;
  final AIServiceConfig dictionary;
  final AIServiceConfig assessment;
}
