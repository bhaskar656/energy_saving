import 'package:energy_saving/models/appliance.dart';
import 'package:energy_saving/repositories/appliance_repository.dart';
import 'package:flutter/material.dart';

class ApplianceFormScreen extends StatefulWidget {
  const ApplianceFormScreen({
    super.key,
    required this.userId,
    required this.repository,
    this.appliance,
  });

  final int userId;
  final ApplianceRepository repository;
  final Appliance? appliance;

  @override
  State<ApplianceFormScreen> createState() => _ApplianceFormScreenState();
}

class _ApplianceFormScreenState extends State<ApplianceFormScreen> {
  static const _categories = [
    'Lighting',
    'Cooling',
    'Kitchen',
    'Electronics',
    'General',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _powerController;
  late final TextEditingController _hoursController;
  late String _selectedCategory;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.appliance != null;

  List<String> get _categoryOptions {
    final existingCategory = widget.appliance?.category;
    if (existingCategory != null && !_categories.contains(existingCategory)) {
      return [..._categories, existingCategory];
    }
    return _categories;
  }

  @override
  void initState() {
    super.initState();
    final appliance = widget.appliance;
    _nameController = TextEditingController(text: appliance?.name ?? '');
    _powerController = TextEditingController(
      text: appliance == null ? '' : _formatInitialValue(appliance.powerWatts),
    );
    _hoursController = TextEditingController(
      text: appliance == null ? '' : _formatInitialValue(appliance.averageHours),
    );
    _selectedCategory = _categories.contains(appliance?.category)
        ? appliance!.category
        : _categories.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _powerController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  String _formatInitialValue(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter an appliance name.';
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final existing = widget.appliance;
    final appliance = Appliance(
      id: existing?.id,
      userId: widget.userId,
      name: _nameController.text.trim(),
      category: _selectedCategory,
      powerWatts: double.parse(_powerController.text.trim()),
      averageHours: double.parse(_hoursController.text.trim()),
      isActive: existing?.isActive ?? true,
    );

    try {
      if (existing == null) {
        await widget.repository.insert(appliance);
      } else {
        final updated = await widget.repository.update(appliance);
        if (updated != 1) throw StateError('Appliance no longer exists.');
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Appliance could not be saved. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
      title: Row(
        children: [
          const Icon(Icons.electrical_services_rounded, size: 22),
          const SizedBox(width: 10),
          Text(_isEditing ? 'Edit appliance' : 'Add appliance'),
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
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      labelText: 'Appliance name',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateName,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: _categoryOptions
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: _isSaving
                        ? null
                        : (category) {
                            if (category != null) {
                              setState(() => _selectedCategory = category);
                            }
                          },
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
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _hoursController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Average daily use',
                      suffixText: 'hours',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateHours,
                    onFieldSubmitted: (_) => _save(),
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
                    label: Text(_isEditing ? 'Save changes' : 'Add appliance'),
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