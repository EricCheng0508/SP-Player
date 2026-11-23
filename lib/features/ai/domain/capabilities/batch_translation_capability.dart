/// Numbered-list batch translation — the chunked transport for auto-translate.
abstract class BatchTranslationCapability {
  /// Translates [lines] in one LLM call.
  ///
  /// Returns one entry per input line; an entry is `null` when the model
  /// skipped or emptied that line, so the caller can fall back to a
  /// single-line call for it.
  Future<List<String?>> translateLines({
    required List<String> lines,
    required String sourceLanguage,
    required String targetLanguage,
  });
}
