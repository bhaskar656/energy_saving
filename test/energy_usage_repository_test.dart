import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/energy_usage.dart';
import 'package:energy_saving/models/user.dart';
import 'package:energy_saving/repositories/energy_usage_repository.dart';
import 'package:energy_saving/repositories/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper databaseHelper;
  late EnergyUsageRepository usageRepository;
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
    usageRepository = EnergyUsageRepository(databaseHelper: databaseHelper);
    final userRepository = UserRepository(databaseHelper: databaseHelper);
    userId = await userRepository.insert(
      User(name: 'Usage Owner', email: 'usage-owner@example.com'),
    );
    otherUserId = await userRepository.insert(
      User(name: 'Other Owner', email: 'usage-other@example.com'),
    );
  });

  tearDown(() async {
    await databaseHelper.close();
  });

  test('supports CRUD, half-open date ranges, and user isolation', () async {
    final start = DateTime(2026, 9, 1);
    final end = DateTime(2026, 10, 1);
    final inRangeId = await usageRepository.insert(
      EnergyUsage(
        userId: userId,
        appliance: 'Fan',
        usageDate: DateTime(2026, 9, 1),
        unitsKwh: 0.5,
        hoursUsed: 5,
        powerWatts: 100,
      ),
    );
    await usageRepository.insert(
      EnergyUsage(
        userId: userId,
        appliance: 'Light',
        usageDate: DateTime(2026, 9, 30, 23, 59),
        unitsKwh: 0.2,
        hoursUsed: 4,
        powerWatts: 50,
      ),
    );
    await usageRepository.insert(
      EnergyUsage(
        userId: userId,
        appliance: 'Earlier record',
        usageDate: DateTime(2026, 8, 31, 23, 59),
        unitsKwh: 8,
        hoursUsed: 1,
        powerWatts: 100,
      ),
    );
    await usageRepository.insert(
      EnergyUsage(
        userId: userId,
        appliance: 'Next month',
        usageDate: end,
        unitsKwh: 9,
        hoursUsed: 1,
        powerWatts: 100,
      ),
    );
    await usageRepository.insert(
      EnergyUsage(
        userId: otherUserId,
        appliance: 'Other user fan',
        usageDate: start,
        unitsKwh: 20,
        hoursUsed: 1,
        powerWatts: 100,
      ),
    );

    final monthlyRecords = await usageRepository.getForUserBetween(
      userId: userId,
      start: start,
      end: end,
    );
    expect(monthlyRecords.map((record) => record.appliance), ['Light', 'Fan']);

    final edited = EnergyUsage(
      id: inRangeId,
      userId: userId,
      appliance: 'Desk fan',
      usageDate: DateTime(2026, 9, 2),
      unitsKwh: 0.6,
      hoursUsed: 6,
      powerWatts: 100,
      createdAt: monthlyRecords.last.createdAt,
    );
    expect(await usageRepository.update(edited), 1);
    expect(
      (await usageRepository.getForUser(userId))
          .firstWhere((record) => record.id == inRangeId)
          .unitsKwh,
      0.6,
    );

    expect(
      await usageRepository.delete(usageId: inRangeId, userId: otherUserId),
      0,
    );
    expect(await usageRepository.delete(usageId: inRangeId, userId: userId), 1);
    expect(
      (await usageRepository.getForUser(otherUserId)).single.appliance,
      'Other user fan',
    );
  });
}