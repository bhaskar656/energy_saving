import 'package:energy_saving/models/energy_goal.dart';
import 'package:energy_saving/repositories/energy_goal_repository.dart';
import 'package:flutter/material.dart';

class EnergyGoalFormScreen extends StatefulWidget {
  const EnergyGoalFormScreen({
    super.key,
    required this.userId,
    required this.repository,
    this.goal,
  });

  final int userId;
  final EnergyGoalRepository repository;
  final EnergyGoal? goal;

  @override
  State<EnergyGoalFormScreen> createState() => _EnergyGoalFormScreenState();
}

class _EnergyGoalFormScreenState extends State<EnergyGoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _targetController;
  late final TextEditingController _savingTargetController;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _targetController = TextEditingController(
      text: goal == null ? '' : _formatNumber(goal.monthlyTargetKwh),
    );
    _savingTargetController = TextEditingController(
      text: goal == null ? '' : _formatNumber(goal.monthlySavingTarget),
    );
  }

  @override
  void dispose() {
    _targetController.dispose();
    _savingTargetController.dispose();
    super.dispose();
  }

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  String? _validateMonthlyTarget(String? value) {
    final target = double.tryParse(value?.trim() ?? '');
    if (target == null || !target.isFinite || target <= 0) {
      return 'Enter a monthly target greater than 0 kWh.';
    }
    return null;
  }

  String? _validateSavingTarget(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final target = double.tryParse(value.trim());
    if (target == null || !target.isFinite || target < 0) {
      return 'Enter 0 or more kWh.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final existing = widget.goal;
    try {
      await widget.repository.saveForUser(
        EnergyGoal(
          id: existing?.id,
          userId: widget.userId,
          monthlyTargetKwh: double.parse(_targetController.text.trim()),
          monthlySavingTarget: double.tryParse(
                _savingTargetController.text.trim(),
              ) ??
              0,
          createdAt: existing?.createdAt,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Monthly goal could not be saved. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
      title: Row(
        children: [
          const Icon(Icons.flag_rounded, size: 22),
          const SizedBox(width: 10),
          Text(_isEditing ? 'Edit monthly goal' : 'Set monthly goal'),
        ],
      ),
    ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  TextFormField(
                    controller: _targetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Monthly energy use target',
                      suffixText: 'kWh',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateMonthlyTarget,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _savingTargetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Monthly saving aim (optional)',
                      suffixText: 'kWh',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateSavingTarget,
                    onFieldSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The saving aim is a target, not a measured saving.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 20),
                    label: Text(_isEditing ? 'Save changes' : 'Set goal'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}