// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'full_translate_ctrl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FullTranslateCtrl)
final fullTranslateCtrlProvider = FullTranslateCtrlFamily._();

final class FullTranslateCtrlProvider
    extends $NotifierProvider<FullTranslateCtrl, FullTranslateUiState> {
  FullTranslateCtrlProvider._({
    required FullTranslateCtrlFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fullTranslateCtrlProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fullTranslateCtrlHash();

  @override
  String toString() {
    return r'fullTranslateCtrlProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FullTranslateCtrl create() => FullTranslateCtrl();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FullTranslateUiState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FullTranslateUiState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FullTranslateCtrlProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fullTranslateCtrlHash() => r'4f3c7c0b175a56b1142ca6a70d8ec23206ac7e63';

final class FullTranslateCtrlFamily extends $Family
    with
        $ClassFamilyOverride<
          FullTranslateCtrl,
          FullTranslateUiState,
          FullTranslateUiState,
          FullTranslateUiState,
          String
        > {
  FullTranslateCtrlFamily._()
    : super(
        retry: null,
        name: r'fullTranslateCtrlProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FullTranslateCtrlProvider call(String mediaId) =>
      FullTranslateCtrlProvider._(argument: mediaId, from: this);

  @override
  String toString() => r'fullTranslateCtrlProvider';
}

abstract class _$FullTranslateCtrl extends $Notifier<FullTranslateUiState> {
  late final _$args = ref.$arg as String;
  String get mediaId => _$args;

  FullTranslateUiState build(String mediaId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FullTranslateUiState, FullTranslateUiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FullTranslateUiState, FullTranslateUiState>,
              FullTranslateUiState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
