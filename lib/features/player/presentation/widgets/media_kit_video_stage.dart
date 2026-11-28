/// media_kit half of the surface host slot: the letterboxed [Video] stage.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/player/application/engines/media_kit/media_kit_player_engine.dart';

/// Stage diagnostics.
///
/// These records land in the always-on release log sink (ADR-0026) and carry
/// the facts that separate the possible native failure modes: whether the
/// gate let [Video] mount, whether the controller got a texture id, what rect
/// the native side reports, and whether mpv decoded anything.
final Logger _log = Logger('player.video');

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
/// While the gate is closed the stage paints nothing — mpv must not be
/// allocated until the previous engine's WebView has detached, and the loading
/// portal's thumbnail / skeleton behind the surface must stay visible (a black
/// placeholder here was the "black flash" on open). The swap arms
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

  String? _lastGateLog;

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;
    if (widget.maxWidth <= 0 || widget.maxHeight <= 0) {
      return const SizedBox.shrink();
    }
    final viewport =
        '${widget.maxWidth.toStringAsFixed(0)}x'
        '${widget.maxHeight.toStringAsFixed(0)}';
    final line =
        'stage: gate=${engine.nativeBackendAllowed} viewport=$viewport';
    if (line != _lastGateLog) {
      _lastGateLog = line;
      _log.info(line);
    }
    if (!engine.nativeBackendAllowed) {
      // Paint nothing while the gate is closed: the loading portal behind the
      // surface already shows the media's thumbnail + skeleton, and a black
      // placeholder here would cover it (the "black flash" on open).
      return const SizedBox.shrink();
    }

    // No outer black backdrop: [Video] letterboxes with `fill` once visible,
    // and until the first frame renders the stage stays transparent so the
    // thumbnail behind the surface keeps showing.
    return _MediaKitVideoStage(
      controller: engine.videoController,
      maxWidth: widget.maxWidth,
      maxHeight: widget.maxHeight,
    );
  }
}

/// Mounts media_kit [Video] for the current engine.
///
/// No repaint tricks. The historical "black stage until a tab switch" was a
/// surface-registry ownership race that unmounted this whole subtree
/// (`player_surface_target.dart`); once the stage actually stays mounted,
/// media_kit's own first-frame handshake and the texture id/rect notifiers
/// present the picture without any relayout pulsing — and the pulsing itself
/// was visible as a double flash plus a backward-seek stutter on every open.
class _MediaKitVideoStage extends StatefulWidget {
  const _MediaKitVideoStage({
    required this.controller,
    required this.maxWidth,
    required this.maxHeight,
  });

  final VideoController controller;
  final double maxWidth;
  final double maxHeight;

  @override
  State<_MediaKitVideoStage> createState() => _MediaKitVideoStageState();
}

class _MediaKitVideoStageState extends State<_MediaKitVideoStage> {
  /// Outcome tracking for the mount diagnostics below.
  Timer? _probe;

  /// Safety valve for [Timer] when the first-frame handshake never lands.
  Timer? _firstFrameFallback;
  var _probeTicks = 0;
  var _firstFrame = false;

  /// Safety valve: if the first-frame handshake never lands (broken media),
  /// reveal the stage anyway after this long so the panel is not stuck on
  /// the poster forever.
  static const Duration _firstFrameFallbackDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _probeVideoState();
    unawaited(_awaitFirstFrame());
  }

  /// One line per second for the first ten seconds of a stage's life.
  ///
  /// The fields together identify the failure: `id=null` means the native
  /// texture was never registered; a `rect` stuck at 1×1 means mpv never
  /// sized its video output; `source=null` means no video track decoded.
  void _probeVideoState() {
    final player = widget.controller.player;
    _log.info(
      'video: mount id=${widget.controller.id.value} '
      'rect=${widget.controller.rect.value} '
      'source=${player.state.width}x${player.state.height} '
      'playing=${player.state.playing}',
    );
    _probe = Timer.periodic(const Duration(seconds: 1), (_) {
      _probeTicks++;
      if (!mounted) {
        _probe?.cancel();
        return;
      }
      _log.info(
        'video: t=${_probeTicks}s id=${widget.controller.id.value} '
        'rect=${widget.controller.rect.value} '
        'source=${player.state.width}x${player.state.height} '
        'playing=${player.state.playing} frame=$_firstFrame',
      );
      if (_probeTicks == 3) {
        final rect = widget.controller.rect.value;
        final hasOutput = rect != null && rect.width > 1 && rect.height > 1;
        _log.info(
          hasOutput
              ? 'video: output live rect=$rect (texture path engaged)'
              : 'video: no video output after ${_probeTicks}s',
        );
      }
      if (_probeTicks >= 10) _probe?.cancel();
    });
  }

  Future<void> _awaitFirstFrame() async {
    // Desktop handshake: completes on the native `VideoOutput.Resize` callback,
    // which fires independently of this widget being painted — safe to keep the
    // stage transparent (poster showing) until it lands.
    _firstFrameFallback ??= Timer(_firstFrameFallbackDuration, _reveal);
    try {
      await widget.controller.waitUntilFirstFrameRendered;
    } on Object {
      _firstFrameFallback?.cancel();
      return;
    }
    _firstFrameFallback?.cancel();
    if (!mounted) return;
    _reveal();
    _log.info('video: first frame rendered at t=${_probeTicks}s');
  }

  void _reveal() {
    if (!mounted || _firstFrame) return;
    setState(() => _firstFrame = true);
  }

  @override
  void dispose() {
    _probe?.cancel();
    _firstFrameFallback?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.maxWidth,
        height: widget.maxHeight,
        // Hidden until the first frame renders so the thumbnail behind the
        // surface shows instead of a black flash, then fades in.
        child: AnimatedOpacity(
          opacity: _firstFrame ? 1.0 : 0.0,
          duration: EnjoyThemeTokens.of(context).motionFast,
          curve: Curves.easeOut,
          child: Video(
            controller: widget.controller,
            controls: null,
            width: widget.maxWidth,
            height: widget.maxHeight,
            fit: BoxFit.contain,
            fill: Colors.black,
            subtitleViewConfiguration: const SubtitleViewConfiguration(
              visible: false,
            ),
          ),
        ),
      ),
    );
  }
}
