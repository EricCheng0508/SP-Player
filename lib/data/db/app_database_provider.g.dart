// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Device-global Drift DB (`enjoy_player`) — diagnostics and other settings
/// that must be readable before the session DB exists (ADR-0012, ADR-0031).

@ProviderFor(deviceGlobalAppDatabase)
final deviceGlobalAppDatabaseProvider = DeviceGlobalAppDatabaseProvider._();

/// Device-global Drift DB (`enjoy_player`) — diagnostics and other settings
/// that must be readable before the session DB exists (ADR-0012, ADR-0031).

final class DeviceGlobalAppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// Device-global Drift DB (`enjoy_player`) — diagnostics and other settings
  /// that must be readable before the session DB exists (ADR-0012, ADR-0031).
  DeviceGlobalAppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceGlobalAppDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceGlobalAppDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return deviceGlobalAppDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$deviceGlobalAppDatabaseHash() =>
    r'86a373429642aeb371e25fd31d82629a0bef6491';

/// Local library + prefs (`enjoy_player_local`) — the only session database
/// in the account-less build.

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// Local library + prefs (`enjoy_player_local`) — the only session database
/// in the account-less build.

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// Local library + prefs (`enjoy_player_local`) — the only session database
  /// in the account-less build.
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'bba216cf0ec3c3fec415df723f3a8e8d3cefdf07';
