import 'package:energy_saving/models/energy_tip.dart';
import 'package:energy_saving/theme/app_palette.dart';
import 'package:energy_saving/widgets/eco_card.dart';
import 'package:flutter/material.dart';

/// Colourful tip card with a category-tinted accent.
class EnergyTipCard extends StatelessWidget {
  const EnergyTipCard({super.key, required this.tip});

  final EnergyTip tip;

  static const _categoryAccents = <String, Color>{
    'lighting': AppPalette.amber,
    'cooling': AppPalette.violet,
    'kitchen': AppPalette.coral,
    'electronics': AppPalette.skyDeep,
    'behaviour': AppPalette.emeraldDeep,
    'appliances': AppPalette.tealDeep,
    'habits': AppPalette.leaf,
  };

  static Color accentFor(String category) {
    return _categoryAccents[category.toLowerCase()] ?? AppPalette.emeraldDeep;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = accentFor(tip.category);

    return EcoCard(
      padding: const EdgeInsets.all(18),
      borderColor: accent.withValues(alpha: 0.22),
      shadow: AppPalette.shadowFor(accent, opacity: 0.10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(
                icon: Icons.lightbulb_rounded,
                accent: accent,
                size: 42,
                iconSize: 21,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  tip.title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tip.description,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          SoftPill(
            label: tip.category,
            icon: Icons.category_rounded,
            accent: accent,
          ),
        ],
      ),
    );
  }
}