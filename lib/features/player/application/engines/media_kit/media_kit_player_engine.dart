/// media_kit playback engine for local files and generic HTTP(S) (ADR-0003).
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show Listenable, VoidCallback;
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart';

import 'package:enjoy_player/data/files/security_scoped_bookmark.dart';
import 'package:enjoy_player/features/player/application/player_engine_capabilities.dart';
import 'package:enjoy_player/features/player/application/player_engine_constants.dart';
import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:enjoy_player/features/player/domain/playable_source.dart';

/// Single [mk.Player] instance — ADR-0003 / ADR-0015.
///
/// The native mpv player is constructed lazily on first access (not in the
/// constructor) so swapping between YouTube and local media does not stall the
/// main isolate with an unnecessary native allocation (issue #283, P8).
class MediaKitPlayerEngine
    implements PlayerEngine, PosterCapture, SubtitleTrackControl {
  MediaKitPlayerEngine();

  mk.Player? __player;

  /// Set by [prepareNativeBackend] after the previous platform view has
  /// detached. Only the video stage consults it (via [nativeBackendAllowed]):
  /// the stream/snapshot getters read `__player` without ever constructing,
  /// and the command path ([_player]) allocates mpv unconditionally — the
  /// WebView-detach wait lives in the swap (EngineSwapCoordinator), not in a
  /// getter (2026-08-30 field report, issue #658).
  var _nativeBackendAllowed = false;

  /// Whether [prepareNativeBackend] has approved native allocation. Read by
  /// the MediaKit video stage (`presentation/widgets/media_kit_video_stage.dart`)
  /// so it mounts a plain black placeholder — never a [VideoController] —
  /// until the previous engine's WebView has detached.
  bool get nativeBackendAllowed => _nativeBackendAllowed;

  /// Fires when [nativeBackendAllowed] flips to `true` so an already-mounted
  /// stage rebuilds and mounts [Video] immediately (issue #751). The surface
  /// host's `playerEngineRevProvider` is an identity-change signal owned by
  /// `PlayerEngineIdentity` — nothing hand-bumps it for stage inputs, so the
  /// stage listens to the input it actually reads instead.
  ///
  /// Deliberately never disposed: it lives exactly as long as this engine,
  /// and a stage that unmounts after `dispose` only calls `removeListener` —
  /// always legal here, because the gate has no dispose protocol at all.
  Listenable get nativeBackendAllowedListenable => _nativeBackendGate;

  final _NativeBackendGate _nativeBackendGate = _NativeBackendGate();

  mk.Player get _player => __player ??= mk.Player();

  mk.Player get player => _player;

  /// Handle for the currently-held macOS security-scoped resource grant, if
  /// any. Owned by this engine and paired with [releaseBookmark] before the
  /// next `open()` or on `dispose()`. See ADR-0060.
  int? _scopeToken;

  VideoController? _videoController;

  static VideoControllerConfiguration get _videoControllerConfiguration {
    if (Platform.isAndroid || Platform.isIOS) {
      return const VideoControllerConfiguration();
    }
    return const VideoControllerConfiguration(
      width: kVideoControllerWidth,
      height: kVideoControllerHeight,
      // Hardware decoding + hardware rendering is the pairing media_kit is
      // actually tested against. The software pairing (hwdec 'no' +
      // enableHardwareAcceleration false) renders into a pixel-buffer texture
      // that never reaches the compositor on Windows, so it is not an option.
      hwdec: 'auto-safe',
      enableHardwareAcceleration: true,
    );
  }

  VideoController get videoController {
    return _videoController ??= VideoController(
      _player,
      configuration: _videoControllerConfiguration,
    );
  }

  /// Allocates the [VideoController] *before* any media is opened.
  ///
  /// The controller is what installs the render API and the video output on
  /// the mpv handle. When `open()` runs first, mpv resolves a video output
  /// against a handle that has no render context yet and then keeps that empty
  /// output — audio plays, the stage stays black, and only an event that
  /// forces mpv to re-initialise the output (a mode-tab switch, a resize)
  /// ever produced a picture. That was the long-standing "black until I switch
  /// tabs" report.
  void ensureVideoOutput() {
    _videoController ??= VideoController(
      _player,
      configuration: _videoControllerConfiguration,
    );
  }

  @override
  Stream<Duration> get position =>
      __player?.stream.position ?? const Stream<Duration>.empty();

  /// [_player.stream.duration] is a broadcast stream that does not replay.
  /// [PlayerController] subscribes after `open` + other awaits, so the first
  /// duration event can be missed on Android. Seed from [_player.state.duration].
  @override
  Stream<Duration> get duration {
    final player = __player;
    if (player == null) return const Stream<Duration>.empty();
    return Stream.multi((controller) {
      final current = player.state.duration;
      if (current > Duration.zero) {
        controller.add(current);
      }
      final sub = player.stream.duration.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Stream<bool> get playing =>
      __player?.stream.playing ?? const Stream<bool>.empty();

  @override
  Stream<bool> get buffering =>
      __player?.stream.buffering ?? const Stream<bool>.empty();

  @override
  Stream<void> get completed =>
      __player?.stream.completed ?? const Stream<void>.empty();

  @override
  Stream<mk.Tracks>? get mkTracksStream => __player?.stream.tracks;

  @override
  bool get supportsVideoPosterCapture => true;

  @override
  bool get supportsSubtitleDisabling => true;

  @override
  Future<void> awaitSurfaceReady() async {}

  @override
  Future<void> awaitSurfaceDetached() async {}

  @override
  void prepareNativeBackend() {
    _nativeBackendAllowed = true;
    _nativeBackendGate.arm();
  }

  /// No metadata capability: MediaKit renders decoded frames directly, so
  /// there is no loading poster, no source identity, and no init timing.
  @override
  PlayerEngineMetadata? get metadata => null;

  @override
  void resetCompletionFlag() {}

  @override
  Future<void> teardownAfterClear({required bool keepSurfaceMounted}) => stop();

  @override
  ({bool playing, bool buffering}) get transportSnapshot {
    final player = __player;
    if (player == null) {
      return (playing: false, buffering: false);
    }
    return (playing: player.state.playing, buffering: player.state.buffering);
  }

  @override
  bool get keepSurfaceWhenParked => false;

  @override
  bool get overlaysNeedSurfaceParking =>
      // Desktop renders into a Flutter Texture (enableHardwareAcceleration:
      // false) — in-scene compositing, overlays cover it correctly. Parking
      // moved the video off-screen on every popup open (black stage).
      !(Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  Future<void> open(PlayableSource source, {Duration? startAt}) async {
    final uri = switch (source) {
      LocalFilePlayableSource(:final uri) => uri,
      RemoteUrlPlayableSource(:final uri) => uri,
      YoutubePlayableSource() => throw UnsupportedError(
        'MediaKitPlayerEngine cannot open YouTube',
      ),
    };
    final previousToken = _scopeToken;
    if (previousToken != null) {
      _scopeToken = null;
      await SecurityScopedBookmarkChannel.releaseBookmark(previousToken);
    }
    if (source is LocalFilePlayableSource) {
      _scopeToken = source.scopeToken;
    }
    // Must precede `open()` — see [ensureVideoOutput].
    ensureVideoOutput();
    // [startAt] makes mpv decode from the resume position directly, so the
    // first presented frame is already the right one — without it the player
    // presents a 0:00 frame and then jumps to the restore position (the
    // "video flashes from the beginning" report). The post-open restore seek
    // in the open choreography stays as a fallback.
    await _player.open(mk.Media(uri, start: startAt));
  }

  @override
  Future<void> disableRenderedSubtitles() =>
      _player.setSubtitleTrack(mk.SubtitleTrack.no());

  @override
  Future<void> seek(Duration target) => _player.seek(target);

  @override
  Future<bool> waitForMediaReady({required Duration timeout}) async {
    // Fast path: the demuxer is already open (duration known) — e.g. the file
    // loaded while other open steps ran.
    if (_player.state.duration > Duration.zero) return true;
    try {
      await _player.stream.duration
          .firstWhere((d) => d > Duration.zero)
          .timeout(timeout);
      return true;
    } on TimeoutException {
      return false;
    }
  }

  @override
  Future<void> setRate(double rate) => _player.setRate(rate);

  @override
  Future<void> setVolumeNormalized(double volume) =>
      _player.setVolume(volume.clamp(0, 1) * kVolumeScale);

  @override
  Future<void> playOrPause() => _player.playOrPause();

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<Uint8List?> screenshot({String? format}) =>
      _player.screenshot(format: format);

  @override
  void warmVideoSurface() {}

  @override
  Future<void> dispose() async {
    final token = _scopeToken;
    if (token != null) {
      _scopeToken = null;
      await SecurityScopedBookmarkChannel.releaseBookmark(token);
    }
    await __player?.dispose();
    __player = null;
  }
}

/// One-shot "native backend armed" signal behind
/// [MediaKitPlayerEngine.nativeBackendAllowedListenable].
///
/// A minimal [Listenable]: a listener set plus add/remove is all the stage
/// gate needs, so there is no `ChangeNotifier` inheritance and no dispose
/// protocol to run — [arm] (the engine-facing entry point, issue #751)
/// simply notifies the current listeners.
class _NativeBackendGate implements Listenable {
  final Set<VoidCallback> _listeners = <VoidCallback>{};

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void arm() => _notify();

  void _notify() {
    for (final listener in _listeners.toList(growable: false)) {
      listener();
    }
  }
}
