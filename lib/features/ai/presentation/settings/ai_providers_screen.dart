import 'package:enjoy_player/core/theme/widgets/enjoy_segmented_control.dart';
import 'dart:async';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
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
class AiEnginesBody extends ConsumerStatefulWidget {
  const AiEnginesBody({super.key});

  @override
  ConsumerState<AiEnginesBody> createState() => _AiEnginesBodyState();
}

class _AiEnginesBodyState extends ConsumerState<AiEnginesBody> {
  bool _mtCloud = true; // translation defaults to cloud (recommended)

  CloudLlmProfile? _llmProfile;
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
    // Cloud is the recommended default: only an explicitly local llama
    // endpoint (127.0.0.1:8760) switches this to local; no config at all keeps
    // the cloud pane visible (its box then says 未配置).
    _mtCloud = llm == null || !isLocalLlm;

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
  }

  bool _endpointMatches(String endpoint, String region, String baseUrl) {
    if (endpoint.isNotEmpty && endpoint == baseUrl) return true;
    if (region.isNotEmpty && baseUrl.contains(region)) return true;
    return false;
  }

  Future<void> _pickLlm() async {
    final selection = await showCloudProfileDialog(
      context: context,
      ref: ref,
      speech: false,
      selectedId: _llmProfile?.id,
    );
    if (!mounted) return;
    final picked = selection?.llm;
    if (picked == null) return;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
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
                // Switching the pane must not auto-open the dialog — the
                // user opens it by tapping the cloud box.
                setState(() => _mtCloud = true);
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
                  kinds: [ComponentKind.mtRuntime, ComponentKind.mtModel],
                ),
              ],
            ),
            cloudBody: _CloudBox(
              title: '云端语言模型',
              meta: _llmProfile?.summary ?? '未配置 · 点击设置（推荐，显著提升翻译质量）',
              configured: _llmProfile != null,
              onTap: _applying ? null : _pickLlm,
            ),
          ),
          Divider(height: t.space24 + 16, color: t.line),
          // ② 语音服务（识别 + 合成）— 本地-only：Azure 云端区块已按
          // ADR-0106 移除，Whisper 过渡对不在界面出现（代码内兜底）。
          _LocalOnlySection(
            icon: EnjoyIcons.waveform,
            title: '语音服务（识别与合成）',
            subtitle: '识别视频语音生成字幕；Craft 用它把文本合成练习音频',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Qwen 运行时+模型合并为一行（uiGroup）；Whisper 对不再展示。
                const AsrLocalComponents(
                  kinds: [
                    ComponentKind.qwenAsrRuntime,
                    ComponentKind.qwenAsrModel,
                    ComponentKind.liveAsr,
                  ],
                ),
                const _OptionalComponentsGroup(),
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
                  style: tt.bodySmall?.copyWith(color: t.ink3, height: 1.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Header + body without the local/cloud toggle — for the speech card, which
/// is local-only since ADR-0106 dropped the Azure cloud speech block.
class _LocalOnlySection extends StatelessWidget {
  const _LocalOnlySection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

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
                    style: tt.bodySmall?.copyWith(color: t.ink3, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: t.space12),
        child,
      ],
    );
  }
}

/// Collapsible "可选增强组件" group — optional engines (vocal separation,
/// transcript matching) that don't affect recognition when absent. Collapsed
/// by default so the required rows stay the visual focus.
class _OptionalComponentsGroup extends StatefulWidget {
  const _OptionalComponentsGroup();

  @override
  State<_OptionalComponentsGroup> createState() =>
      _OptionalComponentsGroupState();
}

class _OptionalComponentsGroupState extends State<_OptionalComponentsGroup> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: ShapeDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusTile),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EnjoyPressable(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      EnjoyIcons.chevronRight,
                      size: 16,
                      color: t.ink3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '可选增强组件',
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: t.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '2',
                      style: tt.labelSmall?.copyWith(
                        fontSize: 11,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '人声分离 · 台本对齐——不装不影响识别，需要时再下载',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(color: t.ink3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Divider(height: 1, color: t.line),
                  // CTC 引擎+模型合并为一行（uiGroup）。
                  const AsrLocalComponents(
                    kinds: [
                      ComponentKind.vocalSeparation,
                      ComponentKind.ctcAlignerRuntime,
                      ComponentKind.ctcAlignerModel,
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

    final localSeg = EnjoySegment<bool>(
      value: true,
      label: cloudFirst ? '本地' : '本地（默认）',
    );
    final cloudSeg = EnjoySegment<bool>(
      value: false,
      label: cloudFirst ? '云端 · 推荐' : '自定义云端',
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
                    style: tt.bodySmall?.copyWith(color: t.ink3, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: t.space12),
        EnjoySegmentedControl<bool>(
          segments: cloudFirst ? [cloudSeg, localSeg] : [localSeg, cloudSeg],
          value: isLocal,
          onChanged: onChanged,
          compact: true,
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

    return EnjoyPressable(
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
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
            Icon(EnjoyIcons.caretUpDown, size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Standalone route wrapper (deep links keep working); the settings page
/// embeds [AiEnginesBody] directly instead of linking to this screen.
class AiProvidersScreen extends StatelessWidget {
  const AiProvidersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    return EnjoyPage(
      kind: EnjoyPageKind.hub,
      title: l10n.settingsAiProvidersTitle,
      showBack: true,
      body: (context, metrics) => ListView(
        padding: metrics.padding(top: t.space16, bottom: t.space32),
        children: const [AiEnginesBody()],
      ),
    );
  }
}
