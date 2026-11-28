/// Managed local components: install status, download / delete actions, and
/// the storage root. Reached from Settings → 本地组件 and referenced by the
/// setup wizard's "download later" guidance.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/local_components/data/component_store.dart';
import 'package:enjoy_player/features/local_components/domain/component_catalog.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class LocalComponentsSectionBody extends ConsumerStatefulWidget {
  const LocalComponentsSectionBody({super.key});

  @override
  ConsumerState<LocalComponentsSectionBody> createState() =>
      _LocalComponentsSectionBodyState();
}

class _LocalComponentsSectionBodyState
    extends ConsumerState<LocalComponentsSectionBody> {
  /// Bumps to re-resolve installed state after installs/deletes.
  int _generation = 0;

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('删除 ${spec.displayName}？'),
        content: const Text('删除后需要重新下载才能继续使用对应功能。'),
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
    try {
      await store.remove(spec);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${spec.displayName} 已删除')));
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _generation++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    ref.watch(componentProgressProvider); // keep progress rebuilds live
    final store = ref.watch(componentStoreProvider);

    return Column(
      children: [
        for (final spec in kComponentSpecs)
          _ComponentTile(
            key: ValueKey('${spec.kind.name}-$_generation'),
            spec: spec,
            installed: store.isInstalled(spec),
            onInstall: () => _install(spec),
            onDelete: () => _delete(spec),
            l10n: l10n,
            theme: theme,
          ),
      ],
    );
  }
}

class _ComponentTile extends StatelessWidget {
  const _ComponentTile({
    super.key,
    required this.spec,
    required this.installed,
    required this.onInstall,
    required this.onDelete,
    required this.l10n,
    required this.theme,
  });

  final ComponentSpec spec;
  final bool installed;
  final VoidCallback onInstall;
  final VoidCallback onDelete;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // The settings card wraps this body with EdgeInsets.zero, so the tile
      // owns its own horizontal insets (16 matches the card's usual padding).
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(
            installed ? EnjoyIcons.checkCircle : EnjoyIcons.download,
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
                Text(
                  // "离线用" rather than "必装": translate/ASR normally go
                  // through the configured AI endpoint; these components are
                  // only required for fully offline use.
                  '${spec.displayName}${spec.optional ? '' : '（离线用）'}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  installed
                      ? '已安装 · ${spec.sizeHint}'
                      : '未安装 · ${spec.sizeHint}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (installed)
            IconButton(
              tooltip: '删除',
              icon: const Icon(EnjoyIcons.delete),
              onPressed: onDelete,
            )
          else
            FilledButton.tonal(onPressed: onInstall, child: const Text('下载')),
        ],
      ),
    );
  }
}
