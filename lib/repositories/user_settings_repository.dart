import 'package:energy_saving/database/database_constants.dart';
import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/user_settings.dart';
import 'package:sqflite/sqflite.dart';

class UserSettingsRepository {
  const UserSettingsRepository({required this.databaseHelper});

  final DatabaseHelper databaseHelper;

  Future<UserSettings> getForUser(int userId) async {
    final rows = await (await databaseHelper.database).query(
      DatabaseConstants.userSettingsTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return rows.isEmpty
        ? UserSettings(userId: userId)
        : UserSettings.fromMap(rows.first);
  }

  Future<UserSettings> setDarkMode(int userId, bool enabled) {
    return _update(
      userId,
      (current) => UserSettings(
        userId: userId,
        darkModeEnabled: enabled,
        electricityTariff: current.electricityTariff,
      ),
    );
  }

  Future<UserSettings> setElectricityTariff(int userId, double? tariff) {
    if (tariff != null && (!tariff.isFinite || tariff < 0)) {
      throw ArgumentError.value(tariff, 'tariff');
    }
    return _update(
      userId,
      (current) => UserSettings(
        userId: userId,
        darkModeEnabled: current.darkModeEnabled,
        electricityTariff: tariff,
      ),
    );
  }

  Future<UserSettings> _update(
    int userId,
    UserSettings Function(UserSettings current) update,
  ) async {
    final database = await databaseHelper.database;
    return database.transaction((transaction) async {
      final rows = await transaction.query(
        DatabaseConstants.userSettingsTable,
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      final current = rows.isEmpty
          ? UserSettings(userId: userId)
          : UserSettings.fromMap(rows.first);
      final updated = update(current);
      final values = updated.toMap()
        ..['updated_at'] = DateTime.now().toIso8601String();
      await transaction.insert(
        DatabaseConstants.userSettingsTable,
        values,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return UserSettings.fromMap(values);
    });
  }
}