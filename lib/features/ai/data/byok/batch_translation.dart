/// Batch (multi-line) translation over an [LlmCapability] — ADR-0106 §5.
///
/// One request carries `kFullTranslateBatchSize` numbered subtitle lines and
/// expects the same numbering back, so request count drops by the batch
/// factor (344 lines → 18 requests) and the model gets cross-line context
/// for consistent terminology. The reply parser is a pure function; on any
/// numbering mismatch it returns null and the caller may fall back to
/// per-line translation for that batch.
library;

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/llm_capability.dart';

/// Builds the system prompt for numbered multi-line translation.
String buildBatchTranslationSystemPrompt({
  required String sourceLanguage,
  required String targetLanguage,
}) {
  return 'You are a professional subtitle translator. Translate numbered '
      'subtitle lines from $sourceLanguage to $targetLanguage. '
      'Output ONLY the translated lines, keeping the exact same numbering '
      'format ("1." style), one line per input line, no extra blank lines, '
      'no commentary. Keep subtitle style: short, natural, spoken. '
      'Translate the lines as one continuous piece of dialogue so pronouns '
      'and terminology stay consistent across lines.';
}

/// Builds the user prompt: numbered input lines.
String buildBatchTranslationUserPrompt(Iterable<String> lines) {
  final buffer = StringBuffer();
  var n = 1;
  for (final line in lines) {
    buffer.writeln('$n. ${line.trim()}');
    n++;
  }
  return buffer.toString().trimRight();
}

/// Parses the numbered reply back to per-line translations.
///
/// Returns null (caller falls back to per-line requests) unless every index
/// `1..expectedCount` maps to a non-empty translation. Extra / out-of-range
/// numbering is ignored; numbering variants like "12、" or "12)" are
/// tolerated.
List<String>? parseBatchTranslationReply(String reply, int expectedCount) {
  if (expectedCount <= 0) return null;
  final slots = List<String?>.filled(expectedCount, null);
  final pattern = RegExp(r'^\s*(\d+)\s*[.、)）．:：]\s*(.*)$');
  for (final raw in reply.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final match = pattern.firstMatch(line);
    if (match == null) continue;
    final index = int.tryParse(match.group(1)!);
    if (index == null || index < 1 || index > expectedCount) continue;
    final text = match.group(2)!.trim();
    // First non-empty occurrence wins; later duplicates are ignored.
    if (text.isNotEmpty && (slots[index - 1] == null)) {
      slots[index - 1] = text;
    }
  }
  final result = <String>[];
  for (final slot in slots) {
    final value = slot;
    if (value == null || value.isEmpty) return null;
    result.add(value);
  }
  return result;
}

/// Translates [lines] in one LLM request. Returns null when the reply is not
/// parseable back to per-line translations (caller decides the fallback).
Future<List<String>?> translateLinesBatch({
  required LlmCapability llm,
  required List<String> lines,
  required String sourceLanguage,
  required String targetLanguage,
}) async {
  if (lines.isEmpty) return const [];
  final reply = await llm.generateText(
    systemPrompt: buildBatchTranslationSystemPrompt(
      sourceLanguage: workerLanguageBase(sourceLanguage),
      targetLanguage: workerLanguageBase(targetLanguage),
    ),
    userPrompt: buildBatchTranslationUserPrompt(lines),
    temperature: 0.3,
    // 20 subtitle lines of CJK output fits comfortably; a truncated reply
    // fails parsing and the caller falls back per line.
    maxTokens: 4096,
  );
  return parseBatchTranslationReply(reply, lines.length);
}
