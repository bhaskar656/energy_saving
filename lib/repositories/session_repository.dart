import 'package:energy_saving/database/database_constants.dart';
import 'package:energy_saving/database/database_helper.dart';

class SessionRepository {
  const SessionRepository({required this.databaseHelper});

  final DatabaseHelper databaseHelper;

  Future<int?> getCurrentUserId() async {
    final rows = await (await databaseHelper.database).query(
      DatabaseConstants.userSessionsTable,
      columns: ['user_id'],
      where: 'id = 1',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['user_id'] as int;
  }

  Future<void> saveCurrentUser(int userId) async {
    final database = await databaseHelper.database;
    await database.transaction((transaction) async {
      await transaction.delete(DatabaseConstants.userSessionsTable);
      await transaction.insert(DatabaseConstants.userSessionsTable, {
        'id': 1,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> clear() async {
    await (await databaseHelper.database).delete(
      DatabaseConstants.userSessionsTable,
      where: 'id = 1',
    );
  }
}