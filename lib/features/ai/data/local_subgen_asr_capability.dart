/// Local-bundle default ASR: binds the bundled subgen transcription service
/// (`start-asr-server.bat`) so voice features work with zero configuration.
///
/// The service exposes an OpenAI-compatible `/v1/audio/transcriptions` on
/// `127.0.0.1:8000` running faster-whisper `large-v3` on GPU. When the service
/// is not running we surface an actionable message instead of a raw socket
/// error. Any explicit speech BYOK config in Settings overrides this default.
library;

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_whisper_client.dart';
import 'package:enjoy_player/features/ai/data/local_subgen_asr_service.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/asr_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';
import 'package:http/http.dart' as http;

final class LocalSubgenAsrCapability implements AsrCapability {
  LocalSubgenAsrCapability({http.Client? httpClient}) : _httpClient = httpClient;

  static const baseUrl = 'http://127.0.0.1:8000/v1';
  static const model = 'large-v3';

  final http.Client? _httpClient;

  @override
  Future<AsrResult> transcribe(AsrRequest request) async {
    // 服务没跑就自动拉起并等就绪(冷启动含模型加载,最长 2 分钟)。
    try {
      await ensureLocalAsrService();
    } on Object {
      throw const ApiException(
        message:
            '本地语音识别服务未能自动启动:请手动双击运行 D:\\Tool\\subgen\\start-asr-server.bat '
            '并确认报错信息,然后点「重试识别」。',
        statusCode: 503,
      );
    }

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
        language: request.language == null
            ? null
            : workerLanguageBase(request.language!),
        prompt: request.prompt,
        // 逐句 segments 需要 verbose_json(本地服务原生支持)。
        responseFormat: 'verbose_json',
        client: _httpClient,
      );
    } on http.ClientException {
      throw const ApiException(
        message:
            '本地语音识别服务连接失败:请确认 D:\\Tool\\subgen\\start-asr-server.bat '
            '窗口仍在运行,然后点「重试识别」。',
        statusCode: 503,
      );
    }
    return AsrResult.fromJson(map);
  }
}
