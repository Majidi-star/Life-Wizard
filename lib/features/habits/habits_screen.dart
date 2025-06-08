import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/theme_utils.dart';
import 'habits_bloc.dart';
import 'habits_event.dart';
import 'habits_state.dart';
import 'habits_model.dart';
import 'habits_widgets.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen>
    with WidgetsBindingObserver {
  bool _isVisible = true;
  late final HabitsBloc _habitsBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _habitsBloc = context.read<HabitsBloc>();
    _habitsBloc.add(const LoadHabits());
    _startRefreshIfVisible();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _habitsBloc.add(const StopPeriodicRefresh());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isVisible) {
      _habitsBloc.add(const StartPeriodicRefresh());
    } else if (state == AppLifecycleState.paused) {
      _habitsBloc.add(const StopPeriodicRefresh());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool isCurrentlyVisible = ModalRoute.of(context)?.isCurrent ?? false;
    if (_isVisible != isCurrentlyVisible) {
      _isVisible = isCurrentlyVisible;
      if (_isVisible) {
        _habitsBloc.add(const StartPeriodicRefresh());
      } else {
        _habitsBloc.add(const StopPeriodicRefresh());
      }
    }
  }

  void _startRefreshIfVisible() {
    if (_isVisible) {
      _habitsBloc.add(const StartPeriodicRefresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set context in the bloc for showing points notifications
    context.read<HabitsBloc>().add(SetContext(context: context));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: const Text('Habits'),
        backgroundColor: ThemeUtils.getAppBarColor(context),
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHabitDialog(context),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<HabitsBloc, HabitsState>(
        builder: (context, state) {
          if (state.status == HabitsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.status == HabitsStatus.error) {
            return Center(child: Text('Error: ${state.errorMessage}'));
          } else if (state.habitsModel == null ||
              state.habitsModel!.habits.isEmpty) {
            return const Center(child: Text('No habits found'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: state.habitsModel!.habits.length,
                  itemBuilder: (context, index) {
                    final habit = state.habitsModel!.habits[index];
                    return InkWell(
                      onTap:
                          () => _showHabitDetailsDialog(context, habit, index),
                      child: HabitCard(
                        habit: habit,
                        colorIndex: index % 6, // Cycle through 6 colors
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    context.read<HabitsBloc>().add(const DebugHabitsState());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Debug Habit States'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.primary,
            title: const Text('Add New Habit'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Habit Name',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 2,
                        ),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final description = descriptionController.text.trim();

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Habit name cannot be empty'),
                      ),
                    );
                    return;
                  }

                  context.read<HabitsBloc>().add(
                    AddHabit(name: name, description: description),
                  );

                  Navigator.of(context).pop();
                },
                child: Text(
                  'Add',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showHabitDetailsDialog(
    BuildContext context,
    HabitsCard habit,
    int index,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.primary,
            title: Text(habit.habitName),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    habit.habitDescription.isEmpty
                        ? 'No description provided'
                        : habit.habitDescription,
                  ),
                  const SizedBox(height: 16),
                  Text('Status: ${habit.habitStatus}'),
                  const SizedBox(height: 8),
                  Text(
                    'Progress: ${habit.habitConsecutiveProgress} consecutive, ${habit.habitTotalProgress} total',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showEditHabitDialog(context, habit, index);
                },
                child: Text(
                  'Edit',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showDeleteConfirmation(context, habit);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showEditHabitDialog(BuildContext context, HabitsCard habit, int index) {
    final nameController = TextEditingController(text: habit.habitName);
    final descriptionController = TextEditingController(
      text: habit.habitDescription,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.primary,
            title: const Text('Edit Habit'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Habit Name',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 2,
                        ),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final description = descriptionController.text.trim();

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Habit name cannot be empty'),
                      ),
                    );
                    return;
                  }

                  if (habit.id != null) {
                    context.read<HabitsBloc>().add(
                      UpdateHabit(
                        id: habit.id!,
                        name: name,
                        description: description,
                      ),
                    );
                  }

                  Navigator.of(context).pop();
                },
                child: Text(
                  'Update',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, HabitsCard habit) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.primary,
            title: const Text('Delete Habit'),
            content: Text(
              'Are you sure you want to delete "${habit.habitName}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (habit.id != null) {
                    context.read<HabitsBloc>().add(DeleteHabit(id: habit.id!));
                  }
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
