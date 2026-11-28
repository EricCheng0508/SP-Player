/// File-backed persistence for live-caption sessions.
///
/// One JSON file per session under
/// `getApplicationSupportDirectory()/live_captions/`. The directory listing is
/// the index (file names carry the session id), which keeps save/load trivial
/// and crash-safe: an in-flight session is rewritten on every appended line
/// (small files, atomic-ish via writeAsString).
library;

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/features/live_captions/domain/live_caption_models.dart';

part 'live_captions_store.g.dart';

final _log = logNamed('liveCaptions.store');

class LiveCaptionsStore {
  Directory? _root;

  Future<Directory> _dir() async {
    final root = _root;
    if (root != null) return root;
    final support = await getApplicationSupportDirectory();
    final dir = Directory(
      '${support.path}${Platform.pathSeparator}live_captions',
    );
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return _root = dir;
  }

  File _file(Directory root, String id) =>
      File('${root.path}${Platform.pathSeparator}$id.json');

  /// All sessions, newest first. Corrupt files are skipped with a warning.
  Future<List<LiveCaptionSession>> loadAll() async {
    final root = await _dir();
    final sessions = <LiveCaptionSession>[];
    await for (final entry in root.list()) {
      if (entry is! File || !entry.path.endsWith('.json')) continue;
      try {
        final map =
            jsonDecode(await entry.readAsString()) as Map<String, dynamic>;
        sessions.add(LiveCaptionSession.fromJson(map));
      } on Object catch (e) {
        _log.warning('Skipping corrupt session file ${entry.path}: $e');
      }
    }
    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sessions;
  }

  Future<void> save(LiveCaptionSession session) async {
    try {
      final root = await _dir();
      final file = _file(root, session.id);
      await file.writeAsString(jsonEncode(session.toJson()), flush: true);
    } on Object catch (e) {
      _log.warning('Failed to save session ${session.id}: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      final root = await _dir();
      final file = _file(root, id);
      if (file.existsSync()) await file.delete();
    } on Object catch (e) {
      _log.warning('Failed to delete session $id: $e');
    }
  }

  /// Writes a plain-text transcript next to the session file; returns the path.
  Future<String> exportText(LiveCaptionSession session) async {
    final root = await _dir();
    final file = File('${root.path}${Platform.pathSeparator}${session.id}.txt');
    final buffer = StringBuffer(
      '${session.title}  ${session.sources.map((s) => s.name).join(' + ')}\n',
    );
    for (final line in session.lines) {
      final offset = Duration(seconds: line.offsetSeconds.round());
      final mm = offset.inMinutes.toString().padLeft(2, '0');
      final ss = (offset.inSeconds % 60).toString().padLeft(2, '0');
      buffer.writeln('[$mm:$ss] ${line.text}');
      if (line.translation != null && line.translation!.isNotEmpty) {
        buffer.writeln('       ${line.translation}');
      }
    }
    await file.writeAsString(buffer.toString(), flush: true);
    return file.path;
  }
}

@Riverpod(keepAlive: true)
LiveCaptionsStore liveCaptionsStore(Ref ref) => LiveCaptionsStore();
