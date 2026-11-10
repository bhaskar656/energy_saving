import 'dart:async';

import 'package:energy_saving/database/database_helper.dart';
import 'package:energy_saving/models/energy_goal.dart';
import 'package:energy_saving/repositories/energy_goal_repository.dart';
import 'package:energy_saving/repositories/energy_usage_repository.dart';
import 'package:energy_saving/screens/energy_goal_form_screen.dart';
import 'package:energy_saving/theme/app_palette.dart';
import 'package:energy_saving/widgets/app_feedback.dart';
import 'package:energy_saving/widgets/eco_card.dart';
import 'package:energy_saving/widgets/gradient_header.dart';
import 'package:flutter/material.dart';

class EnergyGoalsScreen extends StatefulWidget {
  const EnergyGoalsScreen({
    super.key,
    required this.userId,
    this.goalRepository,
    this.usageRepository,
  });

  final int userId;
  final EnergyGoalRepository? goalRepository;
  final EnergyUsageRepository? usageRepository;

  @override
  State<EnergyGoalsScreen> createState() => _EnergyGoalsScreenState();
}

class _EnergyGoalsScreenState extends State<EnergyGoalsScreen> {
  late final EnergyGoalRepository _goalRepository =
      widget.goalRepository ??
      EnergyGoalRepository(databaseHelper: DatabaseHelper.instance);
  late final EnergyUsageRepository _usageRepository =
      widget.usageRepository ??
      EnergyUsageRepository(databaseHelper: DatabaseHelper.instance);
  late Future<_GoalOverview> _overviewFuture;

  @override
  void initState() {
    super.initState();
    _overviewFuture = _loadOverview();
  }

  Future<_GoalOverview> _loadOverview() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final nextMonthStart = DateTime(now.year, now.month + 1);
    final goal = await _goalRepository.getCurrentForUser(widget.userId);
    final usageRecords = await _usageRepository.getForUserBetween(
      userId: widget.userId,
      start: monthStart,
      end: nextMonthStart,
    );
    final currentUsageKwh = usageRecords.fold<double>(
      0,
      (total, record) => total + record.unitsKwh,
    );
    return _GoalOverview(
      goal: goal,
      currentUsageKwh: currentUsageKwh,
      usageRecordCount: usageRecords.length,
    );
  }

  Future<void> _refresh() async {
    final overviewFuture = _loadOverview();
    setState(() => _overviewFuture = overviewFuture);
    try {
      await overviewFuture;
    } catch (_) {}
  }

  Future<void> _openForm(EnergyGoal? goal) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EnergyGoalFormScreen(
          userId: widget.userId,
          repository: _goalRepository,
          goal: goal,
        ),
      ),
    );
    if (saved == true && mounted) {
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(goal == null ? 'Monthly goal saved.' : 'Monthly goal updated.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<_GoalOverview>(
          future: _overviewFuture,
          builder: (context, snapshot) {
            final overview = snapshot.data;
            final monthName = MaterialLocalizations.of(
              context,
            ).formatMonthYear(DateTime.now());

            if (snapshot.connectionState == ConnectionState.waiting ||
                (overview == null && snapshot.hasError)) {
              return Column(
                children: [
                  EcoHeader(
                    eyebrow: 'Stay on target',
                    title: 'Energy goals',
                    illustration: const EcoIllustration(
                      mainIcon: Icons.flag_rounded,
                      accent: AppPalette.leaf,
                    ),
                  ),
                  Expanded(
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const Center(
                            child: AppLoadingIndicator(
                              message: 'Loading energy goals',
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              const SizedBox(height: 32),
                              AppFeedbackPanel(
                                icon: Icons.storage_rounded,
                                title: 'Energy goals could not be loaded',
                                message:
                                    'Your monthly goal is temporarily unavailable.',
                                isError: true,
                                actionLabel: 'Retry',
                                onAction: () => unawaited(_refresh()),
                              ),
                            ],
                          ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                EcoHeader(
                  eyebrow: monthName,
                  title: 'Energy goals',
                  subtitle:
                      '${overview!.usageRecordCount} ${overview.usageRecordCount == 1 ? 'usage record' : 'usage records'} this month',
                  illustration: const EcoIllustration(
                    mainIcon: Icons.flag_rounded,
                    accent: AppPalette.leaf,
                  ),
                  chips: [
                    GlassChip(
                      label:
                          '${overview.currentUsageKwh.toStringAsFixed(1)} kWh used',
                      icon: Icons.bolt_rounded,
                    ),
                    if (overview.goal != null)
                      GlassChip(
                        label:
                            '${overview.goal!.monthlyTargetKwh.toStringAsFixed(1)} kWh target',
                        icon: Icons.flag_rounded,
                      ),
                  ],
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                      children: [
                        _CurrentUsagePanel(
                          currentUsageKwh: overview.currentUsageKwh,
                        ),
                        const SizedBox(height: 16),
                        if (overview.goal == null)
                          _NoGoalPanel(onSetGoal: () => unawaited(_openForm(null)))
                        else ...[
                          _GoalProgressPanel(
                            goal: overview.goal!,
                            currentUsageKwh: overview.currentUsageKwh,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => unawaited(_openForm(overview.goal)),
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Edit monthly goal'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GoalOverview {
  const _GoalOverview({
    required this.goal,
    required this.currentUsageKwh,
    required this.usageRecordCount,
  });

  final EnergyGoal? goal;
  final double currentUsageKwh;
  final int usageRecordCount;
}

class _CurrentUsagePanel extends StatelessWidget {
  const _CurrentUsagePanel({required this.currentUsageKwh});

  final double currentUsageKwh;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return EcoCard(
      gradient: AppPalette.heroGradient,
      borderColor: Colors.transparent,
      shadow: AppPalette.shadowFor(AppPalette.emeraldDeep, opacity: 0.26),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconTile(
            icon: Icons.bolt_rounded,
            accent: AppPalette.amber,
            size: 46,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Usage recorded this month',
              style: textTheme.titleSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
          Text(
            '${currentUsageKwh.toStringAsFixed(1)} kWh',
            style: textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalProgressPanel extends StatelessWidget {
  const _GoalProgressPanel({
    required this.goal,
    required this.currentUsageKwh,
  });

  final EnergyGoal goal;
  final double currentUsageKwh;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    final target = goal.monthlyTargetKwh;
    final progress = (currentUsageKwh / target).clamp(0.0, 1.0);
    final delta = (target - currentUsageKwh).abs();
    final status = delta < 0.05
        ? 'At your monthly target.'
        : currentUsageKwh < target
        ? '${delta.toStringAsFixed(1)} kWh below the usage target.'
        : '${delta.toStringAsFixed(1)} kWh above the usage target.';
    final onTrack = currentUsageKwh <= target;

    return EcoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Monthly usage target', style: textTheme.titleMedium),
              ),
              SoftPill(
                label: onTrack ? 'On track' : 'Over target',
                icon: onTrack
                    ? Icons.trending_down_rounded
                    : Icons.trending_up_rounded,
                accent: onTrack ? AppPalette.emeraldDeep : AppPalette.amber,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              ProgressRing(
                value: progress,
                caption: '${(progress * 100).round()}%',
                accent: onTrack ? AppPalette.emeraldDeep : AppPalette.amber,
                captionStyle: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${currentUsageKwh.toStringAsFixed(1)} of ${target.toStringAsFixed(1)} kWh',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GradientProgressBar(
                      value: progress,
                      accent: onTrack
                          ? AppPalette.emeraldDeep
                          : AppPalette.amber,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      status,
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (goal.monthlySavingTarget > 0) ...[
            const SizedBox(height: 18),
            Divider(color: theme.dividerColor),
            const SizedBox(height: 14),
            Row(
              children: [
                IconTile(
                  icon: Icons.savings_rounded,
                  accent: AppPalette.leaf,
                  size: 40,
                  iconSize: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Monthly saving aim: ${goal.monthlySavingTarget.toStringAsFixed(1)} kWh',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NoGoalPanel extends StatelessWidget {
  const _NoGoalPanel({required this.onSetGoal});

  final VoidCallback onSetGoal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return EcoCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(
                icon: Icons.flag_rounded,
                accent: AppPalette.leaf,
                size: 48,
                iconSize: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text('No monthly goal set', style: textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Set a usage target to track this month’s recorded energy against it.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onSetGoal,
            icon: const Icon(Icons.flag_rounded),
            label: const Text('Set monthly goal'),
          ),
        ],
      ),
    );
  }
}