import 'package:energy_saving/database/database_constants.dart';
import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/dashboard_summary.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class DashboardDataSource {
  Future<DashboardSummary> loadForUser(int userId, {DateTime? now});
}

class DashboardRepository implements DashboardDataSource {
  const DashboardRepository({required this.databaseHelper});

  final DatabaseHelper databaseHelper;

  @override
  Future<DashboardSummary> loadForUser(int userId, {DateTime? now}) async {
    final currentDate = now ?? DateTime.now();
    final todayStart = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final weekStart = todayStart.subtract(
      Duration(days: todayStart.weekday - DateTime.monday),
    );
    final nextWeekStart = weekStart.add(const Duration(days: 7));
    final monthStart = DateTime(currentDate.year, currentDate.month);
    final nextMonthStart = DateTime(currentDate.year, currentDate.month + 1);

    final database = await databaseHelper.database;
    return database.transaction((transaction) async {
      final today = await _usageInRange(
        transaction,
        userId,
        todayStart,
        tomorrowStart,
      );
      final week = await _usageInRange(
        transaction,
        userId,
        weekStart,
        nextWeekStart,
      );
      final month = await _usageInRange(
        transaction,
        userId,
        monthStart,
        nextMonthStart,
      );
      final reminderRows = await transaction.rawQuery(
        '''
        SELECT COUNT(*) AS total
        FROM ${DatabaseConstants.remindersTable}
        WHERE user_id = ? AND is_enabled = 1
        ''',
        [userId],
      );
      final goalRows = await transaction.query(
        DatabaseConstants.energyGoalsTable,
        columns: ['monthly_target_kwh'],
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC, id DESC',
        limit: 1,
      );
      final settingsRows = await transaction.query(
        DatabaseConstants.userSettingsTable,
        columns: ['electricity_tariff'],
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      return DashboardSummary(
        todayUsageKwh: today.totalKwh,
        todayRecordCount: today.recordCount,
        weekUsageKwh: week.totalKwh,
        weekRecordCount: week.recordCount,
        monthUsageKwh: month.totalKwh,
        monthRecordCount: month.recordCount,
        activeReminderCount: (reminderRows.single['total'] as int),
        monthlyTargetKwh: goalRows.isEmpty
            ? null
            : (goalRows.first['monthly_target_kwh'] as num).toDouble(),
        tariffPerKwh: settingsRows.isEmpty
          ? null
          : (settingsRows.first['electricity_tariff'] as num?)?.toDouble(),
      );
    });
  }

  Future<_UsageRangeSummary> _usageInRange(
    DatabaseExecutor database,
    int userId,
    DateTime start,
    DateTime end,
  ) async {
    final rows = await database.rawQuery(
      '''
      SELECT COALESCE(SUM(units_kwh), 0) AS total_kwh, COUNT(*) AS record_count
      FROM ${DatabaseConstants.energyUsageTable}
      WHERE user_id = ? AND usage_date >= ? AND usage_date < ?
      ''',
      [userId, start.toIso8601String(), end.toIso8601String()],
    );
    final row = rows.single;
    return _UsageRangeSummary(
      totalKwh: (row['total_kwh'] as num).toDouble(),
      recordCount: row['record_count'] as int,
    );
  }
}

class _UsageRangeSummary {
  const _UsageRangeSummary({required this.totalKwh, required this.recordCount});

  final double totalKwh;
  final int recordCount;
}