import 'package:energy_saving/database/database_constants.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

typedef DatabaseMigration = Future<void> Function(Database database);

class DatabaseHelper {
  DatabaseHelper({
    DatabaseFactory? factory,
    this.databasePath,
    Future<String> Function()? databasesPath,
  }) : _factory = factory ?? databaseFactory,
       _databasesPath = databasesPath ?? getDatabasesPath;

  static final instance = DatabaseHelper();

  static final Map<int, DatabaseMigration> _migrations = {
    2: _createUserSessionsTable,
    3: _createNotificationPreferencesTable,
    4: _createUserSettingsTable,
  };

  final DatabaseFactory _factory;
  final String? databasePath;
  final Future<String> Function() _databasesPath;
  Future<Database>? _databaseFuture;

  Future<Database> get database => _databaseFuture ??= _openDatabase();

  Future<Database> _openDatabase() async {
    final resolvedDatabasePath = databasePath ??
        path.join(await _databasesPath(), DatabaseConstants.databaseName);

    return _factory.openDatabase(
      resolvedDatabasePath,
      options: OpenDatabaseOptions(
        version: DatabaseConstants.databaseVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> close() async {
    final databaseFuture = _databaseFuture;
    if (databaseFuture == null) return;

    await (await databaseFuture).close();
    _databaseFuture = null;
  }

  static Future<void> _onConfigure(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onCreate(Database database, int version) async {
    for (final statement in DatabaseConstants.tableStatements) {
      await database.execute(statement);
    }
    await database.execute(
      DatabaseConstants.notificationPreferencesTableStatement,
    );
    await database.execute(DatabaseConstants.userSettingsTableStatement);
  }

  static Future<void> _createUserSessionsTable(Database database) async {
    await database.execute(DatabaseConstants.userSessionsTableStatement);
  }

  static Future<void> _createNotificationPreferencesTable(
    Database database,
  ) async {
    await database.execute(
      DatabaseConstants.notificationPreferencesTableStatement,
    );
  }

  static Future<void> _createUserSettingsTable(Database database) async {
    await database.execute(DatabaseConstants.userSettingsTableStatement);
  }

  static Future<void> _onUpgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    for (var version = oldVersion + 1; version <= newVersion; version++) {
      final migration = _migrations[version];
      if (migration != null) await migration(database);
    }
  }
}