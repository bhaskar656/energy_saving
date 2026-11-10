import 'dart:async';

import 'package:energy_saving/models/energy_tip.dart';
import 'package:energy_saving/repositories/energy_tip_repository.dart';
import 'package:energy_saving/theme/app_palette.dart';
import 'package:energy_saving/widgets/app_feedback.dart';
import 'package:energy_saving/widgets/eco_card.dart';
import 'package:energy_saving/widgets/energy_tip_card.dart';
import 'package:energy_saving/widgets/gradient_header.dart';
import 'package:flutter/material.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({
    super.key,
    required this.repository,
  });

  final EnergyTipRepository repository;

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  static const _allCategories = 'All categories';
  final _searchController = TextEditingController();
  String _selectedCategory = _allCategories;
  late Future<List<EnergyTip>> _tipsFuture;

  List<String> get _categories => [
    _allCategories,
    ...EnergyTipRepository.categories,
  ];

  @override
  void initState() {
    super.initState();
    _tipsFuture = _loadTips();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<EnergyTip>> _loadTips() {
    return widget.repository.getTips(
      category: _selectedCategory == _allCategories
          ? null
          : _selectedCategory,
      searchQuery: _searchController.text,
    );
  }

  void _applyFilters() {
    setState(() => _tipsFuture = _loadTips());
  }

  Future<void> _refresh() async {
    final tipsFuture = _loadTips();
    setState(() => _tipsFuture = tipsFuture);
    try {
      await tipsFuture;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            EcoHeader(
              eyebrow: 'Learn and save',
              title: 'Energy-saving tips',
              subtitle: 'Small habits that keep your bills lower',
              illustration: const EcoIllustration(
                mainIcon: Icons.lightbulb_rounded,
                accent: AppPalette.leaf,
              ),
              chips: [
                GlassChip(
                  label: _selectedCategory,
                  icon: Icons.category_rounded,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Search tips',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => _applyFilters(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.filter_list_rounded),
                ),
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (category) {
                  if (category != null) {
                    setState(() {
                      _selectedCategory = category;
                      _tipsFuture = _loadTips();
                    });
                  }
                },
              ),
            ),
            Expanded(
              child: FutureBuilder<List<EnergyTip>>(
                future: _tipsFuture,
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
    );
  }

  Widget _buildList(
    BuildContext context,
    AsyncSnapshot<List<EnergyTip>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 240),
          Center(child: AppLoadingIndicator(message: 'Loading tips')),
        ],
      );
    }

    if (snapshot.hasError) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          AppFeedbackPanel(
            icon: Icons.storage_outlined,
            title: 'Tips could not be loaded',
            message: 'The offline tips are temporarily unavailable.',
            isError: true,
            actionLabel: 'Retry',
            onAction: () => unawaited(_refresh()),
          ),
        ],
      );
    }

    final tips = snapshot.data ?? const <EnergyTip>[];
    if (tips.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          AppFeedbackPanel(
            icon: Icons.search_off,
            title: 'No tips match these filters',
            message: 'Try another category or search term.',
            actionLabel: 'Clear filters',
            actionIcon: Icons.filter_alt_off_outlined,
            onAction: () {
              _searchController.clear();
              setState(() {
                _selectedCategory = _allCategories;
                _tipsFuture = _loadTips();
              });
            },
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      itemCount: tips.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: EnergyTipCard(tip: tips[index]),
      ),
    );
  }
}