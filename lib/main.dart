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
import 'features/progress_dashboard/progress_dashboard_screen.dart';
import 'features/pro_clock/pro_clock_screen.dart';
import 'features/mood_data/mood_data_screen.dart';
import 'database_initializer.dart';

// import 'features/settings/settings_repository.dart';
// import 'features/goals/goals_repository.dart';
// import 'features/habits/habits_repository.dart';
// import 'features/logs/logs_repository.dart';
// import 'features/Mood_data/Mood_data_repository.dart';
// import 'features/schedule/schedule_repository.dart';
// import 'features/settings/settings_repository.dart';
// import 'features/todo/todo_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  // Initialize the database
  // await DatabaseInitializer.deleteDatabase(); //////////////////////////////// Removing the database
  // final db = await DatabaseInitializer.database;

  // await testSettingsRepository();

  // When you're done with the database
  // await DatabaseInitializer.closeDatabase(); ///////////////////////////////// Closing the database

  runApp(MyApp(preferences: preferences));
}

class MyApp extends StatelessWidget {
  final SharedPreferences preferences;

  const MyApp({Key? key, required this.preferences}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc(preferences)..add(LoadSettings()),
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Life Wizard',
            theme: ThemeData(
              primaryColor: state.primaryColor,
              colorScheme: ColorScheme.fromSeed(
                seedColor: state.primaryColor,
                secondary: state.secondaryColor,
                tertiary: state.thirdlyColor,
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
              '/progress': (context) => const ProgressDashboardScreen(),
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
