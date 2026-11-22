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
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:enjoy_player/features/local_components/data/component_store.dart';
import 'package:enjoy_player/features/local_components/domain/component_catalog.dart';

const _healthUrl = 'http://127.0.0.1:8000/health';

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

Future<void>? _ensureFuture;

/// Idempotent, single-flight: probes the service, spawns it if down, then
/// waits until `/health` answers (or the ready timeout elapses).
///
/// Throws [StateError] when no install was found, [TimeoutException] when the
/// service never became ready.
Future<void> ensureLocalAsrService() {
  return _ensureFuture ??= _ensure().whenComplete(() => _ensureFuture = null);
}

Future<void> _ensure() async {
  if (await isLocalAsrUp()) return;

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
    await Process.start(
      exe,
      args,
      workingDirectory: File(exe).parent.path,
      mode: ProcessStartMode.detached,
    );
    return true;
  } on Object {
    return false;
  }
}

/// Developer-machine fallback: venv pythonw in the old checkout.
Future<bool> _spawnLegacyDev() async {
  final pythonw = File('$kSubgenDir\\.venv\\Scripts\\pythonw.exe');
  try {
    if (!pythonw.existsSync()) return false;
    await Process.start(
      pythonw.path,
      [r'serve.py', '--port', '8000'],
      workingDirectory: kSubgenDir,
      mode: ProcessStartMode.detached,
    );
    return true;
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
