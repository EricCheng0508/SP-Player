import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/transcript/application/active_transcript_provider.dart';
import 'package:enjoy_player/features/transcript/application/auto_translate_display_providers.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:enjoy_player/features/transcript/data/transcript_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _mediaId = 'm-1';

class _StubRepo extends TranscriptRepository {
  _StubRepo(AppDatabase db, {this.rows = const {}, this.primaryId}) : super(db);

  final Map<String, TranscriptRow> rows;
  final String? primaryId;

  @override
  Future<TranscriptRow?> transcriptRowById(String transcriptId) async =>
      rows[transcriptId];

  @override
  Future<TranscriptRow?> primaryTranscriptRowForMedia(String mediaId) async =>
      primaryId == null ? null : rows[primaryId!];
}

TranscriptRow _row({
  required String id,
  required String source,
  required String language,
  String? referenceId,
}) {
  final now = DateTime.utc(2026, 11, 28);
  return TranscriptRow(
    id: id,
    targetType: 'Video',
    targetId: _mediaId,
    language: language,
    source: source,
    timelineJson: '[]',
    referenceId: referenceId,
    label: id,
    createdAt: now,
    updatedAt: now,
  );
}

Future<({bool active, String? sourceLanguage, String? targetLanguage})>
_readState(ProviderContainer container) async {
  final sub = container.listen(
    autoTranslateDisplayStateProvider(_mediaId).future,
    (_, _) {},
  );
  addTearDown(sub.close);
  await pumpEventQueue();
  return sub.read();
}

void main() {
  test('AI secondary derives active with row languages', () async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);
    final repo = _StubRepo(
      db,
      primaryId: 'primary-1',
      rows: {
        'primary-1': _row(id: 'primary-1', source: 'official', language: 'en'),
        'ai-1': _row(
          id: 'ai-1',
          source: 'ai',
          language: 'zh-CN',
          referenceId: 'primary-1',
        ),
      },
    );
    final container = ProviderContainer(
      overrides: [
        transcriptRepositoryProvider.overrideWithValue(repo),
        secondaryTranscriptIdProvider(
          _mediaId,
        ).overrideWith((ref) => Stream.value('ai-1')),
      ],
    );
    addTearDown(container.dispose);

    final state = await _readState(container);

    expect(state.active, isTrue);
    expect(state.sourceLanguage, 'en');
    expect(state.targetLanguage, 'zh-CN');
  });

  test('non-AI secondary is inactive', () async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);
    final repo = _StubRepo(
      db,
      primaryId: 'primary-1',
      rows: {
        'primary-1': _row(id: 'primary-1', source: 'official', language: 'en'),
      },
    );
    final container = ProviderContainer(
      overrides: [
        transcriptRepositoryProvider.overrideWithValue(repo),
        secondaryTranscriptIdProvider(
          _mediaId,
        ).overrideWith((ref) => Stream.value('primary-1')),
      ],
    );
    addTearDown(container.dispose);

    final state = await _readState(container);

    expect(state.active, isFalse);
    expect(state.sourceLanguage, isNull);
    expect(state.targetLanguage, isNull);
  });

  test('no secondary is inactive', () async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);
    final repo = _StubRepo(db);
    final container = ProviderContainer(
      overrides: [
        transcriptRepositoryProvider.overrideWithValue(repo),
        secondaryTranscriptIdProvider(
          _mediaId,
        ).overrideWith((ref) => Stream.value(null)),
      ],
    );
    addTearDown(container.dispose);

    final state = await _readState(container);

    expect(state.active, isFalse);
    expect(state.sourceLanguage, isNull);
    expect(state.targetLanguage, isNull);
  });
}
