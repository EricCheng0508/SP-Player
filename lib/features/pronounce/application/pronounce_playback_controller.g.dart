// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pronounce_playback_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PronouncePlaybackController)
final pronouncePlaybackControllerProvider =
    PronouncePlaybackControllerProvider._();

final class PronouncePlaybackControllerProvider
    extends
        $NotifierProvider<PronouncePlaybackController, PronouncePlaybackState> {
  PronouncePlaybackControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pronouncePlaybackControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pronouncePlaybackControllerHash();

  @$internal
  @override
  PronouncePlaybackController create() => PronouncePlaybackController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PronouncePlaybackState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PronouncePlaybackState>(value),
    );
  }
}

String _$pronouncePlaybackControllerHash() =>
    r'bed5b37e291e8ea31c3336a26d1eeff94236d686';

abstract class _$PronouncePlaybackController
    extends $Notifier<PronouncePlaybackState> {
  PronouncePlaybackState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<PronouncePlaybackState, PronouncePlaybackState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PronouncePlaybackState, PronouncePlaybackState>,
              PronouncePlaybackState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
