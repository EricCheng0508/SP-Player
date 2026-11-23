/// Highlighted transcript cue + karaoke word index for the active playback
/// position.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/subtitle/current_transcript_word.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/settings/application/karaoke_highlight_settings.dart';
import 'package:enjoy_player/features/transcript/application/transcript_display_readiness_provider.dart';

import '../../player/application/display_position_provider.dart';
import '../../player/application/echo_mode_provider.dart';
import '../data/transcript_timeline_codec.dart';
import 'karaoke_position_provider.dart';
import 'transcript_cue_selection.dart';
import 'transcript_lines_provider.dart';

part 'transcript_playback_highlight_provider.g.dart';

/// Echo-aware active cue index plus the karaoke word index on that cue.
///
/// `visibleCueIndex` is the display-window variant for the caption overlay:
/// each cue is shown across a professional-subtitling window — leading in up
/// to 200 ms before speech across real gaps, lingering up to 300 ms after
/// speech for reading comfort — but the window never overlaps a neighbouring
/// cue's speech, so back-to-back lines switch exactly on time and a speaking
/// line is never clipped. It is `-1` outside every window. The transcript
/// list keeps using `cueIndex` (persist-through-gap highlight).
typedef TranscriptPlaybackHighlight = ({
  int cueIndex,
  int? wordIndex,
  int visibleCueIndex,
});

/// Current cue index (echo-aware) and karaoke current-word index.
///
/// `cueIndex` is `-1` when there are no lines. `wordIndex` is null when
/// karaoke is off / still loading, `karaokeSwitchEnabled` is false (no timed
/// words on owned media), the cue is out of range, or the position is in a
/// gap.
///
/// The 50 ms karaoke position stream is watched **only after** the karaoke
/// gate passes, so karaoke-off transcripts never subscribe to the word tick
/// stream. Consumers that only need the cue index must use
/// `.select((h) => h.cueIndex)` (or select on a listener) so they are not
/// rebuilt on the 50 ms word ticks; only the active transcript tile should
/// watch the full record.
@riverpod
TranscriptPlaybackHighlight transcriptPlaybackHighlight(
  Ref ref,
  String mediaId,
) {
  final linesAsync = ref.watch(transcriptLinesForMediaProvider(mediaId));
  final lines = linesAsync.value ?? [];
  final echo = ref.watch(echoModeProvider);
  final posAsync = ref.watch(displayPositionProvider);
  final timeSec = switch (posAsync) {
    AsyncData(:final value) => value.inMilliseconds / 1000.0,
    _ => 0.0,
  };
  final rawCueIndex = lines.isEmpty
      ? -1
      : transcriptActiveIndexForEchoUi(
          echo,
          transcriptActiveIndex(lines, timeSec),
        );
  final visibleCueIndex = _captionVisibleIndex(lines, timeSec);
  final cueIndex = rawCueIndex;
  if (cueIndex < 0) {
    return (cueIndex: cueIndex, wordIndex: null, visibleCueIndex: -1);
  }

  final enabled = ref.watch(karaokeHighlightSettingsProvider).value;
  if (enabled != true) {
    return (
      cueIndex: cueIndex,
      wordIndex: null,
      visibleCueIndex: visibleCueIndex,
    );
  }
  final readiness = ref.watch(
    transcriptDisplayReadinessForMediaProvider(mediaId),
  );
  if (!readiness.karaokeSwitchEnabled) {
    return (
      cueIndex: cueIndex,
      wordIndex: null,
      visibleCueIndex: visibleCueIndex,
    );
  }
  final karaokePos = ref.watch(karaokePositionProvider);
  final positionMs = switch (karaokePos) {
    AsyncData(:final value) => value.inMilliseconds,
    _ => null,
  };
  if (positionMs == null) {
    return (
      cueIndex: cueIndex,
      wordIndex: null,
      visibleCueIndex: visibleCueIndex,
    );
  }
  return (
    cueIndex: cueIndex,
    wordIndex: currentWordIndex(lines[cueIndex], positionMs),
    visibleCueIndex: visibleCueIndex,
  );
}

/// Caption-overlay display-window policy (professional subtitling lead-in /
/// tail-out, clamped against neighbouring cues).
///
/// For cue i (in seconds):
///   window start = max(start_i - 200 ms, min(end_{i-1}, start_i))
///     — lead in across real gaps only; back-to-back speech appears exactly
///     on cue instead of racing ahead of the still-displayed previous line.
///   window end   = max(end_i, min(end_i + 300 ms, start_{i+1} - 80 ms))
///     — linger up to 300 ms after speech for reading comfort, but always
///     yield before the next line starts, and never clip this cue's own
///     speech (the `max` with `end_i` guards sub-80 ms gaps and overlapping
///     cue timings from whisper).
///
/// Windows are monotonically ordered and non-overlapping in display-start
/// order (verified by construction), so a binary search on the display start
/// finds the only candidate window; return its index when [t] falls inside,
/// or -1 outside every window.
int _captionVisibleIndex(List<TranscriptLine> lines, double t) {
  const leadIn = 0.2;
  const tailOut = 0.3;
  const yieldGap = 0.08;
  if (lines.isEmpty) return -1;

  double displayStartOf(int i) {
    final start = lines[i].startSeconds;
    final prevEnd = i > 0
        ? lines[i - 1].endSeconds
        : double.negativeInfinity;
    // Floor at start_i so overlapping whisper timings never push the window
    // past the cue's own speech.
    final floor = prevEnd < start ? prevEnd : start;
    final lead = start - leadIn;
    return lead > floor ? lead : floor;
  }

  double displayEndOf(int i) {
    final end = lines[i].endSeconds;
    if (i + 1 >= lines.length) return end + tailOut;
    final nextStart = lines[i + 1].startSeconds;
    final ceiling = nextStart - yieldGap > end ? nextStart - yieldGap : end;
    final linger = end + tailOut;
    return linger < ceiling ? linger : ceiling;
  }

  var lo = 0;
  var hi = lines.length - 1;
  var best = -1;
  while (lo <= hi) {
    final mid = (lo + hi) ~/ 2;
    if (displayStartOf(mid) <= t) {
      best = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  if (best < 0) return -1;
  return t < displayEndOf(best) ? best : -1;
}
