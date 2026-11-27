/// Auto-lifecycle for the native Qwen ASR sidecar (`sp-qwen-asr-server.exe`).
///
/// Mirrors [local_subgen_asr_service.dart] but for the Rust/wgpu engine
/// (ADR-0106): probes `GET /health` on 127.0.0.1:8010, spawns the managed
/// component install when down, waits for readiness. The sidecar ships the
/// DXC shader fallback so first-run GPU init stays fast; without a discrete
/// GPU it falls back to CPU internally (wgpu device selection).
///
/// HTTP contract (implemented by the sidecar, consumed here):
/// - `GET  /health` → 200 `{"status":"ok","model_loaded":true}`
/// - `POST /v1/audio/transcriptions` (multipart `file` + `language` +
///   `response_format=verbose_json`) → Whisper-style verbose JSON
///   (segments + words, seconds) parseable by `AsrResult.fromJson` — the
///   timeline builder is engine-agnostic.
/// - `GET  /v1/progress` → `{"stage":"asr|align|segment","percent":0-100}`
///   machine-readable progress events (ADR-0106 §6 protocol).
library;

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:enjoy_player/features/local_components/data/component_store.dart';
import 'package:enjoy_player/features/local_components/domain/component_catalog.dart';

const kQwenAsrPort = 8010;
const _healthUrl = 'http://127.0.0.1:$kQwenAsrPort/health';

/// Native engine cold start: process spawn + ONNX load is seconds, not the
/// tens-of-seconds CUDA/cuBLAS init the Python sidecar needs.
const _kReadyTimeout = Duration(seconds: 90);

http.Client? _probeClient;

Future<bool> isQwenAsrUp({
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

/// Sync component-store probe: both the native sidecar and its ONNX weights
/// must be installed. Used by the engine resolver to pick Qwen-first with a
/// faster-whisper fallback (ADR-0106) — no async needed, file existence only.
bool isQwenAsrComponentInstalled() {
  final store = ComponentStore(rootOverride: null);
  return store.isInstalled(specOf(ComponentKind.qwenAsrRuntime)) &&
      store.isInstalled(specOf(ComponentKind.qwenAsrModel));
}

Future<void>? _ensureFuture;

/// Idempotent, single-flight: probes the sidecar, spawns the managed install
/// if down, then waits until `/health` answers.
///
/// Throws [StateError] when the component is not installed (caller decides
/// whether to fall back to the faster-whisper sidecar), [TimeoutException]
/// when it never became ready.
Future<void> ensureQwenAsrService() {
  return _ensureFuture ??= _ensure().whenComplete(() => _ensureFuture = null);
}

Future<void> _ensure() async {
  if (await isQwenAsrUp()) return;

  final spawned = await _spawnManaged();
  if (!spawned) {
    throw StateError(
      'Qwen ASR sidecar not installed (install the 千问识别运行时 component).',
    );
  }

  final deadline = DateTime.now().add(_kReadyTimeout);
  while (DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (await isQwenAsrUp(timeout: const Duration(milliseconds: 500))) {
      return;
    }
  }
  throw TimeoutException(
    'Qwen ASR sidecar did not become ready within ${_kReadyTimeout.inSeconds}s',
  );
}

/// Spawns the managed native sidecar with its ONNX weights directory.
Future<bool> _spawnManaged() async {
  final store = ComponentStore(rootOverride: null);
  final exe = store.installedEntryPath(specOf(ComponentKind.qwenAsrRuntime));
  if (exe == null || !File(exe).existsSync()) return false;

  final modelDir = Directory(
    '${store.root}\\${specOf(ComponentKind.qwenAsrModel).installDirName}',
  );
  final args = <String>['--port', '$kQwenAsrPort'];
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

/// Fire-and-forget warm-up at app startup (only when installed): the native
/// engine loads in seconds, so this mostly pre-wins the first transcription.
Future<void> warmUpQwenAsrService() async {
  try {
    await ensureQwenAsrService();
  } on Object {
    // Startup must never block; lazy ensure before transcription surfaces
    // the actionable error and the resolver falls back to Whisper.
  }
}
