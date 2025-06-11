// Pro Clock model

class ProClockModel {
  final int id; // ID of the schedule
  final DateTime date; // Date of the schedule
  final String currentTask; // Current task of the datetime
  final String currentTaskDescription; // Description of the current task
  final String currentTaskNotes; // Notes of the current task
  final List<String> currentTaskTodos; // Todo list of the current task
  final bool
  currentTaskStatus; // Status of the current task (completed, not completed, etc.)
  final String startTime; // Start time of the task in format "HH:MM"
  final String endTime; // End time of the task in format "HH:MM"

  ProClockModel({
    required this.id,
    required this.date,
    required this.currentTask,
    required this.currentTaskDescription,
    required this.currentTaskNotes,
    required this.currentTaskTodos,
    required this.currentTaskStatus,
    this.startTime = "00:00",
    this.endTime = "23:59",
  });

  // Get duration in minutes
  int get durationInMinutes {
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');

    if (startParts.length != 2 || endParts.length != 2) {
      return 0;
    }

    try {
      final startHours = int.parse(startParts[0]);
      final startMinutes = int.parse(startParts[1]);
      final endHours = int.parse(endParts[0]);
      final endMinutes = int.parse(endParts[1]);

      final startTotalMinutes = startHours * 60 + startMinutes;
      final endTotalMinutes = endHours * 60 + endMinutes;

      return endTotalMinutes - startTotalMinutes;
    } catch (e) {
      return 0;
    }
  }

  // Format time range as a string
  String get timeRangeString => '$startTime - $endTime';
}
