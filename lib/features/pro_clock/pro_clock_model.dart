// Pro Clock model

class ProClockModel {
    final DateTime date; // Date of the schedule
    final String currentTask; // Current task of the datetime 
    final String currentTaskDescription; // Description of the current task
    final String currentTaskNotes; // Notes of the current task
    final List<String> currentTaskTodos; // Todo list of the current task
    final bool currentTaskStatus; // Status of the current task (completed, not completed, etc.)

    ProClockModel({
        required this.date,
        required this.currentTask,
        required this.currentTaskDescription,
        required this.currentTaskNotes,
        required this.currentTaskTodos,
        required this.currentTaskStatus,
    });
}

