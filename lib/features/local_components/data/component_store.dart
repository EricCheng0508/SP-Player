/// Install, probe and remove managed local components.
///
/// Components live under a configurable root (default
/// `%LOCALAPPDATA%\SPPlayer\components`). Downloads support resume via HTTP
/// Range, validate a minimum byte size, and Hugging Face URLs auto-switch to
/// hf-mirror.com on mainland China networks.
library;

import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/local_components/domain/component_catalog.dart';

/// Lifecycle phase of one component download.
enum ComponentDownloadPhase {
  idle,
  downloading,
  extracting,
  done,
  failed,
}

final class ComponentProgress {
  const ComponentProgress({
    required this.phase,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.fileLabel = '',
    this.error,
  });

  final ComponentDownloadPhase phase;
  final int receivedBytes;
  final int totalBytes;
  final String fileLabel;
  final String? error;

  double? get fraction =>
      totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : null;
}

final class ComponentStore {
  ComponentStore({required this.rootOverride, String? hfEndpointOverride})
    : hfEndpointOverride = hfEndpointOverride;

  /// Persisted custom root; `null` → platform default.
  final String? rootOverride;

  /// Persisted mirror endpoint; `null` → auto-detect by region.
  final String? hfEndpointOverride;

  static String defaultRoot() {
    final appData = Platform.environment['LOCALAPPDATA'];
    return Directory(
      appData != null && appData.isNotEmpty
          ? '$appData\\SPPlayer\\components'
          : 'SPPlayer-components',
    ).path;
  }

  String get root {
    final raw = rootOverride?.trim();
    return (raw == null || raw.isEmpty) ? defaultRoot() : raw;
  }

  /// Mirror endpoint: explicit override wins; otherwise mainland China →
  /// hf-mirror.com (region, then China Standard Time fallback).
  String? get hfEndpoint {
    final raw = hfEndpointOverride?.trim();
    if (raw != null && raw.isNotEmpty) {
      return raw == kHfOfficial ? null : raw;
    }
    return _isMainlandChina() ? kHfChinaMirror : null;
  }

  static bool _isMainlandChina() {
    // dart:core has no region info; use the timezone name which Windows
    // reports as "China Standard Time" on mainland systems.
    final tz = DateTime.now().timeZoneName;
    if (tz.contains('China Standard Time') || tz == 'CST' || tz == 'GMT+8') {
      return true;
    }
    return false;
  }

  Directory installDir(ComponentSpec spec) =>
      Directory('$root\\${spec.installDirName}');

  /// Whether [spec] is installed: all files present above their size floor
  /// (archives: the entry exe must exist after extraction).
  bool isInstalled(ComponentSpec spec) {
    final dir = installDir(spec);
    if (!dir.existsSync()) return false;
    if (spec.extract) {
      final entry = spec.archiveEntry;
      if (entry == null) return false;
      // Entry may sit at the top or one level deep (zip root folder).
      return File('${dir.path}\\$entry').existsSync() ||
          File('${dir.path}\\sp-asr-server\\$entry').existsSync() ||
          File('${dir.path}\\llama-b10679\\$entry').existsSync() ||
          _findEntryRecursive(dir, entry) != null;
    }
    for (final f in spec.files) {
      final file = File('${dir.path}\\${f.relativePath}');
      if (!file.existsSync() || file.lengthSync() < f.minBytes) return false;
    }
    return true;
  }

  String? installedEntryPath(ComponentSpec spec) {
    final dir = installDir(spec);
    final entry = spec.archiveEntry;
    if (entry == null) return null;
    final direct = File('${dir.path}\\$entry');
    if (direct.existsSync()) return direct.path;
    return _findEntryRecursive(dir, entry);
  }

  static String? _findEntryRecursive(Directory dir, String entry) {
    if (!dir.existsSync()) return null;
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('\\$entry')) {
        return entity.path;
      }
    }
    return null;
  }

  Future<void> remove(ComponentSpec spec) async {
    final dir = installDir(spec);
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
    final partial = Directory(
      '$root\\_downloads\\${spec.installDirName.replaceAll('/', '_')}',
    );
    if (partial.existsSync()) {
      await partial.delete(recursive: true);
    }
  }

  /// Downloads and installs [spec], streaming [ComponentProgress] updates.
  ///
  /// Single-flight per component: a second call while one is running awaits
  /// the same completion.
  Future<void> install(
    ComponentSpec spec,
    void Function(ComponentProgress) onProgress,
  ) {
    final existing = _inFlight[spec.kind];
    if (existing != null) return existing;
    final future = _installImpl(spec, onProgress)
        .catchError((Object e) {
          _inFlight.remove(spec.kind);
          throw e;
        })
        .whenComplete(() => _inFlight.remove(spec.kind));
    _inFlight[spec.kind] = future;
    return future;
  }

  final Map<ComponentKind, Future<void>> _inFlight = {};

  Future<void> _installImpl(
    ComponentSpec spec,
    void Function(ComponentProgress) onProgress,
  ) async {
    try {
      final dir = installDir(spec);
      await dir.create(recursive: true);
      final downloads = Directory('$root\\_downloads');
      await downloads.create(recursive: true);

      final endpoint = hfEndpoint;
      for (final f in spec.files) {
        final url = componentFileUrl(spec, f, endpoint);
        final dest = File(
          '$root\\_downloads\\${spec.installDirName.replaceAll('/', '_')}'
          '\\${f.relativePath.replaceAll('/', '_')}',
        );
        await dest.parent.create(recursive: true);
        await _downloadWithResume(
          url,
          dest,
          f.minBytes,
          fileLabel: f.relativePath,
          onProgress: onProgress,
        );

        if (spec.extract) {
          onProgress(
            const ComponentProgress(phase: ComponentDownloadPhase.extracting),
          );
          await _extractZip(dest, dir);
          await dest.delete();
        } else {
          final target = File('${dir.path}\\${f.relativePath}');
          await target.parent.create(recursive: true);
          if (await target.exists()) await target.delete();
          await dest.rename(target.path);
        }
      }
      onProgress(
        const ComponentProgress(phase: ComponentDownloadPhase.done),
      );
    } on Object catch (e) {
      onProgress(
        ComponentProgress(
          phase: ComponentDownloadPhase.failed,
          error: e.toString(),
        ),
      );
      rethrow;
    }
  }

  Future<void> _downloadWithResume(
    String url,
    File dest,
    int minBytes, {
    required String fileLabel,
    required void Function(ComponentProgress) onProgress,
  }) async {
    var received = 0;
    if (dest.existsSync()) {
      received = dest.lengthSync();
      if (received >= minBytes) {
        // Already fully downloaded in a previous pass.
        return;
      }
    }

    // Mirror/proxy ladder, Transub-style: try every candidate in order and
    // only fail when all of them do. HuggingFace URLs alternate official ↔
    // hf-mirror; GitHub Release URLs get gh-proxy prefixes appended.
    final candidates = _candidateUrls(url);
    Object? lastError;
    final client = HttpClient();
    try {
      for (final candidate in candidates) {
        try {
          received = await _downloadSingle(
            candidate,
            dest,
            minBytes,
            resumeFrom: received,
            fileLabel: fileLabel,
            onProgress: onProgress,
          );
          if (received >= minBytes) return;
          lastError = HttpException(
            'download incomplete: $fileLabel got $received < $minBytes',
          );
        } on Object catch (e) {
          lastError = e;
          // Keep the partial bytes; the next candidate resumes from them.
        }
      }
      throw lastError ??
          HttpException('all download candidates failed for $fileLabel');
    } finally {
      client.close(force: true);
    }
  }

  /// Mirrors/accelerator proxies for [url]: HuggingFace alternates official ↔
  /// hf-mirror.com; GitHub release assets gain gh-proxy prefixes. The
  /// original URL always comes first (system proxy handles the rest).
  static List<String> _candidateUrls(String url) {
    final candidates = <String>[url];
    final lower = url.toLowerCase();
    if (lower.startsWith(kHfOfficial)) {
      candidates.add(url.replaceFirst(kHfOfficial, kHfChinaMirror));
    } else if (lower.contains('github.com') &&
        lower.contains('/releases/download/')) {
      for (final prefix in _kGitHubProxyPrefixes) {
        candidates.add('$prefix$url');
      }
    }
    return candidates;
  }

  static const _kGitHubProxyPrefixes = <String>[
    'https://gh-proxy.com/',
    'https://mirror.ghproxy.com/',
  ];

  /// One attempt at [url] with byte-range resume; returns received bytes.
  /// Throws on HTTP errors; partial bytes stay in [dest] for the next try.
  Future<int> _downloadSingle(
    String url,
    File dest,
    int minBytes, {
    required int resumeFrom,
    required String fileLabel,
    required void Function(ComponentProgress) onProgress,
  }) async {
    final client = HttpClient();
    try {
      var received = resumeFrom;
      while (true) {
        final request = await client.getUrl(Uri.parse(url));
        if (received > 0) {
          request.headers.set(HttpHeaders.rangeHeader, 'bytes=$received-');
        }
        final response = await request.close();
        if (response.statusCode == 416) {
          // Range beyond EOF with a complete-enough file — accept.
          if (received >= minBytes ~/ 2) return received;
          throw HttpException('range not satisfiable: $url');
        }
        if (response.statusCode != 200 && response.statusCode != 206) {
          throw HttpException('HTTP ${response.statusCode} for $url');
        }

        // When the server ignores Range (200 + full body), restart.
        if (response.statusCode == 200 && received > 0) {
          received = 0;
          await dest.writeAsBytes([], mode: FileMode.write);
        }

        final total = received +
            (response.contentLength > 0
                ? response.contentLength
                : 0);
        final sink = dest.openWrite(mode: FileMode.append);
        try {
          await for (final chunk in response) {
            received += chunk.length;
            sink.add(chunk);
            onProgress(
              ComponentProgress(
                phase: ComponentDownloadPhase.downloading,
                receivedBytes: received,
                totalBytes: total > 0 ? total : 0,
                fileLabel: fileLabel,
              ),
            );
          }
        } finally {
          await sink.flush();
          await sink.close();
        }

        if (total > 0 && received < total) {
          continue; // connection dropped mid-body — resume loop
        }
        if (received >= minBytes) {
          return received;
        }
        throw HttpException(
          'download incomplete: $fileLabel got $received < $minBytes',
        );
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _extractZip(File zip, Directory destDir) async {
    final input = InputFileStream(zip.path);
    try {
      final archive = ZipDecoder().decodeStream(input);
      await extractArchiveToDisk(archive, destDir.path);
    } finally {
      await input.close();
    }
  }
}

/// Last progress event per component for UI (stream-based widgets).
final class ComponentProgressNotifier
    extends Notifier<Map<ComponentKind, ComponentProgress>> {
  @override
  Map<ComponentKind, ComponentProgress> build() => const {};

  void update(ComponentKind kind, ComponentProgress progress) {
    state = {...state, kind: progress};
  }
}

final componentProgressProvider =
    NotifierProvider<ComponentProgressNotifier,
        Map<ComponentKind, ComponentProgress>>(
  ComponentProgressNotifier.new,
);

final componentRootSettingProvider = FutureProvider<String?>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.settingsDao.readSetting(SettingsKeys.localComponentsRoot);
});

final componentStoreProvider = Provider<ComponentStore>((ref) {
  final root = ref.watch(componentRootSettingProvider).valueOrNull;
  return ComponentStore(rootOverride: root);
});

/// Snapshot of installed state for all components.
final componentInstalledProvider = Provider<Map<ComponentKind, bool>>((ref) {
  final store = ref.watch(componentStoreProvider);
  return {
    for (final spec in kComponentSpecs) spec.kind: store.isInstalled(spec),
  };
});
