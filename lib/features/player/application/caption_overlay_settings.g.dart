// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'caption_overlay_settings.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CaptionOverlaySettings)
final captionOverlaySettingsProvider = CaptionOverlaySettingsProvider._();

final class CaptionOverlaySettingsProvider
    extends $AsyncNotifierProvider<CaptionOverlaySettings, CaptionOverlayMode> {
  CaptionOverlaySettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'captionOverlaySettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$captionOverlaySettingsHash();

  @$internal
  @override
  CaptionOverlaySettings create() => CaptionOverlaySettings();
}

String _$captionOverlaySettingsHash() =>
    r'0df9f49fddf23968ea00d9a39aef183cddd3bb48';

abstract class _$CaptionOverlaySettings
    extends $AsyncNotifier<CaptionOverlayMode> {
  FutureOr<CaptionOverlayMode> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<CaptionOverlayMode>, CaptionOverlayMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CaptionOverlayMode>, CaptionOverlayMode>,
              AsyncValue<CaptionOverlayMode>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
