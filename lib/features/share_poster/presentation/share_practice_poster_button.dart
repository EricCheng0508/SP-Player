/// Player chrome entry for share-practice-poster when recordings exist.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_top_bar_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/dexie_target_type_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/share_poster/presentation/practice_poster_preview_sheet.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Recordings for one Dexie target — file-level family so the provider
/// identity is stable across rebuilds (an inline provider would be a new
/// object every build and loop the widget forever).
final _recordingsForTargetProvider = StreamProvider.autoDispose
    .family<List<RecordingRow>, ({String targetType, String targetId})>((
      ref,
      params,
    ) {
      return ref
          .watch(appDatabaseProvider)
          .recordingDao
          .watchByTarget(params.targetType, params.targetId);
    });

class SharePracticePosterButton extends ConsumerWidget {
  const SharePracticePosterButton({
    super.key,
    required this.mediaId,
    this.iconColor,
    this.labeled = false,
  });

  final String mediaId;
  final Color? iconColor;

  /// Board-style labeled pill for the player top bar (icon + "Share").
  final bool labeled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sessionInfo = ref.watch(
      playerControllerProvider.select(
        (s) => s != null
            ? (mediaId: s.mediaId, dexieTargetType: s.dexieTargetType)
            : null,
      ),
    );
    final targetTypeAsync = ref.watch(dexieTargetTypeForMediaProvider(mediaId));

    final targetType = sessionInfo?.mediaId == mediaId
        ? sessionInfo!.dexieTargetType
        : targetTypeAsync.value;
    if (targetType == null) return const SizedBox.shrink();

    final recordingsAsync = ref.watch(
      _recordingsForTargetProvider((targetType: targetType, targetId: mediaId)),
    );

    final hasRecordings = recordingsAsync.maybeWhen(
      data: (list) => list.isNotEmpty,
      orElse: () => false,
    );

    if (!hasRecordings) return const SizedBox.shrink();

    if (labeled) {
      return PlayerTopBarChip(
        icon: EnjoyIcons.share,
        label: l10n.practicePosterShareLabel,
        tooltip: l10n.practicePosterShareTooltip,
        onTap: () =>
            showPracticePosterPreviewSheet(context, ref, mediaId: mediaId),
      );
    }

    return IconButton(
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(44, 44),
      ),
      tooltip: l10n.practicePosterShareTooltip,
      icon: Icon(EnjoyIcons.share, color: iconColor, size: 22),
      onPressed: () =>
          showPracticePosterPreviewSheet(context, ref, mediaId: mediaId),
    );
  }
}
