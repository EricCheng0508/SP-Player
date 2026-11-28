/// Local-bundle default ASR: binds the bundled subgen transcription service
/// (`start-asr-server.bat`) so voice features work with zero configuration.
///
/// The service exposes an OpenAI-compatible `/v1/audio/transcriptions` on
/// `127.0.0.1:8000` running faster-whisper `large-v3-turbo` on GPU. When the service
/// is not running we surface an actionable message instead of a raw socket
/// error. Any explicit speech BYOK config in Settings overrides this default.
library;

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_whisper_client.dart';
import 'package:enjoy_player/features/ai/data/local_subgen_asr_service.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/asr_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

final Logger _log = logNamed('local.subgen');

final class LocalSubgenAsrCapability
    implements AsrCapability, AsrThroughputHint {
  LocalSubgenAsrCapability({http.Client? httpClient})
    : _httpClient = httpClient;

  static const baseUrl = 'http://127.0.0.1:8000/v1';
  static const model = 'large-v3-turbo';

  final http.Client? _httpClient;

  @override
  Future<double?> expectedRealtimeFactor() => localAsrRealtimeFactor();

  @override
  Future<AsrResult> transcribe(AsrRequest request) async {
    final watch = Stopwatch()..start();
    // 服务没跑就自动拉起并等就绪(冷启动含模型加载,最长 2 分钟)。
    try {
      await ensureLocalAsrService();
    } on Object catch (e) {
      _log.warning('ensureLocalAsrService failed: $e');
      throw const ApiException(
        message:
            '本地语音识别服务未能自动启动:请到「设置 → AI 提供商 → 语音服务」确认已安装识别组件,'
            '然后点「重试识别」。',
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
        language: request.language == null
            ? null
            : workerLanguageBase(request.language!),
        prompt: request.prompt,
        // 逐句 segments 需要 verbose_json(本地服务原生支持)。
        responseFormat: 'verbose_json',
        client: _httpClient,
      );
    } on http.ClientException catch (e) {
      _log.warning(
        'transcribe ClientException after ${watch.elapsedMilliseconds}ms: $e',
      );
      throw const ApiException(
        message:
            '本地语音识别服务连接失败:服务可能已退出,请到「设置 → AI 提供商 → 语音服务」检查,'
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
