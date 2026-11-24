import 'package:enjoy_player/features/ai/domain/capabilities/line_explanation_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/llm_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/line_explanation.dart';
import 'package:enjoy_player/features/ai/domain/prompts/line_explanation_prompt.dart';

final class ByokLineExplanationCapability implements LineExplanationCapability {
  ByokLineExplanationCapability(this._llm);

  final LlmCapability _llm;

  @override
  Future<LineExplanation> explainSentence({
    required String sentence,
    required String sourceLanguage,
    required String targetLanguage,
    String? context,
    bool? forceRefresh,
  }) async {
    final text = await _llm.generateText(
      systemPrompt: buildExplainSystemPrompt(
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      ),
      userPrompt: buildExplainUserPrompt(sentence: sentence, context: context),
      temperature: 0.3,
      maxTokens: 2048,
    );
    return LineExplanation(text: text.trim());
  }
}
