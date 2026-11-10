import 'package:energy_saving/models/reminder.dart';
import 'package:energy_saving/theme/app_palette.dart';
import 'package:energy_saving/widgets/appliance_visuals.dart';
import 'package:energy_saving/widgets/eco_card.dart';
import 'package:flutter/material.dart';

/// Colourful reminder card with a clear active / paused status indicator.
class ReminderCard extends StatelessWidget {
  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onEnabledChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final Reminder reminder;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final time = TimeOfDay.fromDateTime(reminder.reminderTime);
    final formattedTime = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(time);
    final isEnabled = reminder.isEnabled;
    final accent = isEnabled
        ? ApplianceVisuals.accentForReminder(reminder.title, reminder.appliance)
        : AppPalette.tealDeep;

    return EcoCard(
      padding: EdgeInsets.zero,
      borderColor: accent.withValues(alpha: isEnabled ? 0.28 : 0.14),
      shadow: AppPalette.shadowFor(accent, opacity: isEnabled ? 0.12 : 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                IconTile(
                  icon: ApplianceVisuals.iconFor(reminder.appliance),
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
                        reminder.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isEnabled
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          SoftPill(
                            label: formattedTime,
                            icon: Icons.schedule_rounded,
                            accent: accent,
                          ),
                          SoftPill(
                            label: reminder.appliance,
                            icon: Icons.electrical_services_rounded,
                            accent: accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: reminder.isEnabled,
                  onChanged: onEnabledChanged,
                ),
              ],
            ),
          ),
          if (reminder.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                reminder.description,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                SoftPill(
                  label: isEnabled ? 'Active' : 'Paused',
                  icon: isEnabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
                  accent: isEnabled ? AppPalette.emeraldDeep : AppPalette.amber,
                  solid: isEnabled,
                ),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: onEdit,
                  tooltip: 'Edit reminder',
                  icon: const Icon(Icons.edit_rounded, size: 20),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: onDelete,
                  tooltip: 'Delete reminder',
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  style: IconButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    backgroundColor: colorScheme.errorContainer.withValues(
                      alpha: 0.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}