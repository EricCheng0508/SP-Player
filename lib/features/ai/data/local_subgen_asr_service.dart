/// Auto-lifecycle for the local ASR service (subgen).
///
/// Resolution order:
/// 1. Probe `GET /health` on 127.0.0.1:8000 — an already-running service wins
///    (dev setups, a previous app session, etc.).
/// 2. Managed component install: spawn the frozen `sp-asr-server.exe` from
///    the component store (installed by the first-run wizard) with the model
///    directory managed alongside it.
/// 3. Legacy dev fallback: the old `D:\Tool\subgen` venv, kept for developer
///    machines so existing checkouts keep working.
///
/// The service exposes an OpenAI-compatible `/v1/audio/transcriptions`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:enjoy_player/core/platform/hidden_process.dart';
import 'package:enjoy_player/features/local_components/data/component_store.dart';
import 'package:enjoy_player/features/local_components/domain/component_catalog.dart';

const _healthUrl = 'http://127.0.0.1:8000/health';
const _servicePort = 8000;

/// Legacy dev checkout (kept as last-resort fallback).
const kSubgenDir = r'D:\Tool\subgen';

/// Wait for model load: large-v3-turbo on CUDA takes tens of seconds on cold start.
const _kReadyTimeout = Duration(seconds: 180);

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

/// Throughput large-v3-turbo gets on a CPU-only box, measured warm on the
/// reference laptop (i7-1360P, int8): a 60 s clip takes 30–36 s, so ~1.8 s of
/// audio per wall-clock second and a 5-minute clip in ~2.5–3 minutes.
///
/// Cold model load and a busy CPU both land well under this, which is why the
/// first pass of a session drifts — [AsrRecognitionProgress] re-calibrates
/// from the real duration afterwards.
const double kCpuRealtimeFactor = 1.8;

/// Same model on CUDA (f16). Rough, but the right order of magnitude — the
/// estimator re-calibrates from the first real pass anyway.
const double kCudaRealtimeFactor = 18;

/// Realtime factor for the device the service actually loaded on, from
/// `/health` (`{"ok":true,"model":…,"device":"cpu"}`).
///
/// Returns null when the service is not answering, so the caller keeps
/// whatever estimate it already has.
Future<double?> localAsrRealtimeFactor() async {
  try {
    final client = _probeClient ??= http.Client();
    final response = await client
        .get(Uri.parse(_healthUrl))
        .timeout(const Duration(milliseconds: 1200));
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return null;
    final device = '${decoded['device'] ?? ''}'.toLowerCase();
    if (device.contains('cuda') || device.contains('gpu')) {
      return kCudaRealtimeFactor;
    }
    if (device.contains('cpu')) return kCpuRealtimeFactor;
    return null;
  } on Object {
    return null;
  }
}

Future<void>? _ensureFuture;

/// Idempotent, single-flight: probes the service, spawns it if down, then
/// waits until `/health` answers (or the ready timeout elapses).
///
/// Throws [StateError] when no install was found, [TimeoutException] when the
/// service never became ready.
Future<void> ensureLocalAsrService() {
  return _ensureFuture ??= _ensure().whenComplete(() => _ensureFuture = null);
}

/// Whether a process is listening on the service port.
///
/// `/health` is served by the same blocking worker that runs transcription,
/// so a busy service answers late or not at all inside the 900 ms probe
/// budget. Liveness and readiness are two different questions: the port being
/// open proves the process exists, and spawning a second copy of a service
/// that is merely busy only produces a port-bind failure (which used to show
/// up as a console window flashing on screen).
Future<bool> _serviceIsListening({
  Duration timeout = const Duration(milliseconds: 400),
}) async {
  try {
    final socket = await Socket.connect(
      InternetAddress.loopbackIPv4,
      _servicePort,
      timeout: timeout,
    );
    socket.destroy();
    return true;
  } on Object {
    return false;
  }
}

/// Waits for `/health` to answer, up to [timeout].
Future<void> _waitUntilReady(Duration timeout) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (await isLocalAsrUp(timeout: const Duration(milliseconds: 500))) {
      return;
    }
  }
  throw TimeoutException(
    'Local ASR service did not become ready within ${timeout.inSeconds}s',
  );
}

Future<void> _ensure() async {
  if (await isLocalAsrUp()) return;

  // A busy service is not a missing service. Mid-transcription the health
  // probe times out while the model is very much loaded, so check the socket
  // before concluding anything is wrong.
  if (await _serviceIsListening()) {
    // The request we are about to send queues behind the running one, so
    // there is nothing left to wait for.
    return;
  }

  var spawned = false;
  try {
    spawned = await _spawnManaged();
    if (!spawned) spawned = await _spawnLegacyDev();
  } on Object {
    spawned = false;
  }
  if (!spawned) {
    throw StateError(
      'Local ASR service not installed (run the setup wizard or install the '
      'transcription component in Settings).',
    );
  }

  await _waitUntilReady(_kReadyTimeout);
}

/// Spawns the managed frozen service when the component store has it.
Future<bool> _spawnManaged() async {
  final store = ComponentStore(rootOverride: null);
  final runtimeSpec = specOf(ComponentKind.asrRuntime);
  final exe = store.installedEntryPath(runtimeSpec);
  if (exe == null || !File(exe).existsSync()) return false;

  // Model dir next to the runtime root: components/asr-models/large-v3-turbo.
  final modelDir = Directory(
    '${store.root}\\${specOf(ComponentKind.asrModel).installDirName}',
  );
  final args = <String>['--port', '8000'];
  if (modelDir.existsSync()) {
    args..add('--model')..add(modelDir.path);
  }

  try {
    // Console-subsystem binary: spawn it windowless, or Windows pops a black
    // console window (see [spawnHidden] for why dart:io cannot do this).
    return await spawnHidden(
      exe,
      args,
      workingDirectory: File(exe).parent.path,
    );
  } on Object {
    return false;
  }
}

/// Developer-machine fallback: venv pythonw in the old checkout.
Future<bool> _spawnLegacyDev() async {
  final pythonw = File('$kSubgenDir\\.venv\\Scripts\\pythonw.exe');
  try {
    if (!pythonw.existsSync()) return false;
    return await spawnHidden(
      pythonw.path,
      [r'serve.py', '--port', '8000'],
      workingDirectory: kSubgenDir,
    );
  } on Object {
    return false;
  }
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
