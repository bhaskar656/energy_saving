import 'package:energy_saving/database/database_constants.dart';
import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/reminder.dart';
import 'package:energy_saving/models/user.dart';
import 'package:energy_saving/repositories/sqlite_repository.dart';
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

  test('opens the versioned schema with all tables and foreign keys', () async {
    final database = await databaseHelper.database;
    expect(await database.getVersion(), DatabaseConstants.databaseVersion);

    final tableRows = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final tableNames = tableRows.map((row) => row['name']).toSet();
    expect(
      tableNames,
      containsAll([
        DatabaseConstants.usersTable,
        DatabaseConstants.remindersTable,
        DatabaseConstants.energyUsageTable,
        DatabaseConstants.appliancesTable,
        DatabaseConstants.energyGoalsTable,
        DatabaseConstants.tipsTable,
        DatabaseConstants.notificationsTable,
      ]),
    );

    final foreignKeys = await database.rawQuery(
      'PRAGMA foreign_key_list(${DatabaseConstants.remindersTable})',
    );
    expect(foreignKeys.any((row) => row['table'] == 'users'), isTrue);
  });

  test('inserts, retrieves, updates, and deletes a reminder', () async {
    final userRepository = SqliteRepository<User>(
      databaseHelper: databaseHelper,
      tableName: DatabaseConstants.usersTable,
      fromRow: User.fromMap,
      toRow: (user) => user.toMap(),
    );
    final userId = await userRepository.insert(
      User(name: 'Test User', email: 'test@example.com'),
    );

    final reminderRepository = SqliteRepository<Reminder>(
      databaseHelper: databaseHelper,
      tableName: DatabaseConstants.remindersTable,
      fromRow: Reminder.fromMap,
      toRow: (reminder) => reminder.toMap(),
    );
    final reminderId = await reminderRepository.insert(
      Reminder(
        userId: userId,
        title: 'Switch off the fan',
        appliance: 'Fan',
        reminderTime: DateTime(2026, 9, 29, 22),
      ),
    );

    final inserted = await reminderRepository.getById(reminderId);
    expect(inserted?.title, 'Switch off the fan');
    expect((await reminderRepository.getAll()).length, 1);

    final updated = Reminder(
      id: reminderId,
      userId: userId,
      title: 'Switch off the lights',
      appliance: 'Lights',
      reminderTime: DateTime(2026, 9, 29, 23),
      isEnabled: false,
      createdAt: inserted!.createdAt,
    );
    expect(await reminderRepository.update(reminderId, updated), 1);

    final saved = await reminderRepository.getById(reminderId);
    expect(saved?.title, 'Switch off the lights');
    expect(saved?.isEnabled, isFalse);

    expect(await reminderRepository.delete(reminderId), 1);
    expect(await reminderRepository.getById(reminderId), isNull);
  });
}