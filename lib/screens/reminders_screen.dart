import 'dart:async';

import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/reminder.dart';
import 'package:energy_saving/repositories/notification_preferences_repository.dart';
import 'package:energy_saving/repositories/reminder_repository.dart';
import 'package:energy_saving/screens/reminder_form_screen.dart';
import 'package:energy_saving/services/reminder_notification_service.dart';
import 'package:energy_saving/theme/app_palette.dart';
import 'package:energy_saving/widgets/app_feedback.dart';
import 'package:energy_saving/widgets/eco_card.dart';
import 'package:energy_saving/widgets/gradient_header.dart';
import 'package:energy_saving/widgets/reminder_card.dart';
import 'package:flutter/material.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({
    super.key,
    required this.userId,
    required this.repository,
    this.notificationService,
    this.notificationPreferencesRepository,
  });

  final int userId;
  final ReminderRepository repository;
  final ReminderNotificationService? notificationService;
  final NotificationPreferencesRepository? notificationPreferencesRepository;

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late final ReminderNotificationService _notificationService =
      widget.notificationService ?? LocalReminderNotificationService();
  late final NotificationPreferencesRepository _notificationPreferences =
      widget.notificationPreferencesRepository ??
      NotificationPreferencesRepository(
        databaseHelper: DatabaseHelper.instance,
      );
  late Future<List<Reminder>> _remindersFuture;
  final Set<int> _updatingReminderIds = {};
  bool _notificationsEnabled = false;
  bool _notificationPreferenceLoaded = false;
  bool _isChangingNotificationSetting = false;

  @override
  void initState() {
    super.initState();
    _remindersFuture = _loadReminders();
    unawaited(_loadNotificationPreference());
  }

  Future<void> _loadNotificationPreference() async {
    try {
      if (_notificationService.isSupported) {
        await _notificationService.initialize();
      }
      final isEnabled = await _notificationPreferences.isEnabledForUser(
        widget.userId,
      );
      if (isEnabled && _notificationService.isSupported) {
        await _scheduleEnabledReminders();
      }
      if (mounted) {
        setState(() {
          _notificationsEnabled = isEnabled;
          _notificationPreferenceLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _notificationPreferenceLoaded = true);
    }
  }

  Future<void> _scheduleEnabledReminders() async {
    final reminders = await widget.repository.getForUser(widget.userId);
    for (final reminder in reminders) {
      if (reminder.id == null) continue;
      if (reminder.isEnabled) {
        await _notificationService.schedule(reminder);
      } else {
        await _notificationService.cancel(reminder.id!);
      }
    }
  }

  Future<void> _syncReminderNotification(Reminder reminder) async {
    final id = reminder.id;
    if (id == null || !_notificationService.isSupported) return;
    if (_notificationsEnabled && reminder.isEnabled) {
      await _notificationService.schedule(reminder);
    } else {
      await _notificationService.cancel(id);
    }
  }

  Future<void> _setNotificationsEnabled(bool isEnabled) async {
    if (_isChangingNotificationSetting) return;
    setState(() => _isChangingNotificationSetting = true);

    try {
      if (isEnabled) {
        if (!_notificationService.isSupported) {
          throw UnsupportedError('Local notifications are not supported here.');
        }
        final permissionGranted = await _notificationService.requestPermission();
        if (!permissionGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification permission was not granted.')),
            );
          }
          return;
        }
        await _notificationPreferences.setEnabledForUser(widget.userId, true);
        if (mounted) setState(() => _notificationsEnabled = true);
        await _scheduleEnabledReminders();
      } else {
        await _notificationPreferences.setEnabledForUser(widget.userId, false);
        if (mounted) setState(() => _notificationsEnabled = false);
        await _notificationService.cancelAll();
      }
    } catch (_) {
      if (isEnabled) {
        await _notificationPreferences.setEnabledForUser(widget.userId, false);
        await _notificationService.cancelAll();
        if (mounted) setState(() => _notificationsEnabled = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification settings could not be changed.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isChangingNotificationSetting = false);
    }
  }

  Future<List<Reminder>> _loadReminders() {
    return widget.repository.getForUser(widget.userId);
  }

  Future<void> _refresh() async {
    final remindersFuture = _loadReminders();
    setState(() => _remindersFuture = remindersFuture);
    try {
      await remindersFuture;
    } catch (_) {}
  }

  Future<void> _openForm([Reminder? reminder]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ReminderFormScreen(
          userId: widget.userId,
          repository: widget.repository,
          reminder: reminder,
        ),
      ),
    );
    if (saved == true && mounted) {
      await _refresh();
      var notificationSyncFailed = false;
      if (_notificationsEnabled) {
        try {
          await _scheduleEnabledReminders();
        } catch (_) {
          notificationSyncFailed = true;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              notificationSyncFailed
                  ? 'Reminder saved, but its notification could not be scheduled.'
                  : reminder == null
                  ? 'Reminder added.'
                  : 'Reminder updated.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _setEnabled(Reminder reminder, bool isEnabled) async {
    final id = reminder.id;
    if (id == null || _updatingReminderIds.contains(id)) return;
    setState(() => _updatingReminderIds.add(id));

    try {
      await widget.repository.setEnabled(
        reminderId: id,
        userId: widget.userId,
        isEnabled: isEnabled,
      );
      var notificationSyncFailed = false;
      try {
        await _syncReminderNotification(
          Reminder(
            id: reminder.id,
            userId: reminder.userId,
            title: reminder.title,
            appliance: reminder.appliance,
            description: reminder.description,
            reminderTime: reminder.reminderTime,
            isEnabled: isEnabled,
            createdAt: reminder.createdAt,
          ),
        );
      } catch (_) {
        notificationSyncFailed = true;
      }
      await _refresh();
      if (notificationSyncFailed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder status saved, but its notification could not be updated.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder could not be updated.')),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingReminderIds.remove(id));
    }
  }

  Future<void> _delete(Reminder reminder) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: Text('“${reminder.title}” will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || reminder.id == null) return;

    try {
      await widget.repository.delete(
        reminderId: reminder.id!,
        userId: widget.userId,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder could not be deleted.')),
        );
      }
      return;
    }

    var notificationCancelFailed = false;
    if (_notificationsEnabled) {
      try {
        await _notificationService.cancel(reminder.id!);
      } catch (_) {
        notificationCancelFailed = true;
      }
    }
    await _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            notificationCancelFailed
                ? 'Reminder deleted, but its notification could not be cancelled.'
                : 'Reminder deleted.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            EcoHeader(
              eyebrow: 'Daily habits',
              title: 'Reminders',
              subtitle: 'Nudges that switch appliances off on time',
              illustration: const EcoIllustration(
                mainIcon: Icons.notifications_active_rounded,
                accent: AppPalette.amber,
              ),
              chips: [
                GlassChip(
                  label: !_notificationService.isSupported
                      ? 'Android and iOS only'
                      : _notificationsEnabled
                      ? 'Daily alerts on'
                      : 'Daily alerts off',
                  icon: Icons.notifications_active_rounded,
                ),
              ],
              bottom: _NotificationToggle(
                isSupported: _notificationService.isSupported,
                isEnabled:
                    _notificationService.isSupported && _notificationsEnabled,
                isLoading:
                    !_notificationPreferenceLoaded ||
                    _isChangingNotificationSetting,
                onChanged: (value) => unawaited(_setNotificationsEnabled(value)),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Reminder>>(
                future: _remindersFuture,
                builder: (context, snapshot) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: _buildList(context, snapshot),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => unawaited(_openForm()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add reminder'),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    AsyncSnapshot<List<Reminder>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: AppLoadingIndicator(message: 'Loading reminders')),
        ],
      );
    }

    if (snapshot.hasError) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 32),
          AppFeedbackPanel(
            icon: Icons.storage_rounded,
            title: 'Reminders could not be loaded',
            message: 'Your reminder list is temporarily unavailable.',
            isError: true,
            actionLabel: 'Retry',
            onAction: () => unawaited(_refresh()),
          ),
        ],
      );
    }

    final reminders = snapshot.data ?? const <Reminder>[];
    if (reminders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 32),
          AppFeedbackPanel(
            icon: Icons.notifications_none_rounded,
            title: 'No reminders yet',
            message: 'Your appliance reminders will appear here.',
            actionLabel: 'Create reminder',
            onAction: () => unawaited(_openForm()),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
      itemCount: reminders.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SectionHeader(
              title: 'Your reminders',
              subtitle:
                  '${reminders.length} ${reminders.length == 1 ? 'reminder' : 'reminders'} · '
                  '${reminders.where((reminder) => reminder.isEnabled).length} active',
              icon: Icons.alarm_rounded,
              accent: AppPalette.violet,
            ),
          );
        }
        final reminder = reminders[index - 1];
        final isUpdating = _updatingReminderIds.contains(reminder.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Opacity(
            opacity: isUpdating ? 0.6 : 1,
            child: ReminderCard(
              reminder: reminder,
              onEnabledChanged: (value) => _setEnabled(reminder, value),
              onEdit: () => unawaited(_openForm(reminder)),
              onDelete: () => unawaited(_delete(reminder)),
            ),
          ),
        );
      },
    );
  }
}

/// Notification switch rendered as a frosted card inside the gradient header.
class _NotificationToggle extends StatelessWidget {
  const _NotificationToggle({
    required this.isSupported,
    required this.isEnabled,
    required this.isLoading,
    required this.onChanged,
  });

  final bool isSupported;
  final bool isEnabled;
  final bool isLoading;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = isSupported ? AppPalette.amber : AppPalette.teal;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppPalette.cardRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
      ),
      child: Row(
        children: [
          IconTile(icon: Icons.alarm_rounded, accent: accent, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Local notifications',
                  style: textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  !isSupported
                      ? 'Available on Android and iOS.'
                      : isEnabled
                      ? 'Daily alerts are enabled.'
                      : 'Daily alerts are turned off.',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isSupported && isEnabled,
            onChanged: isLoading || !isSupported ? null : onChanged,
          ),
        ],
      ),
    );
  }
}