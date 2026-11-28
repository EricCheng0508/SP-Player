/// URL guard for BYOK base URLs.
///
/// 允许 `http://` 与 `https://`，host 不做限制（含 localhost 与私网地址），
/// 这样才能接本机的 faster-whisper 服务或本地模型网关。
library;

bool isByokBaseUrlAllowed(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return false;

  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) return false;

  final scheme = uri.scheme.toLowerCase();
  return scheme == 'http' || scheme == 'https';
}
