import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/api/api_client_provider.dart';
import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/features/ai/application/ai_modality_config_controller.dart';
import 'package:enjoy_player/features/ai/application/ai_modality_configs.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_asr_azure_capability.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_asr_openai_capability.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_assessment_azure_capability.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_contextual_translation_capability.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_dictionary_capability.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_llm_capability.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_tts_azure_capability.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_tts_openai_capability.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_translation_capability.dart';
import 'package:enjoy_player/features/ai/data/local_subgen_asr_capability.dart';
import 'package:enjoy_player/features/ai/data/stub_ai_capabilities.dart';
import 'package:enjoy_player/features/ai/domain/ai_provider.dart';
import 'package:enjoy_player/features/ai/domain/ai_service_config.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/asr_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/assessment_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/contextual_translation_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/dictionary_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/llm_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/translation_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/tts_capability.dart';
import 'package:enjoy_player/features/ai/domain/speech_byok_kind.dart';

part 'ai_capability_providers.g.dart';

AsrCapability resolveAsrCapability(Ref ref, AIServiceConfig config) {
  switch (config.provider) {
    case AIProvider.byok:
      final speechByok = config.speechByok;
      if (speechByok == null) {
        // 本地版:语音识别未配置时默认绑定 subgen 本地识别服务
        // (D:\Tool\subgen\start-asr-server.bat → 127.0.0.1:8000,large-v3-turbo),
        // 零配置可用;设置里显式配置过的用户仍以配置为准。
        return LocalSubgenAsrCapability(
          httpClient: ref.read(httpClientProvider),
        );
      }
      return switch (speechByok.kind) {
        SpeechByokKind.openAiCompatible => ByokAsrOpenAiCapability(
          config: speechByok,
          secrets: ref.read(byokSecretStoreProvider),
          httpClient: ref.read(httpClientProvider),
        ),
        SpeechByokKind.azureSpeech => ByokAsrAzureCapability(
          config: speechByok,
          secrets: ref.read(byokSecretStoreProvider),
        ),
      };
  }
}

LlmCapability resolveLlmCapability(Ref ref, AIServiceConfig config) {
  switch (config.provider) {
    case AIProvider.byok:
      final llmByok = config.llmByok;
      if (llmByok == null) return const ByokNotConfiguredLlmCapability();
      return ByokLlmCapability(llmByok, ref.read(byokSecretStoreProvider));
  }
}

TranslationCapability resolveTranslationCapability(
  Ref ref,
  AIServiceConfig config,
) {
  switch (config.provider) {
    case AIProvider.byok:
      return ByokTranslationCapability(resolveLlmCapability(ref, config));
  }
}

DictionaryCapability resolveDictionaryCapability(
  Ref ref,
  AIServiceConfig config,
) {
  switch (config.provider) {
    case AIProvider.byok:
      return ByokDictionaryCapability(resolveLlmCapability(ref, config));
  }
}

ContextualTranslationCapability resolveContextualTranslationCapability(
  Ref ref,
  AIServiceConfig config,
) {
  switch (config.provider) {
    case AIProvider.byok:
      return ByokContextualTranslationCapability(
        resolveLlmCapability(ref, config),
      );
  }
}

TtsCapability resolveTtsCapability(Ref ref, AIServiceConfig config) {
  switch (config.provider) {
    case AIProvider.byok:
      final speechByok = config.speechByok;
      if (speechByok == null) return const ByokNotConfiguredTtsCapability();
      return switch (speechByok.kind) {
        SpeechByokKind.openAiCompatible => ByokTtsOpenAiCapability(
          config: speechByok,
          secrets: ref.read(byokSecretStoreProvider),
          httpClient: ref.read(httpClientProvider),
        ),
        SpeechByokKind.azureSpeech => ByokTtsAzureCapability(
          config: speechByok,
          secrets: ref.read(byokSecretStoreProvider),
        ),
      };
  }
}

AssessmentCapability resolveAssessmentCapability(
  Ref ref,
  AIServiceConfig config,
) {
  switch (config.provider) {
    case AIProvider.byok:
      final speechByok = config.speechByok;
      if (speechByok == null) {
        return const ByokNotConfiguredAssessmentCapability();
      }
      return ByokAssessmentAzureCapability(
        config: speechByok,
        secrets: ref.read(byokSecretStoreProvider),
      );
  }
}

@Riverpod(keepAlive: true)
AiModalityConfigs aiModalityConfigs(Ref ref) {
  return ref.watch(aiModalityConfigCtrlProvider);
}

@Riverpod(keepAlive: true)
AsrCapability asrCapability(Ref ref) {
  final c = ref.watch(aiModalityConfigsProvider);
  return resolveAsrCapability(ref, c.asr);
}

@Riverpod(keepAlive: true)
LlmCapability llmCapability(Ref ref) {
  final c = ref.watch(aiModalityConfigsProvider);
  return resolveLlmCapability(ref, c.llm);
}

@Riverpod(keepAlive: true)
TranslationCapability translationCapability(Ref ref) {
  final c = ref.watch(aiModalityConfigsProvider);
  // 本地版：翻译没单独配置时，直接复用「语言模型」的配置，
  // 设置里填一次端点就够，不必分别配三处。
  final config = c.translation.llmByok == null && c.llm.llmByok != null
      ? c.llm
      : c.translation;
  return resolveTranslationCapability(ref, config);
}

@Riverpod(keepAlive: true)
DictionaryCapability dictionaryCapability(Ref ref) {
  final c = ref.watch(aiModalityConfigsProvider);
  final config = c.dictionary.llmByok == null && c.llm.llmByok != null
      ? c.llm
      : c.dictionary;
  return resolveDictionaryCapability(ref, config);
}

@Riverpod(keepAlive: true)
ContextualTranslationCapability contextualTranslationCapability(Ref ref) {
  final c = ref.watch(aiModalityConfigsProvider);
  return resolveContextualTranslationCapability(ref, c.llm);
}

@Riverpod(keepAlive: true)
TtsCapability ttsCapability(Ref ref) {
  final c = ref.watch(aiModalityConfigsProvider);
  return resolveTtsCapability(ref, c.tts);
}

@Riverpod(keepAlive: true)
AssessmentCapability assessmentCapability(Ref ref) {
  final c = ref.watch(aiModalityConfigsProvider);
  return resolveAssessmentCapability(ref, c.assessment);
}
