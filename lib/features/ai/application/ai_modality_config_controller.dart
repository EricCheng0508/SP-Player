import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/ai/application/ai_modality_configs.dart';
import 'package:enjoy_player/features/ai/data/ai_modality_config_repository.dart';
import 'package:enjoy_player/features/ai/domain/ai_service_config.dart';
import 'package:enjoy_player/features/ai/domain/byok_config_validator.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';

part 'ai_modality_config_controller.g.dart';

@Riverpod(keepAlive: true)
AiModalityConfigRepository aiModalityConfigRepository(Ref ref) {
  return AiModalityConfigRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(byokSecretStoreProvider),
    const ByokConfigValidator(),
  );
}

@Riverpod(keepAlive: true)
class AiModalityConfigCtrl extends _$AiModalityConfigCtrl {
  Completer<void>? _hydrateCompleter;

  /// Completes once [_hydrate] has finished loading the persisted config.
  ///
  /// [build] returns [AiModalityConfigs.defaults] synchronously and loads the
  /// real config from the database in a microtask — the provider is lazy, so
  /// the very first AI call of a session can resolve a "not configured" stub
  /// while hydration is still in flight. Callers that observe BYOK as
  /// unconfigured should await this before concluding the key is truly
  /// missing (auto-translate was permanently blocked by exactly this race).
  Future<void> get hydrated =>
      (_hydrateCompleter ??= Completer<void>()).future;

  @override
  AiModalityConfigs build() {
    _hydrateCompleter = Completer<void>();
    unawaited(Future<void>.microtask(_hydrate));
    return AiModalityConfigs.defaults;
  }

  Future<void> _hydrate() async {
    final completer = _hydrateCompleter;
    try {
      final repo = ref.read(aiModalityConfigRepositoryProvider);
      final loaded = await repo.load();
      if (ref.mounted) state = loaded;
    } finally {
      completer?.complete();
    }
  }

  Future<ByokValidationResult> saveModality({
    required ModalityKind modality,
    required AIServiceConfig config,
    String? apiKey,
  }) async {
    final repo = ref.read(aiModalityConfigRepositoryProvider);
    final result = await repo.saveModality(
      modality: modality,
      config: config,
      apiKey: apiKey,
    );
    if (result.isValid) {
      state = await repo.load();
    }
    return result;
  }

  Future<void> removeByok(ModalityKind modality) async {
    final repo = ref.read(aiModalityConfigRepositoryProvider);
    await repo.removeByok(modality);
    state = await repo.load();
  }

}
