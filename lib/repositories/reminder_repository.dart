import 'package:energy_saving/database/database_constants.dart';
import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/reminder.dart';

class ReminderRepository {
  const ReminderRepository({required this.databaseHelper});

  final DatabaseHelper databaseHelper;

  Future<List<Reminder>> getForUser(int userId) async {
    final rows = await (await databaseHelper.database).query(
      DatabaseConstants.remindersTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'reminder_time ASC, id ASC',
    );
    return rows.map(Reminder.fromMap).toList(growable: false);
  }

  Future<int> insert(Reminder reminder) async {
    final values = reminder.toMap()..remove('id');
    return (await databaseHelper.database).insert(
      DatabaseConstants.remindersTable,
      values,
    );
  }

  Future<int> update(Reminder reminder) async {
    final id = reminder.id;
    if (id == null) throw ArgumentError.value(id, 'reminder.id');

    final values = reminder.toMap()..remove('id');
    return (await databaseHelper.database).update(
      DatabaseConstants.remindersTable,
      values,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, reminder.userId],
    );
  }

  Future<int> setEnabled({
    required int reminderId,
    required int userId,
    required bool isEnabled,
  }) async {
    return (await databaseHelper.database).update(
      DatabaseConstants.remindersTable,
      {'is_enabled': isEnabled ? 1 : 0},
      where: 'id = ? AND user_id = ?',
      whereArgs: [reminderId, userId],
    );
  }

  Future<int> delete({required int reminderId, required int userId}) async {
    return (await databaseHelper.database).delete(
      DatabaseConstants.remindersTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [reminderId, userId],
    );
  }
}