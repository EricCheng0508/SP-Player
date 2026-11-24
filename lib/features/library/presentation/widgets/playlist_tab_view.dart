/// Playlists tab inside the local library: list of user-curated playlists,
/// a two-level in-tab detail view, and a media picker dialog.
///
/// Local-only curation backed by the Drift `playlists` / `playlist_items`
/// tables; playing an entry opens the regular player route.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/generative_media_cover.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/error_state.dart';
import 'package:enjoy_player/core/theme/widgets/media_card.dart';
import 'package:enjoy_player/core/theme/widgets/media_card/helpers.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/library/application/library_media_provider.dart';
import 'package:enjoy_player/features/library/application/playlist_providers.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/player/application/local_thumbnail_provider.dart';
import 'package:enjoy_player/features/library/presentation/widgets/local_library_tab_view.dart'
    show libraryBodyInset;
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Third local-library tab: playlists.
class PlaylistTabView extends ConsumerStatefulWidget {
  const PlaylistTabView({super.key});

  @override
  ConsumerState<PlaylistTabView> createState() => _PlaylistTabViewState();
}

class _PlaylistTabViewState extends ConsumerState<PlaylistTabView> {
  String? _openPlaylistId;

  void _open(String id) => setState(() => _openPlaylistId = id);

  @override
  Widget build(BuildContext context) {
    final open = _openPlaylistId;
    if (open != null) {
      return _PlaylistDetail(
        playlistId: open,
        onBack: () => setState(() => _openPlaylistId = null),
      );
    }
    return _PlaylistList(onOpen: _open);
  }
}

// ---------------------------------------------------------------------------
// List level
// ---------------------------------------------------------------------------

class _PlaylistList extends ConsumerWidget {
  const _PlaylistList({required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final playlistsAsync = ref.watch(playlistsProvider);

    return playlistsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(message: '${l10n.error}: $e'),
      data: (playlists) {
        if (playlists.isEmpty) {
          return EmptyState(
            title: l10n.playlistEmptyTitle,
            subtitle: l10n.playlistEmptyHint,
            action: () => createOrRenamePlaylistDialog(context, ref),
            actionLabel: l10n.playlistCreateButton,
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            // Align with the video/audio tabs: same browse-column inset for
            // both the create button and the poster grid.
            final inset = libraryBodyInset(context, constraints.maxWidth);
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(inset, t.space4, inset, t.space16),
                  sliver: SliverToBoxAdapter(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: EnjoyButton.tonal(
                        icon: EnjoyIcons.add,
                        onPressed: () => createOrRenamePlaylistDialog(
                          context,
                          ref,
                        ),
                        child: Text(l10n.playlistCreateButton),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.only(bottom: t.space32),
                  sliver: SliverGrid(
                    gridDelegate:
                        mediaCardTileGridDelegateForMinTileWidth(
                          crossAxisExtent: constraints.maxWidth - inset * 2,
                          minTileWidth: 210,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 20,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final withCount = playlists[index];
                      return _PlaylistCard(
                        key: ValueKey('playlist-card-${withCount.playlist.id}'),
                        withCount: withCount,
                        onOpen: () => onOpen(withCount.playlist.id),
                      );
                    }, childCount: playlists.length),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Poster-wall card for one playlist: cover = first item's media artwork
/// (generative cover when empty), title = playlist name, subtitle = item
/// count. Corner delete mirrors the library media cards.
class _PlaylistCard extends ConsumerWidget {
  const _PlaylistCard({
    required this.withCount,
    required this.onOpen,
    super.key,
  });

  final PlaylistWithCount withCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final playlist = withCount.playlist;
    final items =
        ref.watch(playlistItemsProvider(playlist.id)).asData?.value ??
        const <PlaylistItemRow>[];

    Media? coverMedia;
    for (final item in items) {
      final media = ref.watch(
        playlistMediaResolverProvider((item.targetType, item.targetId)),
      );
      if (media != null) {
        coverMedia = media;
        break;
      }
    }
    final thumbnailFile = coverMedia == null
        ? null
        : ref
              .watch(
                localThumbnailFileProvider(
                  localThumbnailPathForMedia(coverMedia),
                ),
              )
              .value;

    return MediaCardTile(
      title: playlist.name,
      subtitle: l10n.playlistItemCount(withCount.itemCount),
      thumbnailFile: thumbnailFile,
      thumbnailNetworkUrl: coverMedia == null
          ? null
          : networkThumbnailForMedia(coverMedia),
      coverSeed: playlist.id,
      isVideo: coverMedia?.kind == MediaKind.video,
      accentColor: generativeAccentForSeed(playlist.id),
      onTap: onOpen,
      onDelete: () =>
          ref.read(playlistDaoProvider).deletePlaylist(playlist.id),
      deleteTooltip: l10n.playlistDelete,
    );
  }
}

/// Create (no [existing]) / rename dialog; returns the entered name.
Future<void> createOrRenamePlaylistDialog(
  BuildContext context,
  WidgetRef ref, {
  PlaylistRow? existing,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: existing?.name ?? '');
  final name = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        existing == null ? l10n.playlistCreateButton : l10n.playlistRename,
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: l10n.playlistNameHint,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text(l10n.playlistSave),
        ),
      ],
    ),
  );
  if (name == null || name.isEmpty || !context.mounted) return;
  final dao = ref.read(playlistDaoProvider);
  if (existing == null) {
    await dao.create(name);
  } else {
    await dao.rename(existing.id, name);
  }
}

// ---------------------------------------------------------------------------
// Detail level
// ---------------------------------------------------------------------------

class _PlaylistDetail extends ConsumerWidget {
  const _PlaylistDetail({required this.playlistId, required this.onBack});

  final String playlistId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final itemsAsync = ref.watch(playlistItemsProvider(playlistId));
    final dao = ref.watch(playlistDaoProvider);

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(message: '${l10n.error}: $e'),
      data: (items) {
        final playlists =
            ref.watch(playlistsProvider).asData?.value ?? const [];
        String? name;
        for (final p in playlists) {
          if (p.playlist.id == playlistId) {
            name = p.playlist.name;
            break;
          }
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final inset = libraryBodyInset(context, constraints.maxWidth);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(inset, 0, inset, t.space12),
                  child: Row(
                children: [
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: onBack,
                    icon: const Icon(EnjoyIcons.chevronUp, size: 20),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      name ?? playlistId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (name != null)
                    IconButton(
                      tooltip: l10n.playlistRename,
                      icon: const Icon(EnjoyIcons.edit, size: 18),
                      onPressed: () => createOrRenamePlaylistDialog(
                        context,
                        ref,
                        existing: playlists
                            .firstWhere((p) => p.playlist.id == playlistId)
                            .playlist,
                      ),
                    ),
                  if (items.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    EnjoyButton.tonal(
                      icon: EnjoyIcons.play,
                      onPressed: () => openPlayerRoute(context, items.first.targetId),
                      child: Text(l10n.playlistPlayAll),
                    ),
                  ],
                  const SizedBox(width: 8),
                  EnjoyButton.tonal(
                    icon: EnjoyIcons.add,
                    onPressed: () =>
                        showPlaylistMediaPicker(context, ref, playlistId),
                    child: Text(l10n.playlistAddMedia),
                  ),
                ],
              ),
            ),
            if (items.isEmpty)
              Expanded(
                child: EmptyState(
                  title: l10n.playlistEmptyTitle,
                  subtitle: l10n.playlistEmptyHint,
                  action: () => showPlaylistMediaPicker(context, ref, playlistId),
                  actionLabel: l10n.playlistAddMedia,
                ),
              )
            else
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: inset),
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final media = ref.watch(
                        playlistMediaResolverProvider(
                          (item.targetType, item.targetId),
                        ),
                      );
                      return _PlaylistItemTile(
                        item: item,
                        media: media,
                        isFirst: index == 0,
                        isLast: index == items.length - 1,
                        dao: dao,
                      );
                    },
                  ),
                ),
              ),
          ],
        );
          },
        );
      },
    );
  }
}

class _PlaylistItemTile extends StatelessWidget {
  const _PlaylistItemTile({
    required this.item,
    required this.media,
    required this.isFirst,
    required this.isLast,
    required this.dao,
  });

  final PlaylistItemRow item;
  final Media? media;
  final bool isFirst;
  final bool isLast;
  final PlaylistDao dao;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    return ListTile(
      leading: Icon(
        media?.kind == MediaKind.video
            ? EnjoyIcons.playCircle
            : EnjoyIcons.list,
        color: t.ink3,
      ),
      title: Text(
        media?.title ?? l10n.playlistMissingMedia,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: media == null
            ? Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.ink3)
            : null,
      ),
      subtitle: media != null && media!.durationMs > 0
          ? Text(
              formatDurationHmsMs(media!.durationMs),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: t.ink3),
            )
          : null,
      onTap: media == null
          ? null
          : () => openPlayerRoute(context, item.targetId),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.playlistMoveUp,
            icon: const Icon(EnjoyIcons.chevronUp, size: 18),
            onPressed: isFirst ? null : () => dao.moveItem(item.id, up: true),
          ),
          IconButton(
            tooltip: l10n.playlistMoveDown,
            icon: const Icon(EnjoyIcons.chevronDown, size: 18),
            onPressed: isLast ? null : () => dao.moveItem(item.id, up: false),
          ),
          IconButton(
            tooltip: l10n.playlistRemoveItem,
            icon: const Icon(EnjoyIcons.close, size: 18),
            onPressed: () => dao.removeItem(item.id),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Media picker
// ---------------------------------------------------------------------------

/// Multi-select picker over the local library; adds checked media on save.
Future<void> showPlaylistMediaPicker(
  BuildContext context,
  WidgetRef ref,
  String playlistId,
) async {
  final added = await showDialog<bool>(
    context: context,
    builder: (_) => _PlaylistMediaPickerDialog(playlistId: playlistId),
  );
  if (added != true || !context.mounted) return;
  // Selections were written by the dialog itself on save.
}

class _PlaylistMediaPickerDialog extends ConsumerStatefulWidget {
  const _PlaylistMediaPickerDialog({required this.playlistId});

  final String playlistId;

  @override
  ConsumerState<_PlaylistMediaPickerDialog> createState() =>
      _PlaylistMediaPickerDialogState();
}

class _PlaylistMediaPickerDialogState
    extends ConsumerState<_PlaylistMediaPickerDialog> {
  final Set<String> _selected = <String>{};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final media = ref.watch(libraryMediaProvider).value ?? const <Media>[];
    final visible = _query.isEmpty
        ? media
        : media
              .where((m) => m.title.toLowerCase().contains(_query))
              .toList();

    return AlertDialog(
      title: Text(l10n.playlistAddMedia),
      content: SizedBox(
        width: 420,
        height: 420,
        child: media.isEmpty
            ? Center(child: Text(l10n.playlistPickerNoMedia))
            : Column(
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _query = v.toLowerCase()),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l10n.transcriptSearchHint,
                      prefixIcon: const Icon(EnjoyIcons.search, size: 18),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: t.space8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final m = visible[index];
                        return CheckboxListTile(
                          dense: true,
                          value: _selected.contains(m.id),
                          title: Text(
                            m.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onChanged: (checked) => setState(() {
                            if (checked ?? false) {
                              _selected.add(m.id);
                            } else {
                              _selected.remove(m.id);
                            }
                          }),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () async {
            final dao = ref.read(playlistDaoProvider);
            for (final m in media) {
              if (!_selected.contains(m.id)) continue;
              await dao.addItem(
                playlistId: widget.playlistId,
                targetType: m.kind.dexieTargetType,
                targetId: m.id,
              );
            }
            if (context.mounted) Navigator.pop(context, true);
          },
          child: Text(l10n.playlistSave),
        ),
      ],
    );
  }
}
