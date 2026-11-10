import 'package:energy_saving/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

typedef ModelFromRow<T> = T Function(Map<String, Object?> row);
typedef ModelToRow<T> = Map<String, Object?> Function(T model);

class SqliteRepository<T> {
  const SqliteRepository({
    required this.databaseHelper,
    required this.tableName,
    required this.fromRow,
    required this.toRow,
  });

  final DatabaseHelper databaseHelper;
  final String tableName;
  final ModelFromRow<T> fromRow;
  final ModelToRow<T> toRow;

  Future<int> insert(T model) async {
    final values = toRow(model)..remove('id');
    return (await databaseHelper.database).insert(
      tableName,
      values,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<T?> getById(int id) async {
    final rows = await (await databaseHelper.database).query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : fromRow(rows.first);
  }

  Future<List<T>> getAll() async {
    final rows = await (await databaseHelper.database).query(
      tableName,
      orderBy: 'id ASC',
    );
    return rows.map(fromRow).toList(growable: false);
  }

  Future<int> update(int id, T model) async {
    final values = toRow(model)..remove('id');
    return (await databaseHelper.database).update(
      tableName,
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    return (await databaseHelper.database).delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}