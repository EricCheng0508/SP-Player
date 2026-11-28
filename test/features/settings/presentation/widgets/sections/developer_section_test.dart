import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/sections/developer_section.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _host(GoRouter router) {
  return ProviderScope(
    child: MaterialApp.router(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

GoRouter _router({required String initial}) => GoRouter(
  initialLocation: initial,
  routes: [
    GoRoute(
      path: '/settings',
      builder: (_, _) => const Scaffold(body: DeveloperSectionBody()),
    ),
    GoRoute(
      path: '/settings/ai-playground',
      builder: (_, _) => const Scaffold(body: Text('ai-playground')),
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders a single AI playground row', (tester) async {
    final router = _router(initial: '/settings');
    addTearDown(router.dispose);

    await tester.pumpWidget(_host(router));
    await tester.pumpAndSettle();

    expect(find.byIcon(EnjoyIcons.lab), findsOneWidget);
    expect(find.text('AI playground'), findsOneWidget);
  });

  testWidgets('AI playground row pushes the playground route', (tester) async {
    final router = _router(initial: '/settings');
    addTearDown(router.dispose);

    await tester.pumpWidget(_host(router));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(EnjoyIcons.lab));
    await tester.pumpAndSettle();

    expect(find.text('ai-playground'), findsOneWidget);
  });
}
