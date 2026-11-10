import 'package:energy_saving/database/database_constants.dart';
import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/dashboard_summary.dart';
import 'package:energy_saving/models/energy_goal.dart';
import 'package:energy_saving/models/energy_usage.dart';
import 'package:energy_saving/models/reminder.dart';
import 'package:energy_saving/models/user.dart';
import 'package:energy_saving/repositories/dashboard_repository.dart';
import 'package:energy_saving/repositories/sqlite_repository.dart';
import 'package:energy_saving/repositories/user_repository.dart';
import 'package:energy_saving/repositories/user_settings_repository.dart';
import 'package:energy_saving/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _EmptyDashboardDataSource implements DashboardDataSource {
  const _EmptyDashboardDataSource();

  @override
  Future<DashboardSummary> loadForUser(int userId, {DateTime? now}) async {
    return const DashboardSummary(
      todayUsageKwh: 0,
      todayRecordCount: 0,
      weekUsageKwh: 0,
      weekRecordCount: 0,
      monthUsageKwh: 0,
      monthRecordCount: 0,
      activeReminderCount: 0,
      monthlyTargetKwh: null,
      tariffPerKwh: null,
    );
  }
}

void main() {
  late DatabaseHelper databaseHelper;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() {
    databaseHelper = DatabaseHelper(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
  });

  tearDown(() async {
    await databaseHelper.close();
  });

  test('aggregates current user data over calendar periods', () async {
    final userRepository = UserRepository(databaseHelper: databaseHelper);
    final userId = await userRepository.insert(
      User(name: 'Dashboard User', email: 'dashboard@example.com'),
    );
    final otherUserId = await userRepository.insert(
      User(name: 'Other User', email: 'other@example.com'),
    );

    final usageRepository = SqliteRepository<EnergyUsage>(
      databaseHelper: databaseHelper,
      tableName: DatabaseConstants.energyUsageTable,
      fromRow: EnergyUsage.fromMap,
      toRow: (usage) => usage.toMap(),
    );
    Future<void> addUsage(int ownerId, DateTime date, double kwh) async {
      await usageRepository.insert(
        EnergyUsage(
          userId: ownerId,
          appliance: 'Fan',
          usageDate: date,
          unitsKwh: kwh,
          hoursUsed: 1,
          powerWatts: 75,
        ),
      );
    }

    await addUsage(userId, DateTime(2026, 9, 29, 10), 1.5);
    await addUsage(userId, DateTime(2026, 9, 28, 10), 2.5);
    await addUsage(userId, DateTime(2026, 9, 27, 10), 4);
    await addUsage(userId, DateTime(2026, 8, 31, 10), 10);
    await addUsage(otherUserId, DateTime(2026, 9, 29, 10), 100);

    final reminderRepository = SqliteRepository<Reminder>(
      databaseHelper: databaseHelper,
      tableName: DatabaseConstants.remindersTable,
      fromRow: Reminder.fromMap,
      toRow: (reminder) => reminder.toMap(),
    );
    for (var index = 0; index < 2; index++) {
      await reminderRepository.insert(
        Reminder(
          userId: userId,
          title: 'Reminder $index',
          appliance: 'Fan',
          reminderTime: DateTime(2026, 9, 29, 20),
        ),
      );
    }
    await reminderRepository.insert(
      Reminder(
        userId: userId,
        title: 'Disabled reminder',
        appliance: 'Light',
        reminderTime: DateTime(2026, 9, 29, 21),
        isEnabled: false,
      ),
    );
    await reminderRepository.insert(
      Reminder(
        userId: otherUserId,
        title: 'Other user reminder',
        appliance: 'TV',
        reminderTime: DateTime(2026, 9, 29, 21),
      ),
    );

    final goalRepository = SqliteRepository<EnergyGoal>(
      databaseHelper: databaseHelper,
      tableName: DatabaseConstants.energyGoalsTable,
      fromRow: EnergyGoal.fromMap,
      toRow: (goal) => goal.toMap(),
    );
    await goalRepository.insert(
      EnergyGoal(
        userId: userId,
        monthlyTargetKwh: 10,
        monthlySavingTarget: 2,
        createdAt: DateTime(2026, 9, 1),
      ),
    );
    await UserSettingsRepository(
      databaseHelper: databaseHelper,
    ).setElectricityTariff(userId, 8.5);

    final summary = await DashboardRepository(
      databaseHelper: databaseHelper,
    ).loadForUser(userId, now: DateTime(2026, 9, 29, 14));

    expect(summary.todayUsageKwh, 1.5);
    expect(summary.todayRecordCount, 1);
    expect(summary.weekUsageKwh, 4);
    expect(summary.weekRecordCount, 2);
    expect(summary.monthUsageKwh, 8);
    expect(summary.monthRecordCount, 3);
    expect(summary.activeReminderCount, 2);
    expect(summary.monthlyTargetKwh, 10);
    expect(summary.tariffPerKwh, 8.5);
  });

  testWidgets('shows explicit empty usage and goal states', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          user: User(
            id: 1,
            name: 'Dashboard User',
            email: 'dashboard@example.com',
          ),
          onLogout: () {},
          dashboardRepository: const _EmptyDashboardDataSource(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Energy used today'), findsOneWidget);
    expect(find.text('No usage recorded'), findsNWidgets(5));
    expect(find.text('No monthly target recorded.'), findsOneWidget);
    expect(find.text('Tariff not configured'), findsOneWidget);
  });

  testWidgets('shows the estimate from monthly usage and saved tariff', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          user: User(
            id: 1,
            name: 'Dashboard User',
            email: 'dashboard@example.com',
          ),
          onLogout: () {},
          dashboardRepository: const _FixedDashboardDataSource(
            DashboardSummary(
              todayUsageKwh: 1,
              todayRecordCount: 1,
              weekUsageKwh: 4,
              weekRecordCount: 2,
              monthUsageKwh: 8,
              monthRecordCount: 3,
              activeReminderCount: 0,
              monthlyTargetKwh: 10,
              tariffPerKwh: 8.5,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('₹68.00'), findsOneWidget);
    expect(find.text('At ₹8.50/kWh · estimate'), findsOneWidget);
  });
}

class _FixedDashboardDataSource implements DashboardDataSource {
  const _FixedDashboardDataSource(this.summary);

  final DashboardSummary summary;

  @override
  Future<DashboardSummary> loadForUser(int userId, {DateTime? now}) async =>
      summary;
}