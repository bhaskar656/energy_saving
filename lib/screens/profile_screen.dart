import 'dart:async';

import 'package:energy_saving/models/energy_goal.dart';
import 'package:energy_saving/models/user.dart';
import 'package:energy_saving/models/user_settings.dart';
import 'package:energy_saving/repositories/energy_goal_repository.dart';
import 'package:energy_saving/repositories/energy_usage_repository.dart';
import 'package:energy_saving/repositories/notification_preferences_repository.dart';
import 'package:energy_saving/repositories/reminder_repository.dart';
import 'package:energy_saving/repositories/user_settings_repository.dart';
import 'package:energy_saving/screens/energy_goals_screen.dart';
import 'package:energy_saving/screens/reminders_screen.dart';
import 'package:energy_saving/services/reminder_notification_service.dart';
import 'package:energy_saving/theme/app_palette.dart';
import 'package:energy_saving/widgets/app_feedback.dart';
import 'package:energy_saving/widgets/eco_card.dart';
import 'package:energy_saving/widgets/gradient_header.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    required this.onLogout,
    required this.settingsRepository,
    required this.notificationPreferencesRepository,
    required this.reminderRepository,
    required this.goalRepository,
    required this.usageRepository,
    required this.notificationService,
    required this.onThemeModeChanged,
  });

  final User user;
  final VoidCallback onLogout;
  final UserSettingsRepository settingsRepository;
  final NotificationPreferencesRepository notificationPreferencesRepository;
  final ReminderRepository reminderRepository;
  final EnergyGoalRepository goalRepository;
  final EnergyUsageRepository usageRepository;
  final ReminderNotificationService notificationService;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _tariffController = TextEditingController();
  late Future<_ProfileData> _profileFuture;
  bool _isSavingTariff = false;
  bool _isChangingTheme = false;
  bool _tariffInitialized = false;
  String? _tariffError;
  String? _settingsError;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  @override
  void dispose() {
    _tariffController.dispose();
    super.dispose();
  }

  Future<_ProfileData> _loadProfile() async {
    final settings = await widget.settingsRepository.getForUser(
      widget.user.id!,
    );
    final notificationsEnabled = await widget.notificationPreferencesRepository
        .isEnabledForUser(widget.user.id!);
    final goal = await widget.goalRepository.getCurrentForUser(widget.user.id!);

    if (!_tariffInitialized) {
      _tariffController.text = settings.electricityTariff?.toString() ?? '';
      _tariffInitialized = true;
    }
    return _ProfileData(
      settings: settings,
      notificationsEnabled: notificationsEnabled,
      goal: goal,
    );
  }

  Future<void> _refresh() async {
    final profileFuture = _loadProfile();
    setState(() {
      _profileFuture = profileFuture;
      _settingsError = null;
    });
    try {
      await profileFuture;
    } catch (_) {}
  }

  Future<void> _setDarkMode(bool enabled) async {
    setState(() {
      _isChangingTheme = true;
      _settingsError = null;
    });
    try {
      await widget.settingsRepository.setDarkMode(widget.user.id!, enabled);
      widget.onThemeModeChanged(enabled ? ThemeMode.dark : ThemeMode.light);
      await _refresh();
    } catch (_) {
      if (mounted) {
        setState(() => _settingsError = 'Appearance setting could not be saved.');
      }
    } finally {
      if (mounted) setState(() => _isChangingTheme = false);
    }
  }

  Future<void> _saveTariff() async {
    final input = _tariffController.text.trim();
    final tariff = input.isEmpty ? null : double.tryParse(input);
    if (input.isNotEmpty &&
        (tariff == null || !tariff.isFinite || tariff < 0)) {
      setState(() => _tariffError = 'Enter a tariff of 0 or more.');
      return;
    }

    setState(() {
      _isSavingTariff = true;
      _tariffError = null;
    });
    try {
      await widget.settingsRepository.setElectricityTariff(
        widget.user.id!,
        tariff,
      );
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Electricity tariff saved.')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _tariffError = 'Electricity tariff could not be saved.');
      }
    } finally {
      if (mounted) setState(() => _isSavingTariff = false);
    }
  }

  Future<void> _openReminders() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => RemindersScreen(
          userId: widget.user.id!,
          repository: widget.reminderRepository,
          notificationService: widget.notificationService,
          notificationPreferencesRepository:
              widget.notificationPreferencesRepository,
        ),
      ),
    );
    if (mounted) await _refresh();
  }

  Future<void> _openGoals() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => EnergyGoalsScreen(
          userId: widget.user.id!,
          goalRepository: widget.goalRepository,
          usageRepository: widget.usageRepository,
        ),
      ),
    );
    if (mounted) await _refresh();
  }

  void _logout() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: FutureBuilder<_ProfileData>(
              future: _profileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: AppLoadingIndicator(message: 'Loading profile'),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: AppFeedbackPanel(
                      icon: Icons.storage_rounded,
                      title: 'Profile settings could not be loaded',
                      message: 'Your account settings are temporarily unavailable.',
                      isError: true,
                      actionLabel: 'Retry',
                      onAction: () => unawaited(_refresh()),
                    ),
                  );
                }

                final profile = snapshot.data!;
                return Column(
                  children: [
                    _ProfileHeader(
                      user: widget.user,
                      darkModeEnabled: profile.settings.darkModeEnabled,
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                        children: [
                          SectionHeader(
                            title: 'Account',
                            icon: Icons.badge_rounded,
                            accent: AppPalette.skyDeep,
                          ),
                          const SizedBox(height: 12),
                          EcoCard(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                IconTile(
                                  icon: Icons.person_rounded,
                                  accent: AppPalette.sky,
                                  size: 48,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.user.name,
                                        style: textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.user.email,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SoftPill(
                                        label:
                                            'Created ${MaterialLocalizations.of(context).formatMediumDate(widget.user.createdAt)}',
                                        icon: Icons.event_rounded,
                                        accent: AppPalette.teal,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 26),
                          SectionHeader(
                            title: 'Settings',
                            icon: Icons.tune_rounded,
                            accent: AppPalette.violet,
                          ),
                          const SizedBox(height: 12),
                          EcoCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: Column(
                              children: [
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  secondary: const Icon(
                                    Icons.dark_mode_rounded,
                                    color: AppPalette.violet,
                                  ),
                                  title: const Text('Dark mode'),
                                  subtitle: Text(
                                    profile.settings.darkModeEnabled
                                        ? 'Using the deep forest palette'
                                        : 'Using the bright eco palette',
                                  ),
                                  value: profile.settings.darkModeEnabled,
                                  onChanged: _isChangingTheme
                                      ? null
                                      : _setDarkMode,
                                ),
                                Divider(color: Theme.of(context).dividerColor),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.notifications_active_rounded,
                                    color: AppPalette.amber,
                                  ),
                                  title: const Text('Reminder notifications'),
                                  subtitle: Text(
                                    profile.notificationsEnabled
                                        ? 'Enabled'
                                        : 'Disabled',
                                  ),
                                  trailing: const Icon(Icons.chevron_right_rounded),
                                  onTap: () => unawaited(_openReminders()),
                                ),
                                Divider(color: Theme.of(context).dividerColor),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.flag_rounded,
                                    color: AppPalette.leaf,
                                  ),
                                  title: const Text('Monthly energy goal'),
                                  subtitle: Text(
                                    profile.goal == null
                                        ? 'No goal set'
                                        : '${profile.goal!.monthlyTargetKwh.toStringAsFixed(1)} kWh target',
                                  ),
                                  trailing: const Icon(Icons.chevron_right_rounded),
                                  onTap: () => unawaited(_openGoals()),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 26),
                          SectionHeader(
                            title: 'Electricity tariff',
                            subtitle: 'Used for every cost estimate',
                            icon: Icons.payments_rounded,
                            accent: AppPalette.emeraldDeep,
                          ),
                          const SizedBox(height: 12),
                          EcoCard(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _tariffController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: InputDecoration(
                                    labelText: 'Cost per kWh',
                                    prefixText: '₹ ',
                                    suffixText: '/ kWh',
                                    helperText:
                                        'Leave blank to remove the saved tariff.',
                                    errorText: _tariffError,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton.icon(
                                    onPressed: _isSavingTariff ? null : _saveTariff,
                                    icon: _isSavingTariff
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.save_rounded, size: 20),
                                    label: const Text('Save tariff'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_settingsError != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _settingsError!,
                              style: textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 26),
                          EcoCard(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context)
                                    .colorScheme
                                    .errorContainer
                                    .withValues(alpha: 0.55),
                                Theme.of(context)
                                    .colorScheme
                                    .errorContainer
                                    .withValues(alpha: 0.20),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderColor: Theme.of(
                              context,
                            ).colorScheme.error.withValues(alpha: 0.25),
                            shadow: AppPalette.shadowFor(
                              Theme.of(context).colorScheme.error,
                              opacity: 0.12,
                            ),
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    IconTile(
                                      icon: Icons.logout_rounded,
                                      accent: AppPalette.coral,
                                      size: 42,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Log out',
                                            style: textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Your data stays on this device.',
                                            style: textTheme.bodySmall?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _logout,
                                  icon: const Icon(Icons.logout_rounded),
                                  label: const Text('Log out'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.error,
                                    side: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error
                                          .withValues(alpha: 0.45),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.darkModeEnabled});

  final User user;
  final bool darkModeEnabled;

  @override
  Widget build(BuildContext context) {
    return EcoHeader(
      eyebrow: 'Account',
      title: 'Profile & settings',
      subtitle: user.email,
      illustration: const EcoIllustration(
        mainIcon: Icons.eco_rounded,
        accent: AppPalette.teal,
      ),
      chips: [
        GlassChip(
          label: darkModeEnabled ? 'Dark mode on' : 'Light mode on',
          icon: darkModeEnabled
              ? Icons.dark_mode_rounded
              : Icons.light_mode_rounded,
        ),
      ],
    );
  }
}

class _ProfileData {
  const _ProfileData({
    required this.settings,
    required this.notificationsEnabled,
    required this.goal,
  });

  final UserSettings settings;
  final bool notificationsEnabled;
  final EnergyGoal? goal;
}