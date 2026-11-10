import 'package:energy_saving/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Maps free-form appliance names and categories to a friendly icon and an
/// accent colour so every appliance looks distinct but stays on palette.
abstract final class ApplianceVisuals {
  static const _rules = <_VisualRule>[
    _VisualRule(
      ['light', 'lamp', 'bulb', 'tubelight', 'led'],
      Icons.lightbulb_outline_rounded,
      AppPalette.amber,
    ),
    _VisualRule(
      ['fan', 'cooler'],
      Icons.air_rounded,
      AppPalette.sky,
    ),
    _VisualRule(
      ['air condition', 'air-condition', 'aircon', 'cooling', 'split ac'],
      Icons.ac_unit_rounded,
      AppPalette.violet,
    ),
    _VisualRule(
      ['fridge', 'refrigerator', 'freezer', 'kitchen', 'mixer', 'grinder',
        'microwave', 'oven', 'toaster', 'induction', 'dishwasher', 'chopper'],
      Icons.kitchen_rounded,
      AppPalette.coral,
    ),
    _VisualRule(
      ['tv', 'television', 'laptop', 'computer', 'monitor', 'desktop',
        'electronics', 'router', 'wifi', 'speaker', 'console'],
      Icons.devices_rounded,
      AppPalette.skyDeep,
    ),
    _VisualRule(
      ['heater', 'geyser', 'iron', 'dryer', 'washer', 'washing machine',
        'laundry'],
      Icons.local_fire_department_rounded,
      AppPalette.coral,
    ),
    _VisualRule(
      ['water', 'pump', 'heater pump'],
      Icons.water_drop_rounded,
      AppPalette.teal,
    ),
    _VisualRule(
      ['phone', 'mobile', 'charger', 'tablet', 'laptop'],
      Icons.smartphone_rounded,
      AppPalette.violet,
    ),
    _VisualRule(
      ['solar', 'inverter', 'battery'],
      Icons.solar_power_rounded,
      AppPalette.leaf,
    ),
  ];

  /// Icon for an appliance name, falling back to the category mapping.
  static IconData iconFor(String name, {String? category}) {
    final normalized = name.toLowerCase();
    for (final rule in _rules) {
      if (rule.keywords.any(normalized.contains)) return rule.icon;
    }
    return iconForCategory(category ?? '');
  }

  /// Accent colour that matches [iconFor].
  static Color accentFor(String name, {String? category}) {
    final normalized = name.toLowerCase();
    for (final rule in _rules) {
      if (rule.keywords.any(normalized.contains)) return rule.accent;
    }
    return accentForCategory(category ?? '');
  }

  static IconData iconForCategory(String category) {
    return switch (category) {
      'Lighting' => Icons.lightbulb_outline_rounded,
      'Cooling' => Icons.ac_unit_rounded,
      'Kitchen' => Icons.kitchen_rounded,
      'Electronics' => Icons.devices_rounded,
      _ => Icons.electrical_services_rounded,
    };
  }

  static Color accentForCategory(String category) {
    return switch (category) {
      'Lighting' => AppPalette.amber,
      'Cooling' => AppPalette.violet,
      'Kitchen' => AppPalette.coral,
      'Electronics' => AppPalette.skyDeep,
      _ => AppPalette.emerald,
    };
  }

  /// Reminders reuse the appliance accent when their title has no match.
  static Color accentForReminder(String title, String appliance) {
    final accent = accentFor(appliance, category: title);
    return accent;
  }
}

class _VisualRule {
  const _VisualRule(this.keywords, this.icon, this.accent);

  final List<String> keywords;
  final IconData icon;
  final Color accent;
}