import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/theme_utils.dart';
import '../../main.dart' as main_app;
import 'pro_clock_bloc.dart';
import 'pro_clock_event.dart';
import 'pro_clock_state.dart';
import 'pro_clock_widgets.dart';

class ProClockScreen extends StatefulWidget {
  const ProClockScreen({Key? key}) : super(key: key);

  @override
  State<ProClockScreen> createState() => _ProClockScreenState();
}

class _ProClockScreenState extends State<ProClockScreen> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Reload tasks whenever the screen is displayed
    final bloc = context.read<ProClockBloc>();
    if (!_isInitialized) {
      _isInitialized = true;
    } else {
      // This will be called when returning to this screen
      // Reload today's tasks to get any updates
      bloc.add(LoadTasks(date: bloc.state.selectedDate));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = main_app.settingsBloc.state;
    final textColor =
        settingsState.theme == 'dark' ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pro Clock', style: TextStyle(color: textColor)),
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          // Timer settings button (only for pomodoro mode)
          BlocBuilder<ProClockBloc, ProClockState>(
            builder: (context, state) {
              if (state.timerMode == TimerMode.pomodoro) {
                return IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Timer Settings',
                  onPressed: () => showTimerSettings(context),
                );
              } else {
                return IconButton(
                  icon: const Icon(Icons.calendar_month),
                  tooltip: 'Change Date',
                  onPressed: () => selectDate(context),
                );
              }
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(color: theme.colorScheme.background),
        child: SafeArea(
          child: BlocBuilder<ProClockBloc, ProClockState>(
            builder: (context, state) {
              if (state.isLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: settingsState.activatedColor,
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mode selector (Pomodoro / Schedule)
                  const TimerModeSelector(),

                  // Main content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Circular timer for both modes
                            const CircularTimerDisplay(),

                            // Timer controls for both modes
                            const TimerControls(),

                            const SizedBox(height: 24),

                            // Mode-specific content
                            if (state.timerMode == TimerMode.schedule) ...[
                              // Display current task for schedule mode
                              const TaskDisplay(),

                              const SizedBox(height: 16),

                              // Task navigation controls
                              if (state.tasks.isNotEmpty)
                                const TaskNavigation(),
                            ] else ...[
                              // Display pomodoro info for pomodoro mode
                              // Explicitly handle work/rest phases with a dedicated widget
                              const PomodoroInfo(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
