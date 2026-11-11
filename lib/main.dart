import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database_initializer.dart';
import 'features/ai_chat/ai_chat_bloc.dart';
import 'features/ai_chat/ai_chat_screen.dart';
import 'features/ai_chat/gemini_chat_service.dart';
import 'features/ai_prompting/function_test_screen.dart';
import 'features/goals/goals_bloc.dart';
import 'features/goals/goals_event.dart';
import 'features/goals/goals_screen.dart';
import 'features/habits/habits_bloc.dart';
import 'features/habits/habits_event.dart';
import 'features/habits/habits_screen.dart';
import 'features/mood_data/mood_data_bloc.dart';
import 'features/mood_data/mood_data_event.dart';
import 'features/mood_data/mood_data_screen.dart';
import 'features/pro_clock/pro_clock_bloc.dart';
import 'features/pro_clock/pro_clock_repository.dart';
import 'features/pro_clock/pro_clock_screen.dart';
import 'features/schedule/schedule_bloc.dart';
import 'features/schedule/schedule_screen.dart';
import 'features/settings/settings_bloc.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/settings_state.dart';
import 'features/todo/todo_bloc.dart';
import 'features/todo/todo_screen.dart';
import 'utils/notification_utils.dart';
import 'widgets/loading_screen.dart';

// Global singletons for BLoCs to ensure a single source of truth across the app.
// These are initialized once and then provided via BlocProvider.value.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late SettingsBloc settingsBloc;
late MoodDataBloc moodDataBloc;
late TodoBloc todoBloc;
late HabitsBloc habitsBloc;
late GoalsBloc goalsBloc;
late ProClockBloc proClockBloc;
late ScheduleBloc scheduleBloc;
late AIChatBloc aiChatBloc;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite_ffi for desktop platforms (Windows, Linux, macOS)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final preferences = await SharedPreferences.getInstance();

  // Initialize the database before constructing repositories/BLoCs
  await DatabaseInitializer.database;

  // Await SettingsBloc so repository and secure storage are ready before any event fires
  settingsBloc = await SettingsBloc.create(preferences);
  moodDataBloc = MoodDataBloc();
  todoBloc = TodoBloc();
  habitsBloc = HabitsBloc();
  goalsBloc = GoalsBloc();
  proClockBloc = ProClockBloc();
  scheduleBloc = ScheduleBloc();
  final geminiService = createGeminiChatService(
    apiKey: settingsBloc.state.geminiApiKey,
    model: settingsBloc.state.geminiModel,
  );
  aiChatBloc = AIChatBloc(
    settingsBloc: settingsBloc,
    moodDataBloc: moodDataBloc,
    geminiService: geminiService,
  );

  // Run the main application
  runApp(AppWithNotificationInit(preferences: preferences));
}

class AppWithNotificationInit extends StatefulWidget {
  final SharedPreferences preferences;
  const AppWithNotificationInit({super.key, required this.preferences});

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
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // When app resumes from background, clean up expired notification entries
    if (state == AppLifecycleState.resumed) {
      await NotificationUtils.cleanupOldNotifications();
    }
  }

  Future<void> _initializeApp() async {
    await _initNotifications();
    moodDataBloc.add(LoadMoodQuestions());
    habitsBloc.add(const LoadHabits());
    goalsBloc.add(const LoadGoals());

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initNotifications() async {
    await NotificationUtils.initialize(context);
    final alreadySeeded =
        widget.preferences.getBool('notifications_seeded') ?? false;
    if (!alreadySeeded) {
      await _scheduleNotifications();
      await widget.preferences.setBool('notifications_seeded', true);
    }
  }

  Future<void> _scheduleNotifications() async {
    if (!await NotificationUtils.areNotificationsEnabled()) {
      return;
    }
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      await ProClockRepository().scheduleNotificationsForDate(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: settingsBloc),
        BlocProvider.value(value: moodDataBloc),
        BlocProvider.value(value: todoBloc),
        BlocProvider.value(value: habitsBloc),
        BlocProvider.value(value: goalsBloc),
        BlocProvider.value(value: proClockBloc),
        BlocProvider.value(value: scheduleBloc),
        BlocProvider.value(value: aiChatBloc),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return MaterialApp(
            navigatorKey: navigatorKey,
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
              cardTheme: const CardThemeData(
                surfaceTintColor: Colors.transparent,
              ),
            ),
            builder: (context, child) {
              if (_isLoading) {
                return const LoadingScreen();
              }
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: MediaQuery.of(context).padding.copyWith(
                    top: MediaQuery.of(context).padding.top + 8,
                  ),
                ),
                child: child!,
              );
            },
            routes: {
              '/': (context) => const AIChatScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/todo': (context) => const TodoScreen(),
              '/goals': (context) => const GoalsScreen(),
              '/habits': (context) => const HabitsScreen(),
              '/schedule': (context) => const ScheduleScreen(),
              '/pro_clock': (context) => const ProClockScreen(),
              '/mood': (context) => const MoodDataScreen(),
              if (kDebugMode)
                '/function_test': (context) => const FunctionTestScreen(),
            },
            initialRoute: '/',
          );
        },
      ),
    );
  }
}
