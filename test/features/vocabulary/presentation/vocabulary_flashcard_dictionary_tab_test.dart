import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_ai_error.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_explanation_codec.dart';
import 'package:enjoy_player/features/vocabulary/presentation/widgets/vocabulary_flashcard_dictionary_tab.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  testWidgets('auto-fetches dictionary when cache is empty', (tester) async {
    var fetchCount = 0;
    await tester.pumpWidget(
      _wrap(
        FlashcardDictionaryTab(
          explanation: null,
          fetchInFlight: false,
          error: null,
          onFetch: () => fetchCount++,
        ),
        overrides: const [],
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(fetchCount, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading…'), findsOneWidget);
    expect(find.text('Dictionary not available offline'), findsNothing);
    expect(find.text('Look up dictionary'), findsNothing);
  });

  testWidgets('shows loading while fetch is in flight', (tester) async {
    await tester.pumpWidget(
      _wrap(
        FlashcardDictionaryTab(
          explanation: null,
          fetchInFlight: true,
          error: null,
          onFetch: () {},
        ),
        overrides: const [],
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Look up dictionary'), findsNothing);
  });

  testWidgets('shows retry only after a failed fetch', (tester) async {
    var fetchCount = 0;
    await tester.pumpWidget(
      _wrap(
        FlashcardDictionaryTab(
          explanation: null,
          fetchInFlight: false,
          error: 'fetch_failed',
          onFetch: () => fetchCount++,
        ),
        overrides: const [],
      ),
    );
    await tester.pump();

    expect(find.text('Look up dictionary'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(fetchCount, 0);

    await tester.tap(find.text('Look up dictionary'));
    await tester.pump();
    expect(fetchCount, 1);
  });

  testWidgets('a failure shows the generic message and no CTA', (tester) async {
    await tester.pumpWidget(
      _wrap(
        FlashcardDictionaryTab(
          explanation: null,
          fetchInFlight: false,
          error: kVocabularyAiErrorFetchFailed,
          onFetch: () {},
        ),
        overrides: const [],
      ),
    );
    await tester.pump();

    expect(find.text(l10n.vocabularyAiFetchFailed), findsOneWidget);
    expect(find.text(l10n.subscriptionViewPlansAndPackages), findsNothing);
  });

  testWidgets('renders cached dictionary without fetching', (tester) async {
    var fetchCount = 0;
    final cached = encodeDictionaryExplanation(
      const DictionaryResult(
        word: 'hello',
        sourceLanguage: 'en',
        targetLanguage: 'zh',
        senses: [DictionarySense(definition: 'A greeting.', translation: '你好')],
      ),
    );
    await tester.pumpWidget(
      _wrap(
        FlashcardDictionaryTab(
          explanation: cached,
          fetchInFlight: false,
          error: null,
          onFetch: () => fetchCount++,
        ),
        overrides: const [],
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(fetchCount, 0);
    expect(find.text('A greeting.'), findsOneWidget);
    expect(find.text('你好'), findsOneWidget);
  });
}
