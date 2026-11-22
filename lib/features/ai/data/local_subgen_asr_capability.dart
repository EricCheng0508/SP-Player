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
            '本地语音识别服务未启动:请先双击运行 D:\\Tool\\subgen\\start-asr-server.bat,'
            '等模型加载完成后点「重试识别」。',
        statusCode: 503,
      );
    }
    return AsrResult.fromJson(map);
  }
}
