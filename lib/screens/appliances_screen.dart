import 'dart:async';

import 'package:energy_saving/models/appliance.dart';
import 'package:energy_saving/repositories/appliance_repository.dart';
import 'package:energy_saving/screens/appliance_form_screen.dart';
import 'package:energy_saving/theme/app_palette.dart';
import 'package:energy_saving/widgets/app_feedback.dart';
import 'package:energy_saving/widgets/appliance_card.dart';
import 'package:energy_saving/widgets/eco_card.dart';
import 'package:energy_saving/widgets/gradient_header.dart';
import 'package:flutter/material.dart';

class AppliancesScreen extends StatefulWidget {
  const AppliancesScreen({
    super.key,
    required this.userId,
    required this.repository,
  });

  final int userId;
  final ApplianceRepository repository;

  @override
  State<AppliancesScreen> createState() => _AppliancesScreenState();
}

class _AppliancesScreenState extends State<AppliancesScreen> {
  late Future<List<Appliance>> _appliancesFuture;

  @override
  void initState() {
    super.initState();
    _appliancesFuture = _loadAppliances();
  }

  Future<List<Appliance>> _loadAppliances() {
    return widget.repository.getForUser(widget.userId);
  }

  Future<void> _refresh() async {
    final appliancesFuture = _loadAppliances();
    setState(() => _appliancesFuture = appliancesFuture);
    try {
      await appliancesFuture;
    } catch (_) {}
  }

  Future<void> _openForm([Appliance? appliance]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ApplianceFormScreen(
          userId: widget.userId,
          repository: widget.repository,
          appliance: appliance,
        ),
      ),
    );
    if (saved == true && mounted) {
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appliance == null ? 'Appliance added.' : 'Appliance updated.'),
          ),
        );
      }
    }
  }

  Future<void> _setActive(Appliance appliance, bool isActive) async {
    final id = appliance.id;
    if (id == null) return;
    try {
      await widget.repository.setActive(
        applianceId: id,
        userId: widget.userId,
        isActive: isActive,
      );
      await _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appliance status could not be updated.')),
        );
      }
    }
  }

  Future<void> _delete(Appliance appliance) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete appliance?'),
        content: Text('“${appliance.name}” will be removed.'),
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
    if (shouldDelete != true || appliance.id == null) return;

    try {
      await widget.repository.delete(
        applianceId: appliance.id!,
        userId: widget.userId,
      );
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appliance deleted.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appliance could not be deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<Appliance>>(
          future: _appliancesFuture,
          builder: (context, snapshot) {
            final appliances = snapshot.data ?? const <Appliance>[];
            final activeCount = appliances
                .where((appliance) => appliance.isActive)
                .length;

            return Column(
              children: [
                EcoHeader(
                  eyebrow: 'Your home',
                  title: 'Appliances',
                  subtitle: 'Rated power and daily use for every device',
                  illustration: const EcoIllustration(
                    mainIcon: Icons.electrical_services_rounded,
                    accent: AppPalette.amber,
                  ),
                  chips: [
                    GlassChip(
                      label: appliances.isEmpty
                          ? 'No appliances yet'
                          : '${appliances.length} saved',
                      icon: Icons.devices_rounded,
                    ),
                    if (appliances.isNotEmpty)
                      GlassChip(
                        label: '$activeCount in use',
                        icon: Icons.power_settings_new_rounded,
                      ),
                  ],
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: _buildList(context, snapshot),
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
        label: const Text('Add appliance'),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    AsyncSnapshot<List<Appliance>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 280),
          Center(child: AppLoadingIndicator(message: 'Loading appliances')),
        ],
      );
    }

    if (snapshot.hasError) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          AppFeedbackPanel(
            icon: Icons.storage_outlined,
            title: 'Appliances could not be loaded',
            message: 'Your appliance list is temporarily unavailable.',
            isError: true,
            actionLabel: 'Retry',
            onAction: () => unawaited(_refresh()),
          ),
        ],
      );
    }

    final appliances = snapshot.data ?? const <Appliance>[];
    if (appliances.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          AppFeedbackPanel(
            icon: Icons.electrical_services_outlined,
            title: 'No appliances yet',
            message: 'Add appliances to keep their power and usage details together.',
            actionLabel: 'Add appliance',
            onAction: () => unawaited(_openForm()),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
      itemCount: appliances.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SectionHeader(
              title: 'Saved appliances',
              subtitle: appliances.isEmpty
                  ? 'Nothing added yet'
                  : '${appliances.length} ${appliances.length == 1 ? 'device' : 'devices'} on file',
              icon: Icons.devices_rounded,
              accent: AppPalette.emeraldDeep,
            ),
          );
        }
        final appliance = appliances[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ApplianceCard(
            appliance: appliance,
            onActiveChanged: (value) => _setActive(appliance, value),
            onEdit: () => unawaited(_openForm(appliance)),
            onDelete: () => unawaited(_delete(appliance)),
          ),
        );
      },
    );
  }
}