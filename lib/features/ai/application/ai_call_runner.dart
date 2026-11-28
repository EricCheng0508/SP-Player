/// Shared failure mapping for one-shot AI calls across features.
library;

import 'package:enjoy_player/core/logging/log.dart';

/// Runs one AI call and maps its failure modes in a single place.
///
/// [logLabel] names the logger and [surface] names the operation in the
/// warning text, so each caller keeps its own log wording. [call] performs
/// the request, [onSuccess] consumes the result, and [onGeneric] handles
/// every error.
///
/// Returns the call result, or null when the call failed.
Future<T?> runAiCall<T>({
  required String logLabel,
  required String surface,
  required Future<T> Function() call,
  void Function(T result)? onSuccess,
  required T? Function(Object error, StackTrace stackTrace) onGeneric,
}) async {
  try {
    final result = await call();
    onSuccess?.call(result);
    return result;
  } catch (e, st) {
    logNamed(logLabel).warning('$surface failed: $e', e, st);
    return onGeneric(e, st);
  }
}
