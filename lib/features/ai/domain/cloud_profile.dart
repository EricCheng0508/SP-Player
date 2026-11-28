/// Saved cloud service profiles for the AI settings screen.
///
/// Two independent families:
/// - speech: shared by speech recognition (ASR) and text-to-speech (TTS) —
///   one endpoint/key pair, one model per function;
/// - llm: translation / dictionary / contextual translation (chat API).
///
/// API keys never live here — [ByokSecretStore] owns them per modality; the
/// profile only records whether a key has been stored.
library;

import 'package:flutter/foundation.dart';

enum CloudVendor { openAiCompatible, azure }

@immutable
class CloudSpeechProfile {
  const CloudSpeechProfile({
    required this.id,
    required this.name,
    this.vendor = CloudVendor.openAiCompatible,
    this.endpoint = '',
    this.region = '',
    this.asrModel = 'whisper-1',
    this.ttsModel = 'tts-1',
    this.hasKey = false,
  });

  final String id;
  final String name;
  final CloudVendor vendor;
  final String endpoint;
  final String region;
  final String asrModel;
  final String ttsModel;
  final bool hasKey;

  CloudSpeechProfile copyWith({
    String? name,
    CloudVendor? vendor,
    String? endpoint,
    String? region,
    String? asrModel,
    String? ttsModel,
    bool? hasKey,
  }) => CloudSpeechProfile(
    id: id,
    name: name ?? this.name,
    vendor: vendor ?? this.vendor,
    endpoint: endpoint ?? this.endpoint,
    region: region ?? this.region,
    asrModel: asrModel ?? this.asrModel,
    ttsModel: ttsModel ?? this.ttsModel,
    hasKey: hasKey ?? this.hasKey,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'vendor': vendor.name,
    'endpoint': endpoint,
    'region': region,
    'asrModel': asrModel,
    'ttsModel': ttsModel,
    'hasKey': hasKey,
  };

  static CloudSpeechProfile? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) return null;
    return CloudSpeechProfile(
      id: id,
      name: json['name'] as String? ?? '',
      vendor: CloudVendor.values.firstWhere(
        (v) => v.name == json['vendor'],
        orElse: () => CloudVendor.openAiCompatible,
      ),
      endpoint: json['endpoint'] as String? ?? '',
      region: json['region'] as String? ?? '',
      asrModel: json['asrModel'] as String? ?? 'whisper-1',
      ttsModel: json['ttsModel'] as String? ?? 'tts-1',
      hasKey: json['hasKey'] as bool? ?? false,
    );
  }

  /// Summary line for the section's cloud box.
  String get summary {
    final host = vendor == CloudVendor.azure
        ? 'Azure · $region'
        : endpoint.replaceFirst(RegExp(r'^https?://'), '');
    return '$host · 识别 $asrModel / 合成 $ttsModel';
  }
}

@immutable
class CloudLlmProfile {
  const CloudLlmProfile({
    required this.id,
    required this.name,
    this.vendor = CloudVendor.openAiCompatible,
    this.endpoint = '',
    this.region = '',
    this.model = 'gpt-4o-mini',
    this.hasKey = false,
  });

  final String id;
  final String name;
  final CloudVendor vendor;
  final String endpoint;
  final String region;
  final String model;
  final bool hasKey;

  CloudLlmProfile copyWith({
    String? name,
    CloudVendor? vendor,
    String? endpoint,
    String? region,
    String? model,
    bool? hasKey,
  }) => CloudLlmProfile(
    id: id,
    name: name ?? this.name,
    vendor: vendor ?? this.vendor,
    endpoint: endpoint ?? this.endpoint,
    region: region ?? this.region,
    model: model ?? this.model,
    hasKey: hasKey ?? this.hasKey,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'vendor': vendor.name,
    'endpoint': endpoint,
    'region': region,
    'model': model,
    'hasKey': hasKey,
  };

  static CloudLlmProfile? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) return null;
    return CloudLlmProfile(
      id: id,
      name: json['name'] as String? ?? '',
      vendor: CloudVendor.values.firstWhere(
        (v) => v.name == json['vendor'],
        orElse: () => CloudVendor.openAiCompatible,
      ),
      endpoint: json['endpoint'] as String? ?? '',
      region: json['region'] as String? ?? '',
      model: json['model'] as String? ?? 'gpt-4o-mini',
      hasKey: json['hasKey'] as bool? ?? false,
    );
  }

  /// Summary line for the section's cloud box.
  String get summary {
    final host = vendor == CloudVendor.azure
        ? 'Azure · $region'
        : endpoint.replaceFirst(RegExp(r'^https?://'), '');
    return '$host · $model';
  }
}

/// Built-in LLM presets (protocol + endpoint + default model).
@immutable
class LlmPreset {
  const LlmPreset(this.id, this.label, this.endpoint, this.model);
  final String id;
  final String label;
  final String endpoint;
  final String model;
}

const List<LlmPreset> kLlmPresets = [
  LlmPreset('openai', 'OpenAI', 'https://api.openai.com/v1', 'gpt-4o-mini'),
  LlmPreset(
    'deepseek',
    'DeepSeek',
    'https://api.deepseek.com/v1',
    'deepseek-chat',
  ),
  LlmPreset(
    'groq',
    'Groq',
    'https://api.groq.com/openai/v1',
    'llama-3.3-70b-versatile',
  ),
  LlmPreset('azureOpenAi', 'Azure OpenAI', '', ''),
  LlmPreset(
    'anthropic',
    'Anthropic',
    'https://api.anthropic.com/v1',
    'claude-3-5-sonnet',
  ),
  LlmPreset(
    'google',
    'Google',
    'https://generativelanguage.googleapis.com/v1beta',
    'gemini-2.0-flash',
  ),
  LlmPreset('custom', '自定义', '', ''),
];
