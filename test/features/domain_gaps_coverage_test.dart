/// Covers small remaining gaps across multiple domain files.
library;

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/ai/domain/llm_api_spec.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_result.dart';
import 'package:enjoy_player/features/asr/domain/asr_long_form_mapper.dart';
import 'package:enjoy_player/features/asr/domain/asr_long_form_models.dart';
import 'package:enjoy_player/features/craft/domain/craft_failure.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_blur.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_fetch_status.dart';
import 'package:enjoy_player/features/update/domain/semver_compare.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_relative_review.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TranscriptFetchUiState', () {
    test('isLoading reflects loading status', () {
      const state = TranscriptFetchUiState(
        status: TranscriptFetchStatus.loading,
      );
      expect(state.isLoading, isTrue);
      const idle = TranscriptFetchUiState();
      expect(idle.isLoading, isFalse);
    });

    test('copyWith replaces status and errorMessage', () {
      const state = TranscriptFetchUiState(
        status: TranscriptFetchStatus.error,
        errorMessage: 'oops',
      );
      final cleared = state.copyWith(
        status: TranscriptFetchStatus.success,
        clearError: true,
      );
      expect(cleared.status, TranscriptFetchStatus.success);
      expect(cleared.errorMessage, isNull);
    });

    test('fromPersisted maps known values', () {
      expect(
        TranscriptFetchUiState.fromPersisted('success'),
        TranscriptFetchStatus.success,
      );
      expect(
        TranscriptFetchUiState.fromPersisted('empty'),
        TranscriptFetchStatus.empty,
      );
      expect(
        TranscriptFetchUiState.fromPersisted('error'),
        TranscriptFetchStatus.error,
      );
      expect(
        TranscriptFetchUiState.fromPersisted(null),
        TranscriptFetchStatus.idle,
      );
      expect(
        TranscriptFetchUiState.fromPersisted('garbage'),
        TranscriptFetchStatus.idle,
      );
    });

    test('toPersisted maps statuses', () {
      expect(
        TranscriptFetchUiState.toPersisted(TranscriptFetchStatus.success),
        'success',
      );
      expect(
        TranscriptFetchUiState.toPersisted(TranscriptFetchStatus.empty),
        'empty',
      );
      expect(
        TranscriptFetchUiState.toPersisted(TranscriptFetchStatus.error),
        'error',
      );
      expect(
        TranscriptFetchUiState.toPersisted(TranscriptFetchStatus.idle),
        'success',
      );
      expect(
        TranscriptFetchUiState.toPersisted(TranscriptFetchStatus.loading),
        'success',
      );
    });
  });

  group('semver_compare extras', () {
    test('parseSemver pads two-part version', () {
      expect(parseSemver('1.2'), [1, 2, 0]);
    });

    test('compareSemver falls back to string compare on invalid', () {
      expect(compareSemver('abc', 'abc'), 0);
      expect(compareSemver('abc', 'def'), lessThan(0));
    });

    test('isVersionLessThanOrEqual', () {
      expect(isVersionLessThanOrEqual('1.0.0', '1.0.0'), isTrue);
      expect(isVersionLessThanOrEqual('1.0.0', '2.0.0'), isTrue);
      expect(isVersionLessThanOrEqual('2.0.0', '1.0.0'), isFalse);
    });
  });

  group('RelativeNextReviewInDays', () {
    test('equality and hashCode', () {
      const a = RelativeNextReviewInDays(5);
      const b = RelativeNextReviewInDays(5);
      const c = RelativeNextReviewInDays(3);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('toString', () {
      const label = RelativeNextReviewInDays(7);
      expect(label.toString(), 'RelativeNextReviewInDays(7)');
    });
  });

  group('TapRevealHold', () {
    test('isActiveAt before expiry', () {
      final hold = TapRevealHold(
        cueId: 'cue-1',
        expiresAt: DateTime.utc(2030, 1, 1),
      );
      expect(hold.isActiveAt(DateTime.utc(2029, 6, 1)), isTrue);
      expect(hold.isActiveAt(DateTime.utc(2030, 6, 1)), isFalse);
    });

    test('equality and hashCode', () {
      final a = TapRevealHold(cueId: 'x', expiresAt: DateTime.utc(2025));
      final b = TapRevealHold(cueId: 'x', expiresAt: DateTime.utc(2025));
      final c = TapRevealHold(cueId: 'y', expiresAt: DateTime.utc(2025));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('LlmApiSpec json', () {
    test('toJsonKey returns correct keys', () {
      expect(LlmApiSpec.openAiCompatible.toJsonKey(), 'openAiCompatible');
      expect(LlmApiSpec.anthropicCompatible.toJsonKey(), 'anthropicCompatible');
      expect(LlmApiSpec.googleCompatible.toJsonKey(), 'googleCompatible');
    });

    test('fromJsonKey parses known keys', () {
      expect(
        LlmApiSpecJson.fromJsonKey('openAiCompatible'),
        LlmApiSpec.openAiCompatible,
      );
      expect(
        LlmApiSpecJson.fromJsonKey('anthropicCompatible'),
        LlmApiSpec.anthropicCompatible,
      );
      expect(
        LlmApiSpecJson.fromJsonKey('googleCompatible'),
        LlmApiSpec.googleCompatible,
      );
      expect(LlmApiSpecJson.fromJsonKey('unknown'), isNull);
      expect(LlmApiSpecJson.fromJsonKey(null), isNull);
    });
  });

  group('cueIdFor', () {
    test('returns sentinel for empty text', () {
      const line = TranscriptLine(text: '', startMs: 100, durationMs: 500);
      final id = cueIdFor(line);
      expect(id, '__invalid__:100:600');
    });

    test('returns sentinel for markup-only text', () {
      const line = TranscriptLine(
        text: '<font color="red">  </font>',
        startMs: 0,
        durationMs: 1000,
      );
      final id = cueIdFor(line);
      expect(id, startsWith('__invalid__:'));
    });

    test('returns hash-based id for real text', () {
      const line = TranscriptLine(
        text: 'Hello world',
        startMs: 2000,
        durationMs: 3000,
      );
      final id = cueIdFor(line);
      expect(id, startsWith('2000:5000:'));
      expect(id.length, greaterThan('2000:5000:'.length));
    });

    test('is unchanged when nested words are added', () {
      const flat = TranscriptLine(
        text: 'Hello world',
        startMs: 2000,
        durationMs: 3000,
      );
      const nested = TranscriptLine(
        text: 'Hello world',
        startMs: 2000,
        durationMs: 3000,
        timeline: [
          TranscriptWord(text: 'Hello'),
          TranscriptWord(text: 'world'),
        ],
      );
      expect(cueIdFor(nested), cueIdFor(flat));
    });
  });

  group('CraftFailure subclasses', () {
    test('CraftOfflineFailure has retry action', () {
      final failure = const CraftOfflineFailure();
      expect(failure.action, CraftFailureAction.retry);
    });

    test('CraftVendorUnsupportedLanguageFailure stores language', () {
      final failure = const CraftVendorUnsupportedLanguageFailure(
        language: 'xx',
      );
      expect(failure.language, 'xx');
      expect(failure.action, CraftFailureAction.retry);
    });
  });

  group('TtsWordBoundary', () {
    test('stores fields', () {
      final wb = const TtsWordBoundary(
        text: 'hello',
        audioOffsetMs: 100,
        durationMs: 500,
      );
      expect(wb.text, 'hello');
      expect(wb.audioOffsetMs, 100);
      expect(wb.durationMs, 500);
    });
  });

  group('mapLongFormTranscriptToAsrResult segment words', () {
    test('maps segment-level words', () {
      const transcript = AsrLongFormTranscript(
        text: 'hello world',
        language: 'en',
        actualDurationSeconds: 3.0,
        segments: [
          {
            'start': 0.0,
            'end': 1.5,
            'text': 'hello',
            'words': [
              {'word': 'hello', 'start': 0.0, 'end': 0.8},
            ],
          },
          {
            'start': 1.5,
            'end': 3.0,
            'text': 'world',
            'words': [
              {'word': 'world', 'start': 1.5, 'end': 2.5},
            ],
          },
        ],
      );
      final result = mapLongFormTranscriptToAsrResult(transcript);
      expect(result.segments, isNotNull);
      expect(result.segments!.length, 2);
      expect(result.segments![0].words, isNotNull);
      expect(result.segments![0].words!.length, 1);
      expect(result.segments![0].words![0].word, 'hello');
      expect(result.segments![1].words![0].word, 'world');
    });

    test('filters empty words from segments', () {
      const transcript = AsrLongFormTranscript(
        text: 'test',
        segments: [
          {
            'start': 0.0,
            'end': 1.0,
            'text': 'test',
            'words': [
              {'word': '', 'start': 0.0, 'end': 0.1},
              {'word': 'real', 'start': 0.1, 'end': 0.5},
            ],
          },
        ],
      );
      final result = mapLongFormTranscriptToAsrResult(transcript);
      expect(result.segments![0].words!.length, 1);
      expect(result.segments![0].words![0].word, 'real');
    });
  });
}
