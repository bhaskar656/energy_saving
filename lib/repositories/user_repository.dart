import 'package:energy_saving/database/database_constants.dart';
import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/user.dart';

class UserRepository {
  const UserRepository({required this.databaseHelper});

  final DatabaseHelper databaseHelper;

  Future<int> insert(User user) async {
    final values = user.toMap()..remove('id');
    return (await databaseHelper.database).insert(
      DatabaseConstants.usersTable,
      values,
    );
  }

  Future<User?> findByEmail(String email) async {
    final rows = await (await databaseHelper.database).query(
      DatabaseConstants.usersTable,
      where: 'email = ? COLLATE NOCASE',
      whereArgs: [email.trim()],
      limit: 1,
    );
    return rows.isEmpty ? null : User.fromMap(rows.first);
  }

  Future<User?> findById(int id) async {
    final rows = await (await databaseHelper.database).query(
      DatabaseConstants.usersTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : User.fromMap(rows.first);
  }
}