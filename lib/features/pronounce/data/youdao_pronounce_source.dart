/// 有道词典发音音频地址构造（本地替代 Enjoy worker 的 `POST /pronounce`）。
///
/// 原实现把「单词文本 + 语种」发给 `worker.enjoy.bot/pronounce`，由 worker
/// 合成音频、放到它自己的 CDN，再返回一个 `audio_url`。这里改成直接拼有道
/// 词典网页版自用的发音地址，本机 GET 即得 mp3：
///
///   `https://dict.youdao.com/dictvoice?audio=word&type=2`   (英语：1=英音 2=美音)
///   `https://dict.youdao.com/dictvoice?audio=word&le=ja`    (其他语种)
///
/// 语种覆盖与 [kPronounceSupportedLocales]（15 个 tag）逐项实测对齐；
/// 没有对应 `le` 的语种返回 `null`，调用方据此禁用发音按钮。
library;

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/application/language_descriptor.dart';

/// BCP47 主语言 → 有道 `le` 参数。
///
/// 只收录实测返回 `200 audio/mpeg` 的值。挪威语必须用 `no`——
/// `le=nb` 会返回 HTTP 451（有道不认这个 subtag）。
const Map<String, String> kYoudaoLeByPrimary = {
  'zh': 'zh',
  'ja': 'ja',
  'ko': 'ko',
  'es': 'es',
  'fr': 'fr',
  'de': 'de',
  'it': 'it',
  'pt': 'pt',
  'ru': 'ru',
  'nb': 'no',
};

/// 有道的发音音频地址；该语种无对应实现时返回 `null`。
///
/// [resolvedLocale] 应当是 [resolvePronounceLocale] 的输出（如 `en-GB`）。
Uri? buildYoudaoAudioUri({
  required String text,
  required String resolvedLocale,
}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;

  final primary = primaryLanguageSubtag(resolvedLocale);
  if (primary.isEmpty) return null;

  if (primary == 'en') {
    // 英音 / 美音；其余英语变体（含 en-US 本身）默认美音。
    final isBritish = tagsEqual(resolvedLocale, 'en-GB');
    return Uri.https('dict.youdao.com', '/dictvoice', {
      'audio': trimmed,
      'type': isBritish ? '1' : '2',
    });
  }

  final le = kYoudaoLeByPrimary[primary];
  if (le == null) return null;
  return Uri.https('dict.youdao.com', '/dictvoice', {
    'audio': trimmed,
    'le': le,
  });
}
