// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcript_search_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the search bar is shown above the transcript list.

@ProviderFor(TranscriptSearchOpen)
final transcriptSearchOpenProvider = TranscriptSearchOpenProvider._();

/// Whether the search bar is shown above the transcript list.
final class TranscriptSearchOpenProvider
    extends $NotifierProvider<TranscriptSearchOpen, bool> {
  /// Whether the search bar is shown above the transcript list.
  TranscriptSearchOpenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transcriptSearchOpenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transcriptSearchOpenHash();

  @$internal
  @override
  TranscriptSearchOpen create() => TranscriptSearchOpen();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$transcriptSearchOpenHash() =>
    r'3493fb728f7de2771f32773762be2d528ed04c7e';

/// Whether the search bar is shown above the transcript list.

abstract class _$TranscriptSearchOpen extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Current query; empty string hides the results list.

@ProviderFor(TranscriptSearchQuery)
final transcriptSearchQueryProvider = TranscriptSearchQueryProvider._();

/// Current query; empty string hides the results list.
final class TranscriptSearchQueryProvider
    extends $NotifierProvider<TranscriptSearchQuery, String> {
  /// Current query; empty string hides the results list.
  TranscriptSearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transcriptSearchQueryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transcriptSearchQueryHash();

  @$internal
  @override
  TranscriptSearchQuery create() => TranscriptSearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$transcriptSearchQueryHash() =>
    r'5bd9b51a5a3090443c8f6c2fd3b10b7206ba25ab';

/// Current query; empty string hides the results list.

abstract class _$TranscriptSearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
