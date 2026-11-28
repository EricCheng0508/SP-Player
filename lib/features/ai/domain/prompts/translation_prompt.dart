/// Prompts for BYOK translation (aligned with Enjoy worker shapes).
library;

import 'package:enjoy_player/core/application/app_language_catalog.dart';

String buildTranslationSystemPrompt({
  required String sourceLanguage,
  required String targetLanguage,
}) {
  final source = workerLanguageBase(sourceLanguage);
  final target = workerLanguageBase(targetLanguage);
  return 'You are a professional translator. Translate text from $source to $target. '
      'Reply with only the translated text — no quotes, labels, or explanation.';
}

String buildTranslationUserPrompt(String text) => text;

/// Max lines accepted in one batched translation call.
const kAutoTranslateBatchMaxLines = 24;

/// Max total input characters per batched call — bounds the reply size so a
/// screenful of cues cannot hit the output token ceiling mid-batch.
const kAutoTranslateBatchMaxChars = 1600;

/// Output token ceiling for one batched call.
const kAutoTranslateBatchMaxTokens = 4096;

/// Numbered-list system prompt for batched transcript translation.
String buildBatchTranslationSystemPrompt({
  required String sourceLanguage,
  required String targetLanguage,
}) {
  final source = workerLanguageBase(sourceLanguage);
  final target = workerLanguageBase(targetLanguage);
  return 'You are a professional translator. Translate each numbered line '
      'from $source to $target. The lines come from the same transcript, so '
      'use the surrounding lines as context. Reply with ONLY the numbered '
      'lines in the same format — "<n>|<translation>" — keeping the same '
      'numbering, one reply line per input line, same order. Never merge, '
      'split, skip, or reorder lines. No quotes, labels, or explanation.';
}

/// Numbered-list user prompt: one `n|line` entry per source line.
String buildBatchTranslationUserPrompt(List<String> lines) {
  final buffer = StringBuffer();
  for (var i = 0; i < lines.length; i++) {
    buffer.writeln('${i + 1}|${lines[i]}');
  }
  return buffer.toString().trimRight();
}

final RegExp _numberedPipe = RegExp(r'^\s*(\d{1,4})\s*[|]\s?(.*)$');
final RegExp _numberedLoose = RegExp(r'^\s*(\d{1,4})\s*[.)\]]\s+(.+)$');

/// Parses numbered batch output back to per-line translations.
///
/// Index [i] of the result corresponds to input line `i+1`; it is `null`
/// when the model skipped or emptied that line, so the caller can fall back
/// to a single-line call. With a single input line and no numbering found,
/// the whole output is taken as that line's translation.
List<String?> parseBatchTranslationOutput(String raw, int lineCount) {
  final result = List<String?>.filled(lineCount, null);
  var numbered = 0;
  for (final line in raw.split('\n')) {
    final match =
        _numberedPipe.firstMatch(line) ?? _numberedLoose.firstMatch(line);
    if (match == null) continue;
    final n = int.tryParse(match.group(1)!);
    if (n == null || n < 1 || n > lineCount) continue;
    final text = (match.group(2) ?? '').trim();
    result[n - 1] = text.isEmpty ? null : text;
    numbered++;
  }
  if (numbered == 0 && lineCount == 1) {
    final single = raw.trim();
    return [single.isEmpty ? null : single];
  }
  return result;
}
