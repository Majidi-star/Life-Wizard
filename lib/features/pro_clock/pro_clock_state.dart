// Pro Clock State file

import 'package:equatable/equatable.dart';
import 'pro_clock_model.dart';

enum TimerMode {
  schedule, // Timer based on schedule tasks
  pomodoro, // Free pomodoro timer
}

enum TimerStatus { idle, running, paused, rest }

class ProClockState extends Equatable {
  final List<ProClockModel> tasks;
  final int currentTaskIndex;
  final DateTime selectedDate;
  final TimerMode timerMode;
  final TimerStatus timerStatus;
  final int remainingSeconds;
  final bool isWorkPhase; // true for work, false for rest
  final int pomodoroCount;
  final int workMinutes; // Customizable work duration (default 25)
  final int restMinutes; // Customizable rest duration (default 5)
  final bool isLoading; // Indicates loading status

  const ProClockState({
    this.tasks = const [],
    this.currentTaskIndex = 0,
    required this.selectedDate,
    this.timerMode = TimerMode.schedule,
    this.timerStatus = TimerStatus.idle,
    this.remainingSeconds = 0,
    this.isWorkPhase = true,
    this.pomodoroCount = 0,
    this.workMinutes = 25,
    this.restMinutes = 5,
    this.isLoading = false,
  });

  ProClockState copyWith({
    List<ProClockModel>? tasks,
    int? currentTaskIndex,
    DateTime? selectedDate,
    TimerMode? timerMode,
    TimerStatus? timerStatus,
    int? remainingSeconds,
    bool? isWorkPhase,
    int? pomodoroCount,
    int? workMinutes,
    int? restMinutes,
    bool? isLoading,
  }) {
    return ProClockState(
      tasks: tasks ?? this.tasks,
      currentTaskIndex: currentTaskIndex ?? this.currentTaskIndex,
      selectedDate: selectedDate ?? this.selectedDate,
      timerMode: timerMode ?? this.timerMode,
      timerStatus: timerStatus ?? this.timerStatus,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isWorkPhase: isWorkPhase ?? this.isWorkPhase,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
      workMinutes: workMinutes ?? this.workMinutes,
      restMinutes: restMinutes ?? this.restMinutes,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  ProClockModel? get currentTask {
    if (tasks.isEmpty || currentTaskIndex >= tasks.length) {
      return null;
    }
    return tasks[currentTaskIndex];
  }

  bool get canMoveToPrevious => currentTaskIndex > 0;
  bool get canMoveToNext => currentTaskIndex < tasks.length - 1;

  String get timerDisplay {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get phaseDisplay {
    if (timerMode == TimerMode.schedule) {
      return 'Schedule';
    } else {
      return isWorkPhase ? 'Work' : 'Rest';
    }
  }

  @override
  List<Object?> get props => [
    tasks,
    currentTaskIndex,
    selectedDate,
    timerMode,
    timerStatus,
    remainingSeconds,
    isWorkPhase,
    pomodoroCount,
    workMinutes,
    restMinutes,
    isLoading,
  ];
}
