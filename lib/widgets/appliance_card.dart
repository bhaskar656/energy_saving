import 'package:energy_saving/models/appliance.dart';
import 'package:energy_saving/theme/app_palette.dart';
import 'package:energy_saving/widgets/appliance_visuals.dart';
import 'package:energy_saving/widgets/dashboard_components.dart';
import 'package:energy_saving/widgets/eco_card.dart';
import 'package:flutter/material.dart';

/// Colourful appliance card with a category accent and a daily kWh estimate.
class ApplianceCard extends StatelessWidget {
  const ApplianceCard({
    super.key,
    required this.appliance,
    required this.onActiveChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final Appliance appliance;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = ApplianceVisuals.accentForCategory(appliance.category);
    final dailyKwh = appliance.powerWatts * appliance.averageHours / 1000;

    return EcoCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      borderColor: accent.withValues(alpha: 0.22),
      shadow: AppPalette.shadowFor(accent, opacity: 0.10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(
                icon: ApplianceVisuals.iconFor(appliance.name, category: appliance.category),
                accent: accent,
                size: 46,
                iconSize: 23,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appliance.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        SoftPill(
                          label: appliance.category,
                          icon: Icons.category_rounded,
                          accent: accent,
                        ),
                        SoftPill(
                          label: appliance.isActive ? 'In use' : 'Idle',
                          icon: appliance.isActive
                              ? Icons.power_settings_new_rounded
                              : Icons.pause_circle_rounded,
                          accent: appliance.isActive
                              ? AppPalette.emeraldDeep
                              : AppPalette.amber,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'Active appliance',
                child: Switch(
                  value: appliance.isActive,
                  onChanged: onActiveChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Rated power',
                  value: '${_formatNumber(appliance.powerWatts)} W',
                  accent: accent,
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Daily use',
                  value: '${_formatNumber(appliance.averageHours)} h',
                  accent: accent,
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Est. daily',
                  value: '${dailyKwh.toStringAsFixed(2)} kWh',
                  accent: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: colorScheme.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleSmall?.copyWith(
            color: accentForeground(context, accent),
          ),
        ),
      ],
    );
  }
}