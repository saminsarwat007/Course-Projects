import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:agrothink/models/todo_item_model.dart';
import 'package:agrothink/providers/auth_provider.dart';
import 'package:agrothink/providers/todo_provider.dart';
import 'package:agrothink/config/theme.dart';
import 'package:agrothink/widgets/custom_app_bar.dart';
import 'package:agrothink/models/saved_guide_model.dart';
import 'package:agrothink/providers/saved_guides_provider.dart';
import 'package:table_calendar/table_calendar.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({Key? key}) : super(key: key);

  static const String routeName = '/user/todo-list';

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<TodoItemModel> _selectedDayTodos = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TodoProvider>(
        context,
        listen: false,
      ).addListener(_showConfirmationDialogListener);
    });
  }

  @override
  void dispose() {
    Provider.of<TodoProvider>(
      context,
      listen: false,
    ).removeListener(_showConfirmationDialogListener);
    super.dispose();
  }

  void _showConfirmationDialogListener() {
    final provider = Provider.of<TodoProvider>(context, listen: false);
    if (provider.generationStatus == TodoGenerationStatus.success &&
        provider.generatedTasks.isNotEmpty) {
      _showConfirmationDialog(context, provider.generatedTasks);
    } else if (provider.generationStatus == TodoGenerationStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating tasks: ${provider.generationError}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  List<TodoItemModel> _getTodosForDay(DateTime day, List<TodoItemModel> todos) {
    return todos.where((todo) => isSameDay(todo.dueDate, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'My Farming Tasks'),
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<TodoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.todos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredTodos = provider.filteredTodos;
          _selectedDayTodos = _getTodosForDay(_selectedDay!, filteredTodos);

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(8.0),
                elevation: 2.0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      _buildGuideFilterDropdown(context),
                      TableCalendar<TodoItemModel>(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate:
                            (day) => isSameDay(_selectedDay, day),
                        onDaySelected: _onDaySelected,
                        eventLoader:
                            (day) => _getTodosForDay(day, filteredTodos),
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          // Use calendarBuilders for custom markers
                          markerDecoration: const BoxDecoration(
                            color: AppTheme.accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, day, events) {
                            if (events.isNotEmpty) {
                              return Positioned(
                                right: 1,
                                bottom: 1,
                                child: _buildEventsMarker(),
                              );
                            }
                            return null;
                          },
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildTodoList(_selectedDayTodos)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventsMarker() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.accentColor,
      ),
      width: 7.0,
      height: 7.0,
    );
  }

  Widget _buildGuideFilterDropdown(BuildContext context) {
    final guideProvider = Provider.of<SavedGuidesProvider>(context);
    final todoProvider = Provider.of<TodoProvider>(context);

    if (guideProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Text("Loading guides..."),
      );
    }

    final validGuideIds = guideProvider.guides.map((g) => g.id).toSet();
    final String? selectedValue =
        validGuideIds.contains(todoProvider.selectedGuideId)
            ? todoProvider.selectedGuideId
            : null;

    if (selectedValue == null && todoProvider.selectedGuideId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<TodoProvider>(context, listen: false).filterByGuide(null);
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: DropdownButtonFormField<String?>(
        value: selectedValue,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        hint: const Text("Filter by Guide"),
        isExpanded: true,
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text("All Tasks"),
          ),
          ...guideProvider.guides.map((guide) {
            return DropdownMenuItem<String?>(
              value: guide.id,
              child: Text(guide.seedName),
            );
          }).toList(),
        ],
        onChanged: (String? newValue) {
          Provider.of<TodoProvider>(
            context,
            listen: false,
          ).filterByGuide(newValue);
        },
      ),
    );
  }

  Widget _buildTodoList(List<TodoItemModel> todos) {
    if (todos.isEmpty) {
      return const Center(child: Text('No tasks for this day.'));
    }

    final todoProvider = Provider.of<TodoProvider>(context, listen: false);

    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: CheckboxListTile(
            title: Text(todo.title),
            subtitle: Text(
              DateFormat('h:mm a').format(todo.dueDate),
            ), // Show time
            value: todo.isCompleted,
            onChanged: (bool? value) {
              todoProvider.updateTodoStatus(todo.id, value ?? false);
            },
            secondary: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppTheme.errorColor,
              ),
              onPressed: () => todoProvider.deleteTodo(todo.id),
            ),
          ),
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Pass the selected day to the dialog
        return AddTaskDialog(selectedDate: _selectedDay);
      },
    );
  }

  void _showConfirmationDialog(
    BuildContext context,
    List<TodoItemModel> tasks,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final todoProvider = Provider.of<TodoProvider>(
          dialogContext,
          listen: false,
        );
        return AlertDialog(
          title: const Text('Generated Tasks'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ListTile(
                  title: Text(task.title),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(task.dueDate)),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Discard'),
              onPressed: () {
                todoProvider.clearGeneratedTodos();
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Add to My List'),
              onPressed: () {
                todoProvider.addMultipleTodos(tasks);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class AddTaskDialog extends StatefulWidget {
  final DateTime? selectedDate;
  const AddTaskDialog({Key? key, this.selectedDate}) : super(key: key);

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  bool _isManual = true;
  SavedGuideModel? _selectedGuide;

  final TextEditingController _titleController = TextEditingController();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context);

    return AlertDialog(
      title: const Text('Add a New Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Manual')),
                ButtonSegment(value: false, label: Text('From Guide')),
              ],
              selected: {_isManual},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _isManual = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 20),
            if (_isManual) _buildManualEntry(context), // Pass context
            if (!_isManual) _buildGuideGenerator(),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child:
              todoProvider.generationStatus == TodoGenerationStatus.loading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Add Task'),
          onPressed:
              todoProvider.generationStatus == TodoGenerationStatus.loading
                  ? null
                  : _handleSubmit,
        ),
      ],
    );
  }

  void _handleSubmit() async {
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);

    if (_isManual) {
      if (_titleController.text.isNotEmpty) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.user;
        if (user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: You must be logged in to add tasks.'),
              ),
            );
          }
          return;
        }

        final newTodo = TodoItemModel(
          id: '',
          userId: user.uid,
          title: _titleController.text,
          dueDate: _selectedDate,
        );

        try {
          await todoProvider.addTodo(newTodo);
          if (mounted) Navigator.of(context).pop();
        } catch (e) {
          print('Error adding task: $e');
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Failed to add task: $e')));
          }
        }
      }
    } else {
      if (_selectedGuide != null) {
        // Close the dialog first, then start generation
        if (mounted) Navigator.of(context).pop();
        await todoProvider.generateTodosFromGuide(_selectedGuide!);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a guide first.')),
          );
        }
      }
    }
  }

  Widget _buildManualEntry(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Task Title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        ListTile(
          title: Text('Date: ${DateFormat.yMd().format(_selectedDate)}'),
          trailing: const Icon(Icons.calendar_today),
          onTap: _pickDate,
        ),
        ListTile(
          title: Text('Time: ${DateFormat.jm().format(_selectedDate)}'),
          trailing: const Icon(Icons.access_time),
          onTap: _pickTime,
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Widget _buildGuideGenerator() {
    return ChangeNotifierProvider(
      create:
          (context) => SavedGuidesProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
      child: Consumer<SavedGuidesProvider>(
        builder: (context, guideProvider, child) {
          if (guideProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (guideProvider.guides.isEmpty) {
            return const Text(
              'You have no saved guides to generate tasks from.',
            );
          }
          return DropdownButtonFormField<SavedGuideModel>(
            value: _selectedGuide,
            hint: const Text('Select a Saved Guide'),
            isExpanded: true,
            items:
                guideProvider.guides.map((guide) {
                  return DropdownMenuItem(
                    value: guide,
                    child: Text(guide.seedName),
                  );
                }).toList(),
            onChanged: (guide) {
              setState(() {
                _selectedGuide = guide;
              });
            },
          );
        },
      ),
    );
  }
}
