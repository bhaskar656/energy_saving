import 'package:energy_saving/theme/app_palette.dart';
import 'package:energy_saving/widgets/eco_card.dart';
import 'package:flutter/material.dart';

/// Colour that stays readable when used on top of an accent wash.
Color accentForeground(BuildContext context, Color accent) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? accent : Color.lerp(accent, Colors.black, 0.32)!;
}

/// Colourful statistic card used across the dashboard.
class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    this.accent,
    this.badge,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color? accent;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final resolvedAccent = accent ?? theme.colorScheme.primary;
    final foreground = accentForeground(context, resolvedAccent);

    return EcoCard(
      gradient: AppPalette.washFor(resolvedAccent),
      borderColor: resolvedAccent.withValues(alpha: 0.22),
      shadow: AppPalette.shadowFor(resolvedAccent, opacity: 0.12),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(
                icon: icon,
                accent: resolvedAccent,
                size: 42,
                iconSize: 21,
              ),
              const Spacer(),
              if (badge != null)
                SoftPill(label: badge!, accent: resolvedAccent),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Period tile with the kWh total and a share-of-maximum bar.
class UsagePeriodRow extends StatelessWidget {
  const UsagePeriodRow({
    super.key,
    required this.label,
    required this.kwh,
    required this.recordCount,
    this.accent,
    this.maxKwh,
  });

  final String label;
  final double kwh;
  final int recordCount;
  final Color? accent;
  final double? maxKwh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final resolvedAccent = accent ?? theme.colorScheme.primary;
    final maximum = maxKwh;
    final share = maximum != null && maximum > 0 ? kwh / maximum : null;

    return EcoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppPalette.gradientFor(resolvedAccent),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: textTheme.titleSmall)),
              Text(
                '${kwh.toStringAsFixed(1)} kWh',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accentForeground(context, resolvedAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            recordCount == 0
                ? 'No usage recorded'
                : '$recordCount ${recordCount == 1 ? 'record' : 'records'}',
            style: textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (share != null) ...[
            const SizedBox(height: 12),
            GradientProgressBar(
              value: share,
              accent: resolvedAccent,
              height: 8,
            ),
          ],
        ],
      ),
    );
  }
}

/// Monthly target panel with a circular ring and a real progress message.
class MonthlyGoalPanel extends StatelessWidget {
  const MonthlyGoalPanel({
    super.key,
    required this.monthUsageKwh,
    required this.targetKwh,
    this.onEdit,
  });

  final double monthUsageKwh;
  final double? targetKwh;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final accent = AppPalette.leaf;
    final target = targetKwh;
    final hasTarget = target != null && target > 0;
    final progress = hasTarget
        ? (monthUsageKwh / target).clamp(0.0, 1.0)
        : 0.0;
    final underTarget = hasTarget && monthUsageKwh <= target;
    final progressMessage = !hasTarget
        ? 'No monthly target recorded.'
        : underTarget
        ? '${(target - monthUsageKwh).toStringAsFixed(1)} kWh below the target'
        : '${(monthUsageKwh - target).toStringAsFixed(1)} kWh above the target';

    return EcoCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ProgressRing(
            value: progress,
            caption: hasTarget
                ? '${(progress * 100).round()}%'
                : '—',
            accent: underTarget ? AppPalette.emeraldDeep : accent,
            captionStyle: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Monthly usage target',
                        style: textTheme.titleMedium,
                      ),
                    ),
                    if (hasTarget)
                      SoftPill(
                        label: underTarget ? 'On track' : 'Over target',
                        icon: underTarget
                            ? Icons.trending_down_rounded
                            : Icons.trending_up_rounded,
                        accent: underTarget
                            ? AppPalette.emeraldDeep
                            : AppPalette.amber,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (hasTarget) ...[
                  Text(
                    '${monthUsageKwh.toStringAsFixed(1)} of ${target.toStringAsFixed(1)} kWh',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GradientProgressBar(value: progress, accent: accent),
                  const SizedBox(height: 10),
                ],
                Text(
                  progressMessage,
                  style: textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (onEdit != null) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.flag_rounded, size: 18),
                      label: Text(hasTarget ? 'Edit goal' : 'Set monthly goal'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}