import 'dart:io';

import 'package:energy_saving/database/database_constants.dart';
import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('AuthService', () {
    late DatabaseHelper databaseHelper;
    late AuthService authService;

    setUp(() {
      databaseHelper = DatabaseHelper(
        factory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
      );
      authService = AuthService(databaseHelper: databaseHelper);
    });

    tearDown(() async {
      await databaseHelper.close();
    });

    test('registers, restores a session, logs out, and signs in', () async {
      const password = 'demo password 123';
      final user = await authService.register(
        name: 'Riya Sharma',
        email: 'RIYA@example.com',
        password: password,
      );

      expect(user.email, 'riya@example.com');
      expect(user.passwordHash, startsWith('sha256-v1:'));
      expect(user.passwordHash, isNot(contains(password)));

      final restoredUser = await AuthService(
        databaseHelper: databaseHelper,
      ).currentUser();
      expect(restoredUser?.id, user.id);

      await authService.logout();
      expect(await authService.currentUser(), isNull);

      final signedInUser = await authService.login(
        email: 'Riya@Example.com',
        password: password,
      );
      expect(signedInUser.id, user.id);
      expect((await authService.currentUser())?.id, user.id);
    });

    test('rejects duplicate email and invalid credentials', () async {
      await authService.register(
        name: 'Riya Sharma',
        email: 'riya@example.com',
        password: 'demo password 123',
      );

      await expectLater(
        authService.register(
          name: 'Another User',
          email: 'RIYA@example.com',
          password: 'another password 123',
        ),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        authService.login(
          email: 'riya@example.com',
          password: 'incorrect password',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  test('upgrades a version 1 database with the session table', () async {
    final databasePath = path.join(
      Directory.systemTemp.path,
      'energy_saving_v1_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final versionOneDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (database, version) async {
          for (final statement in DatabaseConstants.baseTableStatements) {
            await database.execute(statement);
          }
        },
      ),
    );
    await versionOneDatabase.close();

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
        tables.any((row) => row['name'] == DatabaseConstants.userSessionsTable),
        isTrue,
      );
    } finally {
      await databaseHelper.close();
      await databaseFactoryFfi.deleteDatabase(databasePath);
    }
  });
}