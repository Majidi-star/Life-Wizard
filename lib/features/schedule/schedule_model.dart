// Schedule model

class DateModel {
    final String date; // Date of the schedule
    final Int day; // Day of the month
    final String month; // Month of the year
    final Int year; // Year of the date

    DateModel({
        required this.date,
        required this.day,
        required this.month,
        required this.year,
    });
}

class ScheduleModel {
    final List<TimeBox> timeBoxes; // List of time boxes (TimeBox model)
    final TimeBox currentTimeBox; // Current time box (TimeBox model)
    final TimeBox challengeTimeBox; // Challenge time box (TimeBox model)

    ScheduleModel({
        required this.timeBoxes,
        required this.currentTimeBox,
        required this.challengeTimeBox,
    });
}

class TimeBox {
    final Int startTimeHour; // Start time of the time box (hour)
    final Int startTimeMinute; // Start time of the time box (minute)
    final Int endTimeHour; // End time of the time box (hour)
    final Int endTimeMinute; // End time of the time box (minute)
    final String activity; // Activity of the time box
    final String notes; // Notes of the time box (notes, etc.)
    final List<String> todos; // Todo list of the time box's activity
    final bool timeBoxStatus; // Status of the time box (completed, not completed, etc.)
    final Int priority; // Priority of the activity
    final Int heatmapProductivity; // How productive you have been in this time box (1-10) 
    
    TimeBox({
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
    });
    
}

class ActiveHabits {
    final List<Habit> habits; // List of habits (Habit model)

    ActiveHabits({
        required this.habits,
    });
}

class Habit {
    final String habitName; // Name of the habit
    final String habitDescription; // Description of the habit
    final Int habitConsecutiveProgress; // How many consecutive times the habit has been done
    final Int habitPriority; // Priority of the habit
    final bool habitCompleted; // Status of the habit (completed, not completed, etc.)
    final bool habitStatus; // The AI judgement of the habit frequency
    Habit({
        required this.habitName,
        required this.habitDescription,
        required this.habitConsecutiveProgress,
        required this.habitPriority,
        required this.habitCompleted,
        required this.habitStatus,
    });
}
