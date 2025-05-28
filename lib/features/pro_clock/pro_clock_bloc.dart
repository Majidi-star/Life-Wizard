// Pro Clock BLoC file

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'pro_clock_event.dart';
import 'pro_clock_state.dart';
import 'pro_clock_repository.dart';
import 'pro_clock_model.dart';

class ProClockBloc extends Bloc<ProClockEvent, ProClockState> {
  final ProClockRepository repository;
  Timer? _timer;

  // Maintain separate states for each mode
  int _scheduleRemainingSeconds = 0;
  int _pomodoroRemainingSeconds = 0;
  bool _pomodoroIsWorkPhase = true;
  TimerStatus _scheduleTimerStatus = TimerStatus.idle;
  TimerStatus _pomodoroTimerStatus = TimerStatus.idle;

  ProClockBloc({ProClockRepository? repository})
    : repository = repository ?? ProClockRepository(),
      super(ProClockState(selectedDate: DateTime.now())) {
    on<LoadTasks>(_onLoadTasks);
    on<ChangeDate>(_onChangeDate);
    on<StartTimer>(_onStartTimer);
    on<PauseTimer>(_onPauseTimer);
    on<ResetTimer>(_onResetTimer);
    on<NextTask>(_onNextTask);
    on<PreviousTask>(_onPreviousTask);
    on<TimerTick>(_onTimerTick);
    on<CompletePhase>(_onCompletePhase);
    on<ChangeTimerMode>(_onChangeTimerMode);
    on<UpdateTimerSettings>(_onUpdateTimerSettings);
    on<MarkTaskAsCompleted>(_onMarkTaskAsCompleted);

    // Initialize by loading today's tasks
    add(LoadTasks(date: DateTime.now()));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  // Start or resume the timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const TimerTick());
    });
  }

  // Stop the timer
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // Helper to initialize timer based on current phase
  void _initializeTimer() {
    int durationInMinutes;
    if (state.timerMode == TimerMode.schedule && state.currentTask != null) {
      // Calculate duration based on schedule - use the task's actual duration if available
      if (state.currentTask!.durationInMinutes > 0) {
        durationInMinutes = state.currentTask!.durationInMinutes;
      } else {
        durationInMinutes = state.workMinutes; // Use the customizable duration
      }
      _scheduleRemainingSeconds = durationInMinutes * 60;
    } else {
      // Pomodoro mode
      durationInMinutes =
          state.isWorkPhase ? state.workMinutes : state.restMinutes;
      _pomodoroRemainingSeconds = durationInMinutes * 60;
    }

    // Update the state's remaining seconds based on active mode
    int remainingSeconds =
        state.timerMode == TimerMode.schedule
            ? _scheduleRemainingSeconds
            : _pomodoroRemainingSeconds;

    emit(state.copyWith(remainingSeconds: remainingSeconds));
  }

  // Event Handlers
  Future<void> _onLoadTasks(
    LoadTasks event,
    Emitter<ProClockState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));

      final tasks = await repository.getTasksForDate(event.date);

      // For today, check if there is a current task
      ProClockModel? currentTask;
      int initialIndex = 0;

      if (event.date.year == DateTime.now().year &&
          event.date.month == DateTime.now().month &&
          event.date.day == DateTime.now().day) {
        // Get the current task for today
        currentTask = await repository.getCurrentTask();

        // If current task is found, set the initial index to show that task
        if (currentTask != null && tasks.isNotEmpty) {
          // Find the index of the current task
          initialIndex = tasks.indexWhere(
            (task) =>
                task.currentTask == currentTask!.currentTask &&
                task.startTime == currentTask!.startTime,
          );
          if (initialIndex < 0)
            initialIndex = 0; // Default to first task if not found
        }
      }

      // If no tasks found for selected date, try sample data
      final tasksToUse =
          tasks.isEmpty ? await _getSampleTasksIfNeeded(event.date) : tasks;

      emit(
        state.copyWith(
          tasks: tasksToUse,
          selectedDate: event.date,
          currentTaskIndex: initialIndex,
          isLoading: false,
        ),
      );

      // Initialize timer for the current task
      if (tasksToUse.isNotEmpty) {
        _initializeTimer();
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  // Helper to get sample tasks if needed (for development only)
  Future<List<ProClockModel>> _getSampleTasksIfNeeded(DateTime date) async {
    // Only show sample data for today or when debugging
    final isToday =
        date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    // In a real app, you might check for a debug flag here
    const bool isDebugging = true;

    if (isToday || isDebugging) {
      return await repository.getSampleTasks();
    }

    return [];
  }

  void _onChangeDate(ChangeDate event, Emitter<ProClockState> emit) {
    // Only affect schedule mode
    if (state.timerMode == TimerMode.schedule) {
      // Stop schedule timer
      if (_scheduleTimerStatus == TimerStatus.running) {
        _stopTimer();
      }
      _scheduleTimerStatus = TimerStatus.idle;
    }

    // Load tasks for the new date
    add(LoadTasks(date: event.date));
  }

  void _onStartTimer(StartTimer event, Emitter<ProClockState> emit) {
    // Handle state based on current mode
    if (state.timerMode == TimerMode.schedule) {
      // If timer is at 0, initialize it
      if (_scheduleRemainingSeconds == 0) {
        _initializeTimer();
      }
      _scheduleTimerStatus = TimerStatus.running;
    } else {
      // Pomodoro mode
      if (_pomodoroRemainingSeconds == 0) {
        _initializeTimer();
      }
      _pomodoroTimerStatus = TimerStatus.running;
    }

    emit(state.copyWith(timerStatus: TimerStatus.running));
    _startTimer();
  }

  void _onPauseTimer(PauseTimer event, Emitter<ProClockState> emit) {
    _stopTimer();

    // Update the relevant timer status
    if (state.timerMode == TimerMode.schedule) {
      _scheduleTimerStatus = TimerStatus.paused;
    } else {
      _pomodoroTimerStatus = TimerStatus.paused;
    }

    emit(state.copyWith(timerStatus: TimerStatus.paused));
  }

  void _onResetTimer(ResetTimer event, Emitter<ProClockState> emit) {
    _stopTimer();

    // Reset the relevant mode
    if (state.timerMode == TimerMode.schedule) {
      _scheduleTimerStatus = TimerStatus.idle;
    } else {
      _pomodoroTimerStatus = TimerStatus.idle;
    }

    _initializeTimer();
    emit(state.copyWith(timerStatus: TimerStatus.idle));
  }

  void _onNextTask(NextTask event, Emitter<ProClockState> emit) {
    if (!state.canMoveToNext) return;

    emit(state.copyWith(currentTaskIndex: state.currentTaskIndex + 1));

    // In schedule mode, reset the timer for the new task
    if (state.timerMode == TimerMode.schedule) {
      _initializeTimer();
    }
  }

  void _onPreviousTask(PreviousTask event, Emitter<ProClockState> emit) {
    if (!state.canMoveToPrevious) return;

    emit(state.copyWith(currentTaskIndex: state.currentTaskIndex - 1));

    // In schedule mode, reset the timer for the new task
    if (state.timerMode == TimerMode.schedule) {
      _initializeTimer();
    }
  }

  void _onTimerTick(TimerTick event, Emitter<ProClockState> emit) {
    // Determine which timer is currently active
    if (state.timerMode == TimerMode.schedule) {
      if (_scheduleRemainingSeconds <= 1) {
        // Timer completed
        _stopTimer();
        _scheduleRemainingSeconds = 0;
        _scheduleTimerStatus = TimerStatus.idle;

        emit(
          state.copyWith(remainingSeconds: 0, timerStatus: TimerStatus.idle),
        );

        // In schedule mode, mark task as complete and move to next
        add(const CompletePhase());
      } else {
        // Timer continues
        _scheduleRemainingSeconds -= 1;
        emit(state.copyWith(remainingSeconds: _scheduleRemainingSeconds));
      }
    } else {
      // Pomodoro mode
      if (_pomodoroRemainingSeconds <= 1) {
        // Timer completed
        _stopTimer();
        _pomodoroRemainingSeconds = 0;
        _pomodoroTimerStatus = TimerStatus.idle;

        emit(
          state.copyWith(remainingSeconds: 0, timerStatus: TimerStatus.idle),
        );

        // Move to next phase
        add(const CompletePhase());
      } else {
        // Timer continues
        _pomodoroRemainingSeconds -= 1;
        emit(state.copyWith(remainingSeconds: _pomodoroRemainingSeconds));
      }
    }
  }

  void _onCompletePhase(CompletePhase event, Emitter<ProClockState> emit) {
    if (state.timerMode == TimerMode.pomodoro) {
      // In pomodoro mode, toggle between work and rest
      _pomodoroIsWorkPhase = !_pomodoroIsWorkPhase;
      final newPomodoroCount =
          _pomodoroIsWorkPhase ? state.pomodoroCount + 1 : state.pomodoroCount;

      emit(
        state.copyWith(
          isWorkPhase: _pomodoroIsWorkPhase,
          pomodoroCount: newPomodoroCount,
        ),
      );

      // Initialize timer for the new phase
      _initializeTimer();

      // Automatically start the next phase
      add(const StartTimer());
    } else {
      // In schedule mode, mark current task as completed and move to next if available
      if (state.currentTask != null) {
        add(
          MarkTaskAsCompleted(
            taskIndex: state.currentTaskIndex,
            isCompleted: true,
          ),
        );

        if (state.canMoveToNext) {
          add(const NextTask());
        }
      }
    }
  }

  void _onChangeTimerMode(ChangeTimerMode event, Emitter<ProClockState> emit) {
    // Get the current state for the target mode
    final isScheduleMode = event.mode == TimerMode.schedule;
    final modeTimerStatus =
        isScheduleMode ? _scheduleTimerStatus : _pomodoroTimerStatus;

    // Switch to the target mode while maintaining its own state
    emit(
      state.copyWith(
        timerMode: event.mode,
        timerStatus: modeTimerStatus,
        isWorkPhase: isScheduleMode ? true : _pomodoroIsWorkPhase,
        remainingSeconds:
            isScheduleMode
                ? _scheduleRemainingSeconds
                : _pomodoroRemainingSeconds,
      ),
    );

    // Start or stop the timer based on the target mode's state
    if (modeTimerStatus == TimerStatus.running && _timer == null) {
      _startTimer();
    } else if (modeTimerStatus != TimerStatus.running && _timer != null) {
      _stopTimer();
    }
  }

  void _onUpdateTimerSettings(
    UpdateTimerSettings event,
    Emitter<ProClockState> emit,
  ) {
    emit(
      state.copyWith(
        workMinutes: event.workMinutes,
        restMinutes: event.restMinutes,
      ),
    );

    // If in pomodoro mode and timer is idle, initialize with new settings
    if (state.timerMode == TimerMode.pomodoro &&
        _pomodoroTimerStatus == TimerStatus.idle) {
      _initializeTimer();
    }
  }

  Future<void> _onMarkTaskAsCompleted(
    MarkTaskAsCompleted event,
    Emitter<ProClockState> emit,
  ) async {
    if (event.taskIndex < 0 || event.taskIndex >= state.tasks.length) return;

    // Update the task in state
    final updatedTasks = List.of(state.tasks);
    final task = updatedTasks[event.taskIndex];

    // Create new instance with updated status
    updatedTasks[event.taskIndex] = ProClockModel(
      date: task.date,
      currentTask: task.currentTask,
      currentTaskDescription: task.currentTaskDescription,
      currentTaskNotes: task.currentTaskNotes,
      currentTaskTodos: task.currentTaskTodos,
      currentTaskStatus: event.isCompleted,
      startTime: task.startTime,
      endTime: task.endTime,
    );

    emit(state.copyWith(tasks: updatedTasks));

    // Update in database
    await repository.updateTaskStatus(
      task.date,
      task.currentTask,
      event.isCompleted,
    );
  }
}
