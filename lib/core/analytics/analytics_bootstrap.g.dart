// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_bootstrap.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(analyticsInit)
final analyticsInitProvider = AnalyticsInitProvider._();

final class AnalyticsInitProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  AnalyticsInitProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsInitProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsInitHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return analyticsInit(ref);
  }
}

String _$analyticsInitHash() => r'5a9998b491b0f19fc9c0145d14e56487405bbed0';
