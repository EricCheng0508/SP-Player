import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/ai/data/byok/batch_translation.dart';

void main() {
  group('buildBatchTranslationUserPrompt', () {
    test('numbers every line', () {
      final prompt = buildBatchTranslationUserPrompt(['Hey!', 'Wake up.']);
      expect(prompt, '1. Hey!\n2. Wake up.');
    });

    test('trims each line', () {
      final prompt = buildBatchTranslationUserPrompt(['  hey  ']);
      expect(prompt, '1. hey');
    });
  });

  group('parseBatchTranslationReply', () {
    test('maps numbered reply back to lines', () {
      final parsed = parseBatchTranslationReply(
        '1. 嘿嘿嘿！醒醒！\n2. 我一点也不怀念 Tegrity。\n3. 住手。',
        3,
      );
      expect(parsed, ['嘿嘿嘿！醒醒！', '我一点也不怀念 Tegrity。', '住手。']);
    });

    test('tolerates blank lines and missing trailing lines order', () {
      final parsed = parseBatchTranslationReply(
        '\n2. 乙\n\n1. 甲\n',
        2,
      );
      expect(parsed, ['甲', '乙']);
    });

    test('accepts CJK and paren numbering variants', () {
      final parsed = parseBatchTranslationReply('1、甲\n2）乙', 2);
      expect(parsed, ['甲', '乙']);
    });

    test('returns null when a line is missing', () {
      final parsed = parseBatchTranslationReply('1. 甲\n3. 丙', 3);
      expect(parsed, isNull);
    });

    test('returns null when a mapped line is empty', () {
      final parsed = parseBatchTranslationReply('1. 甲\n2. ', 2);
      expect(parsed, isNull);
    });

    test('returns null for garbage without numbering', () {
      expect(parseBatchTranslationReply('no numbering at all', 1), isNull);
    });

    test('ignores out-of-range numbering', () {
      final parsed = parseBatchTranslationReply('1. 甲\n9. 越界', 1);
      expect(parsed, ['甲']);
    });

    test('empty expected count returns null', () {
      expect(parseBatchTranslationReply('1. 甲', 0), isNull);
    });
  });
}
