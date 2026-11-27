/// Native-bundle Qwen ASR capability: talks to `sp-qwen-asr-server.exe`
/// (qwen3-asr-wgpu sidecar, ADR-0106) on `127.0.0.1:8010`.
///
/// English-primary engine (WER ≈ 8.9%, ~8× faster than large-v3-turbo, native
/// cold start). The sidecar answers with Whisper-style verbose JSON —
/// segments + word timestamps in seconds — so `AsrResult.fromJson` and the
/// timeline builder work unchanged. Falls back gracefully at the resolver
/// level ([local_qwen_asr_service] throws StateError when not installed).
library;

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_whisper_client.dart';
import 'package:enjoy_player/features/ai/data/local_qwen_asr_service.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/asr_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

final Logger _log = logNamed('local.qwen');

/// Parses one `GET /v1/progress` event (ADR-0106 §6 protocol). Pure —
/// unit-testable; unknown stages map to `null` so the UI can ignore them.
({String stage, int percent})? parseQwenAsrProgressEvent(
  Map<String, dynamic> json,
) {
  final stage = json['stage'] as String?;
  final percent = json['percent'];
  if (stage == null || percent is! num) return null;
  final clamped = percent.toInt().clamp(0, 100);
  return (stage: stage, percent: clamped);
}

final class LocalQwenAsrCapability implements AsrCapability {
  LocalQwenAsrCapability({http.Client? httpClient}) : _httpClient = httpClient;

  static const baseUrl = 'http://127.0.0.1:$kQwenAsrPort/v1';
  static const model = 'qwen3-asr-0.6b';

  final http.Client? _httpClient;

  @override
  Future<AsrResult> transcribe(AsrRequest request) async {
    final watch = Stopwatch()..start();
    try {
      await ensureQwenAsrService();
    } on Object catch (e) {
      _log.warning('ensureQwenAsrService failed: $e');
      throw const ApiException(
        message:
            '千问识别引擎未能自动启动:请到「设置 → 本地组件」确认已安装「千问识别运行时」和'
            '「千问识别模型」,然后点「重试识别」。',
        statusCode: 503,
      );
    }
    _log.info(
      'transcribe start: path=${request.audioPath} '
      'bytes=${request.audioBytes?.length} lang=${request.language}',
    );

    final Map<String, dynamic> map;
    try {
      map = await postWhisperTranscription(
        baseUrl: baseUrl,
        // 本地服务不校验 key;Bearer 头仅需非空。
        apiKey: 'local',
        audioBytes: request.audioBytes,
        audioPath: request.audioPath,
        filename: request.filename,
        model: model,
        language: request.language,
        // Qwen3-ASR has no initial_prompt mechanism; hotwords were dropped
        // from scope (ADR-0106 §6). Pass through silently when set.
        prompt: request.prompt,
        // Whisper-style verbose JSON keeps the timeline builder untouched.
        responseFormat: 'verbose_json',
        client: _httpClient,
      );
    } on http.ClientException catch (e) {
      _log.warning(
        'transcribe ClientException after ${watch.elapsedMilliseconds}ms: $e',
      );
      throw const ApiException(
        message:
            '千问识别引擎连接失败:服务可能已退出,请到「设置 → 本地组件」检查,'
            '然后点「重试识别」。',
        statusCode: 503,
      );
    }
    final segments = map['segments'];
    _log.info(
      'transcribe done in ${watch.elapsedMilliseconds}ms '
      'segments=${segments is List ? segments.length : '?'}',
    );
    return AsrResult.fromJson(map);
  }
}
