import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/pronounce/data/youdao_pronounce_source.dart';

void main() {
  group('buildYoudaoAudioUri', () {
    test('英语按变体选英音/美音', () {
      final us = buildYoudaoAudioUri(text: 'hello', resolvedLocale: 'en-US')!;
      expect(us.host, 'dict.youdao.com');
      expect(us.path, '/dictvoice');
      expect(us.queryParameters['audio'], 'hello');
      expect(us.queryParameters['type'], '2');
      expect(us.queryParameters.containsKey('le'), isFalse);

      final gb = buildYoudaoAudioUri(text: 'hello', resolvedLocale: 'en-GB')!;
      expect(gb.queryParameters['type'], '1');
    });

    test('其他语种用 le 参数', () {
      expect(
        buildYoudaoAudioUri(text: 'こんにちは', resolvedLocale: 'ja-JP')!
            .queryParameters['le'],
        'ja',
      );
      expect(
        buildYoudaoAudioUri(text: '안녕하세요', resolvedLocale: 'ko-KR')!
            .queryParameters['le'],
        'ko',
      );
      expect(
        buildYoudaoAudioUri(text: '你好', resolvedLocale: 'zh-CN')!
            .queryParameters['le'],
        'zh',
      );
      // 挪威语：有道只认 no，不认 nb。
      expect(
        buildYoudaoAudioUri(text: 'hei', resolvedLocale: 'nb-NO')!
            .queryParameters['le'],
        'no',
      );
      // 同主语言的不同地区变体共用一个 le。
      expect(
        buildYoudaoAudioUri(text: 'hola', resolvedLocale: 'es-MX')!
            .queryParameters['le'],
        'es',
      );
    });

    test('短语原样编码进 audio 参数', () {
      final uri = buildYoudaoAudioUri(
        text: 'take it easy',
        resolvedLocale: 'en-US',
      )!;
      expect(uri.queryParameters['audio'], 'take it easy');
    });

    test('空白文本返回 null', () {
      expect(buildYoudaoAudioUri(text: '   ', resolvedLocale: 'en-US'), isNull);
    });

    test('没有 le 映射的语种返回 null', () {
      expect(
        buildYoudaoAudioUri(text: 'xin chào', resolvedLocale: 'vi-VN'),
        isNull,
      );
    });
  });
}
