/// 发音音频的解析结果（本地文件路径，或尚未缓存时的远程地址）。
library;

final class PronounceResult {
  const PronounceResult({required this.audioSource, required this.fromCache});

  /// 可直接交给播放引擎的地址：缓存命中时是本地文件绝对路径，
  /// 未命中且写盘失败时是远程 http(s) URL。
  final String audioSource;

  /// 音频是否来自本地磁盘缓存（已落盘、以后离线可听）。
  final bool fromCache;
}
