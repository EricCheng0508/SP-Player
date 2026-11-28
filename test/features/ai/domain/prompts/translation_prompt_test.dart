import 'package:enjoy_player/features/ai/domain/prompts/translation_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildTranslationSystemPrompt', () {
    test('mentions source/target language base tags', () {
      final prompt = buildTranslationSystemPrompt(
        sourceLanguage: 'en',
        targetLanguage: 'zh',
      );
      expect(prompt, contains('en'));
      expect(prompt, contains('zh'));
    });

    test('asks for translation-only output', () {
      final prompt = buildTranslationSystemPrompt(
        sourceLanguage: 'fr',
        targetLanguage: 'de',
      );
      expect(prompt.toLowerCase(), contains('only the translated text'));
      expect(prompt.toLowerCase(), contains('no quotes'));
    });

    test('extracts BCP-47 base tag', () {
      final prompt = buildTranslationSystemPrompt(
        sourceLanguage: 'zh-CN',
        targetLanguage: 'en-US',
      );
      expect(prompt, contains('zh'));
      expect(prompt, contains('en'));
    });

    test('is deterministic', () {
      final a = buildTranslationSystemPrompt(
        sourceLanguage: 'en',
        targetLanguage: 'zh',
      );
      final b = buildTranslationSystemPrompt(
        sourceLanguage: 'en',
        targetLanguage: 'zh',
      );
      expect(a, b);
    });
  });

  group('buildTranslationUserPrompt', () {
    test('returns the text verbatim', () {
      expect(buildTranslationUserPrompt('bonjour'), 'bonjour');
    });

    test('preserves empty input', () {
      expect(buildTranslationUserPrompt(''), '');
    });

    test('preserves unicode', () {
      expect(buildTranslationUserPrompt('你好'), '你好');
    });

    test('preserves multi-line text', () {
      const multiline = 'line one\nline two\nline three';
      expect(buildTranslationUserPrompt(multiline), multiline);
    });
  });

  group('buildBatchTranslationUserPrompt', () {
    test('numbers every line with the n| prefix', () {
      final prompt = buildBatchTranslationUserPrompt(['Hello', 'World']);
      expect(prompt, '1|Hello\n2|World');
    });

    test('single line yields a single numbered entry', () {
      expect(buildBatchTranslationUserPrompt(['Hello']), '1|Hello');
    });
  });

  group('parseBatchTranslationOutput', () {
    test('maps numbered replies back by index', () {
      final parsed = parseBatchTranslationOutput('1|你好\n2|世界', 2);
      expect(parsed, ['你好', '世界']);
    });

    test('returns null for lines the model skipped', () {
      final parsed = parseBatchTranslationOutput('1|你好\n3|第三个', 3);
      expect(parsed, ['你好', null, '第三个']);
    });

    test('empty translation counts as skipped', () {
      final parsed = parseBatchTranslationOutput('1|\n2|世界', 2);
      expect(parsed, [null, '世界']);
    });

    test('ignores out-of-range and non-numbered noise', () {
      final parsed = parseBatchTranslationOutput(
        'Sure! Here you go:\n1|你好\n9|越界\n2|世界',
        2,
      );
      expect(parsed, ['你好', '世界']);
    });

    test('tolerates loose n. numbering', () {
      final parsed = parseBatchTranslationOutput('1. 你好\n2. 世界', 2);
      expect(parsed, ['你好', '世界']);
    });

    test('a single unnumbered reply is taken whole for one input line', () {
      expect(parseBatchTranslationOutput('你好', 1), ['你好']);
    });

    test('multi-line input with no numbering yields all nulls', () {
      expect(parseBatchTranslationOutput('你好\n世界', 2), [null, null]);
    });

    test('trims surrounding whitespace from replies', () {
      final parsed = parseBatchTranslationOutput('1|  你好  \n2|世界', 2);
      expect(parsed, ['你好', '世界']);
    });

    test('extracts a translation that itself contains a pipe', () {
      final parsed = parseBatchTranslationOutput('1|A|B\n2|世界', 2);
      expect(parsed, ['A|B', '世界']);
    });
  });

  group('batch constants', () {
    test('caps bound the reply far below typical output ceilings', () {
      expect(kAutoTranslateBatchMaxLines, lessThanOrEqualTo(32));
      expect(kAutoTranslateBatchMaxChars, lessThanOrEqualTo(2048));
    });
  });
}
