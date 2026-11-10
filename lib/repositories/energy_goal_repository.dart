import 'package:energy_saving/database/database_constants.dart';
import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/energy_goal.dart';

class EnergyGoalRepository {
  const EnergyGoalRepository({required this.databaseHelper});

  final DatabaseHelper databaseHelper;

  Future<EnergyGoal?> getCurrentForUser(int userId) async {
    final rows = await (await databaseHelper.database).query(
      DatabaseConstants.energyGoalsTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC, id DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : EnergyGoal.fromMap(rows.first);
  }

  Future<EnergyGoal> saveForUser(EnergyGoal goal) async {
    final database = await databaseHelper.database;
    return database.transaction((transaction) async {
      final existingRows = await transaction.query(
        DatabaseConstants.energyGoalsTable,
        where: 'user_id = ?',
        whereArgs: [goal.userId],
        orderBy: 'created_at DESC, id DESC',
        limit: 1,
      );

      if (existingRows.isEmpty) {
        final values = goal.toMap()..remove('id');
        final id = await transaction.insert(
          DatabaseConstants.energyGoalsTable,
          values,
        );
        return EnergyGoal(
          id: id,
          userId: goal.userId,
          monthlyTargetKwh: goal.monthlyTargetKwh,
          monthlySavingTarget: goal.monthlySavingTarget,
          createdAt: goal.createdAt,
        );
      }

      final existing = EnergyGoal.fromMap(existingRows.first);
      final updated = EnergyGoal(
        id: existing.id,
        userId: goal.userId,
        monthlyTargetKwh: goal.monthlyTargetKwh,
        monthlySavingTarget: goal.monthlySavingTarget,
        createdAt: existing.createdAt,
      );
      final values = updated.toMap()..remove('id');
      await transaction.update(
        DatabaseConstants.energyGoalsTable,
        values,
        where: 'id = ? AND user_id = ?',
        whereArgs: [existing.id, goal.userId],
      );
      return updated;
    });
  }
}