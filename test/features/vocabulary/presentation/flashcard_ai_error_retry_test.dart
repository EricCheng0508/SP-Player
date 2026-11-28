import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_ai_error.dart';
import 'package:enjoy_player/features/vocabulary/presentation/widgets/flashcard_ai_error_retry.dart';
import 'package:enjoy_player/features/vocabulary/presentation/widgets/flashcard_soft_error.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  Future<void> pumpSurface(
    WidgetTester tester, {
    required String? error,
    required VoidCallback onRetry,
  }) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FlashcardAiErrorRetry(
                error: error,
                onRetry: onRetry,
                retryLabel: l10n.vocabularyFetchDictionary,
              ),
            ),
          ),
        ),
      ],
    );

    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          colorScheme: scheme,
          extensions: [EnjoyThemeTokens.build(scheme)],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a failure shows the generic message without any CTA', (
    tester,
  ) async {
    await pumpSurface(
      tester,
      error: kVocabularyAiErrorFetchFailed,
      onRetry: () {},
    );

    expect(find.byType(FlashcardSoftError), findsOneWidget);
    expect(find.text(l10n.vocabularyAiFetchFailed), findsOneWidget);
    expect(find.text(l10n.subscriptionViewPlansAndPackages), findsNothing);
  });

  testWidgets('a null error shows only the retry action', (tester) async {
    await pumpSurface(tester, error: null, onRetry: () {});

    expect(find.byType(FlashcardSoftError), findsNothing);
    expect(find.text(l10n.subscriptionViewPlansAndPackages), findsNothing);
    expect(find.text(l10n.vocabularyFetchDictionary), findsOneWidget);
  });

  testWidgets('the retry button re-attempts the fetch', (tester) async {
    var retries = 0;
    await pumpSurface(
      tester,
      error: kVocabularyAiErrorFetchFailed,
      onRetry: () => retries++,
    );

    await tester.tap(find.text(l10n.vocabularyFetchDictionary));
    await tester.pump();

    expect(retries, 1);
  });
}
