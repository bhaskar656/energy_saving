// TEMPORARY visual preview harness: renders the redesigned screens with real
// seeded database data and writes PNGs via `flutter test --update-goldens`.
// Delete this file (and test/preview/) once the redesign has been reviewed.
import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/appliance.dart';
import 'package:energy_saving/models/energy_goal.dart';
import 'package:energy_saving/models/energy_usage.dart';
import 'package:energy_saving/models/reminder.dart';
import 'package:energy_saving/models/user.dart';
import 'package:energy_saving/repositories/appliance_repository.dart';
import 'package:energy_saving/repositories/dashboard_repository.dart';
import 'package:energy_saving/repositories/energy_goal_repository.dart';
import 'package:energy_saving/repositories/energy_tip_repository.dart';
import 'package:energy_saving/repositories/energy_usage_repository.dart';
import 'package:energy_saving/repositories/notification_preferences_repository.dart';
import 'package:energy_saving/repositories/reminder_repository.dart';
import 'package:energy_saving/repositories/user_repository.dart';
import 'package:energy_saving/repositories/user_settings_repository.dart';
import 'package:energy_saving/screens/appliances_screen.dart';
import 'package:energy_saving/screens/auth_gate.dart';
import 'package:energy_saving/screens/energy_calculator_screen.dart';
import 'package:energy_saving/screens/energy_goals_screen.dart';
import 'package:energy_saving/screens/energy_usage_screen.dart';
import 'package:energy_saving/screens/home_screen.dart';
import 'package:energy_saving/screens/profile_screen.dart';
import 'package:energy_saving/screens/reminders_screen.dart';
import 'package:energy_saving/screens/tips_screen.dart';
import 'package:energy_saving/services/auth_service.dart';
import 'package:energy_saving/services/reminder_notification_service.dart';
import 'package:energy_saving/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _OfflineAuthSession implements AuthSession {
  const _OfflineAuthSession();

  @override
  Future<User?> currentUser() async => null;

  @override
  Future<User> login({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> logout() async {}
}

void main() {
  late DatabaseHelper databaseHelper;
  late int userId;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    databaseHelper = DatabaseHelper(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    userId = await UserRepository(
      databaseHelper: databaseHelper,
    ).insert(User(name: 'Aarav Sharma', email: 'aarav@example.com'));

    final usageRepository = EnergyUsageRepository(
      databaseHelper: databaseHelper,
    );
    final now = DateTime.now();
    Future<void> addUsage(String appliance, double kwh, double hours) {
      return usageRepository.insert(
        EnergyUsage(
          userId: userId,
          appliance: appliance,
          usageDate: now.subtract(Duration(days: now.weekday - 2)),
          unitsKwh: kwh,
          hoursUsed: hours,
          powerWatts: 75,
        ),
      );
    }

    await addUsage('Ceiling Fan', 1.5, 2);
    await addUsage('LED Light', 0.4, 5);
    await addUsage('Air Conditioner', 4.2, 7);
    await addUsage('Refrigerator', 1.8, 10);

    final reminderRepository = ReminderRepository(
      databaseHelper: databaseHelper,
    );
    await reminderRepository.insert(
      Reminder(
        userId: userId,
        title: 'Switch off the geyser',
        appliance: 'Geyser',
        description: 'The geyser uses more power than every other appliance.',
        reminderTime: DateTime(now.year, now.month, now.day, 21, 30),
      ),
    );
    await reminderRepository.insert(
      Reminder(
        userId: userId,
        title: 'Unplug the TV',
        appliance: 'TV',
        description: 'Avoid standby power overnight.',
        reminderTime: DateTime(now.year, now.month, now.day, 23, 0),
      ),
    );
    await reminderRepository.insert(
      Reminder(
        userId: userId,
        title: 'Fan off before sleep',
        appliance: 'Fan',
        reminderTime: DateTime(now.year, now.month, now.day, 22, 45),
        isEnabled: false,
      ),
    );

    final applianceRepository = ApplianceRepository(
      databaseHelper: databaseHelper,
    );
    for (final appliance in [
      Appliance(
        userId: userId,
        name: 'Ceiling Fan',
        category: 'Cooling',
        powerWatts: 75,
        averageHours: 6,
      ),
      Appliance(
        userId: userId,
        name: 'LED Light',
        category: 'Lighting',
        powerWatts: 12,
        averageHours: 5,
      ),
      Appliance(
        userId: userId,
        name: 'Air Conditioner',
        category: 'Cooling',
        powerWatts: 1200,
        averageHours: 7,
      ),
      Appliance(
        userId: userId,
        name: 'Refrigerator',
        category: 'Kitchen',
        powerWatts: 150,
        averageHours: 10,
      ),
    ]) {
      await applianceRepository.insert(appliance);
    }

    await EnergyGoalRepository(databaseHelper: databaseHelper).saveForUser(
      EnergyGoal(
        userId: userId,
        monthlyTargetKwh: 220,
        monthlySavingTarget: 35,
      ),
    );
    await UserSettingsRepository(
      databaseHelper: databaseHelper,
    ).setElectricityTariff(userId, 8.5);
    await NotificationPreferencesRepository(
      databaseHelper: databaseHelper,
    ).setEnabledForUser(userId, true);
  });

  tearDown(() async {
    await databaseHelper.close();
  });

  Future<void> pumpPhone(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: child,
      ),
    );
    // Fixed number of pumps: some screens legitimately keep a spinner on
    // screen, so pumpAndSettle would never return.
    for (var frame = 0; frame < 25; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  final user = () => User(
    id: userId,
    name: 'Aarav Sharma',
    email: 'aarav@example.com',
  );

  testWidgets('preview: home dashboard', (tester) async {
    await pumpPhone(
      tester,
      HomeScreen(
        user: user(),
        onLogout: () {},
        dashboardRepository: DashboardRepository(databaseHelper: databaseHelper),
        settingsRepository: UserSettingsRepository(
          databaseHelper: databaseHelper,
        ),
      ),
    );
    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('preview/01_home_top.png'),
    );
  });

  testWidgets('preview: home dashboard scrolled', (tester) async {
    await pumpPhone(
      tester,
      HomeScreen(
        user: user(),
        onLogout: () {},
        dashboardRepository: DashboardRepository(databaseHelper: databaseHelper),
        settingsRepository: UserSettingsRepository(
          databaseHelper: databaseHelper,
        ),
      ),
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('preview/02_home_scrolled.png'),
    );
  });

  testWidgets('preview: energy usage tab', (tester) async {
    await pumpPhone(
      tester,
      EnergyUsageScreen(
        userId: userId,
        repository: EnergyUsageRepository(databaseHelper: databaseHelper),
      ),
    );
    await expectLater(
      find.byType(EnergyUsageScreen),
      matchesGoldenFile('preview/03_usage.png'),
    );
  });

  testWidgets('preview: reminders tab', (tester) async {
    await pumpPhone(
      tester,
      RemindersScreen(
        userId: userId,
        repository: ReminderRepository(databaseHelper: databaseHelper),
        notificationService: LocalReminderNotificationService(),
        notificationPreferencesRepository: NotificationPreferencesRepository(
          databaseHelper: databaseHelper,
        ),
      ),
    );
    await expectLater(
      find.byType(RemindersScreen),
      matchesGoldenFile('preview/04_reminders.png'),
    );
  });

  testWidgets('preview: profile tab', (tester) async {
    await pumpPhone(
      tester,
      ProfileScreen(
        user: user(),
        onLogout: () {},
        settingsRepository: UserSettingsRepository(
          databaseHelper: databaseHelper,
        ),
        notificationPreferencesRepository: NotificationPreferencesRepository(
          databaseHelper: databaseHelper,
        ),
        reminderRepository: ReminderRepository(
          databaseHelper: databaseHelper,
        ),
        goalRepository: EnergyGoalRepository(
          databaseHelper: databaseHelper,
        ),
        usageRepository: EnergyUsageRepository(
          databaseHelper: databaseHelper,
        ),
        notificationService: LocalReminderNotificationService(),
        onThemeModeChanged: (_) {},
      ),
    );
    await expectLater(
      find.byType(ProfileScreen),
      matchesGoldenFile('preview/05_profile.png'),
    );
  });

  testWidgets('preview: appliances', (tester) async {
    await pumpPhone(
      tester,
      AppliancesScreen(
        userId: userId,
        repository: ApplianceRepository(databaseHelper: databaseHelper),
      ),
    );
    await expectLater(
      find.byType(AppliancesScreen),
      matchesGoldenFile('preview/06_appliances.png'),
    );
  });

  testWidgets('preview: goals', (tester) async {
    await pumpPhone(
      tester,
      EnergyGoalsScreen(
        userId: userId,
        goalRepository: EnergyGoalRepository(databaseHelper: databaseHelper),
        usageRepository: EnergyUsageRepository(databaseHelper: databaseHelper),
      ),
    );
    await expectLater(
      find.byType(EnergyGoalsScreen),
      matchesGoldenFile('preview/07_goals.png'),
    );
  });

  testWidgets('preview: tips', (tester) async {
    await pumpPhone(
      tester,
      TipsScreen(
        repository: EnergyTipRepository(databaseHelper: databaseHelper),
      ),
    );
    await expectLater(
      find.byType(TipsScreen),
      matchesGoldenFile('preview/08_tips.png'),
    );
  });

  testWidgets('preview: calculator', (tester) async {
    await pumpPhone(tester, const EnergyCalculatorScreen());
    await expectLater(
      find.byType(EnergyCalculatorScreen),
      matchesGoldenFile('preview/09_calculator.png'),
    );
  });

  testWidgets('preview: login', (tester) async {
    await pumpPhone(
      tester,
      const AuthGate(
        authSession: _OfflineAuthSession(),
      ),
    );
    await expectLater(
      find.byType(AuthGate),
      matchesGoldenFile('preview/10_login.png'),
    );
  });
}