import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/domain/auto_translate.dart';
import 'package:enjoy_player/features/transcript/application/auto_translate_resolved_text.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_alignment.dart';
import 'package:flutter_test/flutter_test.dart';

TranscriptLine cue(
  int startMs,
  int durationMs,
  String text, {
  String? sourceKey,
}) {
  return TranscriptLine(
    text: text,
    startMs: startMs,
    durationMs: durationMs,
    sourceKey: sourceKey,
  );
}

String? callResolve({
  required bool autoTranslateActive,
  required List<TranscriptLine> primaryLines,
  required List<TranscriptLine> aiLines,
  required int lineIndex,
  String? sourceLanguage,
  String? targetLanguage,
  required TranscriptSecondaryMatcher matcher,
  required TranscriptLine line,
}) {
  return resolveAutoTranslateTextForDisplay(
    autoTranslateActive: autoTranslateActive,
    primaryLines: primaryLines,
    aiLines: aiLines,
    lineIndex: lineIndex,
    sourceLanguage: sourceLanguage,
    targetLanguage: targetLanguage,
    matcher: matcher,
    line: line,
  );
}

void main() {
  group('resolveAutoTranslateTextForDisplay', () {
    group('autoTranslateActive=false (echo / echo-match path)', () {
      test('falls back to matcher.match(line).text', () {
        final primary = [cue(0, 2000, 'hola')];
        final echoSecondary = [cue(500, 1500, 'hello world')];
        final matcher = TranscriptSecondaryMatcher.from(echoSecondary);
        final result = callResolve(
          autoTranslateActive: false,
          primaryLines: primary,
          aiLines: const [],
          lineIndex: 0,
          matcher: matcher,
          line: primary.first,
        );
        expect(result, 'hello world');
      });

      test('secondaryText is null when matcher returns null', () {
        final primary = [cue(0, 2000, 'hola')];
        final matcher = TranscriptSecondaryMatcher.from(const []);
        final result = callResolve(
          autoTranslateActive: false,
          primaryLines: primary,
          aiLines: const [],
          lineIndex: 0,
          matcher: matcher,
          line: primary.first,
        );
        expect(result, isNull);
      });
    });

    group('autoTranslateActive=true with sourceKey enforcement', () {
      test('returns ai text when sourceKey matches', () {
        final primary = [cue(0, 2000, 'hola')];
        const src = 'es';
        const tgt = 'en';
        final key = autoTranslateSourceKey(
          primaryText: 'hola',
          sourceLanguage: src,
          targetLanguage: tgt,
        );
        final ai = [cue(0, 2000, 'hello', sourceKey: key)];
        final matcher = TranscriptSecondaryMatcher.from(const []);
        final result = callResolve(
          autoTranslateActive: true,
          primaryLines: primary,
          aiLines: ai,
          lineIndex: 0,
          sourceLanguage: src,
          targetLanguage: tgt,
          matcher: matcher,
          line: primary.first,
        );
        expect(result, 'hello');
      });

      test('returns null when sourceKey mismatches (soft-stale)', () {
        final primary = [cue(0, 2000, 'hola')];
        final ai = [cue(0, 2000, 'hello', sourceKey: 'stale-key')];
        final matcher = TranscriptSecondaryMatcher.from(const []);
        final result = callResolve(
          autoTranslateActive: true,
          primaryLines: primary,
          aiLines: ai,
          lineIndex: 0,
          sourceLanguage: 'es',
          targetLanguage: 'en',
          matcher: matcher,
          line: primary.first,
        );
        expect(result, isNull);
      });

      test(
        'returns null when sourceLanguage provided but ai slot lacks sourceKey',
        () {
          final primary = [cue(0, 2000, 'hola')];
          final ai = [cue(0, 2000, 'hello')];
          final matcher = TranscriptSecondaryMatcher.from(const []);
          final result = callResolve(
            autoTranslateActive: true,
            primaryLines: primary,
            aiLines: ai,
            lineIndex: 0,
            sourceLanguage: 'es',
            targetLanguage: 'en',
            matcher: matcher,
            line: primary.first,
          );
          expect(result, isNull);
        },
      );

      test('skips sourceKey check when neither language is provided', () {
        final primary = [cue(0, 2000, 'hola')];
        final ai = [cue(0, 2000, 'hello')];
        final matcher = TranscriptSecondaryMatcher.from(const []);
        final result = callResolve(
          autoTranslateActive: true,
          primaryLines: primary,
          aiLines: ai,
          lineIndex: 0,
          matcher: matcher,
          line: primary.first,
        );
        expect(result, 'hello');
      });

      test(
        'skips sourceKey check when only one of the languages is provided',
        () {
          final primary = [cue(0, 2000, 'hola')];
          final ai = [cue(0, 2000, 'hello')];
          final matcher = TranscriptSecondaryMatcher.from(const []);
          final result = callResolve(
            autoTranslateActive: true,
            primaryLines: primary,
            aiLines: ai,
            lineIndex: 0,
            sourceLanguage: 'es',
            matcher: matcher,
            line: primary.first,
          );
          expect(result, 'hello');
        },
      );
    });

    group('bounds and empty text', () {
      test('returns null when lineIndex is out of primary range', () {
        final primary = [cue(0, 2000, 'a'), cue(2000, 2000, 'b')];
        final ai = [cue(0, 2000, 'A'), cue(2000, 2000, 'B')];
        final matcher = TranscriptSecondaryMatcher.from(const []);
        final result = callResolve(
          autoTranslateActive: true,
          primaryLines: primary,
          aiLines: ai,
          lineIndex: 5,
          matcher: matcher,
          line: primary.first,
        );
        expect(result, isNull);
      });

      test('returns null when aiLines shorter than lineIndex', () {
        final primary = [cue(0, 2000, 'a'), cue(2000, 2000, 'b')];
        final ai = [cue(0, 2000, 'A')];
        final matcher = TranscriptSecondaryMatcher.from(const []);
        final result = callResolve(
          autoTranslateActive: true,
          primaryLines: primary,
          aiLines: ai,
          lineIndex: 1,
          matcher: matcher,
          line: primary.last,
        );
        expect(result, isNull);
      });

      test('returns null when ai slot text is whitespace-only', () {
        final primary = [cue(0, 2000, 'hola')];
        final ai = [cue(0, 2000, '   ')];
        final matcher = TranscriptSecondaryMatcher.from(const []);
        final result = callResolve(
          autoTranslateActive: true,
          primaryLines: primary,
          aiLines: ai,
          lineIndex: 0,
          matcher: matcher,
          line: primary.first,
        );
        expect(result, isNull);
      });
    });
  });
}
