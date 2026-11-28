/// Learning statistics aggregated from the local recordings table.
library;

class PeriodStats {
  const PeriodStats({
    required this.recordingDurationMs,
    required this.recordingCount,
  });

  final int recordingDurationMs;
  final int recordingCount;

  static PeriodStats zero() =>
      const PeriodStats(recordingDurationMs: 0, recordingCount: 0);
}

class LearningStatistics {
  const LearningStatistics({
    required this.today,
    required this.week,
    required this.month,
  });

  final PeriodStats today;
  final PeriodStats week;
  final PeriodStats month;

  static LearningStatistics empty() => LearningStatistics(
    today: PeriodStats.zero(),
    week: PeriodStats.zero(),
    month: PeriodStats.zero(),
  );
}
