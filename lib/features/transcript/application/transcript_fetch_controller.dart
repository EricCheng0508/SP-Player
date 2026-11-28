/// Observable transcript fetch lifecycle for a media item.
library;

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_failure_reason.dart';
import '../../../core/analytics/analytics_provider.dart';
import '../../../core/application/app_preferences_provider.dart';
import '../../../core/riverpod/async_value_x.dart';
import '../domain/transcript_fetch_status.dart';
import 'transcript_repository_provider.dart';

part 'transcript_fetch_controller.g.dart';

@Riverpod(keepAlive: true)
class TranscriptFetchCtrl extends _$TranscriptFetchCtrl {
  Future<void>? _inFlight;

  @override
  TranscriptFetchUiState build(String mediaId) {
    unawaited(_hydrateFromPersisted());
    return const TranscriptFetchUiState();
  }

  Future<void> _hydrateFromPersisted() async {
    final row = await ref
        .read(transcriptRepositoryProvider)
        .readCloudFetchState(mediaId);
    if (row == null || row.lastStatus == null) return;

    if (!ref.mounted) return;
    state = TranscriptFetchUiState(
      status: TranscriptFetchUiState.fromPersisted(row.lastStatus),
      errorMessage: row.lastError,
    );
  }

  /// Resolves transcripts on media open (primary, sidecar).
  Future<void> resolveOnOpen() async {
    if (_inFlight != null) {
      await _inFlight;
      return;
    }

    _inFlight = _runResolve(forceCloud: false);
    try {
      await _inFlight;
    } finally {
      _inFlight = null;
    }
  }

  /// Forces a cloud refresh from the subtitle picker or error retry.
  Future<void> refreshFromCloud() async {
    if (_inFlight != null) {
      await _inFlight;
      return;
    }

    if (ref.mounted) {
      state = state.copyWith(
        status: TranscriptFetchStatus.loading,
        clearError: true,
      );
    }

    _inFlight = _runResolve(
      forceCloud: true,
      analyticsSource: AnalyticsEvents.sourceYoutube,
    );
    try {
      await _inFlight;
    } finally {
      _inFlight = null;
    }
  }

  Future<void> _runResolve({
    required bool forceCloud,

    /// When set, the transcript-acquisition journey is captured under this
    /// catalog `source` (spec 046). Only deliberate user actions set it —
    /// automatic on-open resolution is not counted.
    String? analyticsSource,
  }) async {
    final analytics = ref.read(analyticsProvider);
    if (analyticsSource != null) {
      analytics.capture(
        AnalyticsEvents.transcriptGenerationRequested,
        properties: AnalyticsEvents.transcriptRequested(
          source: analyticsSource,
        ),
      );
    }
    final repo = ref.read(transcriptRepositoryProvider);
    final prefs = ref.read(appPreferencesCtrlProvider).valueOrNull;
    final nativeLanguage = prefs?.effectiveNativeLanguage;
    final learningLanguage = prefs?.effectiveLearningLanguage;
    try {
      final result = await repo.resolveOnOpen(
        mediaId,
        forceCloud: forceCloud,
        fetchCloud: forceCloud,
        nativeLanguage: nativeLanguage,
        learningLanguage: learningLanguage,
      );

      if (!ref.mounted) return;
      state = TranscriptFetchUiState(
        status: result.uiStatus,
        errorMessage: result.errorMessage,
      );
      if (analyticsSource != null &&
          result.uiStatus != TranscriptFetchStatus.error) {
        analytics.capture(
          AnalyticsEvents.transcriptGenerationCompleted,
          properties: AnalyticsEvents.transcriptCompleted(
            source: analyticsSource,
            durationSeconds: 0,
          ),
        );
      }
    } on Object catch (e) {
      if (analyticsSource != null) {
        analytics.capture(
          AnalyticsEvents.transcriptGenerationFailed,
          properties: AnalyticsEvents.transcriptFailed(
            source: analyticsSource,
            reason: analyticsFailureReasonFromObject(e),
          ),
        );
      }
      if (!ref.mounted) return;
      state = TranscriptFetchUiState(
        status: TranscriptFetchStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

/// Read-only alias for widgets that only need fetch status.
@riverpod
TranscriptFetchUiState transcriptFetchStatus(Ref ref, String mediaId) {
  return ref.watch(transcriptFetchCtrlProvider(mediaId));
}
