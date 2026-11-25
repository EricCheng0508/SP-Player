import 'dart:async';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/presentation/section_label.dart';
import 'package:enjoy_player/core/validation/byok_secret_mask.dart';
import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/features/ai/application/ai_modality_config_controller.dart';
import 'package:enjoy_player/features/ai/domain/ai_provider.dart';
import 'package:enjoy_player/features/ai/domain/ai_service_config.dart';
import 'package:enjoy_player/features/ai/domain/llm_api_spec.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/speech_byok_kind.dart';
import 'package:enjoy_player/features/ai/presentation/settings/widgets/asr_local_components.dart';
import 'package:enjoy_player/features/ai/presentation/settings/widgets/byok_api_key_field.dart';
import 'package:enjoy_player/features/ai/presentation/settings/widgets/llm_byok_form.dart';
import 'package:enjoy_player/features/ai/presentation/settings/widgets/speech_endpoint_tile.dart';
import 'package:enjoy_player/features/local_components/data/managed_llama_server.dart';
import 'package:enjoy_player/features/local_components/domain/component_catalog.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// AI engines screen — one card, three engine sections (recognition,
/// translation & language model, text-to-speech) and ONE shared cloud
/// speech endpoint typed once for recognition + synthesis.
class AiProvidersScreen extends ConsumerStatefulWidget {
  const AiProvidersScreen({super.key});

  @override
  ConsumerState<AiProvidersScreen> createState() => _AiProvidersScreenState();
}

class _AiProvidersScreenState extends ConsumerState<AiProvidersScreen> {
  bool _asrLocal = true;
  bool _ttsLocal = true;
  bool _mtLocal = true;

  // Shared cloud speech endpoint (ASR + TTS).
  SpeechByokKind _speechKind = SpeechByokKind.openAiCompatible;
  final _speechBaseUrl = TextEditingController();
  final _speechKey = TextEditingController();
  final _speechRegion = TextEditingController();
  final _whisperModel = TextEditingController();
  final _ttsModel = TextEditingController();
  bool _hasSpeechKey = false;
  String? _speechMasked;

  // Translation & language model (cloud side uses the LLM form).
  LlmApiSpec _llmSpec = LlmApiSpec.openAiCompatible;
  String? _llmPresetId;
  final _llmBaseUrl = TextEditingController();
  final _llmKey = TextEditingController();
  final _llmModel = TextEditingController();
  bool _hasLlmKey = false;
  String? _llmMasked;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  void _hydrate() {
    final configs = ref.read(aiModalityConfigCtrlProvider);
    final asr = configs.asr.speechByok;
    final tts = configs.tts.speechByok;
    _asrLocal = asr == null;
    _ttsLocal = tts == null;
    final speech = asr ?? tts;
    if (speech != null) {
      _speechKind = speech.kind;
      _speechBaseUrl.text = speech.baseUrl ?? '';
      _speechRegion.text = speech.region ?? '';
      _whisperModel.text = asr?.model ?? '';
      _ttsModel.text = tts?.model ?? '';
    }

    final llm = configs.llm.llmByok;
    final isLocalLlm =
        llm != null &&
        llm.baseUrl.startsWith('http://127.0.0.1') &&
        llm.baseUrl.contains('8760');
    _mtLocal = llm == null || isLocalLlm;
    if (llm != null && !isLocalLlm) {
      _llmSpec = llm.apiSpec;
      _llmPresetId = llm.presetId;
      _llmBaseUrl.text = llm.baseUrl;
      _llmModel.text = llm.model;
    }
    unawaited(_loadKeyHints());
  }

  Future<void> _loadKeyHints() async {
    final store = ref.read(byokSecretStoreProvider);
    final hasSpeech = await store.hasApiKey(ModalityKind.asr);
    final hasLlm = await store.hasApiKey(ModalityKind.llm);
    String? speechMask;
    String? llmMask;
    if (hasSpeech) {
      final k = await store.readApiKey(ModalityKind.asr);
      if (k != null && k.isNotEmpty) speechMask = maskByokApiKey(k);
    }
    if (hasLlm) {
      final k = await store.readApiKey(ModalityKind.llm);
      if (k != null && k.isNotEmpty) llmMask = maskByokApiKey(k);
    }
    if (!mounted) return;
    setState(() {
      _hasSpeechKey = hasSpeech;
      _speechMasked = speechMask;
      _hasLlmKey = hasLlm;
      _llmMasked = llmMask;
    });
  }

  @override
  void dispose() {
    _speechBaseUrl.dispose();
    _speechKey.dispose();
    _speechRegion.dispose();
    _whisperModel.dispose();
    _ttsModel.dispose();
    _llmBaseUrl.dispose();
    _llmKey.dispose();
    _llmModel.dispose();
    super.dispose();
  }

  SpeechByokConfig _sharedSpeechConfig(String model) {
    if (_speechKind == SpeechByokKind.azureSpeech) {
      return SpeechByokConfig(
        kind: SpeechByokKind.azureSpeech,
        region: _speechRegion.text.trim(),
        model: model.isEmpty ? null : model,
      );
    }
    return SpeechByokConfig(
      kind: SpeechByokKind.openAiCompatible,
      baseUrl: _speechBaseUrl.text.trim(),
      model: model.isEmpty ? null : model,
    );
  }

  Future<void> _saveAll() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    final ctrl = ref.read(aiModalityConfigCtrlProvider.notifier);
    final failures = <String>[];
    try {
      // ① 语音识别
      if (_asrLocal) {
        await ctrl.removeByok(ModalityKind.asr);
      } else {
        final r = await ctrl.saveModality(
          modality: ModalityKind.asr,
          config: AIServiceConfig(
            provider: AIProvider.byok,
            speechByok: _sharedSpeechConfig(_whisperModel.text.trim()),
          ),
          apiKey: _speechKey.text.trim().isEmpty
              ? null
              : _speechKey.text.trim(),
        );
        if (!r.isValid) failures.add('语音识别');
      }
      // ② 字幕翻译与语言模型
      if (_mtLocal) {
        await ctrl.saveModality(
          modality: ModalityKind.llm,
          config: const AIServiceConfig(
            provider: AIProvider.byok,
            llmByok: LlmByokConfig(
              apiSpec: LlmApiSpec.openAiCompatible,
              baseUrl: kLocalLlmBaseUrl,
              model: kLocalLlmModelId,
            ),
          ),
          apiKey: 'local',
        );
      } else {
        final r = await ctrl.saveModality(
          modality: ModalityKind.llm,
          config: AIServiceConfig(
            provider: AIProvider.byok,
            llmByok: LlmByokConfig(
              apiSpec: _llmSpec,
              baseUrl: _llmBaseUrl.text.trim(),
              model: _llmModel.text.trim(),
              presetId: _llmPresetId,
            ),
          ),
          apiKey: _llmKey.text.trim().isEmpty ? null : _llmKey.text.trim(),
        );
        if (!r.isValid) failures.add('字幕翻译');
      }
      // ③ 文字转语音
      if (_ttsLocal) {
        await ctrl.removeByok(ModalityKind.tts);
      } else {
        final r = await ctrl.saveModality(
          modality: ModalityKind.tts,
          config: AIServiceConfig(
            provider: AIProvider.byok,
            speechByok: _sharedSpeechConfig(_ttsModel.text.trim()),
          ),
          apiKey: _speechKey.text.trim().isEmpty
              ? null
              : _speechKey.text.trim(),
        );
        if (!r.isValid) failures.add('文字转语音');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    if (failures.isEmpty) {
      _speechKey.clear();
      _llmKey.clear();
      await _loadKeyHints();
      if (!mounted) return;
      AppNotice.success(context, l10n.settingsAiProvidersSaveSuccess);
    } else {
      AppNotice.error(context, '以下配置不完整：${failures.join('、')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final showSpeechEndpoint = !_asrLocal || !_ttsLocal;

    return EnjoyPage(
      kind: EnjoyPageKind.hub,
      title: l10n.settingsAiProvidersTitle,
      showBack: true,
      body: (context, metrics) => ListView(
        padding: metrics.padding(top: t.space16, bottom: t.space32),
        children: [
          Text(
            l10n.settingsAiProvidersSubtitle,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          SizedBox(height: t.space16),
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
                if (showSpeechEndpoint) ...[
                  _SpeechServiceBlock(
                    kind: _speechKind,
                    onKindChanged: (k) => setState(() => _speechKind = k),
                    baseUrlController: _speechBaseUrl,
                    keyController: _speechKey,
                    regionController: _speechRegion,
                    hasExistingKey: _hasSpeechKey,
                    maskedPreview: _speechMasked,
                  ),
                  Divider(height: t.space24, color: t.line),
                ],
                // ① 语音识别
                _EngineSection(
                  icon: EnjoyIcons.waveform,
                  title: l10n.settingsAiProvidersModalityAsr,
                  subtitle: l10n.settingsAiProvidersModalityAsrHint,
                  isLocal: _asrLocal,
                  onChanged: (local) => setState(() => _asrLocal = local),
                  localBody: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.settingsAiProvidersAsrLocalHint,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
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
                    ],
                  ),
                  cloudBody: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '端点在卡片顶部「云端语音服务」选择（识别与合成共用），这里只填识别模型名。',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: t.space12),
                      TextField(
                        controller: _whisperModel,
                        decoration: InputDecoration(
                          labelText: l10n
                              .settingsAiProvidersSpeechWhisperModelLabel,
                          hintText: l10n
                              .settingsAiProvidersSpeechWhisperModelHint,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: t.space24, color: t.line),
                // ② 字幕翻译与语言模型
                _EngineSection(
                  icon: EnjoyIcons.sparkle,
                  title: '字幕翻译与语言模型',
                  subtitle: '字幕翻译、词典与语境翻译共用这一份配置',
                  cloudLabel: '云端 · 推荐',
                  isLocal: _mtLocal,
                  onChanged: (local) => setState(() => _mtLocal = local),
                  localBody: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '离线翻译：llama.cpp + TranslateGemma，下载后无需联网。',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const AsrLocalComponents(
                        kinds: [
                          ComponentKind.mtRuntime,
                          ComponentKind.mtModel,
                        ],
                      ),
                    ],
                  ),
                  cloudBody: LlmByokForm(
                    apiSpec: _llmSpec,
                    baseUrlController: _llmBaseUrl,
                    apiKeyController: _llmKey,
                    modelController: _llmModel,
                    hasExistingKey: _hasLlmKey,
                    presetId: _llmPresetId,
                    maskedApiKeyPreview: _llmMasked,
                    onSpecChanged: (spec) => setState(() {
                      _llmSpec = spec;
                      _llmPresetId = null;
                    }),
                    onPresetSelected: (preset) => setState(() {
                      _llmSpec = preset.apiSpec;
                      _llmPresetId = preset.id;
                      _llmBaseUrl.text = preset.baseUrl;
                      _llmModel.text = preset.model;
                    }),
                  ),
                ),
                Divider(height: t.space24, color: t.line),
                // ③ 文字转语音
                _EngineSection(
                  icon: EnjoyIcons.speak,
                  title: l10n.settingsAiProvidersModalityTts,
                  subtitle: l10n.settingsAiProvidersModalityTtsHint,
                  isLocal: _ttsLocal,
                  onChanged: (local) => setState(() => _ttsLocal = local),
                  localBody: Text(
                    l10n.settingsAiProvidersTtsLocalHint,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  cloudBody: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '端点在卡片顶部「云端语音服务」选择，与识别共用；这里只填合成模型名。',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: t.space12),
                      TextField(
                        controller: _ttsModel,
                        decoration: InputDecoration(
                          labelText:
                              l10n.settingsAiProvidersSpeechTtsModelLabel,
                          hintText: l10n.settingsAiProvidersSpeechTtsModelHint,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: t.space16),
                Row(
                  children: [
                    Icon(EnjoyIcons.lock, size: 16, color: t.ink3),
                    SizedBox(width: t.space8),
                    Expanded(
                      child: Text(
                        l10n.settingsAiProvidersPrivacyNotice,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(
                          color: t.ink3,
                          height: 1.3,
                        ),
                      ),
                    ),
                    SizedBox(width: t.space8),
                    EnjoyButton.brand(
                      onPressed: _saving ? null : _saveAll,
                      child: _saving
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
        ],
      ),
    );
  }
}

/// One engine section: header, local/cloud toggle, and the matching body.
class _EngineSection extends StatelessWidget {
  const _EngineSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLocal,
    required this.onChanged,
    required this.localBody,
    required this.cloudBody,
    this.cloudLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLocal;
  final ValueChanged<bool> onChanged;
  final Widget localBody;
  final Widget cloudBody;

  /// Optional label override for the cloud segment (e.g. "云端 · 推荐").
  final String? cloudLabel;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Icon(icon, size: 19, color: cs.onSurfaceVariant),
            ),
            SizedBox(width: t.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: tt.titleSmall?.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: t.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: tt.bodySmall?.copyWith(
                      color: t.ink3,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: t.space12),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(l10n.settingsAiEngineLocal)),
            ButtonSegment(
              value: false,
              label: Text(cloudLabel ?? l10n.settingsAiEngineCloud),
            ),
          ],
          selected: {isLocal},
          onSelectionChanged: (sel) => onChanged(sel.first),
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
        ),
        SizedBox(height: t.space12),
        // Fixed minimum body height: switching local <-> cloud swaps content
        // of different sizes, and an animated/loose height made the whole
        // card jump under the cursor. Reserve a stable block instead (no
        // animation).
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 132),
          child: isLocal ? localBody : cloudBody,
        ),
      ],
    );
  }
}


/// Shared cloud speech service block (top of the card): vendor kind, endpoint
/// picker tile, key and Azure region. One source of truth for ASR + TTS.
class _SpeechServiceBlock extends StatelessWidget {
  const _SpeechServiceBlock({
    required this.kind,
    required this.onKindChanged,
    required this.baseUrlController,
    required this.keyController,
    required this.regionController,
    required this.hasExistingKey,
    required this.maskedPreview,
  });

  final SpeechByokKind kind;
  final ValueChanged<SpeechByokKind> onKindChanged;
  final TextEditingController baseUrlController;
  final TextEditingController keyController;
  final TextEditingController regionController;
  final bool hasExistingKey;
  final String? maskedPreview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isAzure = kind == SpeechByokKind.azureSpeech;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '云端语音服务（识别与合成共用，只需填一次）',
          style: tt.titleSmall?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: t.ink,
          ),
        ),
        SizedBox(height: t.space12),
        SectionLabel(
          icon: EnjoyIcons.route,
          text: l10n.settingsAiProvidersSpeechKindLabel,
        ),
        SizedBox(height: t.space8),
        SegmentedButton<SpeechByokKind>(
          segments: [
            ButtonSegment(
              value: SpeechByokKind.openAiCompatible,
              label: Text(l10n.settingsAiProvidersSpeechKindOpenAi),
            ),
            ButtonSegment(
              value: SpeechByokKind.azureSpeech,
              label: Text(l10n.settingsAiProvidersSpeechKindAzure),
            ),
          ],
          selected: {kind},
          onSelectionChanged: (sel) => onKindChanged(sel.first),
          style: SegmentedButton.styleFrom(
            visualDensity: VisualDensity.comfortable,
            selectedBackgroundColor: cs.primaryContainer.withValues(
              alpha: 0.55,
            ),
            selectedForegroundColor: cs.onPrimaryContainer,
            foregroundColor: cs.onSurfaceVariant,
            side: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.32),
            ),
          ),
        ),
        SizedBox(height: t.space8),
        Text(
          isAzure
              ? l10n.settingsAiProvidersSpeechKindHintAzure
              : l10n.settingsAiProvidersSpeechKindHintOpenAi,
          style: tt.bodySmall?.copyWith(fontSize: 12, color: t.ink2),
        ),
        SizedBox(height: t.space12),
        SpeechEndpointTile(controller: baseUrlController, enabled: !isAzure),
        SizedBox(height: t.space12),
        ByokApiKeyField(
          controller: keyController,
          hasExistingKey: hasExistingKey,
          labelText: isAzure
              ? l10n.settingsAiProvidersSpeechSubscriptionKeyLabel
              : l10n.settingsAiProvidersApiKeyLabel,
          maskedPreview: maskedPreview,
        ),
        if (isAzure) ...[
          SizedBox(height: t.space12),
          TextField(
            controller: regionController,
            decoration: InputDecoration(
              labelText: l10n.settingsAiProvidersSpeechRegionLabel,
              hintText: l10n.settingsAiProvidersSpeechRegionHint,
            ),
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
          ),
        ],
      ],
    );
  }
}
