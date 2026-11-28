/// Prompts for BYOK sentence explanation (markdown response).
library;

import 'package:enjoy_player/core/application/app_language_catalog.dart';

String buildExplainSystemPrompt({
  required String sourceLanguage,
  required String targetLanguage,
}) {
  final source = workerLanguageBase(sourceLanguage);
  final target = workerLanguageBase(targetLanguage);
  return 'You are a patient language teacher. The learner speaks $target '
      'and is studying $source. Explain the given sentence so a learner can '
      'fully understand it. Respond in $target using markdown:\n'
      '- **整句翻译**: a natural $target translation of the sentence\n'
      '- **语法拆解**: break the sentence into chunks; for each chunk give the '
      'grammatical role and meaning (keep original $source text inline)\n'
      '- **关键词组**: 2-5 key words or phrases with concise explanations\n'
      '- **用法提示**: any nuance, register, or common-collocation note worth '
      'remembering\n\n'
      'Be concise and concrete. No preamble, no closing remarks.';
}

String buildExplainUserPrompt({required String sentence, String? context}) {
  final ctx = context?.trim();
  if (ctx == null || ctx.isEmpty || ctx == sentence) {
    return 'Explain this sentence:\n\n$sentence';
  }
  return 'Explain this sentence:\n\n$sentence\n\n'
      'It appears in this context:\n\n$ctx';
}
