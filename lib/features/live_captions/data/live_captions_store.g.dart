// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_captions_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(liveCaptionsStore)
final liveCaptionsStoreProvider = LiveCaptionsStoreProvider._();

final class LiveCaptionsStoreProvider
    extends
        $FunctionalProvider<
          LiveCaptionsStore,
          LiveCaptionsStore,
          LiveCaptionsStore
        >
    with $Provider<LiveCaptionsStore> {
  LiveCaptionsStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveCaptionsStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveCaptionsStoreHash();

  @$internal
  @override
  $ProviderElement<LiveCaptionsStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LiveCaptionsStore create(Ref ref) {
    return liveCaptionsStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LiveCaptionsStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LiveCaptionsStore>(value),
    );
  }
}

String _$liveCaptionsStoreHash() => r'6cb2bc1f3710b6204f8c2291c77c563640830b56';
