import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/contextual_translation_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/llm_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/contextual_translation_result.dart';
import 'package:enjoy_player/features/ai/domain/prompts/contextual_translation_prompt.dart';

/// 语境翻译：把 LLM 能力的输出按「当前上下文里这个词/句怎么理解」来问。
///
/// 这条链路本身与供应商无关 —— 只是复用注入的 [LlmCapability]，
/// 所以本地版（全部 BYOK）可以直接沿用。
final class ByokContextualTranslationCapability
    implements ContextualTranslationCapability {
  ByokContextualTranslationCapability(this._llm);

  final LlmCapability _llm;

  @override
  Future<ContextualTranslationResult> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    String? context,
  }) async {
    final systemPrompt = getContextualTranslationSystemPrompt(
      workerLanguageBase(targetLanguage),
    );
    final userPrompt = buildContextualTranslationUserPrompt(
      text: text,
      context: context,
    );
    final raw = await _llm.generateText(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: 0.3,
      maxTokens: 1024,
    );
    return ContextualTranslationResult(translatedText: raw.trim());
  }
}
