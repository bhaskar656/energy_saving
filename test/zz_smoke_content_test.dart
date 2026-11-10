// TEMPORARY smoke test: asserts the redesigned screens really render their
// key labels with live database data. Delete once reviewed.
import 'package:energy_saving/database/database_constants.dart';
import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/energy_goal.dart';
import 'package:energy_saving/models/energy_usage.dart';
import 'package:energy_saving/models/reminder.dart';
import 'package:energy_saving/models/user.dart';
import 'package:energy_saving/repositories/appliance_repository.dart';
import 'package:energy_saving/repositories/dashboard_repository.dart';
import 'package:energy_saving/repositories/energy_goal_repository.dart';
import 'package:energy_saving/repositories/energy_usage_repository.dart';
import 'package:energy_saving/repositories/notification_preferences_repository.dart';
import 'package:energy_saving/repositories/reminder_repository.dart';
import 'package:energy_saving/repositories/user_repository.dart';
import 'package:energy_saving/repositories/user_settings_repository.dart';
import 'package:energy_saving/screens/appliances_screen.dart';
import 'package:energy_saving/screens/energy_usage_screen.dart';
import 'package:energy_saving/screens/home_screen.dart';
import 'package:energy_saving/screens/profile_screen.dart';
import 'package:energy_saving/screens/reminders_screen.dart';
import 'package:energy_saving/services/reminder_notification_service.dart';
import 'package:energy_saving/theme/app_theme.dart';
import 'package:energy_saving/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper databaseHelper;
  late int userId;

  setUpAll(() async {
    sqfliteFfiInit();
    // Let the app's DatabaseHelper.instance work so the tab shell can be
    // exercised exactly like the real app does.
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.close();
    await databaseFactoryFfi.deleteDatabase(
      path.join(
        await databaseFactoryFfi.getDatabasesPath(),
        DatabaseConstants.databaseName,
      ),
    );
  });

  setUp(() async {
    databaseHelper = DatabaseHelper(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    userId = await UserRepository(
      databaseHelper: databaseHelper,
    ).insert(User(name: 'Aarav Sharma', email: 'aarav@example.com'));

    await EnergyUsageRepository(databaseHelper: databaseHelper).insert(
      EnergyUsage(
        userId: userId,
        appliance: 'Ceiling Fan',
        usageDate: DateTime.now(),
        unitsKwh: 1.5,
        hoursUsed: 2,
        powerWatts: 75,
      ),
    );
    await ReminderRepository(databaseHelper: databaseHelper).insert(
      Reminder(
        userId: userId,
        title: 'Switch off the geyser',
        appliance: 'Geyser',
        description: 'The geyser uses more power than everything else.',
        reminderTime: DateTime(2026, 10, 5, 21, 30),
      ),
    );
    await EnergyGoalRepository(databaseHelper: databaseHelper).saveForUser(
      EnergyGoal(userId: userId, monthlyTargetKwh: 220, monthlySavingTarget: 35),
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

  Future<User> buildUser() async => User(
    id: userId,
    name: 'Aarav Sharma',
    email: 'aarav@example.com',
  );

  /// Pumps the widget tree and gives the database isolate real wall-clock
  /// time to answer, so no arbitrary pump count is needed.
  Future<void> pumpApp(
    WidgetTester tester,
    Widget child, {
    Finder? until,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: child));
    await tester.pump(const Duration(milliseconds: 50));
    final deadline = DateTime.now().add(timeout);
    var spins = 0;
    while (DateTime.now().isBefore(deadline)) {
      if (until == null && spins >= 8) break;
      spins++;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await tester.pump(const Duration(milliseconds: 60));
      if (until == null) continue;
      if (until.evaluate().isNotEmpty) {
        await tester.pump(const Duration(milliseconds: 400));
        return;
      }
    }
  }

  Future<void> wait(
    WidgetTester tester, {
    Finder? until,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await tester.pump(const Duration(milliseconds: 60));
      if (until != null && until.evaluate().isNotEmpty) {
        await tester.pump(const Duration(milliseconds: 400));
        return;
      }
    }
  }

  testWidgets('home dashboard renders live figures', (tester) async {
    await pumpApp(
      tester,
      HomeScreen(
        user: await buildUser(),
        onLogout: () {},
        dashboardRepository: DashboardRepository(databaseHelper: databaseHelper),
        settingsRepository: UserSettingsRepository(
          databaseHelper: databaseHelper,
        ),
      ),
      until: find.text('Your impact'),
    );

    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Usage'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.textContaining('Welcome, Aarav Sharma'), findsOneWidget);
    expect(find.text('Your impact'), findsOneWidget);
    expect(find.text('Energy used today'), findsOneWidget);
    expect(find.text('Energy saved'), findsOneWidget);
    expect(find.text('Money saved'), findsOneWidget);
    expect(find.text('Monthly usage'), findsOneWidget);
    expect(find.text('Estimated bill'), findsOneWidget);
    expect(find.text('Environmental impact'), findsOneWidget);
    expect(find.text('Active reminders'), findsOneWidget);
    expect(find.text('Usage snapshot'), findsOneWidget);
    expect(find.text('Monthly goal'), findsOneWidget);
    expect(find.text('Quick tools'), findsOneWidget);
    expect(find.text('1.5 kWh today'), findsOneWidget);
    expect(find.text('1 reminders on'), findsOneWidget);
    expect(find.text('1.5 kWh'), findsWidgets);
    expect(find.textContaining('₹12.75'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom navigation reaches every tab', (tester) async {
    await pumpApp(
      tester,
      HomeScreen(
        user: await buildUser(),
        onLogout: () {},
        dashboardRepository: DashboardRepository(databaseHelper: databaseHelper),
        settingsRepository: UserSettingsRepository(
          databaseHelper: databaseHelper,
        ),
      ),
      until: find.text('Your impact'),
    );

    await tester.tap(find.text('Usage'));
    await wait(tester, until: find.text('Energy usage'));

    await tester.tap(find.text('Reminders'));
    await wait(tester, until: find.text('Your reminders'));

    await tester.tap(find.text('Profile'));
    await wait(tester, until: find.text('Account'));

    await tester.tap(find.text('Home'));
    await wait(tester, until: find.text('Your impact'));

    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.text('Your impact'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile tab renders account, settings and tariff', (
    tester,
  ) async {
    await pumpApp(
      tester,
      ProfileScreen(
        user: await buildUser(),
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
      until: find.text('Account'),
    );

    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Dark mode'), findsOneWidget);
    expect(find.text('Reminder notifications'), findsOneWidget);
    expect(find.text('Electricity tariff'), findsOneWidget);
    expect(find.text('Save tariff'), findsOneWidget);
    expect(find.textContaining('Log out'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('usage screen renders period header and records', (tester) async {
    await pumpApp(
      tester,
      EnergyUsageScreen(
        userId: userId,
        repository: EnergyUsageRepository(databaseHelper: databaseHelper),
      ),
      until: find.text('Ceiling Fan'),
    );

    expect(find.text('Energy usage'), findsWidgets);
    expect(find.text('Ceiling Fan'), findsWidgets);
    expect(find.text('1.5 kWh'), findsWidgets);
    expect(find.text('Today'), findsWidgets);
    expect(find.textContaining('% of period'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reminders screen renders header toggle and cards', (
    tester,
  ) async {
    await pumpApp(
      tester,
      RemindersScreen(
        userId: userId,
        repository: ReminderRepository(databaseHelper: databaseHelper),
        notificationService: LocalReminderNotificationService(),
        notificationPreferencesRepository: NotificationPreferencesRepository(
          databaseHelper: databaseHelper,
        ),
      ),
      until: find.text('Switch off the geyser'),
    );

    expect(find.text('Reminders'), findsWidgets);
    expect(find.text('Switch off the geyser'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.byType(Switch), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('appliances screen renders metrics', (tester) async {
    await pumpApp(
      tester,
      AppliancesScreen(
        userId: userId,
        repository: ApplianceRepository(databaseHelper: databaseHelper),
      ),
    );

    expect(find.text('Appliances'), findsWidgets);
    expect(find.textContaining('Your appliances'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}