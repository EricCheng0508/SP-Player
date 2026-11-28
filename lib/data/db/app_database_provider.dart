/// Provides [AppDatabase] for the single local session (no account system).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'package:enjoy_player/core/config/local_mode.dart';

import 'app_database.dart';
import 'settings_keys.dart';

part 'app_database_provider.g.dart';

/// The [AppDatabase] that owns [key], picked from the key's declared
/// [SettingsScope].
///
/// Single place mapping settings scope → database provider, so feature code
/// cannot hand a device-scoped key to the session database (or vice versa)
/// by accident. `SettingsDao`'s placement assert backstops direct DAO access
/// in debug builds.
AppDatabase settingsDatabaseFor(Ref ref, SettingKey<dynamic> key) {
  return key.scope == SettingsScope.device
      ? ref.watch(deviceGlobalAppDatabaseProvider)
      : ref.watch(appDatabaseProvider);
}

/// Process-wide device-global [AppDatabase] (`enjoy_player.sqlite`) — Drift
/// warns when two instances wrap the same `driftDatabase(name: …)` executor.
AppDatabase? _deviceGlobalDatabaseInstance;
int _deviceGlobalDatabaseRefCount = 0;

/// The single local session database instance (`enjoy_player_local.sqlite`).
AppDatabase? _localDatabaseInstance;

AppDatabase _acquireDeviceGlobalDatabase() {
  _deviceGlobalDatabaseRefCount++;
  return _deviceGlobalDatabaseInstance ??= AppDatabase(
    name: AppDatabase.deviceGlobalDatabaseName,
  );
}

Future<void> _releaseDeviceGlobalDatabase() async {
  if (_deviceGlobalDatabaseRefCount <= 0) return;
  _deviceGlobalDatabaseRefCount--;
}

/// Closes every open device-global / local [AppDatabase] and clears caches.
Future<void> closeAndClearAllAppDatabases() async {
  debugOnShutdownDatabaseClose?.call();
  _deviceGlobalDatabaseRefCount = 0;
  final deviceGlobal = _deviceGlobalDatabaseInstance;
  _deviceGlobalDatabaseInstance = null;
  final local = _localDatabaseInstance;
  _localDatabaseInstance = null;

  final toClose = <AppDatabase>{};
  if (deviceGlobal != null) toClose.add(deviceGlobal);
  if (local != null) toClose.add(local);

  for (final db in toClose) {
    try {
      await db.close();
    } on Object {} // ignore: empty_catches
  }
}

/// Test-only observer fired on every entry into [closeAndClearAllAppDatabases].
///
/// Lets regression tests for the app-shutdown lifecycle hook (see
/// `_EnjoyAppState.didChangeAppLifecycleState` in `lib/app.dart`) verify the
/// hook fires without having to plumb the singleton maps through a public
/// surface. Production callers leave this `null`.
@visibleForTesting
void Function()? debugOnShutdownDatabaseClose;

/// Drift file base name for the single local session.
String get _localSessionDbBaseName =>
    '${AppDatabase.deviceGlobalDatabaseName}_$kLocalSessionId';

/// Device-global Drift DB (`enjoy_player`) — diagnostics and other settings
/// that must be readable before the session DB exists (ADR-0012, ADR-0031).
@Riverpod(keepAlive: true)
AppDatabase deviceGlobalAppDatabase(Ref ref) {
  final db = _acquireDeviceGlobalDatabase();
  ref.onDispose(() {
    unawaited(_releaseDeviceGlobalDatabase());
  });
  return db;
}

/// Short-lived device-global DB access before [ProviderScope] exists (startup).
Future<T> withDeviceGlobalAppDatabaseForBootstrap<T>(
  Future<T> Function(AppDatabase db) run,
) async {
  final db = _acquireDeviceGlobalDatabase();
  try {
    return await run(db);
  } finally {
    await _releaseDeviceGlobalDatabase();
  }
}

/// Local library + prefs (`enjoy_player_local`) — the only session database
/// in the account-less build.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = _localDatabaseInstance ??= AppDatabase(
    name: _localSessionDbBaseName,
  );
  ref.onDispose(() {
    if (identical(_localDatabaseInstance, db)) {
      _localDatabaseInstance = null;
      unawaited(db.close());
    }
  });
  return db;
}
