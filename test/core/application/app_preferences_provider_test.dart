import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _SettingsSelectCounter extends drift.QueryInterceptor {
  int selectCount = 0;
  int writeCount = 0;

  static final _settingsTable = RegExp(r'FROM\s+"?settings"?');
  static final _settingsWrite = RegExp(
    r'(?:INSERT|UPDATE)\b.*\bsettings\b',
    caseSensitive: false,
  );

  @override
  Future<List<Map<String, Object?>>> runSelect(
    drift.QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (_settingsTable.hasMatch(statement)) selectCount++;
    return executor.runSelect(statement, args);
  }

  @override
  Future<int> runInsert(
    drift.QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (_settingsWrite.hasMatch(statement)) writeCount++;
    return executor.runInsert(statement, args);
  }

  @override
  Future<int> runUpdate(
    drift.QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (_settingsWrite.hasMatch(statement)) writeCount++;
    return executor.runUpdate(statement, args);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('themeModeFromStorage', () {
    test('maps known values and defaults to system', () {
      expect(themeModeFromStorage('light'), ThemeMode.light);
      expect(themeModeFromStorage('dark'), ThemeMode.dark);
      expect(themeModeFromStorage('system'), ThemeMode.system);
      expect(themeModeFromStorage(null), ThemeMode.system);
      expect(themeModeFromStorage('nope'), ThemeMode.system);
    });

    test('themeModeToStorage round-trips', () {
      expect(themeModeToStorage(ThemeMode.light), 'light');
      expect(themeModeToStorage(ThemeMode.dark), 'dark');
      expect(themeModeToStorage(ThemeMode.system), 'system');
    });
  });

  group('AppPreferencesState', () {
    test('initial has default locale and null languages', () {
      const state = AppPreferencesState.initial;
      expect(state.locale, kAppDefaultDisplayLocale);
      expect(state.learningLanguage, isNull);
      expect(state.nativeLanguage, isNull);
    });

    group('effectiveLearningLanguage', () {
      test('returns canonical focus tag when learningLanguage is set', () {
        const state = AppPreferencesState(
          locale: Locale('en', 'US'),
          learningLanguage: 'ja-JP',
        );
        expect(state.effectiveLearningLanguage, 'ja-JP');
      });

      test('returns default when learningLanguage is null', () {
        const state = AppPreferencesState(locale: Locale('en', 'US'));
        expect(state.effectiveLearningLanguage, kDefaultLearningLanguageTag);
      });

      test('canonicalizes non-standard tags', () {
        const state = AppPreferencesState(
          locale: Locale('en', 'US'),
          learningLanguage: 'EN-us',
        );
        expect(state.effectiveLearningLanguage, 'en-US');
      });

      test('falls back to default for unsupported tags', () {
        const state = AppPreferencesState(
          locale: Locale('en', 'US'),
          learningLanguage: 'de-DE',
        );
        expect(state.effectiveLearningLanguage, kDefaultLearningLanguageTag);
      });
    });

    group('effectiveNativeLanguage', () {
      test('returns native when it differs from learning', () {
        const state = AppPreferencesState(
          locale: Locale('en', 'US'),
          learningLanguage: 'ja-JP',
          nativeLanguage: 'zh-CN',
        );
        expect(state.effectiveNativeLanguage, 'zh-CN');
      });

      test('coerces native when it equals learning', () {
        const state = AppPreferencesState(
          locale: Locale('en', 'US'),
          learningLanguage: 'en-US',
          nativeLanguage: 'en-US',
        );
        expect(state.effectiveNativeLanguage, isNot('en-US'));
        expect(
          kSupportedNativeLanguageTags,
          contains(state.effectiveNativeLanguage),
        );
      });

      test('coerces null native to a valid default', () {
        const state = AppPreferencesState(
          locale: Locale('en', 'US'),
          learningLanguage: 'ja-JP',
        );
        expect(
          kSupportedNativeLanguageTags,
          contains(state.effectiveNativeLanguage),
        );
      });
    });

    group('effectiveDisplayLocale', () {
      test('returns locale when set', () {
        const state = AppPreferencesState(locale: Locale('en', 'US'));
        expect(state.effectiveDisplayLocale, const Locale('en', 'US'));
      });

      test('returns default when locale is null', () {
        const state = AppPreferencesState(locale: null);
        expect(state.effectiveDisplayLocale, kAppDefaultDisplayLocale);
      });
    });

    group('copyWith', () {
      test('replaces locale', () {
        const state = AppPreferencesState(
          locale: Locale('en', 'US'),
          learningLanguage: 'ja-JP',
          nativeLanguage: 'zh-CN',
        );
        final next = state.copyWith(locale: const Locale('zh', 'CN'));
        expect(next.locale, const Locale('zh', 'CN'));
        expect(next.learningLanguage, 'ja-JP');
        expect(next.nativeLanguage, 'zh-CN');
      });

      test('replaces learningLanguage', () {
        const state = AppPreferencesState(
          locale: Locale('en', 'US'),
          learningLanguage: 'ja-JP',
          nativeLanguage: 'zh-CN',
        );
        final next = state.copyWith(learningLanguage: 'ko-KR');
        expect(next.learningLanguage, 'ko-KR');
        expect(next.locale, const Locale('en', 'US'));
        expect(next.nativeLanguage, 'zh-CN');
      });

      test('replaces nativeLanguage', () {
        const state = AppPreferencesState(
          locale: Locale('en', 'US'),
          learningLanguage: 'ja-JP',
          nativeLanguage: 'zh-CN',
        );
        final next = state.copyWith(nativeLanguage: 'en-US');
        expect(next.nativeLanguage, 'en-US');
        expect(next.locale, const Locale('en', 'US'));
        expect(next.learningLanguage, 'ja-JP');
      });

      test('preserves all fields when no arguments given', () {
        const state = AppPreferencesState(
          locale: Locale('en', 'US'),
          learningLanguage: 'ja-JP',
          nativeLanguage: 'zh-CN',
        );
        final next = state.copyWith();
        expect(next.locale, state.locale);
        expect(next.learningLanguage, state.learningLanguage);
        expect(next.nativeLanguage, state.nativeLanguage);
      });
    });
  });

  group('AppPreferencesCtrl', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    Future<ProviderContainer> localContainer({AppDatabase? database}) async {
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database ?? db)],
      );
      return container;
    }

    group('build', () {
      test('builds defaults from an empty local session DB', () async {
        final container = await localContainer();
        addTearDown(container.dispose);

        final state = await container.read(appPreferencesCtrlProvider.future);
        final learn = canonicalFocusLanguageTag(null);
        expect(state.locale, kAppDefaultDisplayLocale);
        expect(state.learningLanguage, learn);
        expect(state.nativeLanguage, coerceNativeIfEqualsLearning(null, learn));
        expect(state.themeMode, ThemeMode.system);
        expect(
          await db.settingsDao.getValue(
            SettingsKeys.prefsLearningLanguage.name,
          ),
          learn,
        );
      });

      test('reads and normalizes stored prefs', () async {
        await db.settingsDao.setValue(SettingsKeys.prefsLocale.name, 'en-US');
        await db.settingsDao.setValue(
          SettingsKeys.prefsLearningLanguage.name,
          'ja-JP',
        );
        await db.settingsDao.setValue(
          SettingsKeys.prefsNativeLanguage.name,
          'zh-CN',
        );

        final container = await localContainer();
        addTearDown(container.dispose);

        await container.read(appPreferencesCtrlProvider.future);
        await _pump();
        final settled = container.read(appPreferencesCtrlProvider).valueOrNull!;
        expect(settled.locale, const Locale('en', 'US'));
        expect(settled.learningLanguage, 'ja-JP');
        expect(settled.nativeLanguage, 'zh-CN');
      });

      test('reads stored theme mode', () async {
        await db.settingsDao.setValue(
          SettingsKeys.prefsThemeMode.name,
          'light',
        );

        final container = await localContainer();
        addTearDown(container.dispose);

        await container.read(appPreferencesCtrlProvider.future);
        await _pump();
        final settled = container.read(appPreferencesCtrlProvider).valueOrNull!;
        expect(settled.themeMode, ThemeMode.light);
      });

      test('canonicalizes non-standard learning language in DB', () async {
        await db.settingsDao.setValue(
          SettingsKeys.prefsLearningLanguage.name,
          'EN-us',
        );
        await db.settingsDao.setValue(
          SettingsKeys.prefsNativeLanguage.name,
          'zh-CN',
        );

        final container = await localContainer();
        addTearDown(container.dispose);

        await container.read(appPreferencesCtrlProvider.future);
        await _pump();

        final stored = await db.settingsDao.getValue(
          SettingsKeys.prefsLearningLanguage.name,
        );
        expect(stored, 'en-US');
      });

      test('coerces native language when it equals learning in DB', () async {
        await db.settingsDao.setValue(
          SettingsKeys.prefsLearningLanguage.name,
          'en-US',
        );
        await db.settingsDao.setValue(
          SettingsKeys.prefsNativeLanguage.name,
          'en-US',
        );

        final container = await localContainer();
        addTearDown(container.dispose);

        await container.read(appPreferencesCtrlProvider.future);
        await _pump();

        final stored = await db.settingsDao.getValue(
          SettingsKeys.prefsNativeLanguage.name,
        );
        expect(stored, isNot('en-US'));
        expect(kSupportedNativeLanguageTags, contains(stored));
      });

      test('defaults learning language when DB value is null', () async {
        final container = await localContainer();
        addTearDown(container.dispose);

        await container.read(appPreferencesCtrlProvider.future);
        await _pump();

        final state = container.read(appPreferencesCtrlProvider).valueOrNull!;
        expect(state.learningLanguage, kDefaultLearningLanguageTag);
      });

      test('defaults locale when DB value is null', () async {
        final container = await localContainer();
        addTearDown(container.dispose);

        await container.read(appPreferencesCtrlProvider.future);
        await _pump();

        final state = container.read(appPreferencesCtrlProvider).valueOrNull!;
        expect(state.locale, kAppDefaultDisplayLocale);
      });

      test('normalizes locale raw value in DB', () async {
        await db.settingsDao.setValue(SettingsKeys.prefsLocale.name, 'en');

        final container = await localContainer();
        addTearDown(container.dispose);

        await container.read(appPreferencesCtrlProvider.future);
        await _pump();

        final state = container.read(appPreferencesCtrlProvider).valueOrNull!;
        expect(state.locale, const Locale('en', 'US'));
      });

      test('falls back to default locale for unsupported raw value', () async {
        await db.settingsDao.setValue(SettingsKeys.prefsLocale.name, 'fr-FR');

        final container = await localContainer();
        addTearDown(container.dispose);

        await container.read(appPreferencesCtrlProvider.future);
        await _pump();

        final state = container.read(appPreferencesCtrlProvider).valueOrNull!;
        expect(state.locale, kAppDefaultDisplayLocale);
      });
    });

    group('startup settings read', () {
      test('reads the four preference settings with one query', () async {
        final counter = _SettingsSelectCounter();
        final countingDb = AppDatabase(
          executor: NativeDatabase.memory().interceptWith(counter),
        );
        addTearDown(countingDb.close);

        final container = await localContainer(database: countingDb);
        addTearDown(container.dispose);

        await container.read(appPreferencesCtrlProvider.future);
        await _pump();

        expect(counter.selectCount, 1);
      });

      test('the single query resolves every stored preference', () async {
        final counter = _SettingsSelectCounter();
        final countingDb = AppDatabase(
          executor: NativeDatabase.memory().interceptWith(counter),
        );
        addTearDown(countingDb.close);

        await countingDb.settingsDao.setValue(
          SettingsKeys.prefsLocale.name,
          'en-US',
        );
        await countingDb.settingsDao.setValue(
          SettingsKeys.prefsLearningLanguage.name,
          'ja-JP',
        );
        await countingDb.settingsDao.setValue(
          SettingsKeys.prefsNativeLanguage.name,
          'zh-CN',
        );
        await countingDb.settingsDao.setValue(
          SettingsKeys.prefsThemeMode.name,
          'light',
        );

        final container = await localContainer(database: countingDb);
        addTearDown(container.dispose);

        await container.read(appPreferencesCtrlProvider.future);
        await _pump();

        final state = container.read(appPreferencesCtrlProvider).valueOrNull!;
        expect(state.locale, const Locale('en', 'US'));
        expect(state.learningLanguage, 'ja-JP');
        expect(state.nativeLanguage, 'zh-CN');
        expect(state.themeMode, ThemeMode.light);
        expect(counter.selectCount, 1);
      });
    });

    group('setLocale', () {
      test('updates state and persists to DB', () async {
        final container = await localContainer();
        addTearDown(container.dispose);
        await container.read(appPreferencesCtrlProvider.future);
        await _pump();

        await container
            .read(appPreferencesCtrlProvider.notifier)
            .setLocale(const Locale('en', 'US'));

        final state = container.read(appPreferencesCtrlProvider).valueOrNull;
        expect(state!.locale, const Locale('en', 'US'));

        final stored = await db.settingsDao.getValue(
          SettingsKeys.prefsLocale.name,
        );
        expect(stored, 'en-US');
      });

      test('null locale resolves to default', () async {
        final container = await localContainer();
        addTearDown(container.dispose);
        await container.read(appPreferencesCtrlProvider.future);
        await _pump();

        await container
            .read(appPreferencesCtrlProvider.notifier)
            .setLocale(null);

        final state = container.read(appPreferencesCtrlProvider).valueOrNull;
        expect(state!.locale, kAppDefaultDisplayLocale);
      });

      test('unsupported locale resolves to default', () async {
        final container = await localContainer();
        addTearDown(container.dispose);
        await container.read(appPreferencesCtrlProvider.future);
        await _pump();

        await container
            .read(appPreferencesCtrlProvider.notifier)
            .setLocale(const Locale('fr', 'FR'));

        final state = container.read(appPreferencesCtrlProvider).valueOrNull;
        expect(state!.locale, kAppDefaultDisplayLocale);
      });
    });

    group('setLearningLanguage', () {
      test('updates state and persists canonical tag', () async {
        final container = await localContainer();
        addTearDown(container.dispose);
        await container.read(appPreferencesCtrlProvider.future);
        await _pump();

        await container
            .read(appPreferencesCtrlProvider.notifier)
            .setLearningLanguage('ko-KR');

        final state = container.read(appPreferencesCtrlProvider).valueOrNull;
        expect(state!.learningLanguage, 'ko-KR');

        final stored = await db.settingsDao.getValue(
          SettingsKeys.prefsLearningLanguage.name,
        );
        expect(stored, 'ko-KR');
      });

      test('rejects unsupported learning language tag', () async {
        final container = await localContainer();
        addTearDown(container.dispose);
        await container.read(appPreferencesCtrlProvider.future);
        await _pump();

        await container
            .read(appPreferencesCtrlProvider.notifier)
            .setLearningLanguage('de-DE');

        final state = container.read(appPreferencesCtrlProvider).valueOrNull;
        expect(state!.learningLanguage, isNot('de-DE'));
      });

      test('coerces native when it equals new learning language', () async {
        await db.settingsDao.setValue(
          SettingsKeys.prefsLearningLanguage.name,
          'ja-JP',
        );
        await db.settingsDao.setValue(
          SettingsKeys.prefsNativeLanguage.name,
          'en-US',
        );

        final container = await localContainer();
        addTearDown(container.dispose);
        await container.read(appPreferencesCtrlProvider.future);
        await _pump();

        await container
            .read(appPreferencesCtrlProvider.notifier)
            .setLearningLanguage('en-US');

        final state = container.read(appPreferencesCtrlProvider).valueOrNull;
        expect(state!.learningLanguage, 'en-US');
        expect(state.nativeLanguage, isNot('en-US'));
        expect(kSupportedNativeLanguageTags, contains(state.nativeLanguage));
      });

      test('persists coerced native language to DB', () async {
        await db.settingsDao.setValue(
          SettingsKeys.prefsLearningLanguage.name,
          'ja-JP',
        );
        await db.settingsDao.setValue(
          SettingsKeys.prefsNativeLanguage.name,
          'en-US',
        );

        final container = await localContainer();
        addTearDown(container.dispose);
        await container.read(appPreferencesCtrlProvider.future);
        await _pump();

        await container
            .read(appPreferencesCtrlProvider.notifier)
            .setLearningLanguage('en-US');

        final storedNative = await db.settingsDao.getValue(
          SettingsKeys.prefsNativeLanguage.name,
        );
        expect(storedNative, isNot('en-US'));
      });

      test('canonicalizes case-insensitive input', () async {
        final container = await localContainer();
        addTearDown(container.dispose);
        await container.read(appPreferencesCtrlProvider.future);
        await _pump();

        await container
            .read(appPreferencesCtrlProvider.notifier)
            .setLearningLanguage('JA-jp');

        final state = container.read(appPreferencesCtrlProvider).valueOrNull;
        expect(state!.learningLanguage, 'ja-JP');
      });
    });

    group('setNativeLanguage', () {
      test('updates state and persists to DB', () async {
        await db.settingsDao.setValue(
          SettingsKeys.prefsLearningLanguage.name,
          'ja-JP',
        );
        await db.settingsDao.setValue(
          SettingsKeys.prefsNativeLanguage.name,
          'zh-CN',
        );

        final container = await localContainer();
        addTearDown(container.dispose);
        await container.read(appPreferencesCtrlProvider.future);
        await _pump();

        await container
            .read(appPreferencesCtrlProvider.notifier)
            .setNativeLanguage('en-US');

        final state = container.read(appPreferencesCtrlProvider).valueOrNull;
        expect(state!.nativeLanguage, 'en-US');

        final stored = await db.settingsDao.getValue(
          SettingsKeys.prefsNativeLanguage.name,
        );
        expect(stored, 'en-US');
      });

      test('rejects tag not in allowed native tags', () async {
        await db.settingsDao.setValue(
          SettingsKeys.prefsLearningLanguage.name,
          'ja-JP',
        );
        await db.settingsDao.setValue(
          SettingsKeys.prefsNativeLanguage.name,
          'zh-CN',
        );

        final container = await localContainer();
        addTearDown(container.dispose);
        await container.read(appPreferencesCtrlProvider.future);
        await _pump();

        await container
            .read(appPreferencesCtrlProvider.notifier)
            .setNativeLanguage('ja-JP');

        final state = container.read(appPreferencesCtrlProvider).valueOrNull;
        expect(state!.nativeLanguage, 'zh-CN');
      });

      test('no-op when native equals learning language', () async {
        await db.settingsDao.setValue(
          SettingsKeys.prefsLearningLanguage.name,
          'en-US',
        );
        await db.settingsDao.setValue(
          SettingsKeys.prefsNativeLanguage.name,
          'zh-CN',
        );

        final container = await localContainer();
        addTearDown(container.dispose);
        await container.read(appPreferencesCtrlProvider.future);
        await _pump();

        await container
            .read(appPreferencesCtrlProvider.notifier)
            .setNativeLanguage('en-US');

        final state = container.read(appPreferencesCtrlProvider).valueOrNull;
        expect(state!.nativeLanguage, 'zh-CN');
      });
    });

    group('setThemeMode', () {
      test('persists light mode to the local session DB', () async {
        final container = await localContainer();
        addTearDown(container.dispose);
        await container.read(appPreferencesCtrlProvider.future);

        await container
            .read(appPreferencesCtrlProvider.notifier)
            .setThemeMode(ThemeMode.light);

        final state = container.read(appPreferencesCtrlProvider).valueOrNull;
        expect(state!.themeMode, ThemeMode.light);
        expect(
          await db.settingsDao.getValue(SettingsKeys.prefsThemeMode.name),
          'light',
        );
      });

      test('persists dark mode to the local session DB', () async {
        final container = await localContainer();
        addTearDown(container.dispose);
        await container.read(appPreferencesCtrlProvider.future);

        await container
            .read(appPreferencesCtrlProvider.notifier)
            .setThemeMode(ThemeMode.dark);

        final state = container.read(appPreferencesCtrlProvider).valueOrNull;
        expect(state!.themeMode, ThemeMode.dark);
        expect(
          await db.settingsDao.getValue(SettingsKeys.prefsThemeMode.name),
          'dark',
        );
      });
    });

    group('value equality & cold-start no-op', () {
      test('AppPreferencesState implements value equality and hashCode', () {
        const a = AppPreferencesState(
          locale: Locale('en', 'US'),
          learningLanguage: 'ja-JP',
          nativeLanguage: 'zh-CN',
          themeMode: ThemeMode.dark,
        );
        const b = AppPreferencesState(
          locale: Locale('en', 'US'),
          learningLanguage: 'ja-JP',
          nativeLanguage: 'zh-CN',
          themeMode: ThemeMode.dark,
        );
        const c = AppPreferencesState(
          locale: Locale('zh', 'CN'),
          learningLanguage: 'ja-JP',
          nativeLanguage: 'zh-CN',
          themeMode: ThemeMode.dark,
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
        expect(a, isNot(equals(c)));
      });

      test('cold-start build skips SQLite writes when stored prefs are already '
          'canonical', () async {
        final counter = _SettingsSelectCounter();
        final countedDb = AppDatabase(
          executor: NativeDatabase.memory().interceptWith(counter),
        );
        addTearDown(countedDb.close);

        await countedDb.settingsDao.setValue(
          SettingsKeys.prefsLocale.name,
          'en-US',
        );
        await countedDb.settingsDao.setValue(
          SettingsKeys.prefsLearningLanguage.name,
          'ja-JP',
        );
        await countedDb.settingsDao.setValue(
          SettingsKeys.prefsNativeLanguage.name,
          'zh-CN',
        );
        counter.writeCount = 0;

        final container = await localContainer(database: countedDb);
        addTearDown(container.dispose);

        var emissions = 0;
        final sub = container.listen(
          appPreferencesCtrlProvider,
          (_, _) => emissions++,
        );
        addTearDown(sub.close);

        await container.read(appPreferencesCtrlProvider.future);
        await _pump();

        expect(counter.writeCount, 0);
        expect(emissions, lessThanOrEqualTo(1));
      });
    });
  });
}
