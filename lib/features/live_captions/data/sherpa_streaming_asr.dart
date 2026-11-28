/// sherpa-onnx streaming (real-time) ASR engine for live captions.
///
/// Uses the NVIDIA Nemotron-3.5 streaming transducer (int8, 560 ms chunks,
/// ~682 MB on disk, CPU-only decode, no server process). The recognizer
/// consumes the same 16 kHz mono PCM that `sp_audio_capture` produces; the
/// segmenter stays as the utterance-endpoint detector while the recognizer
/// accumulates text continuously.
///
/// Model layout under `<exe>/components/live-asr/`:
///   encoder.int8.onnx
///   decoder.int8.onnx
///   joiner.int8.onnx
///   tokens.txt
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'package:enjoy_player/core/logging/log.dart';

final Logger _log = Logger('sherpa-streaming');

/// Directory that holds the streaming model (next to the exe).
Directory? streamingModelDir() {
  final exe = Platform.resolvedExecutable;
  final dir = exe.substring(0, exe.lastIndexOf(Platform.pathSeparator));
  final d = Directory(
    '$dir${Platform.pathSeparator}components'
    '${Platform.pathSeparator}live-asr',
  );
  return d.existsSync() &&
          File('${d.path}${Platform.pathSeparator}tokens.txt').existsSync()
      ? d
      : null;
}

bool get streamingAsrInstalled => streamingModelDir() != null;

/// One live recognizer bound to a capture source.
final class SherpaStreamingAsr {
  SherpaStreamingAsr._(this._recognizer, this._stream);

  final sherpa.OnlineRecognizer _recognizer;
  final sherpa.OnlineStream _stream;
  bool _closed = false;

  /// Model display info for the status bar.
  static String get engineLabel => '流式引擎';

  /// Creates the recognizer from the installed model dir.
  /// Returns null when the streaming component is not installed.
  static SherpaStreamingAsr? tryCreate() {
    final dir = streamingModelDir();
    if (dir == null) return null;
    final p = '${dir.path}${Platform.pathSeparator}';
    try {
      final recognizer = sherpa.OnlineRecognizer(
        sherpa.OnlineRecognizerConfig(
          model: sherpa.OnlineModelConfig(
            transducer: sherpa.OnlineTransducerModelConfig(
              encoder: '${p}encoder.int8.onnx',
              decoder: '${p}decoder.int8.onnx',
              joiner: '${p}joiner.int8.onnx',
            ),
            tokens: '${p}tokens.txt',
            debug: false,
          ),
          enableEndpoint: true,
          rule1MinTrailingSilence: 0.6,
          rule2MinTrailingSilence: 1.2,
        ),
      );
      _log.info('sherpa streaming recognizer ready (${dir.path})');
      return SherpaStreamingAsr._(recognizer, recognizer.createStream());
    } on Object catch (e, st) {
      _log.warning('sherpa init failed: $e', e, st);
      return null;
    }
  }

  /// Feeds 16 kHz mono s16le PCM bytes.
  void feedPcm(Uint8List chunk) {
    if (_closed) return;
    final samples = chunk.length ~/ 2;
    if (samples == 0) return;
    final bd = ByteData.view(chunk.buffer, chunk.offsetInBytes, chunk.length);
    final floats = Float32List(samples);
    for (var i = 0; i < samples; i++) {
      floats[i] = bd.getInt16(i * 2, Endian.little) / 32768.0;
    }
    _stream.acceptWaveform(sampleRate: 16000, samples: floats);
  }

  /// Decodes whatever is buffered; returns the current text (partial or,
  /// after [isEndpoint], final for this utterance).
  String decodeAndGetText() {
    if (_closed) return '';
    while (_recognizer.isReady(_stream)) {
      _recognizer.decode(_stream);
    }
    return _recognizer.getResult(_stream).text.trim();
  }

  /// True when the recognizer's endpoint rule fired (trailing silence).
  bool get isEndpoint => _recognizer.isEndpoint(_stream);

  /// Starts a fresh utterance (call after emitting a line).
  void reset() {
    if (_closed) return;
    _recognizer.reset(_stream);
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _stream.free();
    _recognizer.free();
  }
}
