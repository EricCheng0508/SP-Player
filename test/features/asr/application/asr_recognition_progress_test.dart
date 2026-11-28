/// Coarse-progress estimator used while the local ASR service is busy.
library;

import 'package:enjoy_player/features/asr/application/asr_recognition_progress.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-cranked clock so a whole recognition pass runs in microseconds.
class _Clock {
  DateTime value = DateTime(2026, 1, 1);
  DateTime call() => value;
  void advance(Duration d) => value = value.add(d);
}

void main() {
  setUp(AsrRecognitionProgress.resetCalibration);

  test('starts at zero and advances with elapsed time', () {
    final clock = _Clock();
    final p = AsrRecognitionProgress(audioSeconds: 300, clock: clock.call);
    expect(p.progress, 0.0);

    clock.advance(const Duration(seconds: 10));
    final first = p.progress;
    expect(first, greaterThan(0.0));

    clock.advance(const Duration(seconds: 10));
    expect(p.progress, greaterThan(first));
  });

  test('caps at the ceiling instead of claiming completion', () {
    final clock = _Clock();
    final p = AsrRecognitionProgress(audioSeconds: 300, clock: clock.call);
    clock.advance(const Duration(hours: 1));
    expect(p.progress, AsrRecognitionProgress.ceiling);
    expect(p.progress, lessThan(1.0));
  });

  test('short audio keeps a 2s floor so the bar does not snap', () {
    final clock = _Clock();
    final p = AsrRecognitionProgress(audioSeconds: 1, clock: clock.call);
    expect(p.expected, const Duration(seconds: 2));
    clock.advance(const Duration(seconds: 1));
    expect(p.progress, closeTo(0.47, 0.02));
  });

  test('unknown duration still gets a ceiling-bound bar', () {
    final p = AsrRecognitionProgress(audioSeconds: 0);
    expect(p.progress, 0.0);
    expect(p.expected.inSeconds, 1200);
  });

  test('a measured pass recalibrates the shared rate', () {
    final clock = _Clock();
    final seed = AsrRecognitionProgress.audioSecondsPerWallSecond;

    // 300 s of audio in 24 s of wall clock → 12.5× realtime, within 2× of
    // the 9× seed, so it blends instead of snapping.
    final fast = AsrRecognitionProgress(audioSeconds: 300, clock: clock.call);
    clock.advance(const Duration(seconds: 24));
    fast.recordCompletion();

    final after = AsrRecognitionProgress.audioSecondsPerWallSecond;
    expect(after, greaterThan(seed));
    expect(after, closeTo(seed + 0.35 * (12.5 - seed), 0.01));
  });

  test('a sample far from the rate snaps instead of blending', () {
    final clock = _Clock();

    // The seed assumes a fast box (9×); this machine does 1.24×. One pass
    // must be enough to fix the estimate, otherwise every clip parks the bar
    // at its ceiling a third of the way in.
    final slow = AsrRecognitionProgress(audioSeconds: 308, clock: clock.call);
    clock.advance(const Duration(seconds: 248));
    slow.recordCompletion();

    expect(
      AsrRecognitionProgress.audioSecondsPerWallSecond,
      closeTo(308 / 248, 0.01),
    );
  });

  test('physically implausible samples are dropped', () {
    final clock = _Clock();
    final seed = AsrRecognitionProgress.audioSecondsPerWallSecond;

    // 300 s of audio in 3000 s → 0.1×, below anything a real pass can do.
    final broken = AsrRecognitionProgress(audioSeconds: 300, clock: clock.call);
    clock.advance(const Duration(seconds: 3000));
    broken.recordCompletion();

    expect(AsrRecognitionProgress.audioSecondsPerWallSecond, seed);
  });

  test('device seed applies only until a real pass is measured', () {
    final clock = _Clock();

    // CPU box: the service reports 1.24×, so a 308 s clip expects ~248 s.
    AsrRecognitionProgress.seedFromDevice(1.24);
    final cpu = AsrRecognitionProgress(audioSeconds: 308, clock: clock.call);
    expect(cpu.expected.inSeconds, closeTo(248, 1));
    clock.advance(const Duration(seconds: 124));
    expect(cpu.progress, closeTo(0.47, 0.02));

    // A measured pass locks the rate in; a later device hint cannot undo it.
    clock.advance(const Duration(seconds: 124));
    cpu.recordCompletion();
    final measured = AsrRecognitionProgress.audioSecondsPerWallSecond;
    expect(measured, closeTo(1.24, 0.01));

    AsrRecognitionProgress.seedFromDevice(18);
    expect(AsrRecognitionProgress.audioSecondsPerWallSecond, measured);
  });
}
