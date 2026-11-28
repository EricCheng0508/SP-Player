import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

// Smoke test: decode a bilingual test wav through the streaming zipformer.
void main() {
  test('sherpa streaming decode smoke', () {
    // flutter_tester has no plugin registration — bind FFI explicitly to the
    // Release build output DLL.
    // Preload the matching onnxruntime by absolute path: System32 ships an
    // older 1.17.1 that would otherwise win the dependency search.
    final abs = Directory('build\\windows\\x64\\runner\\Release')
        .absolute.path;
    DynamicLibrary.open('$abs\\onnxruntime.dll');
    sherpa.initBindings('build\\windows\\x64\\runner\\Release');
    final dir = 'build\\windows\\x64\\runner\\Release\\components\\live-asr';
    final wav = File('test_media\\sherpa_wav\\0.wav');
    if (!Directory(dir).existsSync() ||
        !File('$dir\\tokens.txt').existsSync() ||
        !wav.existsSync()) {
      return; // model/audio not staged locally: skip silently
    }
    final p = '$dir\\';
    final recognizer = sherpa.OnlineRecognizer(
      sherpa.OnlineRecognizerConfig(
        model: sherpa.OnlineModelConfig(
          transducer: sherpa.OnlineTransducerModelConfig(
            encoder: '${p}encoder-epoch-99-avg-1.int8.onnx',
            decoder: '${p}decoder-epoch-99-avg-1.int8.onnx',
            joiner: '${p}joiner-epoch-99-avg-1.int8.onnx',
          ),
          tokens: '${p}tokens.txt',
          debug: false,
        ),
        enableEndpoint: true,
        rule1MinTrailingSilence: 0.6,
        rule2MinTrailingSilence: 1.2,
      ),
    );
    final stream = recognizer.createStream();
    final bytes = wav.readAsBytesSync();
    final pcm = bytes.sublist(44); // standard 44-byte WAV header
    final samples = Float32List(pcm.length ~/ 2);
    final bd = ByteData.view(pcm.buffer, pcm.offsetInBytes, pcm.length);
    for (var i = 0; i < samples.length; i++) {
      samples[i] = bd.getInt16(i * 2, Endian.little) / 32768.0;
    }
    for (var off = 0; off < samples.length; off += 1600) {
      final end = (off + 1600) > samples.length ? samples.length : off + 1600;
      stream.acceptWaveform(
          sampleRate: 16000, samples: samples.sublist(off, end));
      while (recognizer.isReady(stream)) {
        recognizer.decode(stream);
      }
    }
    final text = recognizer.getResult(stream).text.trim();
    // ignore: avoid_print
    print('SHERPA_DECODE_RESULT: "$text"');
    expect(text, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
