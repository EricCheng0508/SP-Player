import 'package:enjoy_player/features/ai/domain/capabilities/batch_translation_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/llm_capability.dart';
import 'package:enjoy_player/features/ai/domain/prompts/translation_prompt.dart';

/// BYOK numbered-list batch translation over the shared LLM endpoint.
///
/// One call carries up to [kAutoTranslateBatchMaxLines] cues; the reply is
/// parsed back to per-line texts by [parseBatchTranslationOutput].
final class ByokBatchTranslationCapability implements BatchTranslationCapability {
  ByokBatchTranslationCapability(this._llm);

  final LlmCapability _llm;

  @override
  Future<List<String?>> translateLines({
    required List<String> lines,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final raw = await _llm.generateText(
      systemPrompt: buildBatchTranslationSystemPrompt(
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      ),
      userPrompt: buildBatchTranslationUserPrompt(lines),
      temperature: 0.3,
      maxTokens: kAutoTranslateBatchMaxTokens,
    );
    return parseBatchTranslationOutput(raw, lines.length);
  }
}
