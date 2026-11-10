import 'package:energy_saving/models/reminder.dart';
import 'package:energy_saving/repositories/reminder_repository.dart';
import 'package:flutter/material.dart';

class ReminderFormScreen extends StatefulWidget {
  const ReminderFormScreen({
    super.key,
    required this.userId,
    required this.repository,
    this.reminder,
  });

  final int userId;
  final ReminderRepository repository;
  final Reminder? reminder;

  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _applianceController;
  late final TextEditingController _descriptionController;
  late TimeOfDay _selectedTime;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    _titleController = TextEditingController(text: reminder?.title ?? '');
    _applianceController = TextEditingController(
      text: reminder?.appliance ?? '',
    );
    _descriptionController = TextEditingController(
      text: reminder?.description ?? '',
    );
    final initialTime = reminder?.reminderTime ?? DateTime.now().add(
      const Duration(hours: 1),
    );
    _selectedTime = TimeOfDay.fromDateTime(initialTime);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _applianceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (selectedTime != null && mounted) {
      setState(() => _selectedTime = selectedTime);
    }
  }

  DateTime _nextOccurrence(TimeOfDay time) {
    final now = DateTime.now();
    final todayAtSelectedTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    return todayAtSelectedTime.isBefore(now)
        ? todayAtSelectedTime.add(const Duration(days: 1))
        : todayAtSelectedTime;
  }

  String? _requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return 'Enter $fieldName.';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final existing = widget.reminder;
    final reminder = Reminder(
      id: existing?.id,
      userId: widget.userId,
      title: _titleController.text.trim(),
      appliance: _applianceController.text.trim(),
      description: _descriptionController.text.trim(),
      reminderTime: _nextOccurrence(_selectedTime),
      isEnabled: existing?.isEnabled ?? true,
      createdAt: existing?.createdAt,
    );

    try {
      if (existing == null) {
        await widget.repository.insert(reminder);
      } else {
        final updated = await widget.repository.update(reminder);
        if (updated != 1) throw StateError('Reminder no longer exists.');
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Reminder could not be saved. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final formattedTime = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(_selectedTime);

    return Scaffold(
      appBar: AppBar(
      title: Row(
        children: [
          const Icon(Icons.alarm_rounded, size: 22),
          const SizedBox(width: 10),
          Text(_isEditing ? 'Edit reminder' : 'Add reminder'),
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
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => _requiredField(value, 'a title'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _applianceController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Appliance',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => _requiredField(
                      value,
                      'an appliance',
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text('Reminder time · $formattedTime'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 240,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 20),
                    label: Text(_isEditing ? 'Save changes' : 'Add reminder'),
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