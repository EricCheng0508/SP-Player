import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';

/// Automatic speech recognition (Whisper on Enjoy worker).
abstract class AsrCapability {
  Future<AsrResult> transcribe(AsrRequest request);
}

/// Optional capability: how fast this backend turns audio into text.
///
/// Kept separate from [AsrCapability] so backends that cannot answer (remote
/// workers, BYOK vendors, stubs) stay untouched — `implements` would
/// otherwise force every one of them to grow the method. Only the bundled
/// local service implements it: it knows whether it loaded on CPU or CUDA,
/// and the two differ by more than an order of magnitude on
/// `large-v3-turbo` — which is the difference between a progress bar that
/// tracks the work and one that parks at its ceiling a third of the way in.
abstract interface class AsrThroughputHint {
  /// Audio-seconds of audio per wall-clock second of compute — `1.24` on a
  /// CPU-only box, roughly `18` on CUDA. Null when the backend cannot say.
  Future<double?> expectedRealtimeFactor();
}
