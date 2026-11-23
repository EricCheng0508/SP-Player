/// Lifecycle for the managed local translation server (llama-server).
///
/// The first-run wizard / Settings can install two components
/// (`mtRuntime` = llama.cpp Vulkan build, `mtModel` = TranslateGemma 4B GGUF).
/// When both are present the app can serve translation fully offline from
/// `llama-server`, which exposes an OpenAI-compatible chat API on
/// 127.0.0.1:8760 — the same protocol the BYOK LLM client already speaks.
library;

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:enjoy_player/core/platform/hidden_process.dart';
import 'package:enjoy_player/features/local_components/data/component_store.dart';
import 'package:enjoy_player/features/local_components/domain/component_catalog.dart';

/// Marker base URL persisted in the LLM BYOK config when the user selects
/// the local translation model.
const kLocalLlmBaseUrl = 'http://127.0.0.1:8760/v1';

/// Model id llama-server is started with.
const kLocalLlmModelId = 'translategemma-4b-it-Q4_K_M';

bool isLocalLlmEndpoint(String baseUrl) {
  final normalized = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
  return normalized == kLocalLlmBaseUrl.replaceFirst(RegExp(r'/+$'), '');
}

const _healthUrl = 'http://127.0.0.1:8760/health';

/// Vulkan GPU offload; falls back to CPU inside llama-server automatically
/// when no compatible device exists.
const _kGpuLayers = '-ngl';

Future<bool> isLocalLlmUp({
  Duration timeout = const Duration(milliseconds: 900),
}) async {
  try {
    final response = await http
        .get(Uri.parse(_healthUrl))
        .timeout(timeout);
    // llama-server /health returns 200 when ready, 503 while loading.
    return response.statusCode == 200;
  } on Object {
    return false;
  }
}

Future<void>? _ensureFuture;

/// Single-flight: probes, spawns when down, waits until `/health` answers.
Future<void> ensureLocalLlmServer() {
  return _ensureFuture ??= _ensure().whenComplete(() => _ensureFuture = null);
}

Future<void> _ensure() async {
  if (await isLocalLlmUp()) return;

  final store = ComponentStore(rootOverride: null);
  final exe = store.installedEntryPath(specOf(ComponentKind.mtRuntime));
  if (exe == null || !File(exe).existsSync()) {
    throw StateError(
      'Local translation runtime not installed (download it in Settings → '
      '本地组件).',
    );
  }
  final modelDir = Directory('${store.root}\\${specOf(ComponentKind.mtModel).installDirName}');
  final gguf = File(
    '${modelDir.path}\\${kLocalLlmModelId}.gguf',
  );
  if (!gguf.existsSync()) {
    // Fall back to any single *.gguf in the model dir (manual placements).
    final any = modelDir.existsSync()
        ? modelDir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.toLowerCase().endsWith('.gguf'))
              .toList()
        : const <File>[];
    if (any.isEmpty) {
      throw StateError(
        'Local translation model not installed (download it in Settings → '
        '本地组件).',
      );
    }
    await _spawn(exe, any.first.path);
  } else {
    await _spawn(exe, gguf.path);
  }

  // Model load (2.5 GB into VRAM) can take a minute on slow disks.
  final deadline = DateTime.now().add(const Duration(seconds: 120));
  while (DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (await isLocalLlmUp(timeout: const Duration(milliseconds: 500))) {
      return;
    }
  }
  throw TimeoutException('llama-server did not become ready in 120s');
}

Future<void> _spawn(String exe, String modelPath) async {
  // Windowless: llama-server is a console binary, and the detached dart:io
  // path would give it a visible console window.
  await spawnHidden(
    exe,
    [
      '-m',
      modelPath,
      '--port',
      '8760',
      '--host',
      '127.0.0.1',
      _kGpuLayers,
      '99',
    ],
    workingDirectory: File(exe).parent.path,
  );
}

/// Used by the Settings component section to warm the server after install.
Future<void> warmUpLocalLlmServer() async {
  try {
    await ensureLocalLlmServer();
  } on Object {
    // Same policy as ASR warm-up: never block startup on background services.
  }
}
