/// Transcript-panel search bar + results list.
///
/// Search is intentionally a *separate flat results list* (not an in-place
/// filter of the echo-aware virtual list): matching lines are matched against
/// both the primary text and the secondary (translation) text, and tapping a
/// result seeks to the line's start. Closing the search or clearing the query
/// restores the regular transcript list untouched.
library;

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_search_controller.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Number of lines whose primary (or secondary/translation) text contains
/// [query], ignoring case.
int countTranscriptMatches(
  List<TranscriptLine> lines,
  List<TranscriptLine> secondary,
  String query,
) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return 0;
  var count = 0;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].text.toLowerCase().contains(needle)) {
      count++;
      continue;
    }
    if (i < secondary.length &&
        secondary[i].text.toLowerCase().contains(needle)) {
      count++;
    }
  }
  return count;
}

/// Search field row: query input, match count, close button.
class TranscriptSearchBar extends ConsumerStatefulWidget {
  const TranscriptSearchBar({required this.mediaId, super.key});

  final String mediaId;

  @override
  ConsumerState<TranscriptSearchBar> createState() =>
      _TranscriptSearchBarState();
}

class _TranscriptSearchBarState extends ConsumerState<TranscriptSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(transcriptSearchQueryProvider),
    );
    _focus = FocusNode();
    // Ctrl+F re-opens while the bar is already mounted: grab focus again.
    ref.listenManual(transcriptSearchOpenProvider, (prev, next) {
      if (!prev! && next && mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _close() {
    ref.read(transcriptSearchOpenProvider.notifier).close();
    ref.read(transcriptSearchQueryProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final query = ref.watch(transcriptSearchQueryProvider);
    final lines =
        ref.watch(transcriptLinesForMediaProvider(widget.mediaId)).value ??
        const <TranscriptLine>[];
    final secondary =
        ref
            .watch(secondaryTranscriptLinesForMediaProvider(widget.mediaId))
            .value ??
        const <TranscriptLine>[];
    final matchCount = countTranscriptMatches(lines, secondary, query);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): _close,
              },
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: true,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(
                    EnjoyIcons.search,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  hintText: l10n.transcriptSearchHint,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) =>
                    ref.read(transcriptSearchQueryProvider.notifier).set(value),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            query.trim().isEmpty ? '' : '$matchCount',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: _close,
            icon: const Icon(EnjoyIcons.close, size: 18),
          ),
        ],
      ),
    );
  }
}

/// Flat list of matching lines (primary + secondary text), tap to seek.
class TranscriptSearchResults extends ConsumerWidget {
  const TranscriptSearchResults({required this.mediaId, super.key});

  final String mediaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final query = ref.watch(transcriptSearchQueryProvider).trim();
    final lines =
        ref.watch(transcriptLinesForMediaProvider(mediaId)).value ??
        const <TranscriptLine>[];
    final secondary =
        ref.watch(secondaryTranscriptLinesForMediaProvider(mediaId)).value ??
        const <TranscriptLine>[];

    if (query.isEmpty) return const SizedBox.shrink();

    final needle = query.toLowerCase();
    final matches = <(int, TranscriptLine, String?)>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.text.toLowerCase().contains(needle)) {
        matches.add((i, line, null));
        continue;
      }
      final translation = _translationFor(i, lines, secondary);
      if (translation != null && translation.toLowerCase().contains(needle)) {
        matches.add((i, line, translation));
      }
    }

    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.transcriptSearchNoMatches,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final (lineIndex, line, translationHit) = matches[index];
        return _SearchResultTile(
          line: line,
          lineIndex: lineIndex,
          query: query,
          translationHit: translationHit,
        );
      },
    );
  }

  String? _translationFor(
    int index,
    List<TranscriptLine> lines,
    List<TranscriptLine> secondary,
  ) {
    if (index >= secondary.length) return null;
    final text = secondary[index].text.trim();
    return text.isEmpty ? null : text;
  }
}

class _SearchResultTile extends ConsumerWidget {
  const _SearchResultTile({
    required this.line,
    required this.lineIndex,
    required this.query,
    required this.translationHit,
  });

  final TranscriptLine line;
  final int lineIndex;
  final String query;
  final String? translationHit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hit = translationHit;
    final highlight = theme.colorScheme.primary.withValues(alpha: 0.28);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return EnjoyPressable(
      onTap: () =>
          ref.read(playerInteractionsProvider).seekToLine(line, lineIndex),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 52,
              child: Text(
                formatDurationHms(Duration(milliseconds: line.startMs)),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hit == null)
                    _highlightedText(line.text, query, onSurface, highlight)
                  else ...[
                    _highlightedText(hit, query, onSurface, highlight),
                    const SizedBox(height: 2),
                    Text(
                      line.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _highlightedText(
    String text,
    String query,
    Color base,
    Color highlight,
  ) {
    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    final needle = query.toLowerCase();
    var start = 0;
    while (true) {
      final at = lower.indexOf(needle, start);
      if (at < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (at > start) {
        spans.add(TextSpan(text: text.substring(start, at)));
      }
      spans.add(
        TextSpan(
          text: text.substring(at, at + needle.length),
          style: TextStyle(backgroundColor: highlight),
        ),
      );
      start = at + needle.length;
    }
    return RichText(
      text: TextSpan(
        style: TextStyle(color: base, height: 1.3),
        children: spans,
      ),
    );
  }
}
