/// Auto-lifecycle for the bundled local ASR service (subgen).
///
/// The local build bundles faster-whisper `large-v3` as an OpenAI-compatible
/// HTTP service (`D:\Tool\subgen\serve.py`, port 8000, started via
/// `start-asr-server.bat`). Instead of asking the user to run that script,
/// the app probes `GET /health` and silently spawns the server in the
/// background (`pythonw`, no console window) whenever it is not running —
/// both eagerly at app startup and lazily before the first transcription.
library;

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Root of the bundled transcription service. Local-build constant.
const kSubgenDir = r'D:\Tool\subgen';

const _healthUrl = 'http://127.0.0.1:8000/health';

/// Wait for model load: large-v3 on CUDA takes tens of seconds on cold start.
const _kReadyTimeout = Duration(seconds: 120);

http.Client? _probeClient;

Future<bool> isLocalAsrUp({
  Duration timeout = const Duration(milliseconds: 900),
}) async {
  try {
    final client = _probeClient ??= http.Client();
    final response = await client
        .get(Uri.parse(_healthUrl))
        .timeout(timeout);
    return response.statusCode == 200;
  } on Object {
    return false;
  }
}

Future<void>? _ensureFuture;

/// Idempotent, single-flight: probes the service, spawns it if down, then
/// waits until `/health` answers (or the ready timeout elapses).
///
/// Throws [TimeoutException] when the service never became ready; spawn
/// failures are folded into the same path so callers can fall back to the
/// actionable "service not started" message.
Future<void> ensureLocalAsrService() {
  return _ensureFuture ??= _ensure().whenComplete(() => _ensureFuture = null);
}

Future<void> _ensure() async {
  if (await isLocalAsrUp()) return;

  final pythonw = File('$kSubgenDir\\.venv\\Scripts\\pythonw.exe');
  try {
    if (pythonw.existsSync()) {
      await Process.start(
        pythonw.path,
        [r'serve.py', '--port', '8000'],
        workingDirectory: kSubgenDir,
        mode: ProcessStartMode.detached,
      );
    } else {
      // Fallback: run the bundled launcher minimized (shows a console).
      await Process.start(
        'cmd.exe',
        ['/c', 'start', '/min', '', r'start-asr-server.bat'],
        workingDirectory: kSubgenDir,
        mode: ProcessStartMode.detached,
      );
    }
  } on Object {
    throw StateError('Failed to spawn local ASR service in $kSubgenDir');
  }

  final deadline = DateTime.now().add(_kReadyTimeout);
  while (DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (await isLocalAsrUp(timeout: const Duration(milliseconds: 500))) {
      return;
    }
  }
  throw TimeoutException(
    'Local ASR service did not become ready within ${_kReadyTimeout.inSeconds}s',
  );
}

/// Fire-and-forget warm-up used at app startup: kicks the service off early
/// so the first dictation/transcription does not pay the cold-start wait.
Future<void> warmUpLocalAsrService() async {
  try {
    await ensureLocalAsrService();
  } on Object {
    // Startup must never block or surface errors for the background service;
    // the lazy path before transcription will surface the actionable message.
  }
}
