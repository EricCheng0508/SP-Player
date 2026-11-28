import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/features/ai/application/ai_call_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('runAiCall', () {
    test('returns the call result and runs onSuccess', () async {
      final consumed = <String>[];
      final result = await runAiCall<String>(
        logLabel: 'test',
        surface: 'Fetch',
        call: () async => 'value',
        onSuccess: consumed.add,
        onGeneric: (error, st) => 'generic',
      );
      expect(result, 'value');
      expect(consumed, ['value']);
    });

    test('routes errors to onGeneric', () async {
      final result = await runAiCall<String>(
        logLabel: 'test',
        surface: 'Fetch',
        call: () async => throw const NetworkFailure('boom'),
        onGeneric: (error, st) => 'generic:${error is NetworkFailure}',
      );
      expect(result, 'generic:true');
    });

    test('an onSuccess throw lands in onGeneric', () async {
      final result = await runAiCall<String>(
        logLabel: 'test',
        surface: 'Fetch',
        call: () async => 'value',
        onSuccess: (_) => throw const NetworkFailure('boom'),
        onGeneric: (error, st) => 'generic',
      );
      expect(result, 'generic');
    });
  });
}
