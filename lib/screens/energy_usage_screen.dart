import 'dart:async';

import 'package:energy_saving/models/energy_usage.dart';
import 'package:energy_saving/repositories/energy_usage_repository.dart';
import 'package:energy_saving/screens/energy_usage_form_screen.dart';
import 'package:energy_saving/theme/app_palette.dart';
import 'package:energy_saving/widgets/app_feedback.dart';
import 'package:energy_saving/widgets/appliance_visuals.dart';
import 'package:energy_saving/widgets/dashboard_components.dart';
import 'package:energy_saving/widgets/eco_card.dart';
import 'package:energy_saving/widgets/energy_usage_card.dart';
import 'package:energy_saving/widgets/gradient_header.dart';
import 'package:flutter/material.dart';

enum UsagePeriod { day, week, month }

class EnergyUsageScreen extends StatefulWidget {
  const EnergyUsageScreen({
    super.key,
    required this.userId,
    required this.repository,
  });

  final int userId;
  final EnergyUsageRepository repository;

  @override
  State<EnergyUsageScreen> createState() => _EnergyUsageScreenState();
}

class _EnergyUsageScreenState extends State<EnergyUsageScreen> {
  UsagePeriod _period = UsagePeriod.day;
  late Future<List<EnergyUsage>> _usageFuture;

  @override
  void initState() {
    super.initState();
    _usageFuture = _loadUsage();
  }

  ({DateTime start, DateTime end}) _dateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_period) {
      UsagePeriod.day => (start: today, end: today.add(const Duration(days: 1))),
      UsagePeriod.week => _weekRange(today),
      UsagePeriod.month => (
        start: DateTime(now.year, now.month),
        end: DateTime(now.year, now.month + 1),
      ),
    };
  }

  ({DateTime start, DateTime end}) _weekRange(DateTime today) {
    final start = today.subtract(Duration(days: today.weekday - DateTime.monday));
    return (start: start, end: start.add(const Duration(days: 7)));
  }

  Future<List<EnergyUsage>> _loadUsage() {
    final range = _dateRange();
    return widget.repository.getForUserBetween(
      userId: widget.userId,
      start: range.start,
      end: range.end,
    );
  }

  Future<void> _refresh() async {
    final usageFuture = _loadUsage();
    setState(() => _usageFuture = usageFuture);
    try {
      await usageFuture;
    } catch (_) {}
  }

  void _selectPeriod(Set<UsagePeriod> selected) {
    if (selected.isEmpty) return;
    setState(() {
      _period = selected.single;
      _usageFuture = _loadUsage();
    });
  }

  Future<void> _openForm([EnergyUsage? usage]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EnergyUsageFormScreen(
          userId: widget.userId,
          repository: widget.repository,
          usage: usage,
        ),
      ),
    );
    if (saved == true && mounted) {
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(usage == null ? 'Usage added.' : 'Usage updated.')),
        );
      }
    }
  }

  Future<void> _delete(EnergyUsage usage) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete usage record?'),
        content: Text('The ${usage.appliance} entry will be removed.'),
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
    if (shouldDelete != true || usage.id == null) return;

    try {
      await widget.repository.delete(usageId: usage.id!, userId: widget.userId);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usage record deleted.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usage record could not be deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<EnergyUsage>>(
          future: _usageFuture,
          builder: (context, snapshot) {
            final usages = snapshot.data ?? const <EnergyUsage>[];
            final totalKwh = usages.fold<double>(
              0,
              (total, usage) => total + usage.unitsKwh,
            );

            return Column(
              children: [
                _UsageHeader(
                  period: _period,
                  totalKwh: totalKwh,
                  usages: usages,
                  isLoading: snapshot.connectionState == ConnectionState.waiting,
                  onSelectPeriod: _selectPeriod,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: _buildContent(context, snapshot, usages, totalKwh),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => unawaited(_openForm()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add usage'),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncSnapshot<List<EnergyUsage>> snapshot,
    List<EnergyUsage> usages,
    double totalKwh,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 260),
          Center(child: AppLoadingIndicator(message: 'Loading energy use')),
        ],
      );
    }
    if (snapshot.hasError) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 48),
          AppFeedbackPanel(
            icon: Icons.storage_rounded,
            title: 'Energy usage could not be loaded',
            message: 'Your usage records are temporarily unavailable.',
            isError: true,
            actionLabel: 'Retry',
            onAction: () => unawaited(_refresh()),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
      children: [
        _UsageSummaryPanel(
          period: _period,
          totalKwh: totalKwh,
          usages: usages,
        ),
        const SizedBox(height: 16),
        _UsageBarChart(period: _period, usages: usages),
        const SizedBox(height: 26),
        SectionHeader(
          title: 'Records',
          subtitle: usages.isEmpty
              ? 'Nothing recorded in this period yet'
              : '${usages.length} ${usages.length == 1 ? 'entry' : 'entries'} in this period',
          icon: Icons.bolt_rounded,
          accent: AppPalette.skyDeep,
        ),
        const SizedBox(height: 14),
        if (usages.isEmpty)
          AppFeedbackPanel(
            icon: Icons.bolt_rounded,
            title: 'No usage recorded',
            message:
                'Add an appliance usage record to see it in this period.',
            actionLabel: 'Add usage',
            onAction: () => unawaited(_openForm()),
          )
        else
          ...usages.map(
            (usage) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EnergyUsageCard(
                usage: usage,
                shareOfTotal: totalKwh <= 0 ? null : usage.unitsKwh / totalKwh,
                onEdit: () => unawaited(_openForm(usage)),
                onDelete: () => unawaited(_delete(usage)),
              ),
            ),
          ),
      ],
    );
  }
}

class _UsageHeader extends StatelessWidget {
  const _UsageHeader({
    required this.period,
    required this.totalKwh,
    required this.usages,
    required this.isLoading,
    required this.onSelectPeriod,
  });

  final UsagePeriod period;
  final double totalKwh;
  final List<EnergyUsage> usages;
  final bool isLoading;
  final ValueChanged<Set<UsagePeriod>> onSelectPeriod;

  String get _periodLabel => switch (period) {
    UsagePeriod.day => 'Today',
    UsagePeriod.week => 'This week',
    UsagePeriod.month => 'This month',
  };

  @override
  Widget build(BuildContext context) {
    final topAppliance = _topAppliance;

    return EcoHeader(
      eyebrow: _periodLabel,
      title: 'Energy usage',
      subtitle: isLoading
          ? 'Loading your records…'
          : '${totalKwh.toStringAsFixed(2)} kWh recorded · '
                '${usages.length} ${usages.length == 1 ? 'entry' : 'entries'}',
      illustration: const EcoIllustration(
        mainIcon: Icons.bolt_rounded,
        accent: AppPalette.amber,
      ),
      chips: [
        if (topAppliance != null)
          GlassChip(label: 'Top · $topAppliance', icon: Icons.trending_up_rounded),
        if (usages.isNotEmpty)
          GlassChip(
            label:
                'Avg ${(totalKwh / usages.length).toStringAsFixed(2)} kWh per entry',
            icon: Icons.calculate_rounded,
          ),
      ],
      bottom: Align(
        alignment: Alignment.centerLeft,
        child: SegmentedButton<UsagePeriod>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: UsagePeriod.day, label: Text('Today')),
            ButtonSegment(value: UsagePeriod.week, label: Text('Week')),
            ButtonSegment(value: UsagePeriod.month, label: Text('Month')),
          ],
          selected: {period},
          onSelectionChanged: onSelectPeriod,
          style: SegmentedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.14),
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.30)),
            selectedBackgroundColor: Colors.white,
            selectedForegroundColor: AppPalette.forest,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          ),
        ),
      ),
    );
  }

  String? get _topAppliance {
    if (usages.isEmpty) return null;
    final totals = <String, double>{};
    for (final usage in usages) {
      totals.update(
        usage.appliance,
        (total) => total + usage.unitsKwh,
        ifAbsent: () => usage.unitsKwh,
      );
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }
}

class _UsageSummaryPanel extends StatelessWidget {
  const _UsageSummaryPanel({
    required this.period,
    required this.totalKwh,
    required this.usages,
  });

  final UsagePeriod period;
  final double totalKwh;
  final List<EnergyUsage> usages;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final periodLabel = switch (period) {
      UsagePeriod.day => 'Today',
      UsagePeriod.week => 'This week',
      UsagePeriod.month => 'This month',
    };

    return EcoCard(
      gradient: AppPalette.heroGradient,
      borderColor: Colors.transparent,
      shadow: AppPalette.shadowFor(AppPalette.emeraldDeep, opacity: 0.28),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(
                icon: Icons.bolt_rounded,
                accent: AppPalette.amber,
                useGradient: true,
                size: 46,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$periodLabel usage',
                      style: textTheme.titleSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${usages.length} ${usages.length == 1 ? 'record' : 'records'}',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${totalKwh.toStringAsFixed(2)} kWh',
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (usages.isNotEmpty) ...[
            const SizedBox(height: 18),
            ..._applianceBreakdown(context),
          ] else
            Text(
              'Add your first record to see the appliances behind this total.',
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.80),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _applianceBreakdown(BuildContext context) {
    final totals = <String, double>{};
    for (final usage in usages) {
      totals.update(
        usage.appliance,
        (total) => total + usage.unitsKwh,
        ifAbsent: () => usage.unitsKwh,
      );
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(3).toList();

    return [
      Text(
        'Where it went',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
      const SizedBox(height: 10),
      for (final entry in top)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _BreakdownRow(
            label: entry.key,
            kwh: entry.value,
            share: totalKwh <= 0 ? 0 : entry.value / totalKwh,
          ),
        ),
    ];
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.kwh,
    required this.share,
  });

  final String label;
  final double kwh;
  final double share;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              ApplianceVisuals.iconFor(label),
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${kwh.toStringAsFixed(2)} kWh · ${(share * 100).round()}%',
              style: textTheme.labelMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GradientProgressBar(
          value: share,
          height: 7,
          accent: Colors.white,
          trackColor: Colors.white.withValues(alpha: 0.22),
        ),
      ],
    );
  }
}

class _UsageBarChart extends StatelessWidget {
  const _UsageBarChart({required this.period, required this.usages});

  final UsagePeriod period;
  final List<EnergyUsage> usages;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    final today = DateUtils.dateOnly(DateTime.now());
    final start = switch (period) {
      UsagePeriod.day => today,
      UsagePeriod.week => today.subtract(
        Duration(days: today.weekday - DateTime.monday),
      ),
      UsagePeriod.month => DateTime(today.year, today.month),
    };
    final dayCount = switch (period) {
      UsagePeriod.day => 1,
      UsagePeriod.week => 7,
      UsagePeriod.month => today.day,
    };
    final dates = List.generate(
      dayCount,
      (index) => start.add(Duration(days: index)),
    );
    final totalsByDate = <DateTime, double>{};
    for (final usage in usages) {
      final date = DateUtils.dateOnly(usage.usageDate);
      totalsByDate.update(
        date,
        (total) => total + usage.unitsKwh,
        ifAbsent: () => usage.unitsKwh,
      );
    }
    final values = dates.map((date) => totalsByDate[date] ?? 0.0).toList();
    final maximum = values.fold<double>(
      0,
      (currentMaximum, value) => value > currentMaximum ? value : currentMaximum,
    );
    final chartAccent = switch (period) {
      UsagePeriod.day => AppPalette.skyDeep,
      UsagePeriod.week => AppPalette.tealDeep,
      UsagePeriod.month => AppPalette.emeraldDeep,
    };

    return EcoCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Daily consumption', style: textTheme.titleMedium),
              ),
              SoftPill(
                label: maximum <= 0
                    ? 'No data'
                    : 'Peak ${maximum.toStringAsFixed(1)} kWh',
                icon: Icons.show_chart_rounded,
                accent: chartAccent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 168,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(dates.length, (index) {
                  final value = values[index];
                  final fraction = maximum == 0 ? 0.0 : value / maximum;
                  final barHeight = maximum == 0 ? 4.0 : 96 * fraction;
                  final label = switch (period) {
                    UsagePeriod.day => 'Today',
                    UsagePeriod.week => const [
                      'M',
                      'T',
                      'W',
                      'T',
                      'F',
                      'S',
                      'S',
                    ][index],
                    UsagePeriod.month => dates[index].day.toString(),
                  };

                  return SizedBox(
                    width: 44,
                    height: 168,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          value == 0 ? '0' : value.toStringAsFixed(1),
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: value == 0
                                ? theme.colorScheme.onSurfaceVariant
                                : accentForeground(context, chartAccent),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: barHeight),
                          duration: const Duration(milliseconds: 550),
                          curve: Curves.easeOutCubic,
                          builder: (context, height, _) {
                            return Container(
                              width: 18,
                              height: height,
                              decoration: BoxDecoration(
                                gradient: value == 0
                                    ? null
                                    : AppPalette.gradientFor(chartAccent),
                                color: value == 0
                                    ? theme.colorScheme.outlineVariant
                                    : null,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: value == 0
                                    ? null
                                    : AppPalette.shadowFor(
                                        chartAccent,
                                        opacity: 0.3,
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}