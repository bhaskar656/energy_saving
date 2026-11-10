import 'package:energy_saving/database/database_constants.dart';
import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/appliance.dart';

class ApplianceRepository {
  const ApplianceRepository({required this.databaseHelper});

  final DatabaseHelper databaseHelper;

  Future<List<Appliance>> getForUser(int userId) async {
    final rows = await (await databaseHelper.database).query(
      DatabaseConstants.appliancesTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name COLLATE NOCASE ASC, id ASC',
    );
    return rows.map(Appliance.fromMap).toList(growable: false);
  }

  Future<int> insert(Appliance appliance) async {
    final values = appliance.toMap()..remove('id');
    return (await databaseHelper.database).insert(
      DatabaseConstants.appliancesTable,
      values,
    );
  }

  Future<int> update(Appliance appliance) async {
    final id = appliance.id;
    if (id == null) throw ArgumentError.value(id, 'appliance.id');

    final values = appliance.toMap()..remove('id');
    return (await databaseHelper.database).update(
      DatabaseConstants.appliancesTable,
      values,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, appliance.userId],
    );
  }

  Future<int> setActive({
    required int applianceId,
    required int userId,
    required bool isActive,
  }) async {
    return (await databaseHelper.database).update(
      DatabaseConstants.appliancesTable,
      {'is_active': isActive ? 1 : 0},
      where: 'id = ? AND user_id = ?',
      whereArgs: [applianceId, userId],
    );
  }

  Future<int> delete({required int applianceId, required int userId}) async {
    return (await databaseHelper.database).delete(
      DatabaseConstants.appliancesTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [applianceId, userId],
    );
  }
}