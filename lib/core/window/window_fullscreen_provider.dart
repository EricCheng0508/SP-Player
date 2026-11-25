/// Riverpod notifier for OS window fullscreen state.
library;

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:window_manager/window_manager.dart';

import 'desktop_window.dart';

part 'window_fullscreen_provider.g.dart';

/// Tracks and controls the OS fullscreen state of the application window.
///
/// Listens to [WindowListener] callbacks so that the UI stays in sync even
/// when the user toggles fullscreen via OS mechanisms (e.g. F11 at OS level,
/// title-bar buttons on macOS, Windows keyboard shortcuts).
@Riverpod(keepAlive: true)
class WindowFullscreen extends _$WindowFullscreen with WindowListener {
  /// Whether the window was maximized right before entering fullscreen, so
  /// leaving fullscreen can put it back.
  bool _wasMaximizedBeforeFullscreen = false;

  @override
  bool build() {
    if (!isDesktop) return false;

    windowManager.addListener(this);
    ref.onDispose(() => windowManager.removeListener(this));

    unawaited(
      getWindowFullscreen().then((v) {
        if (state != v) state = v;
      }),
    );

    return false;
  }

  @override
  void onWindowEnterFullScreen() => state = true;

  @override
  void onWindowLeaveFullScreen() => state = false;

  Future<void> setFullscreen(bool value) async {
    if (!isDesktop) return;
    if (value) {
      // Entering fullscreen from a maximized window: the window_manager
      // plugin keeps the maximized z-order/bounds path and the OS taskbar
      // stays on top. Restore first, remember to re-maximize on exit.
      _wasMaximizedBeforeFullscreen = await windowManager.isMaximized();
      if (_wasMaximizedBeforeFullscreen) await windowManager.restore();
    }
    await setWindowFullscreen(value);
    state = value;
    if (!value && _wasMaximizedBeforeFullscreen) {
      _wasMaximizedBeforeFullscreen = false;
      await windowManager.maximize();
    }
  }

  Future<void> toggle() => setFullscreen(!state);
}
