import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/appliance.dart';
import 'package:energy_saving/models/user.dart';
import 'package:energy_saving/repositories/appliance_repository.dart';
import 'package:energy_saving/repositories/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper databaseHelper;
  late ApplianceRepository applianceRepository;
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
    applianceRepository = ApplianceRepository(databaseHelper: databaseHelper);
    final userRepository = UserRepository(databaseHelper: databaseHelper);
    userId = await userRepository.insert(
      User(name: 'Appliance Owner', email: 'appliance-owner@example.com'),
    );
    otherUserId = await userRepository.insert(
      User(name: 'Other Owner', email: 'appliance-other@example.com'),
    );
  });

  tearDown(() async {
    await databaseHelper.close();
  });

  test('supports appliance CRUD, active state, and user isolation', () async {
    final applianceId = await applianceRepository.insert(
      Appliance(
        userId: userId,
        name: 'Desk fan',
        category: 'Cooling',
        powerWatts: 75,
        averageHours: 5,
      ),
    );
    final otherApplianceId = await applianceRepository.insert(
      Appliance(
        userId: otherUserId,
        name: 'Television',
        category: 'Electronics',
        powerWatts: 100,
        averageHours: 3,
      ),
    );

    final appliances = await applianceRepository.getForUser(userId);
    expect(appliances.map((appliance) => appliance.name), ['Desk fan']);

    final edited = Appliance(
      id: applianceId,
      userId: userId,
      name: 'Ceiling fan',
      category: 'Cooling',
      powerWatts: 80,
      averageHours: 6.5,
    );
    expect(await applianceRepository.update(edited), 1);
    final updated = (await applianceRepository.getForUser(userId)).single;
    expect(updated.name, 'Ceiling fan');
    expect(updated.powerWatts, 80);
    expect(updated.averageHours, 6.5);

    expect(
      await applianceRepository.setActive(
        applianceId: applianceId,
        userId: userId,
        isActive: false,
      ),
      1,
    );
    expect((await applianceRepository.getForUser(userId)).single.isActive, isFalse);

    expect(
      await applianceRepository.setActive(
        applianceId: otherApplianceId,
        userId: userId,
        isActive: false,
      ),
      0,
    );
    expect(
      await applianceRepository.delete(
        applianceId: otherApplianceId,
        userId: userId,
      ),
      0,
    );
    expect(
      await applianceRepository.delete(applianceId: applianceId, userId: userId),
      1,
    );
    expect(await applianceRepository.getForUser(userId), isEmpty);
    expect((await applianceRepository.getForUser(otherUserId)).single.name, 'Television');
  });
}