/// First-run setup wizard, modelled on Transub Player's install flow.
///
/// Three steps: preferences (translation source choice) → install (managed
/// component downloads with progress) → done. The transcription runtime and
/// large-v3-turbo model are mandatory; the local translation model is optional and
/// can be deferred to a manual download in Settings.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/ai/application/ai_modality_config_controller.dart';
import 'package:enjoy_player/features/ai/domain/ai_provider.dart';
import 'package:enjoy_player/features/ai/domain/ai_service_config.dart';
import 'package:enjoy_player/features/ai/domain/llm_api_spec.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/local_components/data/component_store.dart';
import 'package:enjoy_player/features/local_components/data/managed_llama_server.dart';
import 'package:enjoy_player/features/local_components/domain/component_catalog.dart';

/// One-time-per-session guard so the dialog never loops across navigations.
bool _wizardShownThisSession = false;

/// Shows the wizard when it has never been completed and the mandatory ASR
/// components are missing. Safe to call from any screen's post-frame hook.
Future<void> maybeShowSetupWizard(BuildContext context, WidgetRef ref) async {
  if (_wizardShownThisSession) return;
  try {
    final db = ref.read(appDatabaseProvider);
    final completed =
        await db.settingsDao.readSetting(SettingsKeys.setupWizardCompletedV1);
    if (completed == true) return;

    final store = ref.read(componentStoreProvider);
    final runtimeReady = store.isInstalled(specOf(ComponentKind.asrRuntime));
    final modelReady = store.isInstalled(specOf(ComponentKind.asrModel));
    final cloudConfigured = await _hasCloudTranslationConfig(ref);
    if (runtimeReady && modelReady) {
      // Components present (e.g. dev machine) — mark done silently.
      await db.settingsDao.writeSetting(SettingsKeys.setupWizardCompletedV1, true);
      return;
    }
    if (cloudConfigured && (runtimeReady || modelReady)) {
      // User already configured cloud AI and some components exist — treat
      // as an upgraded install; Settings still offers component management.
      return;
    }

    _wizardShownThisSession = true;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SetupWizardDialog(),
    );
  } on Object {
    // Never let the wizard break app startup.
  }
}

Future<bool> _hasCloudTranslationConfig(WidgetRef ref) async {
  try {
    final configs = await ref.read(aiModalityConfigRepositoryProvider).load();
    final llm = configs.llm.llmByok;
    return llm != null && !isLocalLlmEndpoint(llm.baseUrl);
  } on Object {
    return false;
  }
}

enum _TranslationChoice { cloud, localNow, localLater }

enum _InstallRowState { pending, downloading, extracting, done, failed }

class _RowState {
  _RowState(this.state, {this.received = 0, this.total = 0, this.error});
  final _InstallRowState state;
  final int received;
  final int total;
  final String? error;
}

class SetupWizardDialog extends ConsumerStatefulWidget {
  const SetupWizardDialog({super.key});

  @override
  ConsumerState<SetupWizardDialog> createState() => _SetupWizardDialogState();
}

class _SetupWizardDialogState extends ConsumerState<SetupWizardDialog> {
  int _step = 0;
  _TranslationChoice _choice = _TranslationChoice.cloud;
  bool _installing = false;
  String? _installError;
  final Map<ComponentKind, _RowState> _rows = {};

  List<ComponentSpec> get _targets {
    final local = _choice == _TranslationChoice.localNow;
    return [
      specOf(ComponentKind.asrRuntime),
      specOf(ComponentKind.asrModel),
      if (local) ...[
        specOf(ComponentKind.mtRuntime),
        specOf(ComponentKind.mtModel),
      ],
    ];
  }

  Future<void> _finish() async {
    final db = ref.read(appDatabaseProvider);
    await db.settingsDao.writeSetting(SettingsKeys.setupWizardCompletedV1, true);
    if (_choice == _TranslationChoice.localNow || _choice == _TranslationChoice.localLater) {
      await _writeLocalLlmConfig();
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _writeLocalLlmConfig() async {
    try {
      await ref.read(aiModalityConfigCtrlProvider.notifier).saveModality(
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
    } on Object {
      // Non-fatal: the user can configure translation manually in Settings.
    }
  }

  Future<void> _startInstall() async {
    setState(() {
      _installing = true;
      _installError = null;
      for (final spec in _targets) {
        _rows[spec.kind] = _RowState(_InstallRowState.pending);
      }
    });
    final store = ref.read(componentStoreProvider);
    for (final spec in _targets) {
      try {
        await store.install(spec, (progress) {
          if (!mounted) return;
          setState(() {
            _rows[spec.kind] = _RowState(
              switch (progress.phase) {
                ComponentDownloadPhase.downloading => _InstallRowState.downloading,
                ComponentDownloadPhase.extracting => _InstallRowState.extracting,
                ComponentDownloadPhase.done => _InstallRowState.done,
                ComponentDownloadPhase.failed => _InstallRowState.failed,
                _ => _InstallRowState.pending,
              },
              received: progress.receivedBytes,
              total: progress.totalBytes,
              error: progress.error,
            );
          });
        });
      } on Object catch (e) {
        if (!mounted) return;
        setState(() {
          _installing = false;
          _installError = e.toString();
        });
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _installing = false;
      _step = 2;
    });
    // Warm the translation server so the first use is instant.
    if (_choice == _TranslationChoice.localNow) {
      unawaited(warmUpLocalLlmServer());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '首次配置',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                '选择偏好，安装组件，即可开始。',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              _StepIndicator(current: _step),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: switch (_step) {
                    0 => _buildPrefsStep(theme),
                    1 => _buildInstallStep(theme),
                    _ => _buildDoneStep(theme),
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildActions(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrefsStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoCard(
          title: '字幕识别（必装）',
          subtitle: '本地 large-v3-turbo 模型 · 离线转写字幕 · 约 3.8 GB（运行时 + 模型）',
          icon: Icons.graphic_eq,
          theme: theme,
        ),
        const SizedBox(height: 12),
        Text('翻译方式（可选）', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _ChoiceTile(
          choice: _TranslationChoice.cloud,
          selected: _choice == _TranslationChoice.cloud,
          onTap: () => setState(() => _choice = _TranslationChoice.cloud),
          title: '云端 AI（填 API Key）',
          subtitle: '质量最好，需要自己配置密钥；之后可在设置里修改',
          theme: theme,
        ),
        _ChoiceTile(
          choice: _TranslationChoice.localNow,
          selected: _choice == _TranslationChoice.localNow,
          onTap: () => setState(() => _choice = _TranslationChoice.localNow),
          title: '本地模型 · 现在下载',
          subtitle: 'TranslateGemma 4B 专用翻译模型 · 离线可用 · 约 2.6 GB',
          theme: theme,
        ),
        _ChoiceTile(
          choice: _TranslationChoice.localLater,
          selected: _choice == _TranslationChoice.localLater,
          onTap: () => setState(() => _choice = _TranslationChoice.localLater),
          title: '本地模型 · 稍后在设置里下载',
          subtitle: '先跳过；下载完成前本地翻译无法使用',
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildInstallStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('按顺序下载安装以下组件', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final spec in _targets) _buildRow(spec, theme),
        if (_installError != null) ...[
          const SizedBox(height: 12),
          Text(
            '安装失败：$_installError',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.error),
          ),
        ],
      ],
    );
  }

  Widget _buildRow(ComponentSpec spec, ThemeData theme) {
    final row = _rows[spec.kind] ?? _RowState(_InstallRowState.pending);
    final icon = switch (row.state) {
      _InstallRowState.pending => const Icon(Icons.schedule, size: 20),
      _InstallRowState.downloading ||
      _InstallRowState.extracting => const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      _InstallRowState.done =>
        Icon(Icons.check_circle, size: 20, color: theme.colorScheme.primary),
      _InstallRowState.failed => Icon(
        Icons.error_outline,
        size: 20,
        color: theme.colorScheme.error,
      ),
    };
    String? detail;
    if (row.state == _InstallRowState.downloading && row.total > 0) {
      final pct = ((row.received / row.total) * 100).clamp(0, 100).toStringAsFixed(0);
      detail = '下载中 $pct%';
    } else if (row.state == _InstallRowState.extracting) {
      detail = '正在解压…';
    } else if (row.state == _InstallRowState.failed) {
      detail = row.error;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${spec.displayName} · ${spec.sizeHint}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (detail != null)
                  Text(detail, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneStep(ThemeData theme) {
    final later = _choice == _TranslationChoice.localLater;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('一切就绪', style: theme.textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          later
              ? '字幕识别组件已安装。翻译方式选择了本地模型：请到「设置 → 本地组件」下载翻译模型，下载完成前本地翻译无法使用。'
              : '组件已安装完成，可以开始使用了。之后可在「设置 → 本地组件」管理这些组件。',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: _installing ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        Row(
          children: [
            if (_step > 0 && _step < 2)
              TextButton(
                onPressed: _installing ? null : () => setState(() => _step--),
                child: const Text('上一步'),
              ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _installing
                  ? null
                  : () {
                      if (_step == 0) {
                        setState(() => _step = 1);
                      } else if (_step == 1) {
                        _startInstall();
                      } else {
                        _finish();
                      }
                    },
              child: Text(
                switch (_step) {
                  0 => '下一步',
                  1 => '开始安装',
                  _ => '开始使用',
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget step(String label, int index) {
      final active = index == current;
      final passed = index < current;
      return Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: active || passed
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            child: Text(
              '${index + 1}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: active || passed
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: active
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        step('偏好', 0),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('·'),
        ),
        step('安装', 1),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('·'),
        ),
        step('完成', 2),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.theme,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.choice,
    required this.selected,
    required this.onTap,
    required this.title,
    required this.subtitle,
    required this.theme,
  });

  final _TranslationChoice choice;
  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Radio<_TranslationChoice>(
                value: choice,
                groupValue: selected ? choice : null,
                onChanged: (_) => onTap(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
