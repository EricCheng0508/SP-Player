/// Shared AI translation secondary text resolution helper.
///
/// Used by [TranscriptScrollableList] and [EchoRegionMergedCard] to avoid
/// duplicating the secondary text resolution logic.
library;

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_alignment.dart';
import 'package:enjoy_player/features/transcript/domain/auto_translate.dart';

String? resolveAutoTranslateTextForDisplay({
  required bool autoTranslateActive,
  required List<TranscriptLine> primaryLines,
  required List<TranscriptLine> aiLines,
  required int lineIndex,
  required String? sourceLanguage,
  required String? targetLanguage,
  required TranscriptSecondaryMatcher matcher,
  required TranscriptLine line,
}) {
  return autoTranslateActive
      ? resolveAutoTranslateSecondaryText(
          primaryLines: primaryLines,
          aiLines: aiLines,
          lineIndex: lineIndex,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
        )
      : matcher.match(line)?.text;
}
