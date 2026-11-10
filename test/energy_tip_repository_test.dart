import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/repositories/energy_tip_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper databaseHelper;
  late EnergyTipRepository tipRepository;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() {
    databaseHelper = DatabaseHelper(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    tipRepository = EnergyTipRepository(databaseHelper: databaseHelper);
  });

  tearDown(() async {
    await databaseHelper.close();
  });

  test('seeds offline tips once and filters by category and search text', () async {
    final allTips = await tipRepository.getTips();
    expect(allTips, hasLength(10));
    expect(allTips.map((tip) => tip.category).toSet(), {
      'Lighting',
      'Cooling',
      'Kitchen',
      'Electronics',
      'General',
    });

    final electronicsTips = await tipRepository.getTips(
      category: 'Electronics',
    );
    expect(electronicsTips, hasLength(2));

    final ledTip = await tipRepository.getTips(searchQuery: 'lEd');
    expect(ledTip.map((tip) => tip.title), ['Choose LED bulbs']);

    final filteredTips = await tipRepository.getTips(
      category: 'Lighting',
      searchQuery: 'curtains',
    );
    expect(filteredTips.map((tip) => tip.title), ['Use natural light']);
    expect(await tipRepository.getTips(searchQuery: 'not a real tip'), isEmpty);

    final tipsFromNewRepository = await EnergyTipRepository(
      databaseHelper: databaseHelper,
    ).getTips();
    expect(tipsFromNewRepository, hasLength(10));
  });
}