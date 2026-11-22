/// Persisted on-video caption overlay preference (default off).
///
/// Controls the transparent subtitle line rendered over the bottom of the
/// video area. Storage goes through the typed [SettingsKeys.playerCaptionOverlay]
/// key (`'off'`/`'original'`/`'translation'`/`'both'`); scope and default live
/// in the key's declaration (`settings_keys.dart`), not here.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';

part 'caption_overlay_settings.g.dart';

enum CaptionOverlayMode {
  off,
  original,
  translation,
  both;

  static CaptionOverlayMode fromStored(String? raw) {
    switch (raw) {
      case 'original':
        return CaptionOverlayMode.original;
      case 'translation':
        return CaptionOverlayMode.translation;
      case 'both':
        return CaptionOverlayMode.both;
      default:
        return CaptionOverlayMode.off;
    }
  }

  String get storedName => switch (this) {
    off => 'off',
    original => 'original',
    translation => 'translation',
    both => 'both',
  };
}

@Riverpod(keepAlive: true)
class CaptionOverlaySettings extends _$CaptionOverlaySettings {
  @override
  Future<CaptionOverlayMode> build() async {
    final db = ref.watch(deviceGlobalAppDatabaseProvider);
    final raw = await db.settingsDao.readSetting(
      SettingsKeys.playerCaptionOverlay,
    );
    return CaptionOverlayMode.fromStored(raw);
  }

  Future<void> setMode(CaptionOverlayMode mode) async {
    final db = ref.read(deviceGlobalAppDatabaseProvider);
    await db.settingsDao.writeSetting(
      SettingsKeys.playerCaptionOverlay,
      mode.storedName,
    );
    state = AsyncData(mode);
  }
}
