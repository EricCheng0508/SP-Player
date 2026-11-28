import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/features/ai/application/ai_api_failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ApiException err(int statusCode, {Object? body, bool byokProvider = false}) =>
      ApiException(
        message: 'HTTP $statusCode',
        statusCode: statusCode,
        body: body,
        byokProvider: byokProvider,
      );

  group('mapApiExceptionToAppFailure', () {
    test('any 402 becomes ProviderBillingFailure', () {
      final failure = mapApiExceptionToAppFailure(
        err(
          402,
          body: {
            'error': 'credits_exhausted',
            'required': 750,
            'limit': {
              'used': 800,
              'limit': 1000,
              'resetAt': '2026-08-31T00:00:00.000Z',
            },
          },
        ),
      );

      expect(failure, isA<ProviderBillingFailure>());
    });

    test('BYOK provider 402 becomes ProviderBillingFailure', () {
      final failure = mapApiExceptionToAppFailure(
        err(402, body: {'error': 'insufficient_quota'}, byokProvider: true),
      );

      expect(failure, isA<ProviderBillingFailure>());
    });

    test('401 stays NetworkFailure with the status code attached', () {
      final failure = mapApiExceptionToAppFailure(err(401));
      expect(failure, isA<NetworkFailure>());
      expect((failure as NetworkFailure).statusCode, 401);
    });

    test('409 stays NetworkFailure at the AI seam (subscription-only)', () {
      expect(mapApiExceptionToAppFailure(err(409)), isA<NetworkFailure>());
    });

    test('5xx and unclassified statuses stay NetworkFailure', () {
      expect(mapApiExceptionToAppFailure(err(503)), isA<NetworkFailure>());
      final network = mapApiExceptionToAppFailure(err(429)) as NetworkFailure;
      expect(network.statusCode, 429);
    });
  });
}
