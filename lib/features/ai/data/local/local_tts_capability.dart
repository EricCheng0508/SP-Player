/// Local Windows TTS via SAPI (System.Speech) — the zero-config fallback for
/// the speech-byok-less local build, mirroring how assessment falls back to
/// local scoring. Produces WAV bytes through PowerShell's built-in speech
/// synthesizer; no extra runtime download is required.
///
/// Voice selection: the first installed voice whose culture matches the
/// request's primary language subtag (`zh` / `en` / `ja` …), falling back to
/// the system default voice.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:enjoy_player/features/ai/domain/capabilities/tts_capability.dart';
import 'package:enjoy_player/features/ai/domain/byok_not_configured_failure.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_request.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_result.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:logging/logging.dart';

final Logger _log = Logger('ai.local_tts');

final class LocalTtsCapability implements TtsCapability {
  const LocalTtsCapability();

  @override
  Future<TtsResult> synthesize(TtsRequest request) async {
    if (!Platform.isWindows) {
      throw const ByokNotConfiguredFailure(ModalityKind.tts);
    }
    final text = request.text.trim();
    if (text.isEmpty) {
      return const TtsResult(audioBytes: null, format: 'wav');
    }
    final wav = await _synthesizeViaSapi(text, request.language);
    return TtsResult(audioBytes: wav, format: 'wav');
  }

  Future<Uint8List> _synthesizeViaSapi(String text, String language) async {
    final dir = await Directory.systemTemp.createTemp('sp_tts_');
    final wavPath = '${dir.path}\\out.wav';
    try {
      // Language primary subtag for voice-culture matching ("en-US" → "en").
      final langPrefix =
          language.split('-').first.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      final script = _buildScript(text: text, langPrefix: langPrefix, wavPath: wavPath);
      final encoded = base64Encode(utf8.encode(script));

      final result = await Process.run(
        'powershell.exe',
        ['-NoProfile', '-NonInteractive', '-EncodedCommand', encoded],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      ).timeout(const Duration(seconds: 60));

      if (result.exitCode != 0) {
        _log.warning('SAPI TTS failed (${result.exitCode}): ${result.stderr}');
        throw StateError('local TTS synthesizer exited ${result.exitCode}');
      }
      final file = File(wavPath);
      if (!await file.exists()) {
        throw StateError('local TTS produced no output file');
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw StateError('local TTS produced an empty wav');
      }
      return bytes;
    } on TimeoutException {
      _log.warning('SAPI TTS timed out');
      rethrow;
    } finally {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException {
        // Best-effort temp cleanup; a locked file must not fail synthesis.
      }
    }
  }

  /// Builds the PowerShell script. All dynamic strings travel as base64 so
  /// quotes/newlines in [text] cannot break out of the script.
  static String _buildScript({
    required String text,
    required String langPrefix,
    required String wavPath,
  }) {
    return '''
\$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Speech
\$s = New-Object System.Speech.Synthesis.SpeechSynthesizer
\$text = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('${base64Encode(utf8.encode(text))}'))
\$prefix = '${_escapePs(langPrefix)}'
if (\$prefix.Length -gt 0) {
  \$v = \$s.GetInstalledVoices() | Where-Object { \$_.VoiceInfo.Culture.Name.ToLower().StartsWith(\$prefix) } | Select-Object -First 1
  if (\$v) { \$s.SelectVoice(\$v.VoiceInfo.Name) }
}
\$s.SetOutputToWaveFile('${_escapePs(wavPath)}')
\$s.Speak(\$text)
\$s.Dispose()
''';
  }

  /// Single-quoted PowerShell string needs only `'` doubling.
  static String _escapePs(String value) => value.replaceAll("'", "''");
}
