import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFailure', () {
    test('toString returns the message verbatim', () {
      const failure = FileFailure('something went wrong');
      expect(failure.toString(), 'something went wrong');
    });

    test('sealed failure subclasses are recognized as AppFailure', () {
      final f = const FileFailure('x');
      final n = const NetworkFailure('q', statusCode: 503);
      final b = const ProviderBillingFailure('s');

      expect(f, isA<AppFailure>());
      expect(n, isA<AppFailure>());
      expect(b, isA<AppFailure>());
    });
  });

  group('FileFailure', () {
    test('carries message verbatim', () {
      const f = FileFailure('cannot open');
      expect(f.message, 'cannot open');
      expect(f.toString(), 'cannot open');
    });

    test('UnsupportedImportFileFailure has empty message', () {
      const u = UnsupportedImportFileFailure();
      expect(u.message, '');
      expect(u.toString(), '');
      expect(u, isA<AppFailure>());
    });
  });

  group('NetworkFailure', () {
    test('statusCode defaults to null when omitted', () {
      const n = NetworkFailure('boom');
      expect(n.statusCode, isNull);
    });

    test('statusCode is preserved when provided', () {
      const n = NetworkFailure('boom', statusCode: 503);
      expect(n.statusCode, 503);
    });

    test('HTTP 401 surfaces as a NetworkFailure carrying the status code', () {
      const n = NetworkFailure('HTTP 401', statusCode: 401);
      expect(n.statusCode, 401);
      expect(n, isA<AppFailure>());
    });
  });

  group('ProviderBillingFailure', () {
    test('carries message verbatim and is an AppFailure', () {
      const p = ProviderBillingFailure('provider declined');
      expect(p.message, 'provider declined');
      expect(p, isA<AppFailure>());
    });
  });
}
