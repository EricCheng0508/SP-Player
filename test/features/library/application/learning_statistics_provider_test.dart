import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/library/application/learning_statistics_provider.dart';
import 'package:enjoy_player/features/library/domain/learning_statistics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _insertRecording(
  AppDatabase db, {
  required String id,
  required DateTime createdAt,
  required int durationMs,
}) async {
  await db
      .into(db.recordings)
      .insert(
        RecordingsCompanion.insert(
          createdAt: createdAt,
          updatedAt: DateTime.now(),
          id: id,
          targetType: 'Audio',
          targetId: 'media-$id',
          referenceStart: 0,
          referenceDuration: durationMs + 500,
          referenceText: 'line $id',
          language: 'en',
          duration: durationMs,
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<LearningStatistics> readStats() async {
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    final Future<LearningStatistics?> future = container.read(
      learningStatisticsProvider.future,
    );
    return (await future)!;
  }

  test('empty recordings table yields all-zero periods', () async {
    final stats = await readStats();
    expect(stats.today.recordingDurationMs, 0);
    expect(stats.today.recordingCount, 0);
    expect(stats.week.recordingDurationMs, 0);
    expect(stats.week.recordingCount, 0);
    expect(stats.month.recordingDurationMs, 0);
    expect(stats.month.recordingCount, 0);
  });

  test('aggregates recording duration and count per period', () async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month);
    final beforeMonth = DateTime(monthStart.year, monthStart.month, 0, 23);

    final rows = <(String, DateTime, int)>[
      ('today', todayStart.add(const Duration(hours: 1)), 1000),
      ('week', weekStart.add(const Duration(hours: 1)), 2000),
      ('month', monthStart.add(const Duration(hours: 1)), 4000),
      ('before-month', beforeMonth, 8000),
    ];
    for (final (id, createdAt, durationMs) in rows) {
      await _insertRecording(
        db,
        id: id,
        createdAt: createdAt,
        durationMs: durationMs,
      );
    }

    PeriodStats expectedFor(DateTime start) {
      final inPeriod = rows.where((r) => !r.$2.isBefore(start)).toList();
      return PeriodStats(
        recordingDurationMs: inPeriod.fold<int>(0, (sum, r) => sum + r.$3),
        recordingCount: inPeriod.length,
      );
    }

    final stats = await readStats();

    for (final (period, start) in [
      ('today', todayStart),
      ('week', weekStart),
      ('month', monthStart),
    ]) {
      final expected = expectedFor(start);
      final actual = switch (period) {
        'today' => stats.today,
        'week' => stats.week,
        _ => stats.month,
      };
      expect(actual.recordingCount, expected.recordingCount, reason: period);
      expect(
        actual.recordingDurationMs,
        expected.recordingDurationMs,
        reason: period,
      );
    }
    expect(
      stats.month.recordingDurationMs,
      lessThanOrEqualTo(7000),
      reason: 'the pre-month recording must be excluded',
    );
    expect(
      stats.month.recordingCount,
      lessThanOrEqualTo(3),
      reason: 'the pre-month recording must be excluded',
    );
  });
}
