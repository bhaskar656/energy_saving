import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/repositories/appliance_repository.dart';
import 'package:energy_saving/repositories/energy_goal_repository.dart';
import 'package:energy_saving/repositories/energy_usage_repository.dart';
import 'package:energy_saving/repositories/reminder_repository.dart';
import 'package:energy_saving/screens/appliance_form_screen.dart';
import 'package:energy_saving/screens/energy_goal_form_screen.dart';
import 'package:energy_saving/screens/energy_usage_form_screen.dart';
import 'package:energy_saving/screens/reminder_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

  testWidgets('reminder form rejects missing title and appliance', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReminderFormScreen(
          userId: 1,
          repository: ReminderRepository(databaseHelper: databaseHelper),
        ),
      ),
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Enter a title.'), findsOneWidget);
    expect(find.text('Enter an appliance.'), findsOneWidget);
  });

  testWidgets('appliance form rejects invalid power and daily hours', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ApplianceFormScreen(
          userId: 1,
          repository: ApplianceRepository(databaseHelper: databaseHelper),
        ),
      ),
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Enter an appliance name.'), findsOneWidget);
    expect(find.text('Enter a power value greater than 0 W.'), findsOneWidget);
    expect(find.text('Enter daily hours from 0 to 24.'), findsOneWidget);
  });

  testWidgets('usage form rejects missing appliance and invalid measurements', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EnergyUsageFormScreen(
          userId: 1,
          repository: EnergyUsageRepository(databaseHelper: databaseHelper),
        ),
      ),
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Enter an appliance.'), findsOneWidget);
    expect(find.text('Enter a power value greater than 0 W.'), findsOneWidget);
    expect(find.text('Enter daily hours from 0 to 24.'), findsOneWidget);
  });

  testWidgets('goal form requires a positive monthly target', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EnergyGoalFormScreen(
          userId: 1,
          repository: EnergyGoalRepository(databaseHelper: databaseHelper),
        ),
      ),
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter a monthly target greater than 0 kWh.'),
      findsOneWidget,
    );
  });
}