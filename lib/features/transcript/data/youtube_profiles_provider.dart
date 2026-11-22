/// YouTube InnerTube client profiles.
///
/// 本地版：原来会从 Enjoy worker 的 `GET /youtube/client-profiles` 拉取客户端
/// 版本号再与内置常量合并，现在远程下发整条链路已移除 —— 直接使用
/// [kBuiltInClientProfiles]。抓字幕是本机直连 `youtubei.googleapis.com`，
/// 这些 profile 只是用来伪装不同的 YouTube 客户端（IOS / ANDROID_VR /
/// MWEB / WEB）以规避风控。
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'client_profile.dart';

part 'youtube_profiles_provider.g.dart';

/// 内置字幕抓取 profile 阶梯（按 [kPreferredCaptionClientOrder] 排好）。
///
/// 保留 `Future` 形状只是因为调用方按 `AsyncValue` 取用；这里不发起任何
/// 网络请求，直接完成。
@Riverpod(keepAlive: true)
Future<List<ClientProfile>> youtubeProfiles(Ref ref) async =>
    resolveCaptionClientProfiles(const []);
