import 'package:energy_saving/database/database_constants.dart';
import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/energy_tip.dart';

class EnergyTipRepository {
  const EnergyTipRepository({required this.databaseHelper});

  final DatabaseHelper databaseHelper;

  static const categories = [
    'Lighting',
    'Cooling',
    'Kitchen',
    'Electronics',
    'General',
  ];

  static const _starterTips = <EnergyTip>[
    EnergyTip(
      title: 'Switch off lights when leaving a room',
      description: 'Turn lights off in empty rooms, even when you leave briefly.',
      category: 'Lighting',
    ),
    EnergyTip(
      title: 'Choose LED bulbs',
      description: 'Replace frequently used bulbs with efficient LED lighting.',
      category: 'Lighting',
    ),
    EnergyTip(
      title: 'Use natural light',
      description: 'Open curtains during the day before switching on room lights.',
      category: 'Lighting',
    ),
    EnergyTip(
      title: 'Set cooling to a comfortable level',
      description: 'Avoid setting air conditioning colder than you need.',
      category: 'Cooling',
    ),
    EnergyTip(
      title: 'Turn off fans and AC when not needed',
      description: 'Switch cooling appliances off when leaving the room.',
      category: 'Cooling',
    ),
    EnergyTip(
      title: 'Keep refrigerator doors closed',
      description: 'Decide what you need before opening the refrigerator door.',
      category: 'Kitchen',
    ),
    EnergyTip(
      title: 'Run full loads when practical',
      description: 'Use washing machines and dishwashers with suitable full loads.',
      category: 'Kitchen',
    ),
    EnergyTip(
      title: 'Avoid unnecessary standby power',
      description: 'Switch off electronics when they are not being used.',
      category: 'Electronics',
    ),
    EnergyTip(
      title: 'Unplug chargers after use',
      description: 'Disconnect chargers when devices are fully charged or unplugged.',
      category: 'Electronics',
    ),
    EnergyTip(
      title: 'Check appliance power ratings',
      description: 'Compare wattage and expected usage when choosing appliances.',
      category: 'General',
    ),
  ];

  Future<List<EnergyTip>> getTips({String? category, String? searchQuery}) async {
    await _ensureStarterTips();
    final whereClauses = <String>[];
    final whereArgs = <Object>[];

    if (category != null && category.trim().isNotEmpty) {
      whereClauses.add('category = ?');
      whereArgs.add(category.trim());
    }
    final query = searchQuery?.trim();
    if (query != null && query.isNotEmpty) {
      whereClauses.add(
        '(instr(lower(title), lower(?)) > 0 OR '
        'instr(lower(description), lower(?)) > 0)',
      );
      whereArgs.addAll([query, query]);
    }

    final rows = await (await databaseHelper.database).query(
      DatabaseConstants.tipsTable,
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'category COLLATE NOCASE ASC, title COLLATE NOCASE ASC',
    );
    return rows.map(EnergyTip.fromMap).toList(growable: false);
  }

  Future<void> _ensureStarterTips() async {
    final database = await databaseHelper.database;
    await database.transaction((transaction) async {
      final rows = await transaction.rawQuery(
        'SELECT COUNT(*) AS count FROM ${DatabaseConstants.tipsTable}',
      );
      if ((rows.single['count'] as int) > 0) return;

      final batch = transaction.batch();
      for (final tip in _starterTips) {
        final values = tip.toMap()..remove('id');
        batch.insert(DatabaseConstants.tipsTable, values);
      }
      await batch.commit(noResult: true);
    });
  }
}