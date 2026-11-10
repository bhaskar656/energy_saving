import 'package:energy_saving/database/database_constants.dart';
import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/energy_usage.dart';

class EnergyUsageRepository {
  const EnergyUsageRepository({required this.databaseHelper});

  final DatabaseHelper databaseHelper;

  Future<List<EnergyUsage>> getForUser(int userId) async {
    final rows = await (await databaseHelper.database).query(
      DatabaseConstants.energyUsageTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'usage_date DESC, id DESC',
    );
    return rows.map(EnergyUsage.fromMap).toList(growable: false);
  }

  Future<List<EnergyUsage>> getForUserBetween({
    required int userId,
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = await (await databaseHelper.database).query(
      DatabaseConstants.energyUsageTable,
      where: 'user_id = ? AND usage_date >= ? AND usage_date < ?',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'usage_date DESC, id DESC',
    );
    return rows.map(EnergyUsage.fromMap).toList(growable: false);
  }

  Future<int> insert(EnergyUsage usage) async {
    final values = usage.toMap()..remove('id');
    return (await databaseHelper.database).insert(
      DatabaseConstants.energyUsageTable,
      values,
    );
  }

  Future<int> update(EnergyUsage usage) async {
    final id = usage.id;
    if (id == null) throw ArgumentError.value(id, 'usage.id');

    final values = usage.toMap()..remove('id');
    return (await databaseHelper.database).update(
      DatabaseConstants.energyUsageTable,
      values,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, usage.userId],
    );
  }

  Future<int> delete({required int usageId, required int userId}) async {
    return (await databaseHelper.database).delete(
      DatabaseConstants.energyUsageTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [usageId, userId],
    );
  }
}