// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_captions_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LiveCaptionsController)
final liveCaptionsControllerProvider = LiveCaptionsControllerProvider._();

final class LiveCaptionsControllerProvider
    extends $NotifierProvider<LiveCaptionsController, LiveCaptionsState> {
  LiveCaptionsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveCaptionsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveCaptionsControllerHash();

  @$internal
  @override
  LiveCaptionsController create() => LiveCaptionsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LiveCaptionsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LiveCaptionsState>(value),
    );
  }
}

String _$liveCaptionsControllerHash() =>
    r'1648a8ec4e67fe0836d928e7839ef43972b84d31';

abstract class _$LiveCaptionsController extends $Notifier<LiveCaptionsState> {
  LiveCaptionsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LiveCaptionsState, LiveCaptionsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LiveCaptionsState, LiveCaptionsState>,
              LiveCaptionsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Saved sessions for the history rail (newest first).

@ProviderFor(LiveCaptionsHistory)
final liveCaptionsHistoryProvider = LiveCaptionsHistoryProvider._();

/// Saved sessions for the history rail (newest first).
final class LiveCaptionsHistoryProvider
    extends
        $AsyncNotifierProvider<LiveCaptionsHistory, List<LiveCaptionSession>> {
  /// Saved sessions for the history rail (newest first).
  LiveCaptionsHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveCaptionsHistoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveCaptionsHistoryHash();

  @$internal
  @override
  LiveCaptionsHistory create() => LiveCaptionsHistory();
}

String _$liveCaptionsHistoryHash() =>
    r'c8f018874148e0963298e253ff7b3c01e8e90300';

/// Saved sessions for the history rail (newest first).

abstract class _$LiveCaptionsHistory
    extends $AsyncNotifier<List<LiveCaptionSession>> {
  FutureOr<List<LiveCaptionSession>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<LiveCaptionSession>>,
              List<LiveCaptionSession>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<LiveCaptionSession>>,
                List<LiveCaptionSession>
              >,
              AsyncValue<List<LiveCaptionSession>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
