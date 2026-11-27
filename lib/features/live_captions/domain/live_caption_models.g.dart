// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_caption_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveCaptionLine _$LiveCaptionLineFromJson(Map<String, dynamic> json) =>
    LiveCaptionLine(
      offsetSeconds: (json['offsetSeconds'] as num).toDouble(),
      source: $enumDecode(_$LiveCaptionSourceEnumMap, json['source']),
      text: json['text'] as String,
      translation: json['translation'] as String?,
      failedTranslation: json['failedTranslation'] as bool? ?? false,
      event: json['event'] as String?,
      starred: json['starred'] as bool? ?? false,
    );

Map<String, dynamic> _$LiveCaptionLineToJson(LiveCaptionLine instance) =>
    <String, dynamic>{
      'offsetSeconds': instance.offsetSeconds,
      'source': _$LiveCaptionSourceEnumMap[instance.source]!,
      'text': instance.text,
      'translation': instance.translation,
      'failedTranslation': instance.failedTranslation,
      'event': instance.event,
      'starred': instance.starred,
    };

const _$LiveCaptionSourceEnumMap = {
  LiveCaptionSource.system: 'system',
  LiveCaptionSource.mic: 'mic',
};

LiveCaptionSession _$LiveCaptionSessionFromJson(Map<String, dynamic> json) =>
    LiveCaptionSession(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      sources: (json['sources'] as List<dynamic>)
          .map((e) => $enumDecode(_$LiveCaptionSourceEnumMap, e))
          .toList(),
      translated: json['translated'] as bool? ?? true,
      lines: (json['lines'] as List<dynamic>?)
          ?.map((e) => LiveCaptionLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LiveCaptionSessionToJson(LiveCaptionSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startedAt': instance.startedAt.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
      'sources': instance.sources
          .map((e) => _$LiveCaptionSourceEnumMap[e]!)
          .toList(),
      'translated': instance.translated,
      'lines': instance.lines,
    };
