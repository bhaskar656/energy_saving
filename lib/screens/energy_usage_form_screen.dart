import 'package:energy_saving/models/energy_usage.dart';
import 'package:energy_saving/repositories/energy_usage_repository.dart';
import 'package:energy_saving/services/energy_calculator.dart';
import 'package:flutter/material.dart';

class EnergyUsageFormScreen extends StatefulWidget {
  const EnergyUsageFormScreen({
    super.key,
    required this.userId,
    required this.repository,
    this.usage,
  });

  final int userId;
  final EnergyUsageRepository repository;
  final EnergyUsage? usage;

  @override
  State<EnergyUsageFormScreen> createState() => _EnergyUsageFormScreenState();
}

class _EnergyUsageFormScreenState extends State<EnergyUsageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _applianceController = TextEditingController();
  final _powerController = TextEditingController();
  final _hoursController = TextEditingController();
  final _calculator = const EnergyCalculator();
  late DateTime _usageDate;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.usage != null;

  @override
  void initState() {
    super.initState();
    final usage = widget.usage;
    _applianceController.text = usage?.appliance ?? '';
    _powerController.text = usage == null ? '' : _formatNumber(usage.powerWatts);
    _hoursController.text = usage == null ? '' : _formatNumber(usage.hoursUsed);
    _usageDate = usage?.usageDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _applianceController.dispose();
    _powerController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  String? _validateAppliance(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter an appliance.';
    return null;
  }

  String? _validatePower(String? value) {
    final power = double.tryParse(value?.trim() ?? '');
    if (power == null || !power.isFinite || power <= 0) {
      return 'Enter a power value greater than 0 W.';
    }
    return null;
  }

  String? _validateHours(String? value) {
    final hours = double.tryParse(value?.trim() ?? '');
    if (hours == null || !hours.isFinite || hours < 0 || hours > 24) {
      return 'Enter daily hours from 0 to 24.';
    }
    return null;
  }

  double? get _previewKwh {
    final power = double.tryParse(_powerController.text.trim());
    final hours = double.tryParse(_hoursController.text.trim());
    if (power == null || hours == null || power <= 0 || hours < 0 || hours > 24) {
      return null;
    }
    try {
      return _calculator
          .calculate(powerWatts: power, hoursPerDay: hours, tariffPerKwh: 0)
          .dailyKwh;
    } on ArgumentError {
      return null;
    }
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final initialDate = _usageDate.isAfter(today) ? today : _usageDate;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (selectedDate != null && mounted) {
      setState(() => _usageDate = DateUtils.dateOnly(selectedDate));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final existing = widget.usage;
    final power = double.parse(_powerController.text.trim());
    final hours = double.parse(_hoursController.text.trim());
    final usage = EnergyUsage(
      id: existing?.id,
      userId: widget.userId,
      appliance: _applianceController.text.trim(),
      usageDate: DateUtils.dateOnly(_usageDate),
      unitsKwh: _calculator
          .calculate(powerWatts: power, hoursPerDay: hours, tariffPerKwh: 0)
          .dailyKwh,
      hoursUsed: hours,
      powerWatts: power,
      createdAt: existing?.createdAt,
    );

    try {
      if (existing == null) {
        await widget.repository.insert(usage);
      } else {
        final updated = await widget.repository.update(usage);
        if (updated != 1) throw StateError('Usage record no longer exists.');
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Usage record could not be saved. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final previewKwh = _previewKwh;

    return Scaffold(
      appBar: AppBar(
      title: Row(
        children: [
          const Icon(Icons.bolt_rounded, size: 22),
          const SizedBox(width: 10),
          Text(_isEditing ? 'Edit usage' : 'Add usage'),
        ],
      ),
    ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  TextFormField(
                    controller: _applianceController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Appliance',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateAppliance,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      'Usage date · ${MaterialLocalizations.of(context).formatMediumDate(_usageDate)}',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _powerController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Power consumption',
                      suffixText: 'W',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validatePower,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _hoursController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Hours used',
                      suffixText: 'hours',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateHours,
                    onChanged: (_) => setState(() {}),
                    onFieldSubmitted: (_) => _save(),
                  ),
                  if (previewKwh != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Calculated energy: ${previewKwh.toStringAsFixed(2)} kWh',
                        style: textTheme.titleMedium,
                      ),
                    ),
                  ],
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
                    label: Text(_isEditing ? 'Save changes' : 'Add usage'),
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