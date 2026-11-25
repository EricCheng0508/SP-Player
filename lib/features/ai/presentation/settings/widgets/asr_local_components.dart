/// Local ASR component status rows for the AI settings screen.
///
/// Mirrors [LocalComponentsSection]'s tiles but scoped to the ASR pair
/// (runtime + model) and embedded inside the ASR provider card, so the user
/// sees — right where they configure the engine — whether the local model is
/// downloaded, with inline install/delete actions and live progress.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/local_components/data/component_store.dart';
import 'package:enjoy_player/features/local_components/domain/component_catalog.dart';

/// Consumer stateful so a finished install can force a status refresh.
class AsrLocalComponents extends ConsumerStatefulWidget {
  const AsrLocalComponents({super.key, this.kinds = const []});

  /// Component kinds to render, e.g. the recognition pair
  /// (asrRuntime + asrModel) or the offline-translation pair
  /// (mtRuntime + mtModel) — both belong to the subtitle pipeline.
  final List<ComponentKind> kinds;

  @override
  ConsumerState<AsrLocalComponents> createState() => _AsrLocalComponentsState();
}

class _AsrLocalComponentsState extends ConsumerState<AsrLocalComponents> {
  int _generation = 0;

  List<ComponentSpec> get _specs => kComponentSpecs
      .where((s) => widget.kinds.contains(s.kind))
      .toList();

  Future<void> _install(ComponentSpec spec) async {
    final store = ref.read(componentStoreProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await store.install(spec, (_) {});
      messenger.showSnackBar(
        SnackBar(content: Text('${spec.displayName} 安装完成')),
      );
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${spec.displayName} 安装失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _generation++);
    }
  }

  Future<void> _delete(ComponentSpec spec) async {
    final rootMessenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('删除 ${spec.displayName}？'),
        content: const Text('删除后需要重新下载才能继续本地识别。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final store = ref.read(componentStoreProvider);
    final messenger = rootMessenger;
    try {
      await store.remove(spec);
      messenger.showSnackBar(
        SnackBar(content: Text('${spec.displayName} 已删除')),
      );
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('删除失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _generation++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressMap = ref.watch(
      componentProgressProvider,
    ); // keep progress rebuilds live
    final store = ref.watch(componentStoreProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final spec in _specs)
          _AsrComponentTile(
            key: ValueKey('${spec.kind.name}-$_generation'),
            spec: spec,
            installed: store.isInstalled(spec),
            progress: progressMap[spec.kind],
            onInstall: () => _install(spec),
            onDelete: () => _delete(spec),
            theme: theme,
          ),
      ],
    );
  }
}

class _AsrComponentTile extends StatelessWidget {
  const _AsrComponentTile({
    super.key,
    required this.spec,
    required this.installed,
    required this.progress,
    required this.onInstall,
    required this.onDelete,
    required this.theme,
  });

  final ComponentSpec spec;
  final bool installed;
  final ComponentProgress? progress;
  final VoidCallback onInstall;
  final VoidCallback onDelete;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final progress = this.progress;
    final downloading = progress != null &&
        (progress.phase == ComponentDownloadPhase.downloading ||
            progress.phase == ComponentDownloadPhase.extracting);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            installed
                ? Icons.check_circle
                : Icons.download_for_offline_outlined,
            size: 22,
            color: installed
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(spec.displayName, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  installed
                      ? '已安装 · ${spec.sizeHint}'
                      : '未安装 · ${spec.sizeHint}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (downloading) ...[
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progress.fraction,
                    minHeight: 4,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${progress.fileLabel.isEmpty ? '' : '${progress.fileLabel} · '}'
                    '${(progress.receivedBytes / 1e6).toStringAsFixed(0)}'
                    '/'
                    '${(progress.totalBytes / 1e6).toStringAsFixed(0)} MB',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (installed)
            IconButton(
              tooltip: '删除',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            )
          else if (!downloading)
            FilledButton.tonal(onPressed: onInstall, child: const Text('下载')),
        ],
      ),
    );
  }
}
