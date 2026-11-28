/// App-wide locale and learner language prefs (Drift-backed).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';

export 'package:enjoy_player/core/application/app_language_catalog.dart'
    show kAppDefaultDisplayLocale;

part 'app_preferences_provider.g.dart';

final Logger _prefsLog = logNamed('prefs');

class AppPreferencesState {
  const AppPreferencesState({
    required this.locale,
    this.learningLanguage,
    this.nativeLanguage,
    this.themeMode = ThemeMode.system,
  });

  final Locale? locale;
  final String? learningLanguage;
  final String? nativeLanguage;

  /// Persisted appearance. Default [ThemeMode.system].
  final ThemeMode themeMode;

  static const initial = AppPreferencesState(
    locale: kAppDefaultDisplayLocale,
    learningLanguage: null,
    nativeLanguage: null,
    themeMode: ThemeMode.system,
  );

  String get effectiveLearningLanguage =>
      canonicalFocusLanguageTag(learningLanguage);

  /// Native tag for UX and APIs; never equals [effectiveLearningLanguage].
  String get effectiveNativeLanguage =>
      coerceNativeIfEqualsLearning(nativeLanguage, effectiveLearningLanguage);

  Locale get effectiveDisplayLocale => locale ?? kAppDefaultDisplayLocale;

  AppPreferencesState copyWith({
    Locale? locale,
    String? learningLanguage,
    String? nativeLanguage,
    ThemeMode? themeMode,
  }) {
    return AppPreferencesState(
      locale: locale ?? this.locale,
      learningLanguage: learningLanguage ?? this.learningLanguage,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppPreferencesState &&
          locale == other.locale &&
          learningLanguage == other.learningLanguage &&
          nativeLanguage == other.nativeLanguage &&
          themeMode == other.themeMode;

  @override
  int get hashCode =>
      Object.hash(locale, learningLanguage, nativeLanguage, themeMode);
}

ThemeMode themeModeFromStorage(String? raw) {
  switch (raw) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

String themeModeToStorage(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

@Riverpod(keepAlive: true)
class AppPreferencesCtrl extends _$AppPreferencesCtrl {
  @override
  Future<AppPreferencesState> build() async {
    final sw = Stopwatch()..start();
    _prefsLog.info('prefs: build start');

    final db = ref.watch(appDatabaseProvider);
    final stored = await db.settingsDao.readSettings([
      SettingsKeys.prefsLocale,
      SettingsKeys.prefsLearningLanguage,
      SettingsKeys.prefsNativeLanguage,
      SettingsKeys.prefsThemeMode,
    ]);
    var localeRaw = stored[SettingsKeys.prefsLocale.name];
    var learnRaw = stored[SettingsKeys.prefsLearningLanguage.name];
    var nativeRaw = stored[SettingsKeys.prefsNativeLanguage.name];
    final themeRaw = stored[SettingsKeys.prefsThemeMode.name];
    final themeMode = themeModeFromStorage(themeRaw);

    final learnCanonical = canonicalFocusLanguageTag(learnRaw);
    if (learnRaw == null || learnRaw.isEmpty || learnRaw != learnCanonical) {
      await db.settingsDao.writeSetting(
        SettingsKeys.prefsLearningLanguage,
        learnCanonical,
      );
      learnRaw = learnCanonical;
    }

    final nativeCoerced = coerceNativeIfEqualsLearning(
      nativeRaw,
      learnCanonical,
    );
    if (nativeRaw == null || nativeRaw.isEmpty || nativeRaw != nativeCoerced) {
      await db.settingsDao.writeSetting(
        SettingsKeys.prefsNativeLanguage,
        nativeCoerced,
      );
      nativeRaw = nativeCoerced;
    }

    final decodedLocale = displayLocaleFromRawOrDefault(localeRaw);
    final canonicalLocaleTag = localeToBcp47(decodedLocale);
    if (localeRaw == null ||
        localeRaw.isEmpty ||
        localeRaw != canonicalLocaleTag) {
      await db.settingsDao.writeSetting(
        SettingsKeys.prefsLocale,
        canonicalLocaleTag,
      );
      localeRaw = canonicalLocaleTag;
    }

    final out = AppPreferencesState(
      locale: decodedLocale,
      learningLanguage: learnCanonical,
      nativeLanguage: nativeCoerced,
      themeMode: themeMode,
    );

    _prefsLog.info('prefs: build done in ${sw.elapsedMilliseconds}ms');
    return out;
  }

  Future<void> setLocale(Locale? locale) async {
    final resolved = locale == null
        ? kAppDefaultDisplayLocale
        : displayLocaleFromRawOrDefault(localeToBcp47(locale));
    final next = (await future).copyWith(locale: resolved);
    state = AsyncData(next);
    final tag = localeToBcp47(resolved);
    await ref
        .read(appDatabaseProvider)
        .settingsDao
        .writeSetting(SettingsKeys.prefsLocale, tag);
  }

  Future<void> setLearningLanguage(String tag) async {
    final canonical = canonicalFocusLanguageTag(tag);
    if (!kSupportedFocusLanguageTags.any((t) => tagsEqual(t, canonical))) {
      _prefsLog.warning('prefs: rejected learning language tag: $tag');
      return;
    }
    final nativeCoerced = coerceNativeIfEqualsLearning(
      (await future).nativeLanguage,
      canonical,
    );
    final next = (await future).copyWith(
      learningLanguage: canonical,
      nativeLanguage: nativeCoerced,
    );
    state = AsyncData(next);
    final db = ref.read(appDatabaseProvider);
    await db.settingsDao.writeSetting(
      SettingsKeys.prefsLearningLanguage,
      canonical,
    );
    await db.settingsDao.writeSetting(
      SettingsKeys.prefsNativeLanguage,
      nativeCoerced,
    );
  }

  Future<void> setNativeLanguage(String tag) async {
    final learn = (await future).effectiveLearningLanguage;
    final allowed = allowedNativeTags(learn);
    if (!allowed.any((t) => tagsEqual(t, tag))) {
      _prefsLog.warning('prefs: rejected native language tag: $tag');
      return;
    }
    final canonical = allowed.firstWhere(
      (t) => tagsEqual(t, tag),
      orElse: () => tag,
    );
    if (tagsEqual(canonical, learn)) return;

    final next = (await future).copyWith(nativeLanguage: canonical);
    state = AsyncData(next);
    await ref
        .read(appDatabaseProvider)
        .settingsDao
        .writeSetting(SettingsKeys.prefsNativeLanguage, canonical);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final next = (await future).copyWith(themeMode: mode);
    state = AsyncData(next);
    await ref
        .read(appDatabaseProvider)
        .settingsDao
        .writeSetting(SettingsKeys.prefsThemeMode, themeModeToStorage(mode));
  }
}
