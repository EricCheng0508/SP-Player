/// Local-bundle default pronunciation assessment: transcribes the take with
/// the bundled faster-whisper service (word timestamps) and scores it by
/// sequence-aligning the recognized words against the reference sentence.
///
/// Zero configuration — same auto-start contract as the ASR default
/// (`LocalSubgenAsrCapability`). Output is Azure-shaped JSON so the existing
/// assessment UI, storage, and score display work unchanged. When the user
/// explicitly configures Azure Speech in settings, `ByokAssessmentAzureCapability`
/// takes precedence (phoneme-level diagnosis) and this pipeline is unused.
library;

import 'package:azure_speech/azure_speech.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/features/ai/data/local/local_assessment_scoring.dart';
import 'package:enjoy_player/features/ai/data/local_subgen_asr_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/assessment_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_request.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_result.dart';

final Logger _log = logNamed('local.assessment');

final class LocalAssessmentCapability implements AssessmentCapability {
  LocalAssessmentCapability({http.Client? httpClient})
    : _asr = LocalSubgenAsrCapability(httpClient: httpClient);

  final LocalSubgenAsrCapability _asr;

  @override
  Future<AssessmentResult> assess(AssessmentRequest request) async {
    final asr = await _asr.transcribe(
      AsrRequest(
        audioBytes: request.audioBytes,
        audioPath: request.audioPath,
        // LocalSubgenAsrCapability strips the region ("en-US" → "en").
        language: request.language,
        filename: 'assessment-take.wav',
        // 逐词时间戳需要 verbose_json(本地服务原生支持)。
        responseFormat: 'verbose_json',
      ),
    );

    final spoken = <({String word, int startMs, int endMs})>[];
    for (final seg in asr.segments ?? const <AsrSegment>[]) {
      final words = seg.words;
      if (words == null || words.isEmpty) {
        // 没有词级时间戳的 segment 整段按平铺文本处理(无时间信息)。
        for (final w in splitReferenceWords(seg.text)) {
          spoken.add((word: w, startMs: 0, endMs: 0));
        }
        continue;
      }
      for (final w in words) {
        final text = w.word.trim();
        if (text.isEmpty) continue;
        spoken.add((
          word: text,
          startMs: (w.start * 1000).round(),
          endMs: (w.end * 1000).round(),
        ));
      }
    }
    if (spoken.isEmpty) {
      spoken.addAll(
        splitReferenceWords(
          asr.text,
        ).map((w) => (word: w, startMs: 0, endMs: 0)),
      );
    }

    final alignment = assessLocalPronunciation(
      referenceWords: splitReferenceWords(request.referenceText),
      spokenWords: spoken,
    );
    _log.info(
      'local assessment: spoken=${spoken.length} ref=${request.referenceText.length} '
      'accuracy=${alignment.accuracyScore} completeness=${alignment.completenessScore} '
      'fluency=${alignment.fluencyScore} pron=${alignment.pronScore}',
    );

    final json = synthesizeAzureStyleAssessmentJson(
      alignment: alignment,
      referenceText: request.referenceText,
      durationMs: request.durationMs ?? 0,
    );
    return AssessmentResult(
      detail: AzurePronunciationAssessmentResult.fromJson(json),
      rawJson: json,
    );
  }
}
