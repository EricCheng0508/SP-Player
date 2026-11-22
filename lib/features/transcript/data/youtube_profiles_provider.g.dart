// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'youtube_profiles_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 内置字幕抓取 profile 阶梯（按 [kPreferredCaptionClientOrder] 排好）。
///
/// 保留 `Future` 形状只是因为调用方按 `AsyncValue` 取用；这里不发起任何
/// 网络请求，直接完成。

@ProviderFor(youtubeProfiles)
final youtubeProfilesProvider = YoutubeProfilesProvider._();

/// 内置字幕抓取 profile 阶梯（按 [kPreferredCaptionClientOrder] 排好）。
///
/// 保留 `Future` 形状只是因为调用方按 `AsyncValue` 取用；这里不发起任何
/// 网络请求，直接完成。

final class YoutubeProfilesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ClientProfile>>,
          List<ClientProfile>,
          FutureOr<List<ClientProfile>>
        >
    with
        $FutureModifier<List<ClientProfile>>,
        $FutureProvider<List<ClientProfile>> {
  /// 内置字幕抓取 profile 阶梯（按 [kPreferredCaptionClientOrder] 排好）。
  ///
  /// 保留 `Future` 形状只是因为调用方按 `AsyncValue` 取用；这里不发起任何
  /// 网络请求，直接完成。
  YoutubeProfilesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'youtubeProfilesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$youtubeProfilesHash();

  @$internal
  @override
  $FutureProviderElement<List<ClientProfile>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ClientProfile>> create(Ref ref) {
    return youtubeProfiles(ref);
  }
}

String _$youtubeProfilesHash() => r'89b94d3122125d4aa572153a16848f666dffb59b';
