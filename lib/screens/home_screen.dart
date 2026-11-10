import 'dart:async';

import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/dashboard_summary.dart';
import 'package:energy_saving/models/user.dart';
import 'package:energy_saving/models/user_settings.dart';
import 'package:energy_saving/repositories/appliance_repository.dart';
import 'package:energy_saving/repositories/dashboard_repository.dart';
import 'package:energy_saving/repositories/energy_goal_repository.dart';
import 'package:energy_saving/repositories/energy_tip_repository.dart';
import 'package:energy_saving/repositories/energy_usage_repository.dart';
import 'package:energy_saving/repositories/reminder_repository.dart';
import 'package:energy_saving/repositories/notification_preferences_repository.dart';
import 'package:energy_saving/repositories/user_settings_repository.dart';
import 'package:energy_saving/screens/appliances_screen.dart';
import 'package:energy_saving/screens/energy_calculator_screen.dart';
import 'package:energy_saving/screens/energy_goal_form_screen.dart';
import 'package:energy_saving/screens/energy_goals_screen.dart';
import 'package:energy_saving/screens/energy_usage_form_screen.dart';
import 'package:energy_saving/screens/energy_usage_screen.dart';
import 'package:energy_saving/screens/profile_screen.dart';
import 'package:energy_saving/screens/reminder_form_screen.dart';
import 'package:energy_saving/screens/reminders_screen.dart';
import 'package:energy_saving/screens/tips_screen.dart';
import 'package:energy_saving/services/reminder_notification_service.dart';
import 'package:energy_saving/theme/app_palette.dart';
import 'package:energy_saving/widgets/app_bottom_nav.dart';
import 'package:energy_saving/widgets/app_feedback.dart';
import 'package:energy_saving/widgets/dashboard_components.dart';
import 'package:energy_saving/widgets/eco_card.dart';
import 'package:energy_saving/widgets/gradient_header.dart';
import 'package:flutter/material.dart';

/// Grid emission factor used for the clearly labelled CO2 estimate card.
const double _co2KgPerKwh = 0.404;

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.user,
    required this.onLogout,
    this.dashboardRepository,
    this.settingsRepository,
    this.onThemeModeChanged,
  });

  final User user;
  final VoidCallback onLogout;
  final DashboardDataSource? dashboardRepository;
  final UserSettingsRepository? settingsRepository;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _usageTab = 1;
  static const int _remindersTab = 2;
  static const int _profileTab = 3;

  late final DashboardDataSource _dashboardRepository =
      widget.dashboardRepository ??
      DashboardRepository(databaseHelper: DatabaseHelper.instance);
  late Future<DashboardSummary> _summaryFuture;
  UserSettings? _userSettings;
  int _tabIndex = 0;
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummary();
    unawaited(_loadUserSettings());
  }

  Future<void> _loadUserSettings() async {
    final repository = widget.settingsRepository;
    if (repository == null) return;
    try {
      final settings = await repository.getForUser(widget.user.id!);
      if (!mounted) return;
      setState(() => _userSettings = settings);
      widget.onThemeModeChanged?.call(
        settings.darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      );
    } catch (_) {}
  }

  Future<DashboardSummary> _loadSummary() {
    return _dashboardRepository.loadForUser(widget.user.id!);
  }

  Future<void> _refresh() async {
    final summaryFuture = _loadSummary();
    setState(() => _summaryFuture = summaryFuture);
    try {
      await summaryFuture;
    } catch (_) {}
  }

  void _selectTab(int index) {
    if (index == _tabIndex) return;
    setState(() {
      _tabIndex = index;
      _visitedTabs.add(index);
    });
    if (index == 0) unawaited(_refresh());
  }

  Future<void> _openAppliances() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => AppliancesScreen(
          userId: widget.user.id!,
          repository: ApplianceRepository(databaseHelper: DatabaseHelper.instance),
        ),
      ),
    );
  }

  Future<void> _openCalculator() async {
    var settings = _userSettings;
    final repository = widget.settingsRepository;
    if (repository != null) {
      settings = await repository.getForUser(widget.user.id!);
    }
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => EnergyCalculatorScreen(
          initialTariffPerKwh: settings?.electricityTariff,
        ),
      ),
    );
  }

  Future<void> _openGoals() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => EnergyGoalsScreen(
          userId: widget.user.id!,
          goalRepository: EnergyGoalRepository(
            databaseHelper: DatabaseHelper.instance,
          ),
          usageRepository: EnergyUsageRepository(
            databaseHelper: DatabaseHelper.instance,
          ),
        ),
      ),
    );
    if (mounted) await _refresh();
  }

  Future<void> _openTips() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => TipsScreen(
          repository: EnergyTipRepository(
            databaseHelper: DatabaseHelper.instance,
          ),
        ),
      ),
    );
  }

  Future<void> _addUsage() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EnergyUsageFormScreen(
          userId: widget.user.id!,
          repository: EnergyUsageRepository(databaseHelper: DatabaseHelper.instance),
        ),
      ),
    );
    if (saved == true && mounted) await _refresh();
  }

  Future<void> _addReminder() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ReminderFormScreen(
          userId: widget.user.id!,
          repository: ReminderRepository(databaseHelper: DatabaseHelper.instance),
        ),
      ),
    );
    if (saved == true && mounted) await _refresh();
  }

  Future<void> _editGoal() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EnergyGoalFormScreen(
          userId: widget.user.id!,
          repository: EnergyGoalRepository(databaseHelper: DatabaseHelper.instance),
        ),
      ),
    );
    if (mounted) await _refresh();
  }

  void _openTool(String tool) {
    switch (tool) {
      case 'calculator':
        unawaited(_openCalculator());
      case 'appliances':
        unawaited(_openAppliances());
      case 'goals':
        unawaited(_openGoals());
      case 'tips':
        unawaited(_openTips());
      case 'addUsage':
        unawaited(_addUsage());
      case 'addReminder':
        unawaited(_addReminder());
      case 'editGoal':
        unawaited(_editGoal());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: IndexedStack(
            index: _tabIndex,
            children: [
              _DashboardTab(
                user: widget.user,
                summaryFuture: _summaryFuture,
                onRefresh: _refresh,
                onOpenTool: _openTool,
                onOpenProfile: () => _selectTab(_profileTab),
              ),
              _LazyTab(
                enabled: _visitedTabs.contains(_usageTab),
                builder: (context) => EnergyUsageScreen(
                  userId: widget.user.id!,
                  repository: EnergyUsageRepository(
                    databaseHelper: DatabaseHelper.instance,
                  ),
                ),
              ),
              _LazyTab(
                enabled: _visitedTabs.contains(_remindersTab),
                builder: (context) => RemindersScreen(
                  userId: widget.user.id!,
                  repository: ReminderRepository(
                    databaseHelper: DatabaseHelper.instance,
                  ),
                ),
              ),
              _LazyTab(
                enabled: _visitedTabs.contains(_profileTab),
                builder: (context) => ProfileScreen(
                  user: widget.user,
                  onLogout: widget.onLogout,
                  settingsRepository:
                      widget.settingsRepository ??
                      UserSettingsRepository(
                        databaseHelper: DatabaseHelper.instance,
                      ),
                  notificationPreferencesRepository:
                      NotificationPreferencesRepository(
                        databaseHelper: DatabaseHelper.instance,
                      ),
                  reminderRepository: ReminderRepository(
                    databaseHelper: DatabaseHelper.instance,
                  ),
                  goalRepository: EnergyGoalRepository(
                    databaseHelper: DatabaseHelper.instance,
                  ),
                  usageRepository: EnergyUsageRepository(
                    databaseHelper: DatabaseHelper.instance,
                  ),
                  notificationService: LocalReminderNotificationService(),
                  onThemeModeChanged: widget.onThemeModeChanged ?? (_) {},
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        index: _tabIndex,
        onChanged: _selectTab,
      ),
    );
  }
}

/// Builds a tab body the first time the user opens it, so the dashboard stays
/// instant while the heavier list tabs stay untouched until requested.
class _LazyTab extends StatefulWidget {
  const _LazyTab({required this.enabled, required this.builder});

  final bool enabled;
  final WidgetBuilder builder;

  @override
  State<_LazyTab> createState() => _LazyTabState();
}

class _LazyTabState extends State<_LazyTab> {
  late bool _active = widget.enabled;

  @override
  void didUpdateWidget(_LazyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_active) {
      _active = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) return const SizedBox.shrink();
    return widget.builder(context);
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.user,
    required this.summaryFuture,
    required this.onRefresh,
    required this.onOpenTool,
    required this.onOpenProfile,
  });

  final User user;
  final Future<DashboardSummary> summaryFuture;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onOpenTool;
  final VoidCallback onOpenProfile;

  static const _tools = <_Tool>[
    _Tool(
      label: 'Energy\ncalculator',
      icon: Icons.calculate_rounded,
      accent: AppPalette.tealDeep,
      tool: 'calculator',
    ),
    _Tool(
      label: 'Add\nusage',
      icon: Icons.add_chart_rounded,
      accent: AppPalette.skyDeep,
      tool: 'addUsage',
    ),
    _Tool(
      label: 'My\nappliances',
      icon: Icons.electrical_services_rounded,
      accent: AppPalette.amber,
      tool: 'appliances',
    ),
    _Tool(
      label: 'New\nreminder',
      icon: Icons.add_alarm_rounded,
      accent: AppPalette.violet,
      tool: 'addReminder',
    ),
    _Tool(
      label: 'Monthly\ngoal',
      icon: Icons.flag_rounded,
      accent: AppPalette.emeraldDeep,
      tool: 'goals',
    ),
    _Tool(
      label: 'Eco\ntips',
      icon: Icons.lightbulb_rounded,
      accent: AppPalette.leaf,
      tool: 'tips',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardSummary>(
      future: summaryFuture,
      builder: (context, snapshot) {
        final summary = snapshot.hasData ? snapshot.data : null;
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _WelcomeHeader(
                  user: user,
                  summary: summary,
                  onOpenProfile: onOpenProfile,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 72),
                          child: AppLoadingIndicator(
                            message: 'Loading your energy overview',
                          ),
                        )
                      else if (snapshot.hasError)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: AppFeedbackPanel(
                            icon: Icons.storage_rounded,
                            title: 'Dashboard data could not be loaded.',
                            message:
                                'Your recorded usage is temporarily unavailable.',
                            isError: true,
                            actionLabel: 'Retry',
                            onAction: onRefresh,
                          ),
                        )
                      else if (summary != null)
                        ..._buildContent(context, summary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildContent(BuildContext context, DashboardSummary summary) {
    final target = summary.monthlyTargetKwh;
    final hasTarget = target != null && target > 0;
    final savedKwh = !hasTarget
        ? null
        : summary.monthUsageKwh >= target
        ? 0.0
        : target - summary.monthUsageKwh;
    final tariff = summary.tariffPerKwh;
    final moneySaved = savedKwh == null || tariff == null
        ? null
        : savedKwh * tariff;
    final co2Kg = summary.monthUsageKwh * _co2KgPerKwh;
    final maximum = [
      summary.todayUsageKwh,
      summary.weekUsageKwh,
      summary.monthUsageKwh,
    ].reduce((a, b) => a > b ? a : b);

    return [
      SectionHeader(
        title: 'Your impact',
        subtitle: 'Live figures from the energy you recorded',
        icon: Icons.insights_rounded,
        accent: AppPalette.emeraldDeep,
        trailing: SoftPill(
          label: 'This month',
          icon: Icons.calendar_month_rounded,
          accent: AppPalette.emeraldDeep,
        ),
      ),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 3
              : constraints.maxWidth >= 560
              ? 2
              : 1;
          const spacing = 12.0;
          final cardWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;

          Widget tile(Widget child) =>
              SizedBox(width: cardWidth, child: child);

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              tile(
                DashboardStatCard(
                  label: 'Energy used today',
                  value: '${summary.todayUsageKwh.toStringAsFixed(1)} kWh',
                  detail: _recordDetail(summary.todayRecordCount),
                  icon: Icons.bolt_rounded,
                  accent: AppPalette.sky,
                  badge: 'Today',
                ),
              ),
              tile(
                DashboardStatCard(
                  label: 'Energy saved',
                  value: savedKwh == null
                      ? '—'
                      : '${savedKwh.toStringAsFixed(1)} kWh',
                  detail: _savedDetail(savedKwh, target),
                  icon: Icons.savings_rounded,
                  accent: AppPalette.emeraldDeep,
                ),
              ),
              tile(
                DashboardStatCard(
                  label: 'Money saved',
                  value: moneySaved == null
                      ? '—'
                      : '₹${moneySaved.toStringAsFixed(2)}',
                  detail: moneySaved == null
                      ? 'Needs a monthly target and tariff'
                      : 'Saved against your monthly target',
                  icon: Icons.payments_rounded,
                  accent: AppPalette.green,
                ),
              ),
              tile(
                DashboardStatCard(
                  label: 'Monthly usage',
                  value: '${summary.monthUsageKwh.toStringAsFixed(1)} kWh',
                  detail: _recordDetail(summary.monthRecordCount),
                  icon: Icons.calendar_month_rounded,
                  accent: AppPalette.teal,
                  badge: '30 days',
                ),
              ),
              tile(
                DashboardStatCard(
                  label: 'Estimated bill',
                  value: tariff == null
                      ? '—'
                      : '₹${(summary.monthUsageKwh * tariff).toStringAsFixed(2)}',
                  detail: tariff == null
                      ? 'Tariff not configured'
                      : 'At ₹${tariff.toStringAsFixed(2)}/kWh · estimate',
                  icon: Icons.receipt_long_rounded,
                  accent: AppPalette.amber,
                ),
              ),
              tile(
                DashboardStatCard(
                  label: 'Environmental impact',
                  value: '≈ ${co2Kg.toStringAsFixed(1)} kg',
                  detail: 'CO₂e this month · $_co2KgPerKwh kg per kWh',
                  icon: Icons.eco_rounded,
                  accent: AppPalette.leaf,
                ),
              ),
              tile(
                DashboardStatCard(
                  label: 'Active reminders',
                  value: summary.activeReminderCount.toString(),
                  detail: _reminderDetail(summary.activeReminderCount),
                  icon: Icons.notifications_active_rounded,
                  accent: AppPalette.violet,
                ),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 28),
      SectionHeader(
        title: 'Usage snapshot',
        subtitle: 'Where your recorded energy went',
        icon: Icons.bar_chart_rounded,
        accent: AppPalette.skyDeep,
      ),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 760
              ? 3
              : constraints.maxWidth >= 520
              ? 2
              : 1;
          const spacing = 12.0;
          final cardWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              SizedBox(
                width: cardWidth,
                child: UsagePeriodRow(
                  label: 'Today',
                  kwh: summary.todayUsageKwh,
                  recordCount: summary.todayRecordCount,
                  accent: AppPalette.sky,
                  maxKwh: maximum,
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: UsagePeriodRow(
                  label: 'This week',
                  kwh: summary.weekUsageKwh,
                  recordCount: summary.weekRecordCount,
                  accent: AppPalette.teal,
                  maxKwh: maximum,
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: UsagePeriodRow(
                  label: 'This month',
                  kwh: summary.monthUsageKwh,
                  recordCount: summary.monthRecordCount,
                  accent: AppPalette.emeraldDeep,
                  maxKwh: maximum,
                ),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 28),
      SectionHeader(
        title: 'Monthly goal',
        subtitle: 'Keep this month under your target',
        icon: Icons.flag_rounded,
        accent: AppPalette.leaf,
      ),
      const SizedBox(height: 14),
      MonthlyGoalPanel(
        monthUsageKwh: summary.monthUsageKwh,
        targetKwh: summary.monthlyTargetKwh,
        onEdit: () => onOpenTool('editGoal'),
      ),
      const SizedBox(height: 28),
      SectionHeader(
        title: 'Quick tools',
        subtitle: 'Everything you need, one tap away',
        icon: Icons.auto_awesome_rounded,
        accent: AppPalette.tealDeep,
      ),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 640 ? 4 : 3;
          const spacing = 12.0;
          final cardWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final tool in _tools)
                SizedBox(
                  width: cardWidth,
                  child: _ToolTile(
                    label: tool.label,
                    icon: tool.icon,
                    accent: tool.accent,
                    onTap: () => onOpenTool(tool.tool),
                  ),
                ),
            ],
          );
        },
      ),
    ];
  }

  String _recordDetail(int count) {
    if (count == 0) return 'No usage recorded';
    return '$count ${count == 1 ? 'record' : 'records'}';
  }

  String _savedDetail(double? savedKwh, double? target) {
    if (savedKwh == null || target == null) return 'No comparison baseline';
    if (savedKwh <= 0) return 'Monthly target already met';
    return '${savedKwh.toStringAsFixed(1)} kWh below your target';
  }

  String _reminderDetail(int count) {
    if (count == 0) return 'Add one to switch things off on time';
    if (count == 1) return '1 reminder enabled';
    return '$count reminders enabled';
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({
    required this.user,
    required this.summary,
    required this.onOpenProfile,
  });

  final User user;
  final DashboardSummary? summary;
  final VoidCallback onOpenProfile;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final data = summary;
    final initial = user.name.trim().isEmpty
        ? 'E'
        : user.name.trim()[0].toUpperCase();

    return EcoHeader(
      eyebrow: _greeting,
      title: 'Welcome, ${user.name}',
      subtitle: 'Track every switch-off and watch your savings grow.',
      illustration: const EcoIllustration(),
      trailing: Semantics(
        button: true,
        label: 'Open profile and settings',
        child: InkWell(
          onTap: onOpenProfile,
          customBorder: const CircleBorder(),
          child: Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            ),
            child: Text(
              initial,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
      chips: [
        GlassChip(
          label: data == null
              ? 'Loading today'
              : '${data.todayUsageKwh.toStringAsFixed(1)} kWh today',
          icon: Icons.bolt_rounded,
        ),
        GlassChip(
          label: data == null
              ? 'Loading goal'
              : _goalLabel(data),
          icon: Icons.flag_rounded,
        ),
        GlassChip(
          label: data == null
              ? 'Loading reminders'
              : '${data.activeReminderCount} reminders on',
          icon: Icons.notifications_active_rounded,
        ),
      ],
    );
  }

  String _goalLabel(DashboardSummary data) {
    final target = data.monthlyTargetKwh;
    if (target == null || target <= 0) return 'No monthly target yet';
    return data.monthUsageKwh <= target
        ? 'Within your monthly target'
        : 'Above your monthly target';
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return EcoCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      shadow: AppPalette.shadowFor(accent, opacity: 0.10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTile(icon: icon, accent: accent, size: 44, iconSize: 22),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.titleSmall?.copyWith(
              color: accentForeground(context, accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tool {
  const _Tool({
    required this.label,
    required this.icon,
    required this.accent,
    required this.tool,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final String tool;
}