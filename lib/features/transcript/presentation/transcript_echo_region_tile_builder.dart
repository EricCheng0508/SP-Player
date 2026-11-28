/// Per-line tile construction and reuse cache for the echo region card.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/lookup/application/transcript_lookup_open.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/transcript/application/auto_translate_resolved_text.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_alignment.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_line_tile.dart';

typedef EchoTileInputs = ({
  TranscriptLine line,
  bool isActive,
  String? secondaryText,
  Set<int>? wavyWordIndexes,
  int? recordingCount,
  double loopFontSize,
});

typedef EchoTileCacheEntry = ({EchoTileInputs inputs, Widget tile});

class EchoRegionTileCache {
  final Map<int, EchoTileCacheEntry> _byLineIndex = {};

  EchoTileCacheEntry? at(int lineIndex) => _byLineIndex[lineIndex];

  void store(int lineIndex, EchoTileCacheEntry entry) =>
      _byLineIndex[lineIndex] = entry;

  void clear() => _byLineIndex.clear();
}

List<Widget> buildEchoRegionTiles({
  required WidgetRef ref,
  required BuildContext context,
  required String mediaId,
  required List<TranscriptLine> lines,
  required List<TranscriptLine> secondaryLines,
  required TranscriptSecondaryMatcher matcher,
  required EchoState echo,
  required int activeCueIndex,
  required bool autoTranslateActive,
  required String? autoTranslateSourceLanguage,
  required String? autoTranslateTargetLanguage,
  required Map<int, Set<int>>? wavyByLine,
  required Map<int, int>? lineRecordingCounts,
  required double loopFontSize,
  required double loopLineGap,
  required bool reuseUnchangedTiles,
  required EchoRegionTileCache cache,
}) {
  final lineWidgets = <Widget>[];
  for (var i = echo.startLineIndex; i <= echo.endLineIndex; i++) {
    final line = lines[i];
    final isActive = i == activeCueIndex;
    final secondaryText = resolveAutoTranslateTextForDisplay(
      autoTranslateActive: autoTranslateActive,
      primaryLines: lines,
      aiLines: secondaryLines,
      lineIndex: i,
      sourceLanguage: autoTranslateSourceLanguage,
      targetLanguage: autoTranslateTargetLanguage,
      matcher: matcher,
      line: line,
    );

    final inputs = (
      line: line,
      isActive: isActive,
      secondaryText: secondaryText,
      wavyWordIndexes: wavyByLine?[i],
      recordingCount: lineRecordingCounts?[i],
      loopFontSize: loopFontSize,
    );
    final cached = reuseUnchangedTiles ? cache.at(i) : null;
    if (cached != null && cached.inputs == inputs) {
      lineWidgets.add(cached.tile);
      continue;
    }

    final tile = TranscriptLineTile(
      key: ValueKey<String>('echo-line-$i'),
      wavyWordIndexes: inputs.wavyWordIndexes,
      line: line,
      lineIndex: i,
      mediaId: mediaId,
      secondaryText: secondaryText,
      isActive: isActive,
      inEcho: true,
      groupedInEcho: true,
      selectable: true,
      recordingCount: inputs.recordingCount,
      loopFontSize: loopFontSize,
      onLookupRequested: (t) => openTranscriptLookup(
        ref: ref,
        context: context,
        selectedText: t,
        lines: lines,
        lineIndex: i,
      ),
      onTap: () => ref.read(playerInteractionsProvider).seekToLine(line, i),
    );

    final entry = i == echo.endLineIndex
        ? tile
        : Padding(
            padding: EdgeInsets.only(bottom: loopLineGap),
            child: tile,
          );
    if (reuseUnchangedTiles) {
      cache.store(i, (inputs: inputs, tile: entry));
    }
    lineWidgets.add(entry);
  }
  return lineWidgets;
}
