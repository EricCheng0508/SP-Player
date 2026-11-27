import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/ai/data/local_qwen_asr_capability.dart';

void main() {
  group('parseQwenAsrProgressEvent', () {
    test('parses stage and percent', () {
      final event = parseQwenAsrProgressEvent({
        'stage': 'asr',
        'percent': 62,
      });
      expect(event, isNotNull);
      expect(event!.stage, 'asr');
      expect(event.percent, 62);
    });

    test('clamps out-of-range percent', () {
      expect(parseQwenAsrProgressEvent({'stage': 'align', 'percent': 140})!.percent, 100);
      expect(parseQwenAsrProgressEvent({'stage': 'align', 'percent': -5})!.percent, 0);
    });

    test('returns null for malformed events', () {
      expect(parseQwenAsrProgressEvent({'percent': 50}), isNull);
      expect(parseQwenAsrProgressEvent({'stage': 'asr'}), isNull);
      expect(parseQwenAsrProgressEvent({'stage': 'asr', 'percent': 'x'}), isNull);
    });
  });
}
