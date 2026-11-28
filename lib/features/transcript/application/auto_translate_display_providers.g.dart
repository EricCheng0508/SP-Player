// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_translate_display_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the live secondary for [mediaId] is the AI translation track,
/// plus the source → target pair its lines render with — the derivation both
/// transcript hosts (the echo merged card and the scrollable list) previously
/// re-spelled field by field.
///
/// Languages come from the rows themselves (the pair the writes were keyed
/// with), not from current preferences, so a later native-language change
/// cannot mismatch stored source keys.

@ProviderFor(autoTranslateDisplayState)
final autoTranslateDisplayStateProvider = AutoTranslateDisplayStateFamily._();

/// Whether the live secondary for [mediaId] is the AI translation track,
/// plus the source → target pair its lines render with — the derivation both
/// transcript hosts (the echo merged card and the scrollable list) previously
/// re-spelled field by field.
///
/// Languages come from the rows themselves (the pair the writes were keyed
/// with), not from current preferences, so a later native-language change
/// cannot mismatch stored source keys.

final class AutoTranslateDisplayStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<
            ({bool active, String? sourceLanguage, String? targetLanguage})
          >,
          ({bool active, String? sourceLanguage, String? targetLanguage}),
          FutureOr<
            ({bool active, String? sourceLanguage, String? targetLanguage})
          >
        >
    with
        $FutureModifier<
          ({bool active, String? sourceLanguage, String? targetLanguage})
        >,
        $FutureProvider<
          ({bool active, String? sourceLanguage, String? targetLanguage})
        > {
  /// Whether the live secondary for [mediaId] is the AI translation track,
  /// plus the source → target pair its lines render with — the derivation both
  /// transcript hosts (the echo merged card and the scrollable list) previously
  /// re-spelled field by field.
  ///
  /// Languages come from the rows themselves (the pair the writes were keyed
  /// with), not from current preferences, so a later native-language change
  /// cannot mismatch stored source keys.
  AutoTranslateDisplayStateProvider._({
    required AutoTranslateDisplayStateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'autoTranslateDisplayStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$autoTranslateDisplayStateHash();

  @override
  String toString() {
    return r'autoTranslateDisplayStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<
    ({bool active, String? sourceLanguage, String? targetLanguage})
  >
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<({bool active, String? sourceLanguage, String? targetLanguage})>
  create(Ref ref) {
    final argument = this.argument as String;
    return autoTranslateDisplayState(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AutoTranslateDisplayStateProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$autoTranslateDisplayStateHash() =>
    r'543ee0c27503e8bb1b9afb8c96ecc0e40c51000e';

/// Whether the live secondary for [mediaId] is the AI translation track,
/// plus the source → target pair its lines render with — the derivation both
/// transcript hosts (the echo merged card and the scrollable list) previously
/// re-spelled field by field.
///
/// Languages come from the rows themselves (the pair the writes were keyed
/// with), not from current preferences, so a later native-language change
/// cannot mismatch stored source keys.

final class AutoTranslateDisplayStateFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<
            ({bool active, String? sourceLanguage, String? targetLanguage})
          >,
          String
        > {
  AutoTranslateDisplayStateFamily._()
    : super(
        retry: null,
        name: r'autoTranslateDisplayStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether the live secondary for [mediaId] is the AI translation track,
  /// plus the source → target pair its lines render with — the derivation both
  /// transcript hosts (the echo merged card and the scrollable list) previously
  /// re-spelled field by field.
  ///
  /// Languages come from the rows themselves (the pair the writes were keyed
  /// with), not from current preferences, so a later native-language change
  /// cannot mismatch stored source keys.

  AutoTranslateDisplayStateProvider call(String mediaId) =>
      AutoTranslateDisplayStateProvider._(argument: mediaId, from: this);

  @override
  String toString() => r'autoTranslateDisplayStateProvider';
}
