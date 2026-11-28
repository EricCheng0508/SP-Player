/// Live captions domain models.
///
/// A session mirrors one listening run: it owns the captured lines (each with
/// a wall-clock offset, the recognized source text and an optional Chinese
/// translation) plus which audio sources were mixed in. Sessions persist as
/// JSON files so history survives restarts (see [LiveCaptionsStore]).
library;

import 'package:json_annotation/json_annotation.dart';

part 'live_caption_models.g.dart';

/// Where a line's audio came from.
enum LiveCaptionSource { system, mic }

@JsonSerializable()
final class LiveCaptionLine {
  LiveCaptionLine({
    required this.offsetSeconds,
    required this.source,
    required this.text,
    this.translation,
    this.failedTranslation = false,
    this.event,
    this.starred = false,
  });

  /// Seconds since the session started, for the timestamp column.
  final double offsetSeconds;

  final LiveCaptionSource source;

  /// Recognized source-language text (what was said).
  final String text;

  /// Chinese translation; null while pending.
  String? translation;

  /// True when the translation call failed — UI shows a retry hint instead
  /// of spinning forever.
  bool failedTranslation;

  /// Non-null for synthetic UI-event rows (监听开关切换、开始/停止监听) —
  /// rendered as a grey divider, never translated.
  String? event;

  /// User starred this line (右键菜单「收藏本句」).
  @JsonKey(defaultValue: false)
  bool starred;

  factory LiveCaptionLine.fromJson(Map<String, dynamic> json) =>
      _$LiveCaptionLineFromJson(json);
  Map<String, dynamic> toJson() => _$LiveCaptionLineToJson(this);
}

@JsonSerializable()
final class LiveCaptionSession {
  LiveCaptionSession({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.sources,
    this.translated = true,
    List<LiveCaptionLine>? lines,
  }) : lines = lines ?? [];

  /// Stable id: `live-<yyyyMMdd-HHmmss>`, also the file name.
  final String id;

  final DateTime startedAt;
  DateTime? endedAt;

  /// Sources mixed into this run.
  final List<LiveCaptionSource> sources;

  /// Whether translations were requested during the run.
  bool translated;

  final List<LiveCaptionLine> lines;

  String get title {
    final m = startedAt.month.toString().padLeft(2, '0');
    final d = startedAt.day.toString().padLeft(2, '0');
    final hh = startedAt.hour.toString().padLeft(2, '0');
    final mm = startedAt.minute.toString().padLeft(2, '0');
    return '$m-$d $hh:$mm';
  }

  Duration get duration => (endedAt ?? DateTime.now()).difference(startedAt);

  factory LiveCaptionSession.fromJson(Map<String, dynamic> json) =>
      _$LiveCaptionSessionFromJson(json);
  Map<String, dynamic> toJson() => _$LiveCaptionSessionToJson(this);
}
