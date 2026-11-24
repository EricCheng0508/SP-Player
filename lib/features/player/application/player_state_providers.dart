/// Raw [PlayerEngine] transport streams for UI (playing / buffering).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'player_engine_provider.dart';

Stream<T> _seedThenFollow<T>(T seed, Stream<T> rest) async* {
  yield seed;
  yield* rest;
}

final playerIsPlayingProvider = StreamProvider<bool>((ref) {
  final engine = ref.watch(playerEngineProvider);
  final snap = engine.transportSnapshot;
  return _seedThenFollow(snap.playing, engine.playing).distinct();
});

final playerIsBufferingProvider = StreamProvider<bool>((ref) {
  final engine = ref.watch(playerEngineProvider);
  final snap = engine.transportSnapshot;
  return _seedThenFollow(snap.buffering, engine.buffering).distinct();
});

/// Buffered-ahead end position for the scrubber's buffered band.
/// Empty on engines without buffered-range data (YouTube) → renders as 0.
final playerBufferEndProvider = StreamProvider<Duration>((ref) {
  final engine = ref.watch(playerEngineProvider);
  return engine.bufferEnd;
});
