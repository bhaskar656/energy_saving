import 'package:energy_saving/database/database_constants.dart';
import 'package:energy_saving/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class NotificationPreferencesRepository {
  const NotificationPreferencesRepository({required this.databaseHelper});

  final DatabaseHelper databaseHelper;

  Future<bool> isEnabledForUser(int userId) async {
    final rows = await (await databaseHelper.database).query(
      DatabaseConstants.notificationPreferencesTable,
      columns: ['is_enabled'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return rows.isNotEmpty && rows.first['is_enabled'] == 1;
  }

  Future<void> setEnabledForUser(int userId, bool isEnabled) async {
    await (await databaseHelper.database).insert(
      DatabaseConstants.notificationPreferencesTable,
      {
        'user_id': userId,
        'is_enabled': isEnabled ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}