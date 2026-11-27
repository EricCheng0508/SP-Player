/// Entry for the empty-state「对齐已有字幕 / 台本」action (ADR-0106 §5).
///
/// P0 wires the entry, the file picker and the component gate; the CTC
/// alignment pipeline itself lands in P1 (ADR-0106 演进路线 — transcript
/// matching with omniASR-CTC-300M). Until the pipeline ships, the flow ends
/// with an actionable notice: components missing → install hint; components
/// present → explicit "pipeline pending" notice. Never silently imports the
/// file as a plain track — the whole point of this entry is aligned output.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/features/local_components/data/component_store.dart';
import 'package:enjoy_player/features/local_components/domain/component_catalog.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// `.srt` / `.vtt` for subtitle alignment, `.txt` for raw scripts.
const kAlignSourceExtensions = <String>['srt', 'vtt', 'txt'];

/// Opens the align flow for [mediaId]: pick an already-correct source file,
/// gate on the CTC aligner components, then run the alignment pipeline.
Future<void> alignExistingScript(
  BuildContext context,
  WidgetRef ref,
  String mediaId, {
  Future<({String path, String name})?> Function()? pickFile,
}) async {
  final l10n = AppLocalizations.of(context)!;

  final pick = pickFile ?? _pickAlignSourceFile;
  final picked = await pick();
  if (picked == null || !context.mounted) return;

  final store = ComponentStore(rootOverride: null);
  final installed =
      store.isInstalled(specOf(ComponentKind.ctcAlignerRuntime)) &&
      store.isInstalled(specOf(ComponentKind.ctcAlignerModel));
  if (!installed) {
    AppNotice.error(context, l10n.transcriptAlignNotInstalled);
    return;
  }

  // TODO(ADR-0106 P1): parse the picked script, CTC-align it to this media's
  // audio via the ctc-aligner sidecar, and upsert the word-timed result as a
  // transcript track (texts stay 100% verbatim from the source file).
  AppNotice.info(context, l10n.transcriptAlignPipelinePending);
}

Future<({String path, String name})?> _pickAlignSourceFile() async {
  final pick = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: kAlignSourceExtensions,
  );
  if (pick == null) return null;
  final path = pick.path;
  if (path == null) return null;
  return (path: path, name: pick.name);
}
