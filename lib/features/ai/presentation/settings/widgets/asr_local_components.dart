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

  /// Specs to render, ordered as passed in [AsrLocalComponents.kinds].
  List<ComponentSpec> get _specs => kComponentSpecs
      .where((s) => widget.kinds.contains(s.kind))
      .toList();

  /// Merge specs sharing a [ComponentSpec.uiGroupId] into one display row —
  /// e.g. the qwen runtime+model pair shows as a single engine row. Groups
  /// keep catalog order; singles pass through untouched.
  List<_ComponentUnit> get _units {
    final units = <_ComponentUnit>[];
    final byId = <String, _ComponentUnit>{};
    for (final spec in _specs) {
      final id = spec.uiGroupId;
      if (id == null) {
        units.add(_ComponentUnit(specs: [spec]));
        continue;
      }
      final existing = byId[id];
      if (existing == null) {
        final unit = _ComponentUnit(specs: [spec]);
        byId[id] = unit;
        units.add(unit);
      } else {
        existing.specs.add(spec);
      }
    }
    return units;
  }

  Future<void> _install(ComponentSpec spec) async {
    final store = ref.read(componentStoreProvider);
    final progress = ref.read(componentProgressProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Feed the notifier so the tile swaps the button for a live progress
      // bar — with a no-op callback the download ran invisible and every
      // further click just awaited the same single-flight future.
      await store.install(
        spec,
        (p) => progress.update(spec.kind, p),
      );
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

  /// Installs every missing spec of a merged group row, in order.
  Future<void> _installUnit(_ComponentUnit unit) async {
    for (final spec in unit.specs) {
      if (ref.read(componentStoreProvider).isInstalled(spec)) continue;
      await _install(spec);
    }
  }

  void _cancel(ComponentSpec spec) {
    ref.read(componentStoreProvider).cancel(spec.kind);
    ref.read(componentProgressProvider.notifier).update(
          spec.kind,
          const ComponentProgress(
            phase: ComponentDownloadPhase.failed,
            error: '已取消',
          ),
        );
  }

  void _cancelUnit(_ComponentUnit unit) {
    for (final spec in unit.specs) {
      _cancel(spec);
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

  /// Deletes every installed spec of a merged group row after one confirm.
  Future<void> _deleteUnit(_ComponentUnit unit) async {
    final store = ref.read(componentStoreProvider);
    final installedSpecs =
        unit.specs.where(store.isInstalled).toList(growable: false);
    if (installedSpecs.isEmpty) return;
    await _delete(installedSpecs.first);
    for (final spec in installedSpecs.skip(1)) {
      try {
        await ref.read(componentStoreProvider).remove(spec);
      } on Object {
        break;
      }
    }
    if (mounted) setState(() => _generation++);
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
        for (final unit in _units)
          _AsrComponentTile(
            key: ValueKey(
              '${unit.specs.first.kind.name}-$_generation',
            ),
            label: unit.label,
            sizeHint: unit.sizeHint,
            note: unit.note,
            installed: unit.specs.every(store.isInstalled),
            progress: unit.progressOf(progressMap),
            onInstall: () => _installUnit(unit),
            onCancel: () => _cancelUnit(unit),
            onDelete: () => _deleteUnit(unit),
            theme: theme,
          ),
      ],
    );
  }
}

/// One display row: a single spec, or several specs merged by [uiGroupId].
class _ComponentUnit {
  _ComponentUnit({required this.specs});

  final List<ComponentSpec> specs;

  /// Group label when merged; the single spec's own name otherwise.
  String get label =>
      specs.first.uiGroupLabel ?? specs.first.displayName;

  /// Combined group size hint when merged; the spec hint otherwise.
  String get sizeHint =>
      specs.first.uiGroupSizeHint ?? specs.first.sizeHint;

  /// Capability note for merged rows; null for plain singles.
  String? get note => specs.first.uiGroupNote;

  /// Progress of whichever spec is currently downloading (if any).
  ComponentProgress? progressOf(Map<ComponentKind, ComponentProgress> map) {
    for (final spec in specs) {
      final p = map[spec.kind];
      if (p != null &&
          (p.phase == ComponentDownloadPhase.downloading ||
              p.phase == ComponentDownloadPhase.extracting)) {
        return p;
      }
    }
    return null;
  }
}

class _AsrComponentTile extends StatelessWidget {
  const _AsrComponentTile({
    super.key,
    required this.label,
    required this.sizeHint,
    required this.installed,
    required this.progress,
    required this.onInstall,
    required this.onCancel,
    required this.onDelete,
    required this.theme,
    this.note,
  });

  final String label;
  final String sizeHint;

  /// Optional one-line capability note (merged engine rows only).
  final String? note;
  final bool installed;
  final ComponentProgress? progress;
  final VoidCallback onInstall;
  final VoidCallback onCancel;
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
                Text(label, style: theme.textTheme.bodyMedium),
                if (note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    note!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  installed
                      ? '已安装 · $sizeHint'
                      : '未安装 · $sizeHint',
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
                    '${(progress.totalBytes / 1e6).toStringAsFixed(0)} MB'
                    '${(progress.speedBps ?? 0) > 0 ? ' · ${(progress.speedBps! / 1e6).toStringAsFixed(1)} MB/s' : ''}',
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
          else if (downloading)
            TextButton(onPressed: onCancel, child: const Text('取消'))
          else
            FilledButton.tonal(onPressed: onInstall, child: const Text('下载')),
        ],
      ),
    );
  }
}
