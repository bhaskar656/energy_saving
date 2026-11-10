import 'dart:io';

import 'package:energy_saving/database/database_constants.dart';
import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/user.dart';
import 'package:energy_saving/repositories/notification_preferences_repository.dart';
import 'package:energy_saving/repositories/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  test('persists notification opt-in independently per user', () async {
    final databaseHelper = DatabaseHelper(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    try {
      final userRepository = UserRepository(databaseHelper: databaseHelper);
      final firstUserId = await userRepository.insert(
        User(name: 'First User', email: 'first-notification@example.com'),
      );
      final secondUserId = await userRepository.insert(
        User(name: 'Second User', email: 'second-notification@example.com'),
      );
      final preferences = NotificationPreferencesRepository(
        databaseHelper: databaseHelper,
      );

      expect(await preferences.isEnabledForUser(firstUserId), isFalse);
      await preferences.setEnabledForUser(firstUserId, true);
      expect(await preferences.isEnabledForUser(firstUserId), isTrue);
      expect(await preferences.isEnabledForUser(secondUserId), isFalse);

      await NotificationPreferencesRepository(
        databaseHelper: databaseHelper,
      ).setEnabledForUser(firstUserId, false);
      expect(await preferences.isEnabledForUser(firstUserId), isFalse);
    } finally {
      await databaseHelper.close();
    }
  });

  test('migrates a version 2 database to notification preferences', () async {
    final databasePath = path.join(
      Directory.systemTemp.path,
      'energy_saving_v2_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final versionTwoDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (database, version) async {
          for (final statement in DatabaseConstants.tableStatements) {
            await database.execute(statement);
          }
        },
      ),
    );
    await versionTwoDatabase.close();

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
        tables.any(
          (row) => row['name'] == DatabaseConstants.notificationPreferencesTable,
        ),
        isTrue,
      );
      final foreignKeys = await database.rawQuery(
        'PRAGMA foreign_key_list(${DatabaseConstants.notificationPreferencesTable})',
      );
      expect(foreignKeys.any((row) => row['table'] == 'users'), isTrue);
    } finally {
      await databaseHelper.close();
      await databaseFactoryFfi.deleteDatabase(databasePath);
    }
  });
}