import 'package:enjoy_player/features/craft/domain/craft_failure.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:enjoy_player/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CraftFailure sealed hierarchy', () {
    test('CraftTranslateFailure uses retry and craftFailureTranslate', () {
      const f = CraftTranslateFailure();
      expect(f.action, CraftFailureAction.retry);
      expect(f.detail, isNull);
    });

    test('CraftTranslateFailure carries an optional detail', () {
      const f = CraftTranslateFailure(detail: 'http 500');
      expect(f.detail, 'http 500');
    });

    test('CraftTtsFailure defaults to retry', () {
      const f = CraftTtsFailure();
      expect(f.action, CraftFailureAction.retry);
      expect(f.detail, isNull);
    });

    test('CraftTtsFailure can be raised with openAiSettings', () {
      const f = CraftTtsFailure(action: CraftFailureAction.openAiSettings);
      expect(f.action, CraftFailureAction.openAiSettings);
    });

    test('CraftSaveFailure uses retry', () {
      const f = CraftSaveFailure(detail: 'disk full');
      expect(f.action, CraftFailureAction.retry);
      expect(f.detail, 'disk full');
    });

    test('CraftSignInRequiredFailure uses signIn', () {
      const f = CraftSignInRequiredFailure();
      expect(f.action, CraftFailureAction.signIn);
    });

    test('CraftOfflineFailure uses retry', () {
      const f = CraftOfflineFailure();
      expect(f.action, CraftFailureAction.retry);
    });

    test('CraftSameLanguageFailure uses switchToSpeakDirectly', () {
      const f = CraftSameLanguageFailure();
      expect(f.action, CraftFailureAction.switchToSpeakDirectly);
    });

    test('CraftVendorUnsupportedLanguageFailure carries a language', () {
      const f = CraftVendorUnsupportedLanguageFailure(language: 'fr');
      expect(f.action, CraftFailureAction.retry);
      expect(f.language, 'fr');
    });

    test('CraftAsrFailure uses retry', () {
      const f = CraftAsrFailure();
      expect(f.action, CraftFailureAction.retry);
    });

    test('CraftEmptyTranscriptFailure uses retry', () {
      const f = CraftEmptyTranscriptFailure();
      expect(f.action, CraftFailureAction.retry);
    });
  });

  group('CraftFailure.message()', () {
    late AppLocalizations l10n;

    setUpAll(() {
      l10n = AppLocalizationsEn();
    });

    test('every failure maps to a non-empty, non-raw-exception message', () {
      final failures = <CraftFailure>[
        const CraftTranslateFailure(),
        const CraftTtsFailure(),
        const CraftSaveFailure(),
        const CraftSignInRequiredFailure(),
        const CraftOfflineFailure(),
        const CraftSameLanguageFailure(),
        const CraftVendorUnsupportedLanguageFailure(language: 'fr'),
        const CraftAsrFailure(),
        const CraftEmptyTranscriptFailure(),
      ];

      for (final f in failures) {
        final msg = f.message(l10n);
        expect(msg, isNotEmpty, reason: 'failure=$f must have a message');
        expect(msg, isNot(contains('Exception')));
        expect(msg, isNot(contains('Error:')));
      }
    });

    test('CraftSameLanguageFailure uses the same-language hint string', () {
      const f = CraftSameLanguageFailure();
      expect(f.message(l10n), l10n.craftSameLanguageHint);
    });
  });
}
