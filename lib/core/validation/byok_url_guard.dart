/// URL guard for BYOK base URLs.
///
/// 上游只允许 https 公网地址；本地离线模式（[kLocalOfflineMode]）下额外
/// 允许 `http://` 和 localhost / 私网地址，这样才能接本机的
/// faster-whisper 服务或本地模型网关。
library;

import 'package:enjoy_player/core/config/local_mode.dart';

bool isByokBaseUrlAllowed(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return false;

  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) return false;

  final scheme = uri.scheme.toLowerCase();

  if (kLocalOfflineMode) {
    // 本地模式：http/https 都放行，host 不做限制（含 127.0.0.1 与局域网）。
    return scheme == 'http' || scheme == 'https';
  }

  if (scheme != 'https') return false;

  final host = uri.host.toLowerCase();
  if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
    return false;
  }

  if (_isPrivateIpv4(host)) return false;

  return true;
}

bool _isPrivateIpv4(String host) {
  final parts = host.split('.');
  if (parts.length != 4) return false;

  final octets = <int>[];
  for (final part in parts) {
    final value = int.tryParse(part);
    if (value == null || value < 0 || value > 255) return false;
    octets.add(value);
  }

  if (octets[0] == 10) return true;
  if (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) return true;
  if (octets[0] == 192 && octets[1] == 168) return true;

  return false;
}
