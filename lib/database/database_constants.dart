abstract final class DatabaseConstants {
  static const databaseName = 'energy_saving.db';
  static const databaseVersion = 4;

  static const usersTable = 'users';
  static const userSessionsTable = 'user_sessions';
  static const notificationPreferencesTable = 'notification_preferences';
  static const userSettingsTable = 'user_settings';
  static const remindersTable = 'reminders';
  static const energyUsageTable = 'energy_usage';
  static const appliancesTable = 'appliances';
  static const energyGoalsTable = 'energy_goals';
  static const tipsTable = 'tips';
  static const notificationsTable = 'notifications';

  static const baseTableStatements = <String>[
    '''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE COLLATE NOCASE,
      password_hash TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE reminders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      appliance TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      reminder_time TEXT NOT NULL,
      is_enabled INTEGER NOT NULL DEFAULT 1 CHECK (is_enabled IN (0, 1)),
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''',
    '''
    CREATE TABLE energy_usage (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      appliance TEXT NOT NULL,
      usage_date TEXT NOT NULL,
      units_kwh REAL NOT NULL CHECK (units_kwh >= 0),
      hours_used REAL NOT NULL CHECK (hours_used >= 0),
      power_watts REAL NOT NULL CHECK (power_watts >= 0),
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''',
    '''
    CREATE TABLE appliances (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      power_watts REAL NOT NULL CHECK (power_watts >= 0),
      average_hours REAL NOT NULL CHECK (average_hours >= 0),
      is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''',
    '''
    CREATE TABLE energy_goals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      monthly_target_kwh REAL NOT NULL CHECK (monthly_target_kwh >= 0),
      monthly_saving_target REAL NOT NULL CHECK (monthly_saving_target >= 0),
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''',
    '''
    CREATE TABLE tips (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      category TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE notifications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      message TEXT NOT NULL,
      notification_time TEXT NOT NULL,
      is_read INTEGER NOT NULL DEFAULT 0 CHECK (is_read IN (0, 1)),
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''',
    'CREATE INDEX index_reminders_user_time ON reminders (user_id, reminder_time)',
    'CREATE INDEX index_energy_usage_user_date ON energy_usage (user_id, usage_date)',
    'CREATE INDEX index_appliances_user ON appliances (user_id)',
    'CREATE INDEX index_energy_goals_user ON energy_goals (user_id)',
    'CREATE INDEX index_notifications_user_time ON notifications (user_id, notification_time)',
  ];

  static const userSessionsTableStatement = '''
    CREATE TABLE user_sessions (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      user_id INTEGER NOT NULL UNIQUE,
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''';

  static const notificationPreferencesTableStatement = '''
    CREATE TABLE notification_preferences (
      user_id INTEGER PRIMARY KEY,
      is_enabled INTEGER NOT NULL DEFAULT 0 CHECK (is_enabled IN (0, 1)),
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''';

  static const userSettingsTableStatement = '''
    CREATE TABLE user_settings (
      user_id INTEGER PRIMARY KEY,
      dark_mode INTEGER NOT NULL DEFAULT 0 CHECK (dark_mode IN (0, 1)),
      electricity_tariff REAL CHECK (electricity_tariff IS NULL OR electricity_tariff >= 0),
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''';

  static const tableStatements = <String>[
    ...baseTableStatements,
    userSessionsTableStatement,
  ];
}