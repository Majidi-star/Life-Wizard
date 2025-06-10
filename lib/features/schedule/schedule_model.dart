// Schedule model

class DateModel {
  final String date; // Date of the schedule
  final int day; // Day of the month
  final String month; // Month of the year
  final int year; // Year of the date

  DateModel({
    required this.date,
    required this.day,
    required this.month,
    required this.year,
  });
}

class ScheduleModel {
  final List<TimeBox> timeBoxes; // List of time boxes (TimeBox model)
  final TimeBox? currentTimeBox; // Current time box (TimeBox model)

  ScheduleModel({required this.timeBoxes, this.currentTimeBox});
}

class TimeBox {
  final int id;
  final int startTimeHour; // Start time of the time box (hour)
  final int startTimeMinute; // Start time of the time box (minute)
  final int endTimeHour; // End time of the time box (hour)
  final int endTimeMinute; // End time of the time box (minute)
  final String activity; // Activity of the time box
  final String notes; // Notes of the time box (notes, etc.)
  final List<String> todos; // Todo list of the time box's activity
  final bool
  timeBoxStatus; // Status of the time box (completed, not completed, etc.)
  final int priority; // Priority of the activity
  final double
  heatmapProductivity; // How productive you have been in this time box (1-10)
  final bool isChallenge; // Whether this is a challenge time box
  final String habits; // JSON string containing associated habits

  TimeBox({
    required this.id,
    required this.startTimeHour,
    required this.startTimeMinute,
    required this.endTimeHour,
    required this.endTimeMinute,
    required this.activity,
    required this.notes,
    required this.todos,
    required this.timeBoxStatus,
    required this.priority,
    required this.heatmapProductivity,
    required this.isChallenge,
    this.habits = '', // Default to empty string
  });
}

class ActiveHabits {
  final List<Habit> habits; // List of habits (Habit model)

  ActiveHabits({required this.habits});
}

class Habit {
  final String habitName; // Name of the habit
  final String habitDescription; // Description of the habit
  final int
  habitConsecutiveProgress; // How many consecutive times the habit has been done
  final bool
  habitCompleted; // Status of the habit (completed, not completed, etc.)
  final bool habitStatus; // The AI judgement of the habit frequency

  Habit({
    required this.habitName,
    required this.habitDescription,
    required this.habitConsecutiveProgress,
    required this.habitCompleted,
    required this.habitStatus,
  });
}
