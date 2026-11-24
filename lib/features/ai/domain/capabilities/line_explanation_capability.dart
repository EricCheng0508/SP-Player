/// Sentence explanation capability (grammar/phrases/usage, markdown out).
library;

import 'package:enjoy_player/features/ai/domain/models/line_explanation.dart';

abstract interface class LineExplanationCapability {
  Future<LineExplanation> explainSentence({
    required String sentence,
    required String sourceLanguage,
    required String targetLanguage,
    String? context,
    bool? forceRefresh,
  });
}
