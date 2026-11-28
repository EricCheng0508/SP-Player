/// 单词发音音频解析：有道音频地址 + 本地磁盘缓存。
///
/// 取代原来的 `POST {worker}/pronounce`：不再向 Enjoy 服务器发任何请求，
/// 也把自己的音频副本缓存在本地，听过的词离线可直接重播。
library;

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/features/pronounce/data/youdao_pronounce_source.dart';
import 'package:enjoy_player/features/pronounce/domain/pronounce_result.dart';

part 'pronounce_service.g.dart';

typedef PronounceHttpGet = Future<http.Response> Function(Uri uri);
typedef PronounceCacheDir = Future<Directory> Function();

final class PronounceService {
  PronounceService({PronounceHttpGet? httpGet, PronounceCacheDir? cacheDir})
    : _httpGet = httpGet ?? _defaultHttpGet,
      _cacheDir = cacheDir ?? _defaultCacheDir;

  static final _log = logNamed('Pronounce');

  static const _kCacheDirName = 'pronounce_audio';

  final PronounceHttpGet _httpGet;
  final PronounceCacheDir _cacheDir;

  static Future<http.Response> _defaultHttpGet(Uri uri) async {
    final client = http.Client();
    try {
      return await client.get(uri);
    } finally {
      client.close();
    }
  }

  static Future<Directory> _defaultCacheDir() async {
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, _kCacheDirName));
  }

  /// 解析（必要时下载并落盘）[text] 的发音音频。
  ///
  /// 返回的 [PronounceResult.audioSource] 通常是本地文件绝对路径。
  Future<PronounceResult> pronounce({
    required String text,
    required String locale,
  }) async {
    final uri = buildYoudaoAudioUri(text: text, resolvedLocale: locale);
    if (uri == null) {
      throw const NetworkFailure('该语言暂不支持发音');
    }

    final file = await _cacheFileFor(text: text, locale: locale);
    if (await file.exists()) {
      try {
        if (await file.length() > 0) {
          return PronounceResult(audioSource: file.path, fromCache: true);
        }
        // 空文件（上次写盘被中断）视作未缓存，重下。
        await file.delete();
      } on FileSystemException catch (e, st) {
        _log.info('pronounce cache probe failed for ${file.path}', e, st);
      }
    }

    final bytes = await _download(uri);

    try {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      return PronounceResult(audioSource: file.path, fromCache: true);
    } on Object catch (e, st) {
      // 写盘失败不该让发音失效：退回直接播放远程地址。
      _log.info('pronounce cache write failed for ${file.path}', e, st);
      return PronounceResult(audioSource: uri.toString(), fromCache: false);
    }
  }

  /// 缓存文件名：语种 + 文本的 SHA-1，避免非法字符和长度问题。
  Future<File> _cacheFileFor({
    required String text,
    required String locale,
  }) async {
    final dir = await _cacheDir();
    final key = sha1.convert('$locale\u0000${text.trim()}'.codeUnits);
    return File(p.join(dir.path, '$key.mp3'));
  }

  Future<List<int>> _download(Uri uri) async {
    http.Response response;
    try {
      response = await _httpGet(uri);
    } on Object catch (e, st) {
      _log.warning('pronounce download failed ${uri.host}', e, st);
      throw NetworkFailure('发音音频下载失败：$e');
    }

    if (response.statusCode != 200) {
      // 有道对「词库里没有这个词」返回 500，而不是 404。
      _log.info(
        'pronounce download HTTP ${response.statusCode} for ${uri.path}',
      );
      throw NetworkFailure(
        response.statusCode >= 500
            ? '该词没有发音音频'
            : '发音服务返回 HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final bytes = response.bodyBytes;
    if (bytes.isEmpty) {
      throw const NetworkFailure('发音音频为空');
    }
    return bytes;
  }
}

@Riverpod(keepAlive: true)
PronounceService pronounceService(Ref ref) => PronounceService();
