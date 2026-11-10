import 'package:energy_saving/models/energy_usage.dart';
import 'package:energy_saving/theme/app_palette.dart';
import 'package:energy_saving/widgets/appliance_visuals.dart';
import 'package:energy_saving/widgets/eco_card.dart';
import 'package:flutter/material.dart';

/// Colourful record card with an appliance-specific accent and share bar.
class EnergyUsageCard extends StatelessWidget {
  const EnergyUsageCard({
    super.key,
    required this.usage,
    required this.onEdit,
    required this.onDelete,
    this.shareOfTotal,
  });

  final EnergyUsage usage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final double? shareOfTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final date = MaterialLocalizations.of(
      context,
    ).formatMediumDate(usage.usageDate);
    final accent = ApplianceVisuals.accentFor(usage.appliance);
    final share = shareOfTotal;

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
                icon: ApplianceVisuals.iconFor(usage.appliance),
                accent: accent,
                size: 44,
                iconSize: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usage.appliance,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$date · ${_formatNumber(usage.hoursUsed)} h at ${_formatNumber(usage.powerWatts)} W',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  gradient: AppPalette.gradientFor(accent),
                  borderRadius: BorderRadius.circular(AppPalette.chipRadius),
                  boxShadow: AppPalette.shadowFor(accent, opacity: 0.24),
                ),
                child: Text(
                  '${usage.unitsKwh.toStringAsFixed(2)} kWh',
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (share != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GradientProgressBar(
                    value: share,
                    accent: accent,
                    height: 7,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(share * 100).round()}% of period',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
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