/// Transcript-panel search state (Ctrl+F while a player session is live).
///
/// Transient UI state kept alive for the app lifetime (mirrors
/// [TranscriptBlurMode]); the query is cleared when the panel switches media.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transcript_search_controller.g.dart';

/// Whether the search bar is shown above the transcript list.
@Riverpod(keepAlive: true)
class TranscriptSearchOpen extends _$TranscriptSearchOpen {
  @override
  bool build() => false;

  void open() {
    if (state) return;
    state = true;
  }

  void close() {
    if (!state) return;
    state = false;
  }
}

/// Current query; empty string hides the results list.
@Riverpod(keepAlive: true)
class TranscriptSearchQuery extends _$TranscriptSearchQuery {
  @override
  String build() => '';

  void set(String value) {
    if (state == value) return;
    state = value;
  }

  void clear() {
    if (state.isEmpty) return;
    state = '';
  }
}
