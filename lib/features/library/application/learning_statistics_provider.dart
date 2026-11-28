/// Learning statistics aggregated from the local recordings table.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/library/domain/learning_statistics.dart';

part 'learning_statistics_provider.g.dart';

@riverpod
Future<LearningStatistics?> learningStatistics(Ref ref) async {
  final db = ref.watch(appDatabaseProvider);
  final rows = await db.select(db.recordings).get();

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
  final monthStart = DateTime(now.year, now.month);

  PeriodStats periodFrom(DateTime start) {
    final recorded = rows.where((row) => !row.createdAt.isBefore(start));
    return PeriodStats(
      recordingDurationMs: recorded.fold<int>(
        0,
        (total, row) => total + row.duration,
      ),
      recordingCount: recorded.length,
    );
  }

  return LearningStatistics(
    today: periodFrom(todayStart),
    week: periodFrom(weekStart),
    month: periodFrom(monthStart),
  );
}
