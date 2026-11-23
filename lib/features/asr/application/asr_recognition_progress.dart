/// Determinate progress for the single-shot recognition step.
///
/// The bundled faster-whisper service answers ONE blocking
/// `POST /v1/audio/transcriptions` request and reports no incremental
/// progress (verified against its OpenAPI schema: no `stream` field, no job
/// status route). A 5-minute clip therefore renders as a dead spinner for
/// 20–40 s, and a 22-minute episode for minutes.
///
/// Until the service grows a streaming endpoint we estimate: the audio
/// duration is known, and the service chews through N seconds of audio per
/// wall-clock second on this machine. [AsrRecognitionProgress] advances the
/// bar linearly against that budget, stops short of the end ([ceiling]) so a
/// tail that runs long never looks stuck at 99 %, and re-calibrates the rate
/// from every completed pass so the second clip on a machine is close to
/// right.
library;

/// Tracks one recognition step and estimates how far along it is.
class AsrRecognitionProgress {
  /// `audioSeconds` — length of the audio being transcribed.
  ///
  /// [clock] is injectable so tests can drive elapsed time without waiting.
  AsrRecognitionProgress({required this.audioSeconds, DateTime Function()? clock})
    : _now = clock ?? DateTime.now {
    _startedAt = _now();
  }

  /// Highest fraction the bar reaches on its own; only real completion
  /// (or an error) moves it past this.
  static const double ceiling = 0.94;

  /// Prior guess used before any pass has been measured: 9 s of audio per
  /// wall-clock second, i.e. a 5-minute clip in ~33 s. Deliberately
  /// conservative — over-estimating the wait is worse than under.
  static const double _seedRate = 9.0;

  /// Longest we are willing to claim as an expectation. Only guards against
  /// absurd inputs: local recognition handles clips under the long-form
  /// threshold, which is ~10 minutes of audio ≈ 8 minutes on CPU, so a
  /// smaller cap would park the bar at its ceiling halfway through.
  static const double _maxExpectedSeconds = 1200;

  /// Shortest expectation; below this the bar would snap to the ceiling
  /// before the first tick.
  static const double _minExpectedSeconds = 2;

  /// Blend factor for a fresh observation that agrees with the current rate.
  static const double _smoothing = 0.35;

  /// Beyond this ratio an observation means "different hardware", not noise:
  /// the rate snaps instead of blending, so a machine that turns out to be
  /// 8× slower than the seed converges on the first pass rather than the
  /// fifth.
  static const double _snapRatio = 2;

  /// Physically implausible throughput — a truncated pass, a clock jump.
  static const double _minPlausibleRate = 0.2;
  static const double _maxPlausibleRate = 200;

  static double _rate = _seedRate;
  static bool _hasMeasured = false;

  /// Audio seconds per wall-clock second, as calibrated so far.
  static double get audioSecondsPerWallSecond => _rate;

  /// First-pass hint, typically from the service's `/health` device field.
  ///
  /// CPU and CUDA differ by more than an order of magnitude (1.8× vs ~18×
  /// on large-v3-turbo), so a device-blind seed parks the bar at its ceiling
  /// a third of the way in on slow hardware. Ignored once a real pass has
  /// been measured — the measurement always wins.
  static void seedFromDevice(double rate) {
    if (_hasMeasured) return;
    if (!rate.isFinite || rate <= 0) return;
    _rate = rate;
  }

  final double audioSeconds;
  final DateTime Function() _now;
  late final DateTime _startedAt;

  /// Restores the seed rate. Test-only.
  static void resetCalibration() {
    _rate = _seedRate;
    _hasMeasured = false;
  }

  /// Wall-clock budget this pass is expected to need.
  Duration get expected {
    final seconds = audioSeconds <= 0
        ? _maxExpectedSeconds
        : (audioSeconds / _rate).clamp(_minExpectedSeconds, _maxExpectedSeconds);
    return Duration(milliseconds: (seconds * 1000).round());
  }

  Duration get _elapsed => _now().difference(_startedAt);

  /// `0..ceiling` — never reports completion; the controller owns that.
  double get progress {
    final budgetMs = expected.inMilliseconds;
    if (budgetMs <= 0) return ceiling;
    final ratio = _elapsed.inMilliseconds / budgetMs;
    return (ratio * ceiling).clamp(0.0, ceiling);
  }

  /// Feeds the real wall-clock cost of this pass back into the shared rate.
  ///
  /// A sample within [_snapRatio] of the current rate is blended in; a
  /// sample further away means the rate is simply wrong for this hardware
  /// (the device hint was missing, a GPU went away, …) and replaces it
  /// outright. Samples outside the physically plausible band are dropped.
  void recordCompletion() {
    final wallSeconds = _elapsed.inMilliseconds / 1000;
    if (wallSeconds <= 0.3 || audioSeconds <= 0) return;
    final observed = audioSeconds / wallSeconds;
    if (!observed.isFinite ||
        observed < _minPlausibleRate ||
        observed > _maxPlausibleRate) {
      return;
    }
    final ratio = observed / _rate;
    _rate = (ratio >= 1 / _snapRatio && ratio <= _snapRatio)
        ? _smoothing * observed + (1 - _smoothing) * _rate
        : observed;
    _hasMeasured = true;
  }
}
