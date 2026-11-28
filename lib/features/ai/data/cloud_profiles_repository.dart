/// Persistence + providers for saved cloud service profiles.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/ai/domain/cloud_profile.dart';

@immutable
class CloudProfiles {
  const CloudProfiles({this.speech = const [], this.llm = const []});

  final List<CloudSpeechProfile> speech;
  final List<CloudLlmProfile> llm;

  CloudProfiles copyWith({
    List<CloudSpeechProfile>? speech,
    List<CloudLlmProfile>? llm,
  }) => CloudProfiles(speech: speech ?? this.speech, llm: llm ?? this.llm);

  Map<String, dynamic> toJson() => {
    'speech': [for (final p in speech) p.toJson()],
    'llm': [for (final p in llm) p.toJson()],
  };

  static CloudProfiles fromJson(Map<String, dynamic> json) {
    List<T> parse<T>(Object? raw, T? Function(Map<String, dynamic>) f) {
      if (raw is! List) return const [];
      return [
        for (final item in raw)
          if (item is Map<String, dynamic>)
            if (f(item) case final v?) v,
      ];
    }

    return CloudProfiles(
      speech: parse(json['speech'], CloudSpeechProfile.fromJson),
      llm: parse(json['llm'], CloudLlmProfile.fromJson),
    );
  }
}

final cloudProfilesProvider = FutureProvider<CloudProfiles>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  try {
    final raw = await db.settingsDao.readSetting(
      SettingsKeys.aiCloudProfilesV1,
    );
    if (raw.trim().isEmpty) return const CloudProfiles();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return const CloudProfiles();
    return CloudProfiles.fromJson(decoded);
  } on Object {
    return const CloudProfiles();
  }
});

Future<void> writeCloudProfiles(
  WidgetRef ref,
  CloudProfiles profiles,
) async {
  final db = ref.read(appDatabaseProvider);
  await db.settingsDao.writeSetting(
    SettingsKeys.aiCloudProfilesV1,
    jsonEncode(profiles.toJson()),
  );
  ref.invalidate(cloudProfilesProvider);
}

/// Synchronous snapshot helper for screens that hydrated once.
CloudProfiles readCloudProfilesNow(WidgetRef ref) =>
    ref.read(cloudProfilesProvider).value ?? const CloudProfiles();
