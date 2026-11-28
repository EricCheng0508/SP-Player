part of 'transcript_repository.dart';

/// Cloud transcript fetching for [TranscriptRepository]: skip-once-fetched
/// gating over the persisted fetch state and the YouTube caption dispatch.
/// The InnerTube fetch chain itself lives in
/// `_TranscriptRepositoryYoutubeFetch`.
extension _TranscriptRepositoryCloudFetch on TranscriptRepository {
  /// Single owner of the skip-once-fetched predicate (issue #718): the
  /// `lastStatus != 'error'` rule on the persisted [TranscriptFetchStateRow]
  /// for this target. `false` covers both "no row yet" and "last fetch
  /// errored" — both let the next open retry.
  Future<bool> _isCloudFetchSkippable(String mediaId) async {
    final state = await _readCloudFetchState(mediaId);
    return state != null && state.lastStatus != 'error';
  }

  /// Reads the persisted fetch-state row, resolving the target type once.
  /// The controller uses this for UI hydration; the predicate above uses it
  /// for the skip gate.
  Future<TranscriptFetchStateRow?> _readCloudFetchState(String mediaId) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) return null;
    return _db.transcriptFetchStateDao.getForTarget(tt, mediaId);
  }

  Future<TranscriptCloudFetchResult> _fetchCloudTranscripts(
    String mediaId, {
    bool force = false,
    String? nativeLanguage,
    String? learningLanguage,
  }) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) {
      return const TranscriptCloudFetchResult(
        status: TranscriptCloudFetchStatus.skipped,
      );
    }

    if (!force && await _isCloudFetchSkippable(mediaId)) {
      return const TranscriptCloudFetchResult(
        status: TranscriptCloudFetchStatus.skipped,
      );
    }

    if (tt == 'Video') {
      final video = await MediaRegistry(_db).getVideoById(mediaId);
      if (video != null) {
        final ytPlayback = youtubePlaybackVideoId(
          provider: video.provider,
          vid: video.vid,
          mediaUrl: video.mediaUrl,
          source: video.source,
        );
        if (ytPlayback != null) {
          try {
            return await _fetchYoutubeTranscriptsWithFallback(
              mediaId: mediaId,
              video: video,
              learningLanguage: learningLanguage,
            );
          } on Object catch (e, st) {
            _log.warning(
              'fetchCloudTranscripts (YouTube fallback) failed for $mediaId',
              e,
              st,
            );
            return TranscriptCloudFetchResult(
              status: TranscriptCloudFetchStatus.error,
              errorMessage: e.toString(),
            );
          }
        }
      }
    }

    return const TranscriptCloudFetchResult(
      status: TranscriptCloudFetchStatus.skipped,
    );
  }
}
