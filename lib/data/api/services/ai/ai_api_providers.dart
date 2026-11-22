/// Riverpod wiring for the remaining remote HTTP clients.
///
/// 本地版：Enjoy worker 的 chat / ASR / 翻译 / 词典 / Azure token / YouTube
/// 字幕缓存与 profile 下发 / 单词发音客户端已全部删除。这里只剩 YouTube
/// 频道 feed（discover 订阅，唯一仍依赖 worker 的功能）。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/data/api/api_client_provider.dart';
import 'package:enjoy_player/data/api/secure_token_store.dart';
import 'package:enjoy_player/data/api/services/ai/youtube_feed_api.dart';

final youtubeFeedClientProvider = Provider<YoutubeFeedClient>((ref) {
  final tokens = ref.watch(secureTokenStoreProvider);
  return YoutubeFeedClient(
    httpClient: ref.watch(httpClientProvider),
    getToken: tokens.readAccessToken,
  );
});
