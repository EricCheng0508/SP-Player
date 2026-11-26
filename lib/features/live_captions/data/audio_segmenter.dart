/// Splits the 16 kHz mono s16le capture stream into sentence-ish segments.
///
/// Whisper is not streaming, so latency comes from segmenting: a segment is
/// cut when ~0.5 s of silence follows at least ~0.5 s of speech, or when the
/// buffered audio passes a hard cap (~8 s) so continuous speech still emits
/// one short utterance instead of piling many sentences into one segment.
/// Speech/silence is decided by RMS over 100 ms windows.
library;

import 'dart:math' as math;
import 'dart:typed_data';

final class AudioSegment {
  AudioSegment(this.pcmBytes, this.offsetSeconds);

  /// s16le mono 16 kHz samples ready for WAV wrapping.
  final Uint8List pcmBytes;

  /// Offset of the segment start within the capture, in seconds.
  final double offsetSeconds;
}

final class AudioSegmenter {
  AudioSegmenter({
    this.sampleRate = 16000,
    this.silenceRms = 350,
    this.minSpeechMs = 500,
    this.tailSilenceMs = 500,
    this.maxSegmentMs = 8000,
  });

  final int sampleRate;

  /// RMS above which a 100 ms window counts as speech.
  final double silenceRms;

  /// A segment must contain at least this much speech to be cut on silence.
  final int minSpeechMs;

  /// Trailing silence that closes a segment.
  final int tailSilenceMs;

  /// Hard cap on segment duration.
  final int maxSegmentMs;

  static const int _windowMs = 100;

  final List<int> _pending = <int>[]; // raw s16 samples since last cut
  int _speechMs = 0;
  int _silenceMs = 0;
  bool _inSpeech = false;
  int _windowSampleCount = 0;
  double _windowSumSquares = 0;
  int _totalMs = 0;

  bool get hasOpenUtterance => _inSpeech;

  /// Milliseconds of audio currently buffered (approx, whole windows + tail).
  int get bufferedMs => _totalMs;

  /// Feeds raw s16le bytes; returns completed segments.
  List<AudioSegment> feed(Uint8List chunk) {
    final out = <AudioSegment>[];
    final sampleCount = chunk.length ~/ 2;
    final byteData = ByteData.sublistView(chunk);
    for (var i = 0; i < sampleCount; i++) {
      final s = byteData.getInt16(i * 2, Endian.little);
      _pending.add(s);
      _windowSumSquares += s * s;
      if (++_windowSampleCount < sampleRate * _windowMs ~/ 1000) continue;

      // End of a 100 ms analysis window.
      final rms = math.sqrt(_windowSumSquares / _windowSampleCount);
      _windowSampleCount = 0;
      _windowSumSquares = 0;
      _totalMs += _windowMs;

      final isSpeech = rms >= silenceRms;
      if (isSpeech) {
        _inSpeech = true;
        _speechMs += _windowMs;
        _silenceMs = 0;
      } else if (_inSpeech) {
        _silenceMs += _windowMs;
      }

      final capReached = _totalMs >= maxSegmentMs;
      final cut = capReached ||
          (_inSpeech &&
              _speechMs >= minSpeechMs &&
              _silenceMs >= tailSilenceMs);
      if (cut) {
        out.add(_emit());
      }
    }
    return out;
  }

  /// Flushes an unfinished utterance (session stopping) as a final segment.
  AudioSegment? flush() {
    if (!_inSpeech) {
      reset();
      return null;
    }
    return _emit();
  }

  AudioSegment _emit() {
    final bytes = Uint8List(_pending.length * 2);
    final byteData = ByteData.view(bytes.buffer);
    for (var i = 0; i < _pending.length; i++) {
      byteData.setInt16(i * 2, _pending[i], Endian.little);
    }
    final segment = AudioSegment(bytes, _totalMs / 1000 - _pending.length / sampleRate);
    _pending.clear();
    _speechMs = 0;
    _silenceMs = 0;
    _inSpeech = false;
    _totalMs = 0;
    return segment;
  }

  void reset() {
    _pending.clear();
    _speechMs = 0;
    _silenceMs = 0;
    _inSpeech = false;
    _windowSampleCount = 0;
    _windowSumSquares = 0;
    _totalMs = 0;
  }
}

/// Wraps s16le mono PCM bytes into a complete in-memory WAV file.
Uint8List wrapWav(Uint8List pcm, {int sampleRate = 16000}) {
  const headerSize = 44;
  final out = Uint8List(headerSize + pcm.length);
  final b = ByteData.view(out.buffer);

  void ascii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      out[offset + i] = text.codeUnitAt(i);
    }
  }

  ascii(0, 'RIFF');
  b.setUint32(4, 36 + pcm.length, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little); // PCM
  b.setUint16(22, 1, Endian.little); // mono
  b.setUint32(24, sampleRate, Endian.little);
  b.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  b.setUint16(32, 2, Endian.little); // block align
  b.setUint16(34, 16, Endian.little); // bits
  ascii(36, 'data');
  b.setUint32(40, pcm.length, Endian.little);
  out.setRange(headerSize, out.length, pcm);
  return out;
}
