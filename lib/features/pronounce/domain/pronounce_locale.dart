/// Map app language tags → pronounce locales.
///
/// 本地版：发音音频由 `buildYoudaoAudioUri` 直接指向有道词典，不再有远端
/// worker 的语种白名单。这里的集合只决定「哪些语种的喇叭按钮可用」。
library;

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/application/language_descriptor.dart';

/// 可发音语种 —— 描述表里 `pronounce: true` 的行。
///
/// 与 [kYoudaoLeByPrimary] 的覆盖范围一致（英语走 `type=1/2`，其余走 `le`）。
/// 描述表新增发音语种时，需同时确认有道有对应的 `le`，否则按钮亮了却拿不到
/// 音频。
final Set<String> kPronounceSupportedLocales = <String>{
  for (final row in kLanguageDescriptorRows)
    if (row.pronounce) row.tag,
};

/// 裸语种 / 未知地区 → 该主语言的默认地区变体。
///
/// 生词与录音常只存 ISO 639-1 主体码（`ja`、`zh`）。绝不跨主语言回退。
final Map<String, String> kPronounceDefaultLocaleByPrimary = firstTagPerPrimary(
  kLanguageDescriptorRows.where((row) => row.pronounce),
);

const int kPronounceMaxChars = 200;

/// 把 [tag] 解析为可发音语种，不支持时返回 `null`。
///
/// - `en-UK` → `en-GB`
/// - bare / other `en*` (not GB/UK) → `en-US`
/// - exact allowlist match for remaining tags
/// - bare primary (`ja`, `zh`, …) or unknown region → primary default when
///   that default is allowlisted
String? resolvePronounceLocale(String? tag) {
  if (tag == null || tag.trim().isEmpty) return null;
  final normalized = normalizeBcp47Tag(normalizeLanguageAlias(tag.trim()));
  if (normalized.isEmpty) return null;
  if (!isValidLanguageTag(normalized)) return null;

  if (normalized == 'en-UK' || tagsEqual(normalized, 'en-GB')) {
    return 'en-GB';
  }

  for (final supported in kPronounceSupportedLocales) {
    if (tagsEqual(normalized, supported)) return supported;
  }

  final primary = primaryLanguageSubtag(normalized);
  if (primary == 'en') {
    return 'en-US';
  }

  final byPrimary = kPronounceDefaultLocaleByPrimary[primary];
  if (byPrimary != null && kPronounceSupportedLocales.contains(byPrimary)) {
    return byPrimary;
  }
  return null;
}

/// Whether [text] is eligible for a pronounce request (after trim).
bool isPronounceTextEligible(String text) {
  final t = text.trim();
  return t.isNotEmpty && t.length <= kPronounceMaxChars;
}
