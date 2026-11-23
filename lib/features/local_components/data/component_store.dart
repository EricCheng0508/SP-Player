/// Install, probe and remove managed local components.
///
/// Components live under a configurable root (default: a `components` folder
/// next to the exe for portable installs, `%LOCALAPPDATA%\SPPlayer\components`
/// when the install dir is read-only). Downloads support resume via HTTP
/// Range, validate a minimum byte size, and Hugging Face URLs auto-switch to
/// hf-mirror.com on mainland China networks.
library;

import 'dart:async';
import 'dart:convert';
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
    this.speedBps,
  });

  final ComponentDownloadPhase phase;
  final int receivedBytes;
  final int totalBytes;
  final String fileLabel;
  final String? error;

  /// Smoothed download throughput in bytes/s; `null` when not downloading.
  final int? speedBps;

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

  /// Default root: a `components` folder NEXT TO THE EXE (portable style,
  /// like Transub's install root) when that directory is writable; otherwise
  /// (e.g. Program Files installs) fall back to %LOCALAPPDATA%\SPPlayer.
  static String defaultRoot() {
    final exe = Platform.resolvedExecutable;
    if (exe.isNotEmpty) {
      final exeDir = File(exe).parent.path;
      final portable = Directory('$exeDir\\components');
      if (_isWritable(portable)) return portable.path;
    }
    final appData = Platform.environment['LOCALAPPDATA'];
    return Directory(
      appData != null && appData.isNotEmpty
          ? '$appData\\SPPlayer\\components'
          : 'SPPlayer-components',
    ).path;
  }

  static bool _isWritable(Directory dir) {
    try {
      dir.createSync(recursive: true);
      final probe = File('${dir.path}\\.write-probe');
      probe.writeAsStringSync('ok', flush: true);
      probe.deleteSync();
      return true;
    } on Object {
      return false;
    }
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
        // Block body on purpose: `whenComplete` waits for a returned Future,
        // and `Map.remove` returns the entry it just removed — which is this
        // very future, so the arrow form deadlocks (`install` never completes
        // and the caller's `await` hangs forever).
        .whenComplete(() {
          _inFlight.remove(spec.kind);
        });
    _inFlight[spec.kind] = future;
    return future;
  }

  final Map<ComponentKind, Future<void>> _inFlight = {};

  /// Drops the single-flight record for [kind] and force-closes live sockets,
  /// so a stalled install can be retried from scratch instead of awaiting the
  /// same stuck future. Partial downloads are kept and resumed.
  void cancel(ComponentKind kind) {
    _inFlight.remove(kind);
    _closeStrayClients();
  }

  Future<void> _installImpl(
    ComponentSpec spec,
    void Function(ComponentProgress) onProgress,
  ) async {
    try {
      // Already installed (pre-imported or previous run) → nothing to do.
      if (isInstalled(spec)) {
        onProgress(
          const ComponentProgress(phase: ComponentDownloadPhase.done),
        );
        return;
      }
      final dir = installDir(spec);
      await dir.create(recursive: true);
      final downloads = Directory('$root\\_downloads');
      await downloads.create(recursive: true);

      // Bounded (3 s) and asynchronous: resolves the system proxy off the
      // isolate's critical path before any HTTP work starts.
      await ComponentStore.warmUpSystemProxy();

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
      _closeStrayClients();
    }
  }

  final List<HttpClient> _liveClients = [];

  /// Hosts reachable directly (and fast) from mainland networks — routing
  /// them through a local VPN proxy adds a slow hop (measured 76 MB/s direct
  /// vs 1 MB/s via proxy). Only origin hosts need the system proxy.
  static const _kDirectOkHosts = <String>{
    'gh-proxy.com',
    'ghfast.top',
    'mirror.ghproxy.com',
    'hf-mirror.com',
    'www.modelscope.cn',
    'modelscope.cn',
  };

  static String? _cachedSystemProxy;
  static bool _proxyProbed = false;
  static Future<void>? _proxyProbe;

  /// Resolves the Windows system proxy once, asynchronously and with a hard
  /// deadline.
  ///
  /// MUST be awaited before a download starts. [HttpClient.findProxy] is
  /// invoked *synchronously* by the HTTP stack for every redirect hop, so it
  /// may only ever read the cached value: spawning `reg` from inside that
  /// callback freezes the whole UI isolate (a blocked/sandboxed child process
  /// never returns, and no `.timeout` can fire because timers need the event
  /// loop that is already blocked).
  static Future<void> warmUpSystemProxy() {
    if (_proxyProbed) return Future<void>.value();
    return _proxyProbe ??= _resolveSystemProxy();
  }

  static Future<void> _resolveSystemProxy() async {
    try {
      final query = await Process.run(
        'reg',
        [
          'query',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
          '/v',
          'ProxyServer',
        ],
        stdoutEncoding: systemEncoding,
        stderrEncoding: systemEncoding,
      ).timeout(const Duration(seconds: 3));
      _cachedSystemProxy = query.exitCode == 0
          ? _parseProxyServer(query.stdout.toString())
          : null;
    } on Object {
      // No proxy, or `reg` unavailable/blocked — direct connections only.
      _cachedSystemProxy = null;
    }
    _proxyProbed = true;
  }

  static String? _parseProxyServer(String stdout) {
    final match = RegExp(r'ProxyServer\s+REG_SZ\s+(\S+)').firstMatch(stdout);
    if (match == null) return null;
    final raw = match.group(1)!;
    // "http=...;https=...;ftp=..." per-protocol form → take https/http.
    String hostPort = raw;
    if (raw.contains(';') || raw.contains('=')) {
      final parts = Map.fromEntries(
        raw.split(';').map((p) {
          final i = p.indexOf('=');
          return i < 0
              ? MapEntry(p, p)
              : MapEntry(p.substring(0, i), p.substring(i + 1));
        }),
      );
      hostPort = parts['https'] ?? parts['http'] ?? '';
    }
    if (!hostPort.contains(':')) return null;
    return 'PROXY $hostPort';
  }

  /// Whether [host] should bypass the system proxy entirely — including the
  /// domestic CDN hosts those mirrors redirect to (e.g.
  /// `cdn-lfs-cn-1.modelscope.cn`).
  static bool _isDirectHost(String host) {
    if (_kDirectOkHosts.contains(host)) return true;
    return host.endsWith('.modelscope.cn') || host.endsWith('.hf-mirror.com');
  }

  HttpClient _newClient(String url) {
    final client = HttpClient();
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    if (!_isDirectHost(host)) {
      // Read-only: must never spawn a process here (see warmUpSystemProxy).
      final proxy = _cachedSystemProxy;
      if (proxy != null) client.findProxy = (uri) => proxy;
    }
    client.connectionTimeout = const Duration(seconds: 15);
    client.idleTimeout = const Duration(seconds: 45);
    _liveClients.add(client);
    return client;
  }

  void _closeStrayClients() {
    for (final c in List<HttpClient>.of(_liveClients)) {
      c.close(force: true);
    }
    _liveClients.clear();
  }

  /// Mirrors/accelerator proxies for [url], best-first.
  ///
  /// Hugging Face resolves to a blob CDN that is unreachable on many mainland
  /// networks (Xet `cas-bridge` returns headers, then stalls with zero bytes),
  /// so a ModelScope mirror of the same repo comes FIRST when it exists;
  /// hf-mirror.com and the official host follow as fallbacks. GitHub release
  /// assets gain gh-proxy prefixes, direct last.
  static List<String> _candidateUrls(String url) {
    final seen = <String>{};
    final candidates = <String>[];
    void add(String candidate) {
      if (seen.add(candidate)) candidates.add(candidate);
    }

    final lower = url.toLowerCase();
    final isHf =
        lower.startsWith(kHfOfficial) || lower.startsWith(kHfChinaMirror);
    if (isHf) {
      final modelScope = _modelScopeUrl(url);
      if (modelScope != null) add(modelScope);
      add(url.replaceFirst(kHfChinaMirror, kHfOfficial));
      add(url.replaceFirst(kHfOfficial, kHfChinaMirror));
    } else if (lower.contains('github.com') &&
        lower.contains('/releases/download/')) {
      for (final prefix in _kGitHubProxyPrefixes) {
        add('$prefix$url');
      }
      add(url);
    } else {
      add(url);
    }
    return candidates;
  }

  /// ModelScope equivalent of a Hugging Face resolve link, or `null` when the
  /// URL is not one. `owner/repo/resolve/main/file` → the same repo/revision
  /// on `modelscope.cn`, which serves from domestic CDN nodes.
  static String? _modelScopeUrl(String url) {
    final match = RegExp(
      r'^https?://(?:huggingface\.co|hf-mirror\.com)/([^/]+)/([^/]+)/resolve/(?:main|master)/(.+)$',
    ).firstMatch(url);
    if (match == null) return null;
    return 'https://www.modelscope.cn/models/${match.group(1)}/'
        '${match.group(2)}/resolve/master/${match.group(3)}';
  }

  static const _kGitHubProxyPrefixes = <String>[
    'https://gh-proxy.com/',
    'https://ghfast.top/',
    'https://mirror.ghproxy.com/',
  ];

  /// One attempt at [url]; returns received bytes. Large files go through
  /// parallel range chunks (accelerator mirrors throttle per connection —
  /// 2 connections doubled throughput in testing); small files / range-less
  /// servers fall back to a single stream.
  Future<int> _downloadSingle(
    String url,
    File dest,
    int minBytes, {
    required int resumeFrom,
    required String fileLabel,
    required void Function(ComponentProgress) onProgress,
  }) async {
    final client = _newClient(url);
    try {
      // Range capability probe with a SMALL bounded range: some CDN
      // frontends mishandle open-ended ranges (`bytes=N-`), and a 206 probe
      // for the full remaining body is dangerous to drain (the original
      // "stuck forever" bug). Content-Range reveals the true total size.
      final probe = await client
          .getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      probe.headers.set(
        HttpHeaders.rangeHeader,
        'bytes=$resumeFrom-${resumeFrom + (1 << 20)}',
      );
      final probeResponse = await probe.close().timeout(
            const Duration(seconds: 45),
            onTimeout: () => throw TimeoutException('no response: $url'),
          );
      final status = probeResponse.statusCode;
      if (status == 416) {
        if (resumeFrom >= minBytes ~/ 2) return resumeFrom;
        throw HttpException('range not satisfiable: $url');
      }
      if (status != 200 && status != 206) {
        throw HttpException('HTTP $status for $url');
      }
      // Discard the small probe body (bounded to 1 MB by the range above).
      final sub = probeResponse.listen(null);
      try {
        await sub.cancel();
      } on Object {
        // Cancel is best-effort; the force close below finishes the job.
      }

      // "Content-Range: bytes <start>-<end>/<total>"
      var total = 0;
      if (status == 206) {
        final contentRange =
            probeResponse.headers.value(HttpHeaders.contentRangeHeader);
        final match = RegExp(r'/(\d+)\s*$').firstMatch(contentRange ?? '');
        if (match != null) total = int.tryParse(match.group(1)!) ?? 0;
      } else {
        total = probeResponse.contentLength;
      }
      final remaining = total - resumeFrom;
      if (status == 206 && total > 0 && remaining >= _kParallelMinBytes) {
        return await _downloadParallel(
          url,
          dest,
          resumeFrom: resumeFrom,
          total: total,
          fileLabel: fileLabel,
          onProgress: onProgress,
        );
      }
      return await _downloadStream(
        url,
        dest,
        minBytes,
        resumeFrom: resumeFrom,
        fileLabel: fileLabel,
        onProgress: onProgress,
      );
    } finally {
      client.close(force: true);
      _liveClients.remove(client);
    }
  }

  static const _kParallelChunks = 16;
  static const _kParallelMinBytes = 64 << 20; // 64 MB

  /// Parallel segmented download. EVERY chunk — including chunk 0 — lands in
  /// `dest.partN` files; [dest] keeps only the single-stream resume prefix
  /// `[0, base)` and stays untouched during the run. A `dest.meta` sidecar
  /// records the layout (url/total/base/chunkLen): if a later run's layout
  /// differs, stale part files are discarded instead of corrupting assembly.
  Future<int> _downloadParallel(
    String url,
    File dest, {
    required int resumeFrom,
    required int total,
    required String fileLabel,
    required void Function(ComponentProgress) onProgress,
  }) async {
    final base = resumeFrom;
    final remaining = total - base;
    final chunkLen = remaining ~/ _kParallelChunks;
    final metaFile = File('${dest.path}.meta');

    // Validate or reset the part-file layout against this run's parameters.
    var layoutOk = false;
    if (metaFile.existsSync()) {
      try {
        final meta = jsonDecode(metaFile.readAsStringSync()) as Map;
        layoutOk = meta['url'] == url &&
            meta['total'] == total &&
            meta['base'] == base &&
            meta['chunkLen'] == chunkLen;
      } on Object {
        layoutOk = false;
      }
    }
    if (!layoutOk) {
      for (var i = 0; i < _kParallelChunks; i++) {
        final part = File('${dest.path}.part$i');
        if (part.existsSync()) part.deleteSync();
      }
    }
    metaFile.writeAsStringSync(
      jsonEncode({'url': url, 'total': total, 'base': base, 'chunkLen': chunkLen}),
    );

    Future<void> pullChunk(int index, int start, int end) async {
      final target = File('${dest.path}.part$index');
      for (var attempt = 1; attempt <= 4; attempt++) {
        var offset = 0;
        if (target.existsSync()) offset = target.lengthSync();
        if (offset >= end - start) return;
        final client = _newClient(url);
        try {
          final request = await client
              .getUrl(Uri.parse(url))
              .timeout(const Duration(seconds: 15));
          request.headers.set(
            HttpHeaders.rangeHeader,
            'bytes=${start + offset}-${end - 1}',
          );
          final response = await request.close().timeout(
                const Duration(seconds: 45),
                onTimeout: () => throw TimeoutException('chunk stall: $url'),
              );
          if (response.statusCode != 206) {
            throw HttpException('HTTP ${response.statusCode} chunk $index');
          }
          final sink = target.openWrite(mode: FileMode.append);
          try {
            await for (final chunk in response.timeout(
              const Duration(seconds: 45),
              onTimeout: (s) {
                s.addError(TimeoutException('chunk stalled: $url'));
                s.close();
              },
            )) {
              sink.add(chunk);
            }
            if (target.lengthSync() >= end - start) return;
            throw HttpException('chunk $index incomplete');
          } finally {
            await sink.flush();
            await sink.close();
          }
        } on Object {
          if (attempt == 4) rethrow;
          await Future<void>.delayed(Duration(seconds: 2 * attempt));
        } finally {
          client.close(force: true);
          _liveClients.remove(client);
        }
      }
    }

    var lastTick = DateTime.now();
    var lastBytes = base;
    var lastSpeed = 0;
    int receivedNow() {
      var received = base;
      for (var i = 0; i < _kParallelChunks; i++) {
        final part = File('${dest.path}.part$i');
        if (part.existsSync()) received += part.lengthSync();
      }
      return received.clamp(0, total);
    }

    final reporter = Timer.periodic(const Duration(milliseconds: 500), (_) {
      try {
        final received = receivedNow();
        final now = DateTime.now();
        final elapsed = now.difference(lastTick).inMilliseconds;
        if (elapsed > 0) {
          lastSpeed = ((received - lastBytes) * 1000) ~/ elapsed;
          lastTick = now;
          lastBytes = received;
        }
        onProgress(
          ComponentProgress(
            phase: ComponentDownloadPhase.downloading,
            receivedBytes: received,
            totalBytes: total,
            fileLabel: fileLabel,
            // Always report; UI decides how to render (never leave the user
            // guessing whether the download is alive).
            speedBps: lastSpeed < 0 ? 0 : lastSpeed,
          ),
        );
      } on Object {
        // Reporter must never break the download.
      }
    });
    try {
      final futures = <Future<void>>[];
      for (var i = 0; i < _kParallelChunks; i++) {
        final start = base + i * chunkLen;
        final end = i == _kParallelChunks - 1
            ? total
            : base + (i + 1) * chunkLen;
        futures.add(pullChunk(i, start, end));
      }
      await Future.wait(futures);
    } finally {
      reporter.cancel();
    }

    // Assemble part files into dest at their absolute offsets. FileMode.write
    // does NOT truncate; the resume prefix [0, base) is preserved.
    final raf = dest.openSync(mode: FileMode.write);
    try {
      for (var i = 0; i < _kParallelChunks; i++) {
        final part = File('${dest.path}.part$i');
        if (!part.existsSync()) {
          throw HttpException('missing chunk file $i');
        }
        await raf.setPosition(base + i * chunkLen);
        await for (final bytes in part.openRead()) {
          await raf.writeFrom(bytes);
        }
        await part.delete();
      }
      await raf.truncate(total);
    } finally {
      await raf.close();
    }
    if (metaFile.existsSync()) metaFile.deleteSync();
    return total;
  }

  /// Single-stream fallback (small files, or servers without range support).
  Future<int> _downloadStream(
    String url,
    File dest,
    int minBytes, {
    required int resumeFrom,
    required String fileLabel,
    required void Function(ComponentProgress) onProgress,
  }) async {
    final client = _newClient(url);
    try {
      var received = resumeFrom;
      while (true) {
        final request = await client
            .getUrl(Uri.parse(url))
            .timeout(const Duration(seconds: 15));
        if (received > 0) {
          request.headers.set(HttpHeaders.rangeHeader, 'bytes=$received-');
        }
        final response = await request.close().timeout(
              const Duration(seconds: 45),
              onTimeout: () => throw TimeoutException('no response: $url'),
            );
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
          // Stall guard: any 45s gap between chunks aborts this candidate
          // (error surfaces into the ladder and the next mirror resumes).
          var lastTick = DateTime.now();
          var lastBytes = received;
          await for (final chunk in response.timeout(
            const Duration(seconds: 45),
            onTimeout: (sink) {
              sink.addError(TimeoutException('stalled: $url'));
              sink.close();
            },
          )) {
            received += chunk.length;
            sink.add(chunk);
            final now = DateTime.now();
            if (now.difference(lastTick).inMilliseconds >= 500) {
              final speed =
                  ((received - lastBytes) * 1000) ~/
                      now.difference(lastTick).inMilliseconds;
              lastTick = now;
              lastBytes = received;
              onProgress(
                ComponentProgress(
                  phase: ComponentDownloadPhase.downloading,
                  receivedBytes: received,
                  totalBytes: total > 0 ? total : 0,
                  fileLabel: fileLabel,
                  speedBps: speed,
                ),
              );
            } else {
              onProgress(
                ComponentProgress(
                  phase: ComponentDownloadPhase.downloading,
                  receivedBytes: received,
                  totalBytes: total > 0 ? total : 0,
                  fileLabel: fileLabel,
                ),
              );
            }
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
      _liveClients.remove(client);
    }
  }

  /// Manual import: validate and install a user-downloaded archive (e.g.
  /// fetched from the GitHub release with a proper download manager). No
  /// network involved — verify, extract, mark done.
  Future<void> importArchive(
    ComponentSpec spec,
    String zipPath,
    void Function(ComponentProgress) onProgress,
  ) async {
    try {
      final file = File(zipPath);
      if (!file.existsSync()) {
        throw Exception('找不到文件：$zipPath');
      }
      if (!zipPath.toLowerCase().endsWith('.zip')) {
        throw Exception('请选择 .zip 压缩包');
      }
      final minBytes =
          spec.files.map((f) => f.minBytes).reduce((a, b) => a < b ? a : b);
      if (file.lengthSync() < minBytes) {
        throw Exception(
          '文件不完整（${_fmtSize(file.lengthSync())}，应为约 ${_fmtSize(minBytes)}）'
          '——请重新下载完整压缩包',
        );
      }
      onProgress(
        const ComponentProgress(phase: ComponentDownloadPhase.extracting),
      );
      final dir = installDir(spec);
      await dir.create(recursive: true);
      await _extractZip(file, dir);
      if (spec.archiveEntry != null &&
          installedEntryPath(spec) == null) {
        throw Exception('压缩包内容不对：缺少 ${spec.archiveEntry}');
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

  static String _fmtSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var v = bytes.toDouble();
    var u = 0;
    while (v >= 1024 && u < units.length - 1) {
      v /= 1024;
      u++;
    }
    return '${v.toStringAsFixed(1)} ${units[u]}';
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
