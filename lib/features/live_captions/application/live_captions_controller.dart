/// Live-captions orchestrator: capture process → segmentation → local ASR →
/// optional LLM translation → session state + persistence.
///
/// The capture helper (`sp_audio_capture.exe`, bundled next to the app) pumps
/// 16 kHz mono s16le PCM on stdout. Segments are dispatched to a single
/// sequential worker: the local transcription service serializes requests
/// anyway, and a queue keeps ordering (and therefore readable captions).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_whisper_client.dart';
import 'package:enjoy_player/features/ai/data/local_subgen_asr_service.dart';
import 'package:enjoy_player/features/ai/domain/chat_message.dart';
import 'package:enjoy_player/features/live_captions/data/audio_segmenter.dart';
import 'package:enjoy_player/features/live_captions/data/live_captions_store.dart';
import 'package:enjoy_player/features/live_captions/domain/live_caption_models.dart';

part 'live_captions_controller.g.dart';

final _log = logNamed('liveCaptions');

/// Phase of the whole page, coarse for the status pill.
enum LiveCaptionsPhase { idle, starting, listening, stopping, error }

final class LiveCaptionsState {
  const LiveCaptionsState({
    this.phase = LiveCaptionsPhase.idle,
    this.session,
    this.error,
    this.systemEnabled = true,
    this.micEnabled = false,
    this.translate = true,
    this.lastError,
  });

  final LiveCaptionsPhase phase;
  final LiveCaptionSession? session;
  final String? error;
  final bool systemEnabled;
  final bool micEnabled;
  final bool translate;

  LiveCaptionsState copyWith({
    LiveCaptionsPhase? phase,
    LiveCaptionSession? session,
    String? error,
    bool? systemEnabled,
    bool? micEnabled,
    bool? translate,
  }) =>
      LiveCaptionsState(
        phase: phase ?? this.phase,
        session: session ?? this.session,
        error: error,
        systemEnabled: systemEnabled ?? this.systemEnabled,
        micEnabled: micEnabled ?? this.micEnabled,
        translate: translate ?? this.translate,
        lastError: lastError,
      );

  final String? lastError;
}

@Riverpod(keepAlive: true)
class LiveCaptionsController extends _$LiveCaptionsController {
  final _active = <_CaptureRun>[];

  @override
  LiveCaptionsState build() {
    ref.onDispose(_stopAll);
    // Entering the page opens a fresh (idle) session right away — every visit
    // is its own conversation per the product decision.
    return LiveCaptionsState(session: _newSessionObject());
  }

  bool get _isRunning => state.phase == LiveCaptionsPhase.listening ||
      state.phase == LiveCaptionsPhase.starting;

  LiveCaptionSession _newSessionObject() {
    final now = DateTime.now().toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    final id = 'live-'
        '${now.year}${two(now.month)}${two(now.day)}-'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
    return LiveCaptionSession(
      id: id,
      startedAt: now,
      sources: [
        if (state.systemEnabled) LiveCaptionSource.system,
        if (state.micEnabled) LiveCaptionSource.mic,
      ],
      translated: state.translate,
    );
  }

  /// Creates a fresh session as the current one. While listening this first
  /// stops the capture; a session with content is already persisted line by
  /// line, an empty one simply vanishes.
  Future<void> beginNewSession() async {
    if (_isRunning) await stop();
    state = state.copyWith(
      phase: LiveCaptionsPhase.idle,
      session: _newSessionObject(),
      error: null,
    );
  }

  void setSystemEnabled(bool value) {
    if (_isRunning && !value) _stopSource(LiveCaptionSource.system);
    state = state.copyWith(systemEnabled: value);
    if (_isRunning && value) _startSource(LiveCaptionSource.system);
  }

  void setMicEnabled(bool value) {
    if (_isRunning && !value) _stopSource(LiveCaptionSource.mic);
    state = state.copyWith(micEnabled: value);
    if (_isRunning && value) _startSource(LiveCaptionSource.mic);
  }

  void setTranslate(bool value) =>
      state = state.copyWith(translate: value);

  /// Starts listening on the current session with the checked sources.
  Future<void> start() async {
    if (_isRunning) return;
    final sources = <LiveCaptionSource>[
      if (state.systemEnabled) LiveCaptionSource.system,
      if (state.micEnabled) LiveCaptionSource.mic,
    ];
    if (sources.isEmpty) {
      state = state.copyWith(
        phase: LiveCaptionsPhase.idle,
        error: '请至少勾选一个监听来源',
      );
      return;
    }
    final session = state.session ?? _newSessionObject();
    // Reflect the sources the run actually uses.
    session.sources
      ..clear()
      ..addAll(sources);
    session.translated = state.translate;
    state = state.copyWith(
      phase: LiveCaptionsPhase.starting,
      session: session,
      error: null,
    );

    var anyStarted = false;
    final failures = <String>[];
    for (final source in sources) {
      try {
        await _startSource(source);
        anyStarted = true;
      } on Object catch (e) {
        _log.warning('capture start failed for $source: $e');
        failures.add(source == LiveCaptionSource.system ? '系统声音' : '麦克风');
      }
    }
    if (!anyStarted) {
      state = state.copyWith(
        phase: LiveCaptionsPhase.idle,
        error: '无法启动音频监听${failures.isEmpty ? '' : '（$failures）'}：'
            '请确认应用目录中存在 sp_audio_capture.exe',
      );
      return;
    }
    state = state.copyWith(phase: LiveCaptionsPhase.listening);
    if (failures.isNotEmpty) {
      state = state.copyWith(error: '${failures.join('、')}启动失败，仅监听其余来源');
    }
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    state = state.copyWith(phase: LiveCaptionsPhase.stopping);
    await _stopAll();
    final session = state.session;
    if (session != null) {
      session.endedAt = DateTime.now().toLocal();
      await ref.read(liveCaptionsStoreProvider).save(session);
    }
    state = state.copyWith(phase: LiveCaptionsPhase.idle);
  }

  Future<void> _stopAll() async {
    for (final run in List<_CaptureRun>.from(_active)) {
      await run.stop();
    }
    _active.clear();
  }

  Future<void> _stopSource(LiveCaptionSource source) async {
    for (final run in List<_CaptureRun>.from(_active)) {
      if (run.source != source) continue;
      _active.remove(run);
      await run.stop();
    }
  }

  Future<void> _startSource(LiveCaptionSource source) async {
    final exePath = _captureExePath();
    if (exePath == null) {
      throw StateError('sp_audio_capture.exe not found');
    }
    final session = state.session;
    if (session == null) return;
    final run = _CaptureRun(
      ref: ref,
      source: source,
      startedAt: DateTime.now().toLocal(),
      onLine: (line) => _appendLine(line),
      onFatal: (message) {
        state = state.copyWith(
          phase: LiveCaptionsPhase.idle,
          error: message,
        );
      },
    );
    await run.start(exePath);
    _active.add(run);
  }

  void _appendLine(LiveCaptionLine line) {
    final session = state.session;
    if (session == null) return;
    session.lines.add(line);
    // Persist opportunistically; files are small so every line is fine.
    ref.read(liveCaptionsStoreProvider).save(session);
    // Copy-with a new timestamp list identity is unnecessary; session is
    // mutated in place and the UI listens to a manual tick below.
    state = state.copyWith();
  }

  static String? _captureExePath() {
    final exe = Platform.resolvedExecutable;
    final dir = exe.substring(0, exe.lastIndexOf(Platform.pathSeparator));
    final path =
        '$dir${Platform.pathSeparator}sp_audio_capture.exe';
    return File(path).existsSync() ? path : null;
  }

  /// Manual re-translation of one failed line (from the caption card).
  Future<void> retryTranslation(LiveCaptionLine line) async {
    line.failedTranslation = false;
    line.translation = null;
    state = state.copyWith();
    await translateLine(ref, line);
    state = state.copyWith();
  }
}

/// Shared translation step: Chinese passthrough / LLM translate / failure flag.
Future<void> translateLine(Ref ref, LiveCaptionLine line) async {
  if (cjkRatio(line.text) > 0.5) {
    line.translation = line.text;
    return;
  }
  try {
    final chat = ref.read(chatServiceProvider);
    final result = await chat.complete(
      messages: [
        const ChatMessage(
          role: ChatMessage.roleSystem,
          content: '你是实时字幕翻译器。把用户提供的文本翻译成简体中文，'
              '只输出译文本身，不要解释、不要引号。保留专有名词原文。',
        ),
        ChatMessage(role: ChatMessage.roleUser, content: line.text),
      ],
      temperature: 0.2,
      maxTokens: 500,
    );
    line.translation = result.trim();
  } on Object catch (e) {
    _log.warning('translate line failed: $e');
    line.failedTranslation = true;
  }
}

/// One running capture process (one audio source).
final class _CaptureRun {
  _CaptureRun({
    required this.ref,
    required this.source,
    required this.startedAt,
    required this.onLine,
    required this.onFatal,
  });

  final Ref ref;
  final LiveCaptionSource source;
  final DateTime startedAt;
  final void Function(LiveCaptionLine) onLine;
  final void Function(String) onFatal;

  Process? _process;
  final AudioSegmenter _segmenter = AudioSegmenter();
  Future<void> _worker = Future.value();
  bool _stopping = false;

  Future<void> start(String exePath) async {
    // Attached mode: dart:io sets CREATE_NO_WINDOW, so no console flashes,
    // and we keep the stdout pipe for the PCM stream.
    final process = await Process.start(
      exePath,
      ['--source', source == LiveCaptionSource.system ? 'system' : 'mic'],
    );
    _process = process;

    process.stdout.listen(
      (chunk) => _handlePcm(
          chunk is Uint8List ? chunk : Uint8List.fromList(chunk)),
      onError: (Object e) => _log.warning('stdout error: $e'),
      onDone: () {
        // Process exited; if we were not the one stopping it, surface it.
        if (!_stopping) {
          final tail = _segmenter.flush();
          if (tail != null) _enqueue(tail);
          onFatal('音频监听进程退出（麦克风不可用或被占用时可能发生）');
        }
      },
    );
    process.stderr.listen(
      (line) => _log.info('capture stderr: ${utf8.decode(line, allowMalformed: true)}'),
      onDone: () {},
    );
  }

  void _handlePcm(Uint8List chunk) {
    if (_stopping) return;
    for (final segment in _segmenter.feed(chunk)) {
      _enqueue(segment);
    }
  }

  Future<void> stop() async {
    if (_stopping) return;
    _stopping = true;
    // Give the utterance in flight a chance to become a segment.
    final tail = _segmenter.flush();
    if (tail != null) _enqueue(tail);
    _process?.kill();
    _process = null;
    await _worker;
  }

  void _enqueue(AudioSegment segment) {
    _worker = _worker.then((_) => _transcribe(segment)).catchError((Object e) {
      _log.warning('segment pipeline error: $e');
    });
  }

  Future<void> _transcribe(AudioSegment segment) async {
    // Skip near-silent segments: whisper would hallucinate text on noise.
    if (_isMostlySilent(segment.pcmBytes)) return;
    final wav = wrapWav(segment.pcmBytes);
    try {
      // Ensure the service is up (idempotent, single-flight).
      await ensureLocalAsrService();
      final map = await postWhisperTranscription(
        baseUrl: 'http://127.0.0.1:8000/v1',
        apiKey: 'local',
        audioBytes: wav,
        filename: 'live.wav',
        model: 'large-v3-turbo',
        // Auto-detect; zh and en both work well on large-v3-turbo.
        responseFormat: 'json',
      );
      final text = '${map['text'] ?? ''}'.trim();
      if (text.isEmpty || text.length < 2) return;
      if (_looksLikeHallucination(text)) return;

      final line = LiveCaptionLine(
        offsetSeconds: segment.offsetSeconds,
        source: source,
        text: text,
      );
      onLine(line);
      await _maybeTranslate(line);
    } on Object catch (e, st) {
      _log.warning('transcribe segment failed: $e', e, st);
    }
  }

  Future<void> _maybeTranslate(LiveCaptionLine line) async {
    final translate = ref.read(liveCaptionsControllerProvider).translate;
    if (!translate) return;
    await translateLine(ref, line);
    onLine(line); // tick UI with the translation result
  }

  /// Near-silent audio makes whisper hallucinate; skip those segments.
  static bool _isMostlySilent(Uint8List pcm) {
    final samples = pcm.length ~/ 2;
    if (samples == 0) return true;
    final b = ByteData.view(pcm.buffer, pcm.offsetInBytes, pcm.length);
    var sum = 0.0;
    var peak = 0;
    for (var i = 0; i < samples; i++) {
      final v = b.getInt16(i * 2, Endian.little);
      sum += v * v;
      final a = v.abs();
      if (a > peak) peak = a;
    }
    final rms = math.sqrt(sum / samples);
    return rms < 120 && peak < 1500;
  }

  /// Whisper hallucination filter: the classic "谢谢观看 /字幕由…" pattern.
  static bool _looksLikeHallucination(String text) {
    const patterns = [
      '字幕由',
      '请订阅',
      '谢谢观看',
      'Thank you for watching',
      'Subscribe to',
      '字幕制作',
    ];
    final t = text.replaceAll(' ', '').toLowerCase();
    if (t.length < 3) return true;
    for (final p in patterns) {
      if (t.contains(p.toLowerCase())) return true;
    }
    return false;
  }
}

/// Ratio of CJK ideographs in [text].
double cjkRatio(String text) {
  var cjk = 0;
  for (final unit in text.runes) {
    if ((unit >= 0x4E00 && unit <= 0x9FFF) ||
        (unit >= 0x3400 && unit <= 0x4DBF)) {
      cjk++;
    }
  }
  return text.isEmpty ? 0 : cjk / text.length;
}

/// Saved sessions for the history rail (newest first).
@Riverpod(keepAlive: true)
class LiveCaptionsHistory extends _$LiveCaptionsHistory {
  @override
  Future<List<LiveCaptionSession>> build() =>
      Future.value(ref.read(liveCaptionsStoreProvider).loadAll());

  Future<void> reload() async {
    state = AsyncData(await ref.read(liveCaptionsStoreProvider).loadAll());
  }
}
