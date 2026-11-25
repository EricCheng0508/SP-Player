import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/features/ai/application/ai_modality_config_controller.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/local_components/domain/component_catalog.dart';
import 'package:enjoy_player/features/ai/presentation/settings/widgets/asr_local_components.dart';
import 'package:enjoy_player/features/ai/presentation/settings/widgets/modality_provider_card.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// AI engines screen: one composed card for the subtitle pipeline
/// (speech recognition + text-to-speech) with a shared save button, then
/// the standalone language-model card.
class AiProvidersScreen extends ConsumerStatefulWidget {
  const AiProvidersScreen({super.key});

  @override
  ConsumerState<AiProvidersScreen> createState() => _AiProvidersScreenState();
}

class _AiProvidersScreenState extends ConsumerState<AiProvidersScreen> {
  final _asrKey = GlobalKey<ModalityProviderCardState>();
  final _ttsKey = GlobalKey<ModalityProviderCardState>();
  bool _savingEngines = false;

  Future<void> _saveEngines() async {
    setState(() => _savingEngines = true);
    var allOk = true;
    try {
      final asrOk = await _asrKey.currentState?.save() ?? false;
      final ttsOk = await _ttsKey.currentState?.save() ?? false;
      allOk = asrOk && ttsOk;
    } finally {
      if (mounted) setState(() => _savingEngines = false);
    }
    if (!mounted) return;
    if (allOk) {
      AppNotice.success(
        context,
        AppLocalizations.of(context)!.settingsAiProvidersSaveSuccess,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final configs = ref.watch(aiModalityConfigCtrlProvider);

    return EnjoyPage(
      kind: EnjoyPageKind.hub,
      title: l10n.settingsAiProvidersTitle,
      showBack: true,
      body: (context, metrics) => ListView(
        padding: metrics.padding(top: t.space16, bottom: t.space32),
        children: [
          Text(
            l10n.settingsAiProvidersSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          SizedBox(height: t.space16),
          _PrivacyCallout(text: l10n.settingsAiProvidersPrivacyNotice),
          SizedBox(height: t.space20),
          // ── Merged engines card: subtitle pipeline (ASR + TTS) ──
          Container(
            decoration: ShapeDecoration(
              color: t.paper,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(t.radiusCard),
                side: BorderSide(color: t.brandInk),
              ),
            ),
            padding: EdgeInsets.all(t.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ModalityProviderCard(
                  key: _asrKey,
                  embedded: true,
                  modality: ModalityKind.asr,
                  title: l10n.settingsAiProvidersModalityAsr,
                  subtitle: l10n.settingsAiProvidersModalityAsrHint,
                  config: configs.asr,
                  localBody: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.settingsAiProvidersAsrLocalHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const AsrLocalComponents(
                        kinds: [
                          ComponentKind.asrRuntime,
                          ComponentKind.asrModel,
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '字幕翻译（离线翻译用，可选）',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const AsrLocalComponents(
                        kinds: [ComponentKind.mtRuntime, ComponentKind.mtModel],
                      ),
                    ],
                  ),
                ),
                Divider(height: t.space24, color: t.line),
                ModalityProviderCard(
                  key: _ttsKey,
                  embedded: true,
                  modality: ModalityKind.tts,
                  title: l10n.settingsAiProvidersModalityTts,
                  subtitle: l10n.settingsAiProvidersModalityTtsHint,
                  config: configs.tts,
                  localBody: Text(
                    l10n.settingsAiProvidersTtsLocalHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: t.space12),
                Row(
                  children: [
                    Icon(EnjoyIcons.lock, size: 16, color: t.ink3),
                    SizedBox(width: t.space8),
                    Expanded(
                      child: Text(
                        l10n.settingsAiProvidersPrivacyNotice,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: t.ink3,
                          height: 1.3,
                        ),
                      ),
                    ),
                    SizedBox(width: t.space8),
                    EnjoyButton.brand(
                      onPressed: _savingEngines ? null : _saveEngines,
                      child: _savingEngines
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.settingsAiProvidersSave),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: t.space12),
          ModalityProviderCard(
            modality: ModalityKind.llm,
            title: l10n.settingsAiProvidersModalityLlm,
            subtitle: l10n.settingsAiProvidersModalityLlmHint,
            config: configs.llm,
          ),
        ],
      ),
    );
  }
}

class _PrivacyCallout extends StatelessWidget {
  const _PrivacyCallout({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: t.originalSoft,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(t.radiusTile),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(EnjoyIcons.shield, color: t.originalInk, size: 17),
            SizedBox(width: t.space12),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: tt.bodySmall?.copyWith(
                  fontSize: 13,
                  color: t.originalInk,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
