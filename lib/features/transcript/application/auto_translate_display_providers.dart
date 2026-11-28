/// The AI translation track display state the transcript hosts derive.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'active_transcript_provider.dart';
import 'transcript_repository_provider.dart';

part 'auto_translate_display_providers.g.dart';

/// Whether the live secondary for [mediaId] is the AI translation track,
/// plus the source → target pair its lines render with — the derivation both
/// transcript hosts (the echo merged card and the scrollable list) previously
/// re-spelled field by field.
///
/// Languages come from the rows themselves (the pair the writes were keyed
/// with), not from current preferences, so a later native-language change
/// cannot mismatch stored source keys.
@riverpod
Future<({bool active, String? sourceLanguage, String? targetLanguage})>
autoTranslateDisplayState(Ref ref, String mediaId) async {
  final secondaryId = ref.watch(secondaryTranscriptIdProvider(mediaId)).value;
  if (secondaryId == null) {
    return (active: false, sourceLanguage: null, targetLanguage: null);
  }
  final repo = ref.read(transcriptRepositoryProvider);
  final row = await repo.transcriptRowById(secondaryId);
  if (row == null || row.source != 'ai') {
    return (active: false, sourceLanguage: null, targetLanguage: null);
  }
  final primaryRow = await repo.primaryTranscriptRowForMedia(mediaId);
  return (
    active: true,
    sourceLanguage: primaryRow?.language,
    targetLanguage: row.language,
  );
}
