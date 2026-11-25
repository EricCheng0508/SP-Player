import 'dart:async';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/features/ai/application/ai_modality_config_controller.dart';
import 'package:enjoy_player/features/ai/data/cloud_profiles_repository.dart';
import 'package:enjoy_player/features/ai/domain/ai_provider.dart';
import 'package:enjoy_player/features/ai/domain/ai_service_config.dart';
import 'package:enjoy_player/features/ai/domain/cloud_profile.dart';
import 'package:enjoy_player/features/ai/domain/llm_api_spec.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/speech_byok_kind.dart';
import 'package:enjoy_player/features/ai/presentation/settings/widgets/asr_local_components.dart';
import 'package:enjoy_player/features/ai/presentation/settings/widgets/cloud_profile_dialog.dart';
import 'package:enjoy_player/features/local_components/data/managed_llama_server.dart';
import 'package:enjoy_player/features/local_components/domain/component_catalog.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// AI engines screen — two functional blocks:
/// ① translation & language model (cloud recommended, default),
/// ② speech service (recognition + synthesis, shared cloud config).
///
/// Each block shows exactly one pane (local or cloud) inside a fixed-height
/// area, so switching never resizes the page. Cloud panes are a single
/// compact box that opens the profile dialog.
class AiProvidersScreen extends ConsumerStatefulWidget {
  const AiProvidersScreen({super.key});

  @override
  ConsumerState<AiProvidersScreen> createState() => _AiProvidersScreenState();
}

class _AiProvidersScreenState extends ConsumerState<AiProvidersScreen> {
  bool _mtCloud = true; // translation defaults to cloud (recommended)
  bool _speechLocal = true;

  CloudLlmProfile? _llmProfile;
  CloudSpeechProfile? _speechProfile;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  void _hydrate() {
    final configs = ref.read(aiModalityConfigCtrlProvider);
    final llm = configs.llm.llmByok;
    final isLocalLlm =
        llm != null &&
        llm.baseUrl.startsWith('http://127.0.0.1') &&
        llm.baseUrl.contains('8760');
    _mtCloud = llm != null && !isLocalLlm;

    final asr = configs.asr.speechByok;
    final tts = configs.tts.speechByok;
    _speechLocal = asr == null && tts == null;

    final profiles = ref.read(cloudProfilesProvider).value;
    if (profiles != null) {
      _matchProfiles(profiles);
    } else {
      unawaited(
        ref.read(cloudProfilesProvider.future).then((loaded) {
          if (!mounted) return;
          setState(() => _matchProfiles(loaded));
        }),
      );
    }
  }

  void _matchProfiles(CloudProfiles profiles) {
    final configs = ref.read(aiModalityConfigCtrlProvider);
    final llm = configs.llm.llmByok;
    if (_mtCloud && llm != null) {
      for (final p in profiles.llm) {
        if (_endpointMatches(p.endpoint, p.region, llm.baseUrl)) {
          _llmProfile = p;
          break;
        }
      }
    }
    if (!_speechLocal) {
      final speech = configs.asr.speechByok ?? configs.tts.speechByok;
      for (final p in profiles.speech) {
        if (_endpointMatches(
          p.endpoint,
          p.region,
          speech?.baseUrl ?? '',
        )) {
          _speechProfile = p;
          break;
        }
      }
    }
  }

  bool _endpointMatches(String endpoint, String region, String baseUrl) {
    if (endpoint.isNotEmpty && endpoint == baseUrl) return true;
    if (region.isNotEmpty && baseUrl.contains(region)) return true;
    return false;
  }

  Future<void> _pickLlm({required bool revertOnCancel}) async {
    final selection = await showCloudProfileDialog(
      context: context,
      ref: ref,
      speech: false,
      selectedId: _llmProfile?.id,
    );
    if (!mounted) return;
    final picked = selection?.llm;
    if (picked == null) {
      if (revertOnCancel) setState(() => _mtCloud = false);
      return;
    }
    await _applyLlm(picked, selection!.apiKey);
  }

  Future<void> _applyLlm(CloudLlmProfile p, String? key) async {
    setState(() => _applying = true);
    try {
      final secrets = ref.read(byokSecretStoreProvider);
      if (key != null && key.isNotEmpty) {
        await secrets.writeApiKey(ModalityKind.llm, key);
      }
      final baseUrl = p.vendor == CloudVendor.azure && p.endpoint.isEmpty
          ? 'https://${p.region}.openai.azure.com/openai/v1'
          : p.endpoint;
      await ref
          .read(aiModalityConfigCtrlProvider.notifier)
          .saveModality(
            modality: ModalityKind.llm,
            config: AIServiceConfig(
              provider: AIProvider.byok,
              llmByok: LlmByokConfig(
                apiSpec: LlmApiSpec.openAiCompatible,
                baseUrl: baseUrl,
                model: p.model,
              ),
            ),
            apiKey: key,
          );
      if (!mounted) return;
      setState(() {
        _llmProfile = p;
        _mtCloud = true;
      });
      AppNotice.success(context, '已启用：${p.name}');
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _pickSpeech({required bool revertOnCancel}) async {
    final selection = await showCloudProfileDialog(
      context: context,
      ref: ref,
      speech: true,
      selectedId: _speechProfile?.id,
    );
    if (!mounted) return;
    final picked = selection?.speech;
    if (picked == null) {
      if (revertOnCancel) setState(() => _speechLocal = true);
      return;
    }
    await _applySpeech(picked, selection!.apiKey);
  }

  Future<void> _applySpeech(CloudSpeechProfile p, String? key) async {
    setState(() => _applying = true);
    try {
      final secrets = ref.read(byokSecretStoreProvider);
      if (key != null && key.isNotEmpty) {
        await secrets.writeApiKey(ModalityKind.asr, key);
        await secrets.writeApiKey(ModalityKind.tts, key);
      }
      final kind = p.vendor == CloudVendor.azure
          ? SpeechByokKind.azureSpeech
          : SpeechByokKind.openAiCompatible;
      final ctrl = ref.read(aiModalityConfigCtrlProvider.notifier);
      final r1 = await ctrl.saveModality(
        modality: ModalityKind.asr,
        config: AIServiceConfig(
          provider: AIProvider.byok,
          speechByok: SpeechByokConfig(
            kind: kind,
            baseUrl: p.endpoint.isEmpty ? null : p.endpoint,
            region: p.region.isEmpty ? null : p.region,
            model: p.asrModel,
          ),
        ),
        apiKey: key,
      );
      final r2 = await ctrl.saveModality(
        modality: ModalityKind.tts,
        config: AIServiceConfig(
          provider: AIProvider.byok,
          speechByok: SpeechByokConfig(
            kind: kind,
            baseUrl: p.endpoint.isEmpty ? null : p.endpoint,
            region: p.region.isEmpty ? null : p.region,
            model: p.ttsModel,
          ),
        ),
        apiKey: key,
      );
      if (!mounted) return;
      if (!r1.isValid || !r2.isValid) {
        AppNotice.error(context, '该配置缺少密钥，请点「编辑」补充密钥后再试');
        return;
      }
      setState(() {
        _speechProfile = p;
        _speechLocal = false;
      });
      AppNotice.success(context, '已启用：${p.name}');
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _useLocalTranslation() async {
    await ref
        .read(aiModalityConfigCtrlProvider.notifier)
        .saveModality(
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
    if (!mounted) return;
    setState(() {
      _mtCloud = false;
      _llmProfile = null;
    });
  }

  Future<void> _useLocalSpeech() async {
    final ctrl = ref.read(aiModalityConfigCtrlProvider.notifier);
    await ctrl.removeByok(ModalityKind.asr);
    await ctrl.removeByok(ModalityKind.tts);
    if (!mounted) return;
    setState(() {
      _speechLocal = true;
      _speechProfile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

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
                // ① 字幕翻译与语言模型（默认云端）
                _EngineSection(
                  icon: EnjoyIcons.sparkle,
                  title: '字幕翻译与语言模型',
                  subtitle: '字幕翻译、词典与语境翻译共用这一份配置',
                  cloudFirst: true,
                  isLocal: !_mtCloud,
                  onChanged: (local) async {
                    if (local) {
                      await _useLocalTranslation();
                    } else {
                      setState(() => _mtCloud = true);
                      await _pickLlm(revertOnCancel: true);
                    }
                  },
                  localBody: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '离线翻译：llama.cpp + TranslateGemma，下载后无需联网。翻译质量低于云端 LLM。',
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
                  cloudBody: _CloudBox(
                    title: '云端语言模型',
                    meta:
                        _llmProfile?.summary ??
                        '未配置 · 点击设置（推荐，显著提升翻译质量）',
                    configured: _llmProfile != null,
                    onTap: _applying ? null : () => _pickLlm(revertOnCancel: false),
                  ),
                ),
                Divider(height: t.space24 + 16, color: t.line),
                // ② 语音服务（识别 + 合成）
                _EngineSection(
                  icon: EnjoyIcons.waveform,
                  title: '语音服务（识别与合成）',
                  subtitle: '识别视频语音生成字幕；Craft 用它把文本合成练习音频',
                  isLocal: _speechLocal,
                  onChanged: (local) async {
                    if (local) {
                      await _useLocalSpeech();
                    } else {
                      setState(() => _speechLocal = false);
                      await _pickSpeech(revertOnCancel: true);
                    }
                  },
                  localBody: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AsrLocalComponents(
                        kinds: [
                          ComponentKind.asrRuntime,
                          ComponentKind.asrModel,
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '合成使用 Windows 系统自带语音，无需下载；音色跟随系统语音包。',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                  cloudBody: _CloudBox(
                    title: '云端语音服务',
                    meta:
                        _speechProfile?.summary ??
                        '未配置 · 点击设置（识别与合成共用一个端点）',
                    configured: _speechProfile != null,
                    onTap: _applying
                        ? null
                        : () => _pickSpeech(revertOnCancel: false),
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

/// Fixed-height section: header, engine toggle, and one pane at a time.
class _EngineSection extends StatelessWidget {
  const _EngineSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLocal,
    required this.onChanged,
    required this.localBody,
    required this.cloudBody,
    this.cloudFirst = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLocal;
  final ValueChanged<bool> onChanged;
  final Widget localBody;
  final Widget cloudBody;
  final bool cloudFirst;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final localSeg = ButtonSegment<bool>(
      value: true,
      label: Text(cloudFirst ? '本地' : '本地（默认）'),
    );
    final cloudSeg = ButtonSegment<bool>(
      value: false,
      label: Text(cloudFirst ? '云端 · 推荐' : '自定义云端'),
    );

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
          segments: cloudFirst ? [cloudSeg, localSeg] : [localSeg, cloudSeg],
          selected: {isLocal},
          onSelectionChanged: (sel) => onChanged(sel.first),
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
        ),
        SizedBox(height: t.space12),
        SizedBox(
          height: 172,
          child: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topLeft,
              child: isLocal ? localBody : cloudBody,
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact cloud service box: summary + state badge + chevron.
class _CloudBox extends StatelessWidget {
  const _CloudBox({
    required this.title,
    required this.meta,
    required this.configured,
    this.onTap,
  });

  final String title;
  final String meta;
  final bool configured;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(t.radiusTile),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: ShapeDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(t.radiusTile),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
        ),
        child: Row(
          children: [
            Icon(EnjoyIcons.cloud, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(color: t.ink3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: configured
                    ? cs.primaryContainer.withValues(alpha: 0.6)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                configured ? '已配置' : '未配置',
                style: tt.labelSmall?.copyWith(
                  fontSize: 11,
                  color: configured ? cs.onPrimaryContainer : t.ink3,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.unfold_more, size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
