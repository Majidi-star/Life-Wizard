import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/settings/settings_bloc.dart';
import '../../features/settings/settings_state.dart';
import 'pro_clock_bloc.dart';
import 'pro_clock_event.dart';
import 'pro_clock_state.dart';
import 'pro_clock_model.dart';
import '../../main.dart' as main_app;
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

/// Widget for selecting between Schedule and Pomodoro mode
class TimerModeSelector extends StatelessWidget {
  const TimerModeSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = main_app.settingsBloc.state;

    return BlocBuilder<ProClockBloc, ProClockState>(
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildModeButton(
                context,
                'Schedule',
                Icons.calendar_today,
                state.timerMode == TimerMode.schedule,
                () => context.read<ProClockBloc>().add(
                  const ChangeTimerMode(mode: TimerMode.schedule),
                ),
              ),
              _buildModeButton(
                context,
                'Pomodoro',
                Icons.timer,
                state.timerMode == TimerMode.pomodoro,
                () => context.read<ProClockBloc>().add(
                  const ChangeTimerMode(mode: TimerMode.pomodoro),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeButton(
    BuildContext context,
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final settingsState = main_app.settingsBloc.state;

    // Use activatedColor for selected state
    final color =
        isSelected ? settingsState.activatedColor : Colors.transparent;

    // Adapt text color to theme mode
    final textColor =
        isSelected
            ? (settingsState.theme == 'dark' ? Colors.white : Colors.black)
            : theme.colorScheme.onSurface;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: textColor),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular timer display with progress indicator
class CircularTimerDisplay extends StatelessWidget {
  const CircularTimerDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = main_app.settingsBloc.state;

    return BlocBuilder<ProClockBloc, ProClockState>(
      builder: (context, state) {
        // Force the phase to match the state every time we build
        final bool isWorkPhase = state.isWorkPhase;
        final bool isPomodoro = state.timerMode == TimerMode.pomodoro;

        // Use color based on current mode and phase
        Color timerColor = settingsState.activatedColor;
        if (isPomodoro && !isWorkPhase) {
          // Use red color for the rest phase
          timerColor = Colors.red;
        }

        // Get explicit phase text and icon based on mode and phase
        final String phaseText =
            isPomodoro ? (isWorkPhase ? 'WORK' : 'REST') : '';

        final IconData phaseIcon =
            isPomodoro
                ? (isWorkPhase ? Icons.work : Icons.bedtime)
                : Icons.calendar_today;

        // Text color based on theme mode
        final textColor =
            settingsState.theme == 'dark' ? Colors.white : Colors.black;

        // Calculate progress
        double progress = 0.0;
        int totalSeconds = 0;

        if (isPomodoro) {
          totalSeconds =
              isWorkPhase ? state.workMinutes * 60 : state.restMinutes * 60;
        } else if (state.currentTask != null &&
            state.currentTask!.durationInMinutes > 0) {
          totalSeconds = state.currentTask!.durationInMinutes * 60;
        } else {
          totalSeconds = state.workMinutes * 60;
        }

        if (totalSeconds > 0) {
          progress = 1.0 - (state.remainingSeconds / totalSeconds);
          // Ensure progress stays between 0 and 1
          progress = progress.clamp(0.0, 1.0);
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: timerColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),

              // Progress indicator circle
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 16,
                  backgroundColor: timerColor.withOpacity(0.2),
                  color: timerColor,
                ),
              ),

              // Timer content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Phase label (Work/Rest) - Only show in Pomodoro mode
                  if (isPomodoro) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: timerColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(phaseIcon, size: 16, color: timerColor),
                          const SizedBox(width: 4),
                          Text(
                            phaseText,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: timerColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Timer display (MM:SS)
                  Text(
                    state.timerDisplay,
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: timerColor,
                    ),
                  ),

                  // Pomodoro count (only in pomodoro mode)
                  if (isPomodoro) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Completed: ${state.pomodoroCount}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Timer controls: reset, play/pause, skip
class TimerControls extends StatelessWidget {
  const TimerControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = main_app.settingsBloc.state;

    return BlocBuilder<ProClockBloc, ProClockState>(
      builder: (context, state) {
        final isRunning = state.timerStatus == TimerStatus.running;
        final activatedColor = settingsState.activatedColor;
        final accentColor = theme.colorScheme.secondary;
        final textColor =
            settingsState.theme == 'dark' ? Colors.white : Colors.black;

        // Determine label for skip button based on mode and phase
        final skipButtonLabel =
            state.timerMode == TimerMode.pomodoro
                ? state.isWorkPhase
                    ? 'Rest'
                    : 'Work'
                : 'Skip';

        final skipButtonIcon =
            state.timerMode == TimerMode.pomodoro
                ? state.isWorkPhase
                    ? Icons.nights_stay
                    : Icons.work_outline
                : Icons.skip_next;

        // Use red for rest phase skip button
        final skipButtonColor =
            (state.timerMode == TimerMode.pomodoro && !state.isWorkPhase)
                ? Colors.red
                : activatedColor;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                context,
                Icons.refresh,
                'Reset',
                activatedColor,
                () => context.read<ProClockBloc>().add(const ResetTimer()),
              ),
              const SizedBox(width: 32),
              FloatingActionButton(
                backgroundColor:
                    isRunning ? activatedColor.withOpacity(0.8) : accentColor,
                foregroundColor:
                    settingsState.theme == 'dark' ? Colors.white : Colors.black,
                onPressed: () {
                  if (isRunning) {
                    context.read<ProClockBloc>().add(const PauseTimer());
                  } else {
                    context.read<ProClockBloc>().add(const StartTimer());
                  }
                },
                child: Icon(
                  isRunning ? Icons.pause : Icons.play_arrow,
                  size: 32,
                ),
              ),
              const SizedBox(width: 32),
              _buildControlButton(
                context,
                skipButtonIcon,
                skipButtonLabel,
                skipButtonColor,
                () => context.read<ProClockBloc>().add(const CompletePhase()),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    final settingsState = main_app.settingsBloc.state;
    final textColor =
        settingsState.theme == 'dark' ? Colors.white : Colors.black;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: color, size: 28),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

/// Task display for Schedule mode
class TaskDisplay extends StatelessWidget {
  const TaskDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = main_app.settingsBloc.state;
    final activatedColor = settingsState.activatedColor;
    final textColor =
        settingsState.theme == 'dark' ? Colors.white : Colors.black;

    return BlocBuilder<ProClockBloc, ProClockState>(
      builder: (context, state) {
        // No tasks at all for the selected date
        if (state.tasks.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: activatedColor.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 48,
                    color: activatedColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No activities scheduled for ${_formatDate(state.selectedDate)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select another date or add activities from the Schedule screen',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    icon: Icon(Icons.calendar_today, color: activatedColor),
                    label: Text(
                      'Select another date',
                      style: TextStyle(color: activatedColor),
                    ),
                    onPressed: () => selectDate(context),
                  ),
                ],
              ),
            ),
          );
        }

        final task = state.currentTask;

        // Has tasks but current task is null
        if (task == null) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: activatedColor.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy, size: 48, color: activatedColor),
                  const SizedBox(height: 16),
                  Text(
                    'No current activity for this time',
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'There are ${state.tasks.length} activities on this date',
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    icon: Icon(Icons.calendar_today, color: activatedColor),
                    label: Text(
                      'Select another date',
                      style: TextStyle(color: activatedColor),
                    ),
                    onPressed: () => selectDate(context),
                  ),
                ],
              ),
            ),
          );
        }

        // Display current task with clickable area to show details
        return InkWell(
          onTap: () => _showTaskDetails(context, task),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    task.currentTaskStatus
                        ? activatedColor
                        : theme.colorScheme.onSurface.withOpacity(0.2),
                width: task.currentTaskStatus ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Time range
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: activatedColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 16, color: activatedColor),
                      const SizedBox(width: 4),
                      Text(
                        task.timeRangeString,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: activatedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Task name
                Text(
                  task.currentTask,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: activatedColor,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        task.currentTaskStatus
                            ? activatedColor.withOpacity(0.15)
                            : theme.colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        task.currentTaskStatus
                            ? Icons.check_circle
                            : Icons.pending_actions,
                        size: 16,
                        color:
                            task.currentTaskStatus ? activatedColor : textColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.currentTaskStatus ? 'Completed' : 'In Progress',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              task.currentTaskStatus
                                  ? activatedColor
                                  : textColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // View details hint
                Text(
                  'Tap to view details',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Task navigation arrows for Schedule mode
class TaskNavigation extends StatelessWidget {
  const TaskNavigation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = main_app.settingsBloc.state;
    final activatedColor = settingsState.activatedColor;
    final textColor =
        settingsState.theme == 'dark' ? Colors.white : Colors.black;

    return BlocBuilder<ProClockBloc, ProClockState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous task button
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  size: 20,
                  color:
                      state.canMoveToPrevious
                          ? activatedColor
                          : theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                tooltip: 'Previous Task',
                onPressed:
                    state.canMoveToPrevious
                        ? () => context.read<ProClockBloc>().add(
                          const PreviousTask(),
                        )
                        : null,
              ),

              // Task position indicator
              Text(
                '${state.currentTaskIndex + 1} / ${state.tasks.length}',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),

              // Next task button
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  size: 20,
                  color:
                      state.canMoveToNext
                          ? activatedColor
                          : theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                tooltip: 'Next Task',
                onPressed:
                    state.canMoveToNext
                        ? () =>
                            context.read<ProClockBloc>().add(const NextTask())
                        : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Dedicated widget to show pomodoro information with proper work/rest phase display
class PomodoroInfo extends StatelessWidget {
  const PomodoroInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProClockBloc, ProClockState>(
      builder: (context, state) {
        print('Building PomodoroInfo with isWorkPhase: ${state.isWorkPhase}');

        // Always render both cards, but only show the one that matches the phase
        // This ensures there's always a card visible during transitions
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child:
              state.isWorkPhase
                  ? const WorkPhaseCard(key: ValueKey('work'))
                  : const RestPhaseCard(key: ValueKey('rest')),
        );
      },
    );
  }
}

/// Work Phase Card - Always shows work phase information
class WorkPhaseCard extends StatelessWidget {
  const WorkPhaseCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = main_app.settingsBloc.state;
    final activatedColor = settingsState.activatedColor;
    final textColor =
        settingsState.theme == 'dark' ? Colors.white : Colors.black;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: activatedColor.withOpacity(0.5), width: 2),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Work phase header with icon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: activatedColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.work, color: activatedColor, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'WORK PHASE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: activatedColor,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Work duration
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: activatedColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: BlocBuilder<ProClockBloc, ProClockState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      Icon(Icons.timer, color: activatedColor, size: 36),
                      const SizedBox(height: 12),
                      Text(
                        'Focus on your task for ${state.workMinutes} minutes',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Then take a ${state.restMinutes} minute break',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Pomodoro counter
            BlocBuilder<ProClockBloc, ProClockState>(
              builder: (context, state) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pomodoros Completed: ${state.pomodoroCount}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Rest Phase Card - Always shows rest phase information
class RestPhaseCard extends StatelessWidget {
  const RestPhaseCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = main_app.settingsBloc.state;
    // Use red color for rest phase
    const restColor = Colors.red;
    final textColor =
        settingsState.theme == 'dark' ? Colors.white : Colors.black;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: restColor.withOpacity(0.5), width: 2),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Rest phase header with icon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: restColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bedtime, color: restColor, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'REST PHASE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: restColor,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rest duration
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: restColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: BlocBuilder<ProClockBloc, ProClockState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      Icon(Icons.nights_stay, color: restColor, size: 36),
                      const SizedBox(height: 12),
                      Text(
                        'Relax and recharge for ${state.restMinutes} minutes',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Prepare for your next productive session.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Pomodoro counter
            BlocBuilder<ProClockBloc, ProClockState>(
              builder: (context, state) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pomodoros Completed: ${state.pomodoroCount}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows task details in a modal bottom sheet
void _showTaskDetails(BuildContext context, ProClockModel task) {
  final theme = Theme.of(context);
  final settingsState = main_app.settingsBloc.state;
  final activatedColor = settingsState.activatedColor;
  final secondaryColor = theme.colorScheme.secondary;
  final textColor = settingsState.theme == 'dark' ? Colors.white : Colors.black;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with task name and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.currentTask,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: activatedColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              // Time range
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: activatedColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 16, color: activatedColor),
                    const SizedBox(width: 6),
                    Text(
                      task.timeRangeString,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: activatedColor,
                      ),
                    ),
                    if (task.durationInMinutes > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${task.durationInMinutes} min)',
                        style: TextStyle(
                          color: activatedColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Divider(height: 24),

              // Description (if available)
              if (task.currentTaskDescription.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    task.currentTaskDescription,
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                ),
              ],

              // Notes (if available)
              if (task.currentTaskNotes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    task.currentTaskNotes,
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                ),
              ],

              // Todo items (if available)
              if (task.currentTaskTodos.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Todo Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: task.currentTaskTodos.length,
                    itemBuilder: (context, index) {
                      final todo = task.currentTaskTodos[index];
                      return ListTile(
                        leading: Icon(
                          Icons.check_circle_outline,
                          color: activatedColor,
                        ),
                        title: Text(todo, style: TextStyle(color: textColor)),
                        dense: true,
                      );
                    },
                  ),
                ),
              ],

              // Action buttons
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(
                    task.currentTaskStatus
                        ? Icons.check_circle
                        : Icons.play_circle_outline,
                  ),
                  label: Text(
                    task.currentTaskStatus ? 'Completed' : 'Start Task',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        task.currentTaskStatus ? Colors.grey : activatedColor,
                    foregroundColor:
                        settingsState.theme == 'dark'
                            ? Colors.white
                            : Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    if (!task.currentTaskStatus) {
                      // Mark task as in progress and start timer
                      context.read<ProClockBloc>().add(
                        MarkTaskAsCompleted(
                          taskIndex:
                              context
                                  .read<ProClockBloc>()
                                  .state
                                  .currentTaskIndex,
                          isCompleted: true,
                        ),
                      );
                      context.read<ProClockBloc>().add(const StartTimer());
                    }
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Shows timer settings in a modal bottom sheet
void showTimerSettings(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SafeArea(child: const TimerSettingsSheet()),
  );
}

/// Dedicated StatefulWidget for timer settings to ensure proper state management
class TimerSettingsSheet extends StatefulWidget {
  const TimerSettingsSheet({Key? key}) : super(key: key);

  @override
  State<TimerSettingsSheet> createState() => _TimerSettingsSheetState();
}

class _TimerSettingsSheetState extends State<TimerSettingsSheet> {
  late int workMinutes;
  late int restMinutes;
  String? selectedPreset;

  @override
  void initState() {
    super.initState();
    // Get initial values from the bloc
    final state = context.read<ProClockBloc>().state;
    workMinutes = state.workMinutes;
    restMinutes = state.restMinutes;

    // Determine if current values match a preset
    _checkForMatchingPreset();
  }

  // Map of preset timer ratios
  final Map<String, List<int>> presetRatios = {
    '25:5 (Standard)': [25, 5],
    '50:10 (Extended)': [50, 10],
    '45:15 (Balanced)': [45, 15],
    '20:10 (Short)': [20, 10],
    '30:5 (Intense)': [30, 5],
  };

  // Check if current values match a preset and set selectedPreset accordingly
  void _checkForMatchingPreset() {
    for (final entry in presetRatios.entries) {
      if (workMinutes == entry.value[0] && restMinutes == entry.value[1]) {
        selectedPreset = entry.key;
        return;
      }
    }
    selectedPreset = null; // No matching preset
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = main_app.settingsBloc.state;
    final textColor =
        settingsState.theme == 'dark' ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Timer Settings',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: settingsState.activatedColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Preset ratios
          Text(
            'Preset Ratios',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),

          // Preset ratio chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                presetRatios.entries.map((entry) {
                  final bool isSelected = selectedPreset == entry.key;
                  return FilterChip(
                    selected: isSelected,
                    label: Text(entry.key),
                    selectedColor: settingsState.activatedColor.withOpacity(
                      0.2,
                    ),
                    checkmarkColor: settingsState.activatedColor,
                    labelStyle: TextStyle(
                      color:
                          isSelected ? settingsState.activatedColor : textColor,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          workMinutes = entry.value[0];
                          restMinutes = entry.value[1];
                          selectedPreset = entry.key;
                        }
                      });
                    },
                  );
                }).toList(),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Custom settings
          Text(
            'Custom Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),

          // Work duration slider
          Text(
            'Work Duration: $workMinutes minutes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: workMinutes.toDouble(),
            min: 1,
            max: 60,
            divisions: 59,
            activeColor: settingsState.activatedColor,
            inactiveColor: settingsState.activatedColor.withOpacity(0.3),
            label: '$workMinutes min',
            onChanged: (value) {
              setState(() {
                workMinutes = value.round();
                _checkForMatchingPreset(); // Check if new values match a preset
              });
            },
          ),

          const SizedBox(height: 16),

          // Rest duration slider
          Text(
            'Rest Duration: $restMinutes minutes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: restMinutes.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            activeColor: Colors.red,
            inactiveColor: Colors.red.withOpacity(0.3),
            label: '$restMinutes min',
            onChanged: (value) {
              setState(() {
                restMinutes = value.round();
                _checkForMatchingPreset(); // Check if new values match a preset
              });
            },
          ),

          const SizedBox(height: 24),

          // Current ratio display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: settingsState.activatedColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              'Current Ratio: $workMinutes:$restMinutes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: settingsState.activatedColor,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Save button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: settingsState.activatedColor,
              foregroundColor:
                  settingsState.theme == 'dark' ? Colors.white : Colors.black,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              context.read<ProClockBloc>().add(
                UpdateTimerSettings(
                  workMinutes: workMinutes,
                  restMinutes: restMinutes,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Save Settings', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

/// Date selection dialog
Future<void> selectDate(BuildContext context) async {
  final state = context.read<ProClockBloc>().state;
  final settingsState = main_app.settingsBloc.state;
  final textColor = settingsState.theme == 'dark' ? Colors.white : Colors.black;

  // Use the same date picker as in schedule screen
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Date',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: settingsState.activatedColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textColor),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date picker
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: settingsState.activatedColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SfDateRangePicker(
                    view: DateRangePickerView.month,
                    selectionMode: DateRangePickerSelectionMode.single,
                    monthViewSettings: DateRangePickerMonthViewSettings(
                      firstDayOfWeek: 1,
                      dayFormat: 'EEE',
                      viewHeaderStyle: DateRangePickerViewHeaderStyle(
                        textStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: settingsState.activatedColor,
                        ),
                      ),
                    ),
                    monthCellStyle: DateRangePickerMonthCellStyle(
                      todayTextStyle: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      todayCellDecoration: BoxDecoration(
                        color: Colors.red.shade100,
                        shape: BoxShape.circle,
                      ),
                    ),
                    selectionColor: settingsState.activatedColor,
                    selectionTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    headerStyle: DateRangePickerHeaderStyle(
                      textStyle: TextStyle(
                        color: settingsState.activatedColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onSelectionChanged: (args) {
                      if (args.value is DateTime) {
                        final selectedDate = args.value as DateTime;
                        context.read<ProClockBloc>().add(
                          ChangeDate(date: selectedDate),
                        );
                        // Close the popup immediately after selection
                        Navigator.of(dialogContext).pop();
                      }
                    },
                    initialSelectedDate: state.selectedDate,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Helper method to format the date in a readable way
String _formatDate(DateTime date) {
  final months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
