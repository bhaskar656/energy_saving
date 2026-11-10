import 'package:energy_saving/database/database_constants.dart';
import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/energy_goal.dart';
import 'package:energy_saving/models/user.dart';
import 'package:energy_saving/repositories/energy_goal_repository.dart';
import 'package:energy_saving/repositories/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper databaseHelper;
  late EnergyGoalRepository goalRepository;
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
    goalRepository = EnergyGoalRepository(databaseHelper: databaseHelper);
    final userRepository = UserRepository(databaseHelper: databaseHelper);
    userId = await userRepository.insert(
      User(name: 'Goal Owner', email: 'goal-owner@example.com'),
    );
    otherUserId = await userRepository.insert(
      User(name: 'Other Goal Owner', email: 'other-goal-owner@example.com'),
    );
  });

  tearDown(() async {
    await databaseHelper.close();
  });

  test('creates and updates one current goal per user', () async {
    final createdAt = DateTime(2026, 9, 1);
    final firstSave = await goalRepository.saveForUser(
      EnergyGoal(
        userId: userId,
        monthlyTargetKwh: 100,
        monthlySavingTarget: 10,
        createdAt: createdAt,
      ),
    );
    final secondSave = await goalRepository.saveForUser(
      EnergyGoal(
        userId: userId,
        monthlyTargetKwh: 90,
        monthlySavingTarget: 12,
        createdAt: DateTime(2026, 9, 10),
      ),
    );

    expect(secondSave.id, firstSave.id);
    expect(secondSave.monthlyTargetKwh, 90);
    expect(secondSave.monthlySavingTarget, 12);
    expect(secondSave.createdAt, createdAt);
    expect((await goalRepository.getCurrentForUser(userId))?.id, firstSave.id);

    await goalRepository.saveForUser(
      EnergyGoal(
        userId: otherUserId,
        monthlyTargetKwh: 60,
        monthlySavingTarget: 5,
      ),
    );
    expect(
      (await goalRepository.getCurrentForUser(otherUserId))?.monthlyTargetKwh,
      60,
    );

    final rows = await (await databaseHelper.database).query(
      DatabaseConstants.energyGoalsTable,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    expect(rows, hasLength(1));
  });
}