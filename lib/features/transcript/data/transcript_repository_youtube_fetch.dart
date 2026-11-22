part of 'transcript_repository.dart';

/// YouTube transcript fetching for [TranscriptRepository]: canonical video id /
/// caption-language resolution, the direct InnerTube fetch, and the post-fetch
/// primary picker.
///
/// 本地版：原来的 Tier 1（Enjoy worker 字幕缓存 GET）与抓取后的 worker 上传
/// 已全部移除 —— 这里只保留直连 YouTube InnerTube 的本地抓取，不再向
/// `worker.enjoy.bot` 发起任何请求。
extension _TranscriptRepositoryYoutubeFetch on TranscriptRepository {
  /// Worker body `video_id` / `videoId`: prefer [VideoRow.vid] when it is an
  /// 11-character YouTube id; otherwise fall back to [youtubePlaybackVideoId].
  String _workerYoutubeVideoId(VideoRow video) {
    final v = video.vid.trim();
    if (bareYoutubeIdRegExp.hasMatch(v)) return v;
    final pb = youtubePlaybackVideoId(
      provider: video.provider,
      vid: video.vid,
      mediaUrl: video.mediaUrl,
      source: video.source,
    );
    return pb ?? v;
  }

  String? _workerCaptionLanguage(VideoRow video) {
    final lang = video.language.trim();
    if (kInvalidLanguageTags.contains(lang)) return null;
    return workerLanguageBase(lang);
  }

  /// Direct client-side YouTube caption fetch.
  ///
  /// 只用本地 InnerTube 抓取：`POST youtubei.googleapis.com/youtubei/v1/player`
  /// 拿到 captionTracks，再逐轨 `GET timedtext?fmt=json3` 取时间轴。
  /// 全部落本地 SQLite，不上传、不查远端缓存。
  ///
  /// Tier 2 always runs when the row resolves to YouTube playback, even
  /// when `videos.language` is empty / `und` / unknown — the InnerTube
  /// fetch itself discovers every available language. The unknown
  /// language only narrows the `preferredLang` hint handed to the fetcher.
  Future<TranscriptCloudFetchResult> _fetchYoutubeTranscriptsWithFallback({
    required String mediaId,
    required VideoRow video,
    String? learningLanguage,
  }) async {
    final workerVideoId = _workerYoutubeVideoId(video);
    final videoLanguage = video.language.trim();
    final workerLanguage = _workerCaptionLanguage(video);

    if (workerLanguage == null) {
      _log.info(
        'YouTube direct fetch for $workerVideoId — '
        'videos.language is empty/"und" (InnerTube will still discover)',
      );
    }

    final fetcher = _youtubeFetcher;
    if (fetcher == null) {
      _log.warning(
        'YouTube fetch unavailable: YoutubeCaptionFetcher is not wired',
      );
      return const TranscriptCloudFetchResult(
        status: TranscriptCloudFetchStatus.skipped,
      );
    }

    final preferredLang = workerLanguage ?? '';
    final allResult = await fetcher.fetchAllSubtitles(
      videoId: workerVideoId,
      preferredLang: preferredLang,
    );

    if (!allResult.isSuccess) {
      _log.warning(
        'YouTube direct InnerTube fetch failed for '
        '$workerVideoId/$preferredLang: ${allResult.error}',
      );
      return TranscriptCloudFetchResult(
        status: TranscriptCloudFetchStatus.error,
        errorMessage: allResult.error ?? 'No captions available',
      );
    }

    final now = DateTime.now();
    var storedCount = 0;

    for (final trackResult in allResult.results) {
      if (!trackResult.isSuccess || trackResult.subtitles.isEmpty) continue;
      if (trackResult.language.isEmpty) continue;

      final source = _normalizeSource(trackResult.source);
      final id = enjoyTranscriptId(
        targetType: 'Video',
        targetId: mediaId,
        language: trackResult.language,
        source: source,
      );
      await _upsertTranscriptTrack(
        id: id,
        targetType: 'Video',
        targetId: mediaId,
        language: trackResult.language,
        source: source,
        lines: trackResult.subtitles,
        label: 'YouTube captions (${trackResult.language})',
        createdAt: now,
      );
      storedCount++;
    }

    if (storedCount == 0) {
      _log.info(
        'YouTube direct fetch succeeded profile=${allResult.fetchProfile} '
        'but stored 0 valid tracks for $workerVideoId/$preferredLang',
      );
      return const TranscriptCloudFetchResult(
        status: TranscriptCloudFetchStatus.empty,
      );
    }

    _log.info(
      'YouTube direct fetch stored $storedCount track(s) via '
      'profile=${allResult.fetchProfile} for $workerVideoId/$preferredLang',
    );

    await _pickYoutubePrimary(
      mediaId: mediaId,
      videoLanguage: videoLanguage.isEmpty ? null : videoLanguage,
      learningLanguage: learningLanguage,
    );

    return TranscriptCloudFetchResult(
      status: TranscriptCloudFetchStatus.success,
      storedCount: storedCount,
    );
  }

  /// Chooses a primary transcript for a YouTube media row based on the
  /// video's content language, falling back to the user's learning
  /// language, then to source priority.
  ///
  /// Honors an existing user-picked primary: when the session already
  /// references a row that still exists, it is preserved (mirrors the
  /// guard in [_ensurePrimaryTranscript]).
  Future<void> _pickYoutubePrimary({
    required String mediaId,
    required String? videoLanguage,
    required String? learningLanguage,
  }) async {
    final rows = await _db.transcriptDao.listForTarget('Video', mediaId);
    if (rows.isEmpty) return;

    final session = await _db.echoSessionDao.getLatestForTarget(
      'Video',
      mediaId,
    );
    if (_primaryTranscriptStillResolved(session?.transcriptId, rows)) return;

    final videoMatch = _bestByLanguage(rows, videoLanguage);
    final learningMatch = videoMatch == null
        ? _bestByLanguage(rows, learningLanguage)
        : null;
    final picked =
        videoMatch ??
        learningMatch ??
        () {
          final sorted = [...rows];
          _sortTranscriptRows(sorted);
          return sorted.first;
        }();

    await _db.echoSessionDao.updatePrimaryTranscriptForTarget(
      'Video',
      mediaId,
      picked.id,
    );
  }

  /// Returns the best row whose [TranscriptRow.language] matches [language]
  /// under [matchesLanguageBroad], ranked by source priority then createdAt.
  /// Returns null when no row matches.
  TranscriptRow? _bestByLanguage(List<TranscriptRow> rows, String? language) {
    if (language == null || language.isEmpty) return null;
    final filtered = rows
        .where((r) => matchesLanguageBroad(r.language, language))
        .toList();
    if (filtered.isEmpty) return null;
    _sortTranscriptRows(filtered);
    return filtered.first;
  }
}
