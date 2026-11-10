import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/reminder.dart';
import 'package:energy_saving/models/user.dart';
import 'package:energy_saving/repositories/reminder_repository.dart';
import 'package:energy_saving/repositories/user_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DatabaseHelper databaseHelper;
  late ReminderRepository reminderRepository;
  late int userId;
  late int otherUserId;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    databaseHelper = DatabaseHelper(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    reminderRepository = ReminderRepository(databaseHelper: databaseHelper);
    final userRepository = UserRepository(databaseHelper: databaseHelper);
    userId = await userRepository.insert(
      User(name: 'Reminder Owner', email: 'owner@example.com'),
    );
    otherUserId = await userRepository.insert(
      User(name: 'Other Owner', email: 'other-owner@example.com'),
    );
  });

  tearDown(() async {
    await databaseHelper.close();
  });

  test('supports reminder CRUD, enable state, and user isolation', () async {
    final reminderId = await reminderRepository.insert(
      Reminder(
        userId: userId,
        title: 'Switch off the fan',
        appliance: 'Fan',
        description: 'Before leaving the room',
        reminderTime: DateTime(2026, 9, 29, 20),
      ),
    );
    final otherReminderId = await reminderRepository.insert(
      Reminder(
        userId: otherUserId,
        title: 'Turn off the TV',
        appliance: 'Television',
        reminderTime: DateTime(2026, 9, 29, 21),
      ),
    );

    final reminders = await reminderRepository.getForUser(userId);
    expect(reminders.map((reminder) => reminder.title), ['Switch off the fan']);

    final original = reminders.single;
    final edited = Reminder(
      id: reminderId,
      userId: userId,
      title: 'Switch off the lights',
      appliance: 'Lights',
      description: original.description,
      reminderTime: DateTime(2026, 9, 29, 22),
      isEnabled: original.isEnabled,
      createdAt: original.createdAt,
    );
    expect(await reminderRepository.update(edited), 1);
    expect((await reminderRepository.getForUser(userId)).single.title, 'Switch off the lights');

    expect(
      await reminderRepository.setEnabled(
        reminderId: reminderId,
        userId: userId,
        isEnabled: false,
      ),
      1,
    );
    expect((await reminderRepository.getForUser(userId)).single.isEnabled, isFalse);

    expect(
      await reminderRepository.setEnabled(
        reminderId: otherReminderId,
        userId: userId,
        isEnabled: false,
      ),
      0,
    );
    expect(
      await reminderRepository.delete(
        reminderId: otherReminderId,
        userId: userId,
      ),
      0,
    );
    expect(
      await reminderRepository.delete(reminderId: reminderId, userId: userId),
      1,
    );
    expect(await reminderRepository.getForUser(userId), isEmpty);
    expect((await reminderRepository.getForUser(otherUserId)).single.title, 'Turn off the TV');
  });
}