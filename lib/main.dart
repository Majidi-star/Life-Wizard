import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

// Global singleton for SettingsBloc to ensure single source of truth
late SettingsBloc settingsBloc;
// Global singleton for MoodDataBloc to ensure single source of truth
late MoodDataBloc moodDataBloc;
// Global singleton for TodoBloc to ensure single source of truth
late TodoBloc todoBloc;
// Global singleton for HabitsBloc to ensure single source of truth
late HabitsBloc habitsBloc;
// Global singleton for GoalsBloc to ensure single source of truth
late GoalsBloc goalsBloc;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();

  // Initialize the database
  // await DatabaseInitializer.deleteDatabase(); // Force recreate with sample data
  final db = await DatabaseInitializer.database;

  // Create a single SettingsBloc instance that will be used throughout the app
  settingsBloc = SettingsBloc(preferences);

  // Create a single MoodDataBloc instance that will be used throughout the app
  moodDataBloc = MoodDataBloc();

  // Create a single TodoBloc instance that will be used throughout the app
  todoBloc = TodoBloc();

  // Create a single HabitsBloc instance that will be used throughout the app
  habitsBloc = HabitsBloc();

  // Create a single GoalsBloc instance that will be used throughout the app
  goalsBloc = GoalsBloc();

  // Run state tests and print their output
  // Set this to true to see all states printed in the console
  bool runStateTests = true;
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

  // Don't close the database here, as it will be needed by the app
  // Database will be closed automatically when app terminates

  runApp(MyApp(preferences: preferences));
}

class MyApp extends StatelessWidget {
  final SharedPreferences preferences;

  const MyApp({Key? key, required this.preferences}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: settingsBloc..add(LoadSettings())),
        BlocProvider.value(value: moodDataBloc),
        BlocProvider.value(value: todoBloc),
        BlocProvider.value(value: habitsBloc..add(const LoadHabits())),
        BlocProvider.value(value: goalsBloc..add(const LoadGoals())),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Life Wizard',
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
                background: state.theme == 'dark' ? Colors.black : Colors.white,
                onBackground:
                    state.theme == 'dark' ? Colors.white : Colors.black,
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
              cardTheme: CardTheme(surfaceTintColor: Colors.transparent),

              // Configure radio buttons
              radioTheme: RadioThemeData(
                fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return state.secondaryColor; // Active color
                  }
                  return state.fourthlyColor; // Inactive color
                }),
              ),

              // Configure switches
              switchTheme: SwitchThemeData(
                thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return state.secondaryColor; // Active color
                  }
                  return state.fourthlyColor; // Inactive color
                }),
                trackColor: MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return state.secondaryColor.withOpacity(
                      0.5,
                    ); // Active track
                  }
                  return state.fourthlyColor.withOpacity(0.5); // Inactive track
                }),
              ),

              // Configure checkboxes
              checkboxTheme: CheckboxThemeData(
                fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return state.secondaryColor; // Active color
                  }
                  return state.fourthlyColor; // Inactive color
                }),
              ),

              // Configure sliders
              sliderTheme: SliderThemeData(
                activeTrackColor: state.secondaryColor,
                inactiveTrackColor: state.fourthlyColor,
                thumbColor: state.secondaryColor,
                overlayColor: state.secondaryColor.withOpacity(0.3),
              ),

              // Configure dropdown buttons
              dropdownMenuTheme: DropdownMenuThemeData(
                menuStyle: MenuStyle(
                  backgroundColor: MaterialStatePropertyAll(state.primaryColor),
                ),
              ),

              // Configure text form fields
              inputDecorationTheme: InputDecorationTheme(
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: state.secondaryColor, width: 2),
                ),
                border: const OutlineInputBorder(),
              ),

              // Configure elevated buttons
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.secondaryColor,
                  foregroundColor: Colors.white,
                ),
              ),

              useMaterial3: true,
            ),
            routes: {
              '/': (context) => const AIChatScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/todo': (context) => const TodoScreen(),
              '/goals': (context) => const GoalsScreen(),
              '/habits': (context) => const HabitsScreen(),
              '/schedule': (context) => const ScheduleScreen(),
              '/pro_clock': (context) => const ProClockScreen(),
              '/mood': (context) => const MoodDataScreen(),
            },
            initialRoute: '/',
          );
        },
      ),
    );
  }
}

// Helper function to print the current state of a specific feature
// This can be called from anywhere in your app
Future<void> printFeatureState(String feature) async {
  print('\n===== Printing $feature State =====');
  switch (feature.toLowerCase()) {
    case 'settings':
      // Use the actual settingsBloc state instead of creating a new test state
      final state = settingsBloc.state;
      print('Theme: ${state.theme}');
      print('Language: ${state.language}');
      print('Notifications: ${state.notifications}');
      print('Mood Tracking: ${state.moodTracking}');
      print('Feedback Frequency: ${state.feedbackFrequency}');
      print('AI Guidelines: ${state.aiGuideLines}');
      print('Calculated Colors:');
      print('  primaryColor: ${state.primaryColor}');
      print('  secondaryColor: ${state.secondaryColor}');
      print('  thirdlyColor: ${state.thirdlyColor}');
      print('  fourthlyColor: ${state.fourthlyColor}');
      break;
    case 'todo':
      // Use the actual todoBloc state instead of running the test
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
      habits_test.main();
      break;
    case 'ai_chat':
      ai_chat_test.main();
      break;
    case 'schedule':
      schedule_test.main();
      break;
    case 'pro_clock':
      pro_clock_test.main();
      break;
    case 'goals':
      // Use the actual goalsBloc state instead of running the test
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
      // Use the actual moodDataBloc state instead of running the test
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

      // Add database persistence status
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
      logs_test.main();
      break;
    default:
      print('Feature not found: $feature');
  }
  print('================================\n');
}
