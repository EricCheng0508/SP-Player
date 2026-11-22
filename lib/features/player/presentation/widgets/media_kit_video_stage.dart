/// media_kit half of the surface host slot: the letterboxed [Video] stage.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:enjoy_player/features/player/application/engines/media_kit/media_kit_player_engine.dart';
import 'package:enjoy_player/features/player/application/player_engine_constants.dart';

/// Video stage mounted for a [MediaKitPlayerEngine].
///
/// Moved out of the engine (issue #664): an application service must not build
/// widgets. The engine only publishes the non-widget inputs this stage reads —
/// [MediaKitPlayerEngine.nativeBackendAllowed] (plus its listenable, below)
/// and [MediaKitPlayerEngine.videoController].
class MediaKitVideoStage extends StatefulWidget {
  const MediaKitVideoStage({
    super.key,
    required this.engine,
    required this.maxWidth,
    required this.maxHeight,
  });

  final MediaKitPlayerEngine engine;
  final double maxWidth;
  final double maxHeight;

  @override
  State<MediaKitVideoStage> createState() => _MediaKitStageGateState();
}

/// Gates the [Video] subtree on [MediaKitPlayerEngine.nativeBackendAllowed].
///
/// While the gate is closed the stage is a bare placeholder — mpv must not be
/// allocated until the previous engine's WebView has detached. The swap arms
/// the gate with `prepareNativeBackend()` *after* that detach; this state
/// listens to [MediaKitPlayerEngine.nativeBackendAllowedListenable] so an
/// already-mounted placeholder rebuilds and mounts [Video] immediately — the
/// signal that used to ride a second hand-bumped `playerEngineRevProvider`
/// bump (issue #751: the rev is now the identity module's change signal, and
/// stage inputs notify through the engine that owns them). If the flip lands
/// before the first build, [build] simply reads `true` and mounts directly.
class _MediaKitStageGateState extends State<MediaKitVideoStage> {
  @override
  void initState() {
    super.initState();
    widget.engine.nativeBackendAllowedListenable.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(covariant MediaKitVideoStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.engine, widget.engine)) return;
    oldWidget.engine.nativeBackendAllowedListenable.removeListener(_rebuild);
    widget.engine.nativeBackendAllowedListenable.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.engine.nativeBackendAllowedListenable.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;
    if (widget.maxWidth <= 0 || widget.maxHeight <= 0) {
      return const SizedBox.shrink();
    }
    if (!engine.nativeBackendAllowed) {
      return const ColoredBox(color: Colors.black);
    }

    return ColoredBox(
      color: Colors.black,
      child: _MediaKitVideoStage(
        controller: engine.videoController,
        positionStream: engine.position,
        playingStream: engine.playing,
        nudgeMpvRender: engine.nudgeVideoRender,
        maxWidth: widget.maxWidth,
        maxHeight: widget.maxHeight,
      ),
    );
  }
}

/// Mounts media_kit [Video] and relayouts it once the native texture exists.
///
/// A kick on the first Flutter frame is too early — [Texture] is still a
/// 1×1 placeholder, so the layout is a no-op. Dragging the transcript splitter
/// works because it changes the viewport *after* frames are flowing. Listen
/// for texture id/rect (and first-frame) and then pulse [Video] width/height.
class _MediaKitVideoStage extends StatefulWidget {
  const _MediaKitVideoStage({
    required this.controller,
    required this.positionStream,
    required this.playingStream,
    required this.nudgeMpvRender,
    required this.maxWidth,
    required this.maxHeight,
  });

  final VideoController controller;

  /// Player position stream used to detect seeks: seeking does not change the
  /// viewport or the texture id, yet the compositor may still serve the stale
  /// black frame until the next relayout.
  final Stream<Duration> positionStream;

  /// Play/pause transitions also relayout-adjacent state changes the user
  /// can trigger from elsewhere (mode-tab switches pause, echo loops seek);
  /// each transition is another chance to un-black a stale texture.
  final Stream<bool> playingStream;

  /// Forces mpv to re-render the current frame (1 ms seek). The hard-kick
  /// escalation pairs this with a [Video] remount: remounting alone only
  /// re-presents whatever is in the texture — if mpv never painted (fresh
  /// open, audio playing, black stage), the seek is what actually produces
  /// a frame. Same effect as the user's tab-switch-to-dictate workaround.
  final Future<void> Function() nudgeMpvRender;

  final double maxWidth;
  final double maxHeight;

  @override
  State<_MediaKitVideoStage> createState() => _MediaKitVideoStageState();
}

class _MediaKitVideoStageState extends State<_MediaKitVideoStage> {
  var _nudge = false;
  var _kicked = false;
  var _hardKickEpoch = 0;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<bool>? _playingSub;
  Duration? _lastPosition;

  @override
  void initState() {
    super.initState();
    widget.controller.id.addListener(_onTexture);
    widget.controller.rect.addListener(_onTexture);
    _onTexture();
    unawaited(_kickAfterFirstFrame());
    _positionSub = widget.positionStream.listen(_onPositionTick);
    _playingSub = widget.playingStream.listen(_onPlayingFlip);
    // Burst kicks over the first few seconds: a single kick can land while
    // mpv has not yet presented into the texture (or during the loading →
    // chrome viewport swap) and the frame stays black. The user-visible
    // symptom of missing one is a black stage that only recovers after a
    // mode-tab switch relayouts the column.
    for (final delayMs in const [
      150, 350, 600, 900, 1300, 1800, 2400, 3000, 3800, 4600,
    ]) {
      unawaited(Future<void>.delayed(Duration(milliseconds: delayMs)).then((_) {
        if (mounted) _scheduleKick();
      }));
    }
    // Escalation: soft 1px pulses can fail to revive a stale compositor
    // texture (the freshly-imported first open stayed black until a mode-tab
    // switch). A hard kick remounts the [Video] element, which re-registers
    // the texture with the compositor — strictly stronger than relayout.
    for (final delayMs in const [800, 1800, 3200, 5000, 7500]) {
      unawaited(Future<void>.delayed(Duration(milliseconds: delayMs)).then((_) {
        if (mounted) _scheduleKick(hard: true);
      }));
    }
  }

  @override
  void didUpdateWidget(covariant _MediaKitVideoStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final dw = (oldWidget.maxWidth - widget.maxWidth).abs();
    final dh = (oldWidget.maxHeight - widget.maxHeight).abs();
    // Any viewport change must re-kick: the loading (16:9) stage and the
    // chrome layout can differ by less than a big threshold while the
    // texture still hasn't presented, leaving a black frame.
    if (dw > 0 || dh > 0) {
      _scheduleKick();
    }
  }

  @override
  void dispose() {
    widget.controller.id.removeListener(_onTexture);
    widget.controller.rect.removeListener(_onTexture);
    unawaited(_positionSub?.cancel());
    unawaited(_playingSub?.cancel());
    super.dispose();
  }

  /// Kicks on every play/pause transition. Pausing recomposites the scene
  /// (the paused gate chrome appears) and resuming re-presents mpv frames;
  /// either can revive a texture the compositor went black on.
  void _onPlayingFlip(bool playing) {
    _scheduleKick();
  }

  /// Kicks on seek jumps. Natural playback ticks advance monotonically in
  /// small steps; a backwards jump or a forward leap over ~1s means the user
  /// (or the app) seeked, and the texture may need a relayout pulse to
  /// present the new frame.
  void _onPositionTick(Duration position) {
    final last = _lastPosition;
    _lastPosition = position;
    if (last == null) return;
    final deltaMs = position.inMilliseconds - last.inMilliseconds;
    if (deltaMs < 0 || deltaMs > 1000) {
      _scheduleKick();
    }
  }

  Future<void> _kickAfterFirstFrame() async {
    try {
      await widget.controller.waitUntilFirstFrameRendered;
    } on Object {
      return;
    }
    if (!mounted) return;
    _scheduleKick();
    // Cover the race where the first frame is decoded while the stage is
    // still in the loading (16:9) layout: the chrome viewport swap that
    // follows needs its own kick a moment later.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _scheduleKick();
  }

  void _onTexture() {
    final id = widget.controller.id.value;
    final rect = widget.controller.rect.value;
    if (id == null || rect == null || rect.width <= 1 || rect.height <= 1) {
      return;
    }
    _scheduleKick();
  }

  void _scheduleKick({bool hard = false}) {
    if (hard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Remount re-registers the texture with the compositor; the paired
        // mpv nudge (1 ms seek) is what actually makes mpv paint a frame
        // into it when it has been sitting silent since a fresh open.
        setState(() => _hardKickEpoch++);
        unawaited(widget.nudgeMpvRender());
      });
      return;
    }
    if (_kicked) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _kick());
  }

  void _kick() {
    if (!mounted || _kicked) return;
    _kicked = true;
    setState(() => _nudge = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _nudge = false);
      // Re-arm so later texture/viewport events can kick again. A one-shot
      // latch leaves the texture black when the first frame lands in the
      // loading layout and the chrome viewport swap follows immediately.
      _kicked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final inset = _nudge ? kVideoTextureKickInset : 0.0;
    final w = widget.maxWidth > inset
        ? widget.maxWidth - inset
        : widget.maxWidth;
    final h = widget.maxHeight > inset
        ? widget.maxHeight - inset
        : widget.maxHeight;
    return ExcludeSemantics(
      child: Video(
        // Keyed so a hard kick (epoch bump) remounts the element and forces
        // the compositor to re-register the texture.
        key: ValueKey('media-kit-video-$_hardKickEpoch'),
        controller: widget.controller,
        controls: null,
        width: w,
        height: h,
        fit: BoxFit.contain,
        fill: Colors.black,
        subtitleViewConfiguration: const SubtitleViewConfiguration(
          visible: false,
        ),
      ),
    );
  }
}
