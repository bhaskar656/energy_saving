import 'dart:io';

import 'package:energy_saving/database/database_constants.dart';
import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/user.dart';
import 'package:energy_saving/repositories/user_repository.dart';
import 'package:energy_saving/repositories/user_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  test('persists theme and tariff independently per user', () async {
    final databaseHelper = DatabaseHelper(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    try {
      final userRepository = UserRepository(databaseHelper: databaseHelper);
      final firstUserId = await userRepository.insert(
        User(name: 'First User', email: 'settings-first@example.com'),
      );
      final secondUserId = await userRepository.insert(
        User(name: 'Second User', email: 'settings-second@example.com'),
      );
      final settingsRepository = UserSettingsRepository(
        databaseHelper: databaseHelper,
      );

      final defaults = await settingsRepository.getForUser(firstUserId);
      expect(defaults.darkModeEnabled, isFalse);
      expect(defaults.electricityTariff, isNull);

      await settingsRepository.setDarkMode(firstUserId, true);
      await settingsRepository.setElectricityTariff(firstUserId, 8.5);
      final saved = await settingsRepository.getForUser(firstUserId);
      expect(saved.darkModeEnabled, isTrue);
      expect(saved.electricityTariff, 8.5);

      await settingsRepository.setElectricityTariff(firstUserId, null);
      expect(
        (await settingsRepository.getForUser(firstUserId)).electricityTariff,
        isNull,
      );
      final otherUserSettings = await settingsRepository.getForUser(secondUserId);
      expect(otherUserSettings.darkModeEnabled, isFalse);
      expect(otherUserSettings.electricityTariff, isNull);
    } finally {
      await databaseHelper.close();
    }
  });

  test('migrates a version 3 database with existing preferences to version 4', () async {
    final databasePath = path.join(
      Directory.systemTemp.path,
      'energy_saving_v3_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final versionThreeDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (database, version) async {
          for (final statement in DatabaseConstants.tableStatements) {
            await database.execute(statement);
          }
          await database.execute(
            DatabaseConstants.notificationPreferencesTableStatement,
          );
        },
      ),
    );
    await versionThreeDatabase.close();

    final databaseHelper = DatabaseHelper(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
    );
    try {
      final database = await databaseHelper.database;
      expect(await database.getVersion(), DatabaseConstants.databaseVersion);
      final tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      expect(
        tables.any((row) => row['name'] == DatabaseConstants.userSettingsTable),
        isTrue,
      );
      final foreignKeys = await database.rawQuery(
        'PRAGMA foreign_key_list(${DatabaseConstants.userSettingsTable})',
      );
      expect(foreignKeys.any((row) => row['table'] == 'users'), isTrue);
    } finally {
      await databaseHelper.close();
      await databaseFactoryFfi.deleteDatabase(databasePath);
    }
  });
}