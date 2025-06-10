import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'features/settings/settings_bloc.dart';
import 'features/settings/settings_event.dart';
import 'features/settings/settings_state.dart';
import 'features/ai_chat/ai_chat_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/todo/todo_screen.dart';
import 'features/goals/goals_screen.dart';
import 'features/habits/habits_screen.dart';
import 'features/schedule/schedule_screen.dart';
import 'features/pro_clock/pro_clock_screen.dart';
import 'features/mood_data/mood_data_screen.dart';
import 'features/mood_data/mood_data_bloc.dart';
import 'features/mood_data/mood_data_event.dart';
import 'features/mood_data/mood_data_state.dart';
import 'features/todo/todo_bloc.dart';
import 'features/habits/habits_bloc.dart';
import 'features/habits/habits_event.dart';
import 'features/goals/goals_bloc.dart';
import 'features/goals/goals_event.dart';
import 'features/goals/goals_state.dart';
import 'database_initializer.dart';
import 'features/schedule/schedule_bloc.dart';
import 'features/pro_clock/pro_clock_bloc.dart';
import 'features/ai_chat/ai_chat_bloc.dart';
import 'features/ai_chat/gemini_chat_service.dart';
import 'features/ai_prompting/function_test_screen.dart';
import 'utils/notification_utils.dart';
import 'features/pro_clock/pro_clock_repository.dart';
import 'widgets/loading_screen.dart';

// Import all test files
import 'features/settings/settings_test.dart' as settings_test;
import 'features/todo/todo_test.dart' as todo_test;
import 'features/habits/habits_test.dart' as habits_test;
import 'features/ai_chat/ai_chat_test.dart' as ai_chat_test;
import 'features/schedule/schedule_test.dart' as schedule_test;
import 'features/pro_clock/pro_clock_test.dart' as pro_clock_test;
import 'features/goals/goals_test.dart' as goals_test;
import 'features/mood_data/mood_data_test.dart' as mood_data_test;
import 'features/logs/logs_test.dart' as logs_test;

// Global singletons for BLoCs to ensure a single source of truth across the app.
// These are initialized once and then provided via BlocProvider.value.
late SettingsBloc settingsBloc;
late MoodDataBloc moodDataBloc;
late TodoBloc todoBloc;
late HabitsBloc habitsBloc;
late GoalsBloc goalsBloc;
late ProClockBloc proClockBloc;
late AIChatBloc aiChatBloc;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite_ffi for Windows desktop support
  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final preferences = await SharedPreferences.getInstance();

  // Initialize the database (consider handling errors here)
  // await DatabaseInitializer.deleteDatabase(); // Uncomment to force recreate with sample data
  await DatabaseInitializer.database; // Ensure the database is initialized

  // Initialize all global BLoC instances
  settingsBloc = SettingsBloc(preferences);
  moodDataBloc = MoodDataBloc();
  todoBloc = TodoBloc();
  habitsBloc = HabitsBloc();
  goalsBloc = GoalsBloc();
  proClockBloc = ProClockBloc();
  final geminiService = createGeminiChatService();
  aiChatBloc = AIChatBloc(geminiService: geminiService);

  // Run state tests if enabled (for development/debugging)
  bool runStateTests = false; // Set to true to see all states printed
  if (runStateTests) {
    print('\n\n=========== FEATURE STATES ===========');
    settings_test.main();
    todo_test.main();
    habits_test.main();
    ai_chat_test.main();
    schedule_test.main();
    pro_clock_test.main();
    goals_test.main();
    mood_data_test.main();
    logs_test.main();
    print('======================================\n\n');
  }

  // Run the main application
  runApp(AppWithNotificationInit(preferences: preferences));
}

class AppWithNotificationInit extends StatefulWidget {
  final SharedPreferences preferences;
  const AppWithNotificationInit({Key? key, required this.preferences})
    : super(key: key);

  @override
  State<AppWithNotificationInit> createState() =>
      _AppWithNotificationInitState();
}

class _AppWithNotificationInitState extends State<AppWithNotificationInit>
    with WidgetsBindingObserver {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes from background, restore notifications
    if (state == AppLifecycleState.resumed) {
      _restoreNotifications();
    }
  }

  Future<void> _initializeApp() async {
    await _initNotifications();
    // Dispatch initial events to BLoCs after notifications are initialized
    // This ensures data is loaded before the UI tries to access it
    settingsBloc.add(LoadSettings());
    moodDataBloc.add(
      LoadMoodQuestions(),
    ); // Assuming LoadMoodQuestions is the correct initial event
    habitsBloc.add(const LoadHabits());
    goalsBloc.add(const LoadGoals());

    // Add a small delay to ensure the loading screen is visible
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initNotifications() async {
    await NotificationUtils.initialize(context);
    await _scheduleNotifications();
  }

  Future<void> _restoreNotifications() async {
    await NotificationUtils.restoreNotifications();
  }

  Future<void> _scheduleNotifications() async {
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      await ProClockRepository().scheduleNotificationsForDate(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The MultiBlocProvider is now the parent of the single MaterialApp
    return MultiBlocProvider(
      providers: [
        // Using BlocProvider.value for globally initialized BLoCs
        BlocProvider.value(value: settingsBloc),
        BlocProvider.value(value: moodDataBloc),
        BlocProvider.value(value: todoBloc),
        BlocProvider.value(value: habitsBloc),
        BlocProvider.value(value: goalsBloc),
        BlocProvider.value(value: proClockBloc),
        BlocProvider.value(value: aiChatBloc),
        // ScheduleBloc is created here if it doesn't need to be global
        BlocProvider<ScheduleBloc>(create: (context) => ScheduleBloc()),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          // This MaterialApp uses the theme from SettingsBloc
          return MaterialApp(
            title: 'Life Wizard',
            // Apply theme directly from SettingsState
            theme: ThemeData(
              primaryColor: state.primaryColor,
              colorScheme: ColorScheme(
                brightness:
                    state.theme == 'dark' ? Brightness.dark : Brightness.light,
                primary: state.primaryColor,
                onPrimary: Colors.white,
                secondary: state.secondaryColor,
                onSecondary: Colors.white,
                tertiary: state.thirdlyColor,
                onTertiary: Colors.black,
                surfaceTint: state.fourthlyColor,
                error: Colors.red,
                onError: Colors.white,
                surface:
                    state.theme == 'dark'
                        ? Colors.grey[900]!
                        : Colors.grey[100]!,
                onSurface: state.theme == 'dark' ? Colors.white : Colors.black,
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: state.thirdlyColor,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
              ),
              cardColor: state.fourthlyColor,
              cardTheme: const CardTheme(surfaceTintColor: Colors.transparent),
              // You can add more theme properties here as needed
            ),
            // The `builder` function is used for global media query adjustments
            builder: (context, child) {
              if (_isLoading) {
                return const LoadingScreen();
              }
              // This ensures the top padding is applied to all screens
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: MediaQuery.of(context).padding.copyWith(
                    top: MediaQuery.of(context).padding.top + 8,
                  ),
                ),
                child: child!,
              );
            },
            // Define all your routes
            routes: {
              '/': (context) => const AIChatScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/todo': (context) => const TodoScreen(),
              '/goals': (context) => const GoalsScreen(),
              '/habits': (context) => const HabitsScreen(),
              '/schedule': (context) => const ScheduleScreen(),
              '/pro_clock': (context) => const ProClockScreen(),
              '/mood': (context) => const MoodDataScreen(),
              '/function_test': (context) => const FunctionTestScreen(),
            },
            initialRoute: '/',
          );
        },
      ),
    );
  }
}

// Helper function to print the current state of a specific feature
// This can be called from anywhere in your app for debugging
Future<void> printFeatureState(String feature) async {
  print('\n===== Printing $feature State =====');
  switch (feature.toLowerCase()) {
    case 'settings':
      final state = settingsBloc.state;
      print('Theme: ${state.theme}');
      print('Language: ${state.language}');
      print('Notifications: ${state.notifications}');
      print('Mood Tracking: ${state.moodTracking}');
      print('Feedback Frequency: ${state.feedbackFrequency}');
      print('AI Guidelines: ${state.aiGuideLines}');
      print(
        'Gemini API Key: ${state.geminiApiKey.isEmpty ? "(Not set)" : "********"}',
      );
      print('Calculated Colors:');
      print('  primaryColor: ${state.primaryColor}');
      print('  secondaryColor: ${state.secondaryColor}');
      print('  thirdlyColor: ${state.thirdlyColor}');
      print('  fourthlyColor: ${state.fourthlyColor}');
      break;
    case 'todo':
      final state = todoBloc.state;
      print('===== TODO STATE =====');
      print('Total Todos: ${state.todos.length}');
      if (state.todos.isNotEmpty) {
        print('\nTodos:');
        for (var i = 0; i < state.todos.length; i++) {
          final todo = state.todos[i];
          print('\nTodo ${i + 1}:');
          print('  ID: ${todo.id}');
          print('  Name: ${todo.todoName}');
          print(
            '  Description: ${todo.todoDescription.isEmpty ? 'N/A' : todo.todoDescription}',
          );
          print('  Status: ${todo.todoStatus ? 'Completed' : 'Not Completed'}');
          print('  Created At: ${todo.todoCreatedAt}');
          print('  Priority: ${todo.priority}');
        }
      } else {
        print('No todos found.');
      }
      break;
    case 'habits':
      habits_test
          .main(); // This is calling a test function, not the actual bloc state directly.
      break;
    case 'ai_chat':
      ai_chat_test
          .main(); // This is calling a test function, not the actual bloc state directly.
      break;
    case 'schedule':
      schedule_test
          .main(); // This is calling a test function, not the actual bloc state directly.
      break;
    case 'pro_clock':
      final state = proClockBloc.state;
      print('===== PRO CLOCK STATE =====');
      print('Selected Date: ${state.selectedDate}');
      print('Timer Mode: ${state.timerMode}');
      print('Timer Status: ${state.timerStatus}');
      print('Remaining Time: ${state.timerDisplay}');
      print('Phase: ${state.phaseDisplay}');
      print('Is Work Phase: ${state.isWorkPhase}');
      print('Pomodoro Count: ${state.pomodoroCount}');
      print('Work Minutes: ${state.workMinutes}');
      print('Rest Minutes: ${state.restMinutes}');
      print('\nTasks (${state.tasks.length}):');
      for (int i = 0; i < state.tasks.length; i++) {
        final task = state.tasks[i];
        print('  Task $i:');
        print('    Name: ${task.currentTask}');
        print('    Description: ${task.currentTaskDescription}');
        print('    Notes: ${task.currentTaskNotes}');
        print('    Todos: ${task.currentTaskTodos.join(', ')}');
        print(
          '    Status: ${task.currentTaskStatus ? 'Completed' : 'Not Completed'}',
        );
      }
      print('Current Task Index: ${state.currentTaskIndex}');
      break;
    case 'goals':
      final state = goalsBloc.state;
      print('===== GOALS STATE =====');
      if (state is GoalsLoaded) {
        print('Goals count: ${state.goalsModel.goals.length}');
        print('Selected Goal Index: ${state.selectedGoalIndex}');
        print('Expanded Goals: ${state.expandedGoals}');
        if (state.goalsModel.goals.isNotEmpty) {
          for (int i = 0; i < state.goalsModel.goals.length; i++) {
            final goal = state.goalsModel.goals[i];
            print('\nGoal $i:');
            print('  Name: ${goal.goalName}');
            print('  Description: ${goal.goalDescription}');
            print('  Progress: ${goal.goalProgress}%');
            print('  Priority: ${goal.priority}');
            print(
              '  Scores: ${goal.startingScore} → ${goal.currentScore} → ${goal.futureScore}',
            );
          }
        }
      } else if (state is GoalsLoading) {
        print('Goals are currently loading...');
      } else if (state is GoalsError) {
        print('Goals error: ${state.message}');
      } else {
        print('Goals state: ${state.runtimeType}');
      }
      break;
    case 'mood_data':
      final state = moodDataBloc.state;
      print('===== MOOD DATA STATE =====');
      print('Questions: ${state.questions.length}');
      for (final question in state.questions) {
        print('  - ${question.question} (ID: ${question.id})');
        if (question.type == QuestionType.selection) {
          print('    Options: ${question.options.join(', ')}');
        } else {
          print('    Type: Text Input');
        }
      }
      print('Responses: ${state.responses}');
      for (final entry in state.responses.entries) {
        final questionId = entry.key;
        final question = state.questions.firstWhere(
          (q) => q.id == questionId,
          orElse:
              () => const MoodQuestion(
                id: 'unknown',
                question: 'Unknown',
                options: [],
              ),
        );
        if (question.id != 'unknown') {
          print('  - ${question.question}: ${entry.value}');
        }
      }
      print('\nDatabase Persistence Status:');
      try {
        final repo = await DatabaseInitializer.moodRepository;
        final allMoodData = await repo.getAllMoodData();
        if (allMoodData != null && allMoodData.isNotEmpty) {
          final moodData = allMoodData.first;
          print('  Database ID: ${moodData.id}');
          print('  Questions in DB: ${moodData.questions}');
          print('  Answers in DB: ${moodData.answers}');
        } else {
          print('  No mood data found in database');
        }
      } catch (e) {
        print('  Error accessing database: $e');
      }
      break;
    case 'logs':
      logs_test
          .main(); // This is calling a test function, not the actual bloc state directly.
      break;
    default:
      print('Feature not found: $feature');
  }
  print('================================\n');
}
