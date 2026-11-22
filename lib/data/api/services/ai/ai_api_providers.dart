/// Riverpod wiring for the remaining remote HTTP clients.
///
/// 本地版：Enjoy worker 的 chat / ASR / 翻译 / 词典 / Azure token 客户端已全部
/// 删除，这里只保留仍然需要的三组客户端。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/data/api/api_client_provider.dart';
import 'package:enjoy_player/data/api/secure_token_store.dart';
import 'package:enjoy_player/data/api/services/ai/pronounce_api.dart';
import 'package:enjoy_player/data/api/services/ai/youtube_feed_api.dart';
import 'package:enjoy_player/data/api/services/ai/youtube_transcripts_api.dart';

final pronounceApiProvider = Provider<PronounceApi>(
  (ref) => PronounceApi(ref.watch(aiApiClientProvider)),
);

final youtubeTranscriptsClientProvider = Provider<YoutubeTranscriptsClient>(
  (ref) => YoutubeTranscriptsApi(ref.watch(aiApiClientProvider)),
);

final youtubeFeedClientProvider = Provider<YoutubeFeedClient>((ref) {
  final tokens = ref.watch(secureTokenStoreProvider);
  return YoutubeFeedClient(
    httpClient: ref.watch(httpClientProvider),
    getToken: tokens.readAccessToken,
  );
});
