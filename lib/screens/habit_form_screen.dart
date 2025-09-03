import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';
import '../providers/habit_provider.dart';
import '../providers/auth_provider.dart';

class HabitFormScreen extends StatefulWidget {
  final Habit? habit;

  const HabitFormScreen({super.key, this.habit, required String userId});

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  late String _selectedCategory;
  late HabitFrequency _selectedFrequency;
  DateTime? _selectedStartDate;

  @override
  void initState() {
    super.initState();
    // Initialize form with existing habit data if editing
    if (widget.habit != null) {
      _titleController.text = widget.habit!.title;
      _notesController.text = widget.habit!.notes ?? '';
      _selectedCategory = widget.habit!.categoryId;
      _selectedFrequency = widget.habit!.frequency;
      _selectedStartDate = widget.habit!.startDate;
    } else {
      _selectedCategory = HabitCategory.predefinedCategories.first.id;
      _selectedFrequency = HabitFrequency.daily;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userId = Provider.of<AuthProvider>(context, listen: false).user!.uid;
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);

    final habit = Habit(
      id: widget.habit?.id ?? '',
      title: _titleController.text.trim(),
      categoryId: _selectedCategory,
      frequency: _selectedFrequency,
      startDate: _selectedStartDate,
      notes: _notesController.text.trim(),
      userId: userId,
      createdAt: widget.habit?.createdAt ?? DateTime.now(),
    );

    try {
      print('Saving habit: ${habit.title}'); // Debug log

      if (widget.habit == null) {
        await habitProvider.addHabit(habit);
      } else {
        await habitProvider.updateHabit(habit);
      }
      
      // Check for errors after the operation
      if (habitProvider.error != null) {
        throw Exception(habitProvider.error);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Habit saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error in _saveHabit: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save habit: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit == null ? 'Create Habit' : 'Edit Habit'),
      ),
      body: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Drink 8 glasses of water',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
                items: HabitCategory.predefinedCategories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Row(
                      children: [
                        Icon(category.icon, color: category.color),
                        const SizedBox(width: 8),
                        Text(category.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Frequency Dropdown
              DropdownButtonFormField<HabitFrequency>(
                initialValue: _selectedFrequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                ),
                items: HabitFrequency.values.map((frequency) {
                  return DropdownMenuItem(
                    value: frequency,
                    child: Text(
                      frequency.toString().split('.').last,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFrequency = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Start Date Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start Date (Optional)'),
                subtitle: Text(
                  _selectedStartDate != null
                      ? '${_selectedStartDate!.day}/${_selectedStartDate!.month}/${_selectedStartDate!.year}'
                      : 'Not set',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedStartDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _selectedStartDate = null;
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedStartDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedStartDate = date;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Notes Field
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any additional details',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: habitProvider.isLoading ? null : _saveHabit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: habitProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.habit == null ? 'Create Habit' : 'Update Habit',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
      if (habitProvider.isLoading)
        Container(
          color: Colors.black.withOpacity(0.1),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
    ],
          );
        },
      ),
    );
  }
}
