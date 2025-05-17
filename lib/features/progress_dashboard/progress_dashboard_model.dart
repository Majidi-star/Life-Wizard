// Progress Dashboard model

// Define the goals section
class GoalsModel {
  final List<Goal> goals; // List of goals (Goal model)

  GoalsModel({required this.goals});
}

// Define Goal model to be used in the GoalsModel model
class Goal {
  final String goalName; // Name of the goal
  final String goalDescription; // Description of the goal
  final String
  goalStatus; // Status of the goal (completed, not completed, etc.)
  final String goalCreatedAt; // Date of creation of the goal
  final String goalCompletedAt; // Date of completion of the goal
  final int goalPriority; // Priority of the goal (1-10)
  final int goalCurrentScore; // Score of the goal
  final int goalTargetScore; // Target score of the goal
  final int goalPreviousScore; // Previous score of the goal
  final int goalNextScore; // Next score of the goal (next milestone)
  final List<Milestone> goalMilestones; // List of milestones (Milestone model)
  final Milestone currentMilestone; // Current milestone of the goal
  final List<Tasks> overallTasks; // The list of overall tasks
  final ScoreChart scoreChart; // The score chart of the goal
  final DateTime deadline; // The deadline of the goal

  Goal({
    required this.goalName,
    required this.goalDescription,
    required this.goalStatus,
    required this.goalCreatedAt,
    required this.goalCompletedAt,
    required this.goalPriority,
    required this.goalCurrentScore,
    required this.goalTargetScore,
    required this.goalPreviousScore,
    required this.goalNextScore,
    required this.goalMilestones,
    required this.currentMilestone,
    required this.overallTasks,
    required this.scoreChart,
    required this.deadline,
  });
}

// Define Milestone model to be used in the Goal model
class Milestone {
  final String milestoneName; // Name of the milestone
  final String milestoneDescription; // Description of the milestone
  final DateTime milestoneDeadline; // Deadline of the milestone
  final int milestoneTargetScore; // Target score of the milestone

  Milestone({
    required this.milestoneName,
    required this.milestoneDescription,
    required this.milestoneDeadline,
    required this.milestoneTargetScore,
  });
}

// Define Tasks model to be used in the Goal model
class Tasks {
  final String taskName; // Name of the task
  final String taskDescription; // Description of the task
  final int taskReservedHours; // Reserved hours of the task
  final int taskReservedMinutes; // Reserved minutes of the task
  final int taskDoneHours; // how many hours done
  final int taskDoneMinutes; // how many minutes done

  Tasks({
    required this.taskName,
    required this.taskDescription,
    required this.taskReservedHours,
    required this.taskReservedMinutes,
    required this.taskDoneHours,
    required this.taskDoneMinutes,
  });
}

// Define ScoreChart model to be used in the Goal model
class ScoreChart {
  final List<int> scores; // The scores of the chart
  final List<DateTime> dates; // The dates of the chart

  ScoreChart({required this.scores, required this.dates});
}

// Define habits model to be displayed with its items
class HabitsModel {
  final List<Habit> habits; // The list of habits

  HabitsModel({required this.habits});
}

// Define Habit model to be used in the HabitsModel model
class Habit {
  final String habitName; // Name of the habit
  final String habitDescription; // Description of the habit
  final int
  habitConsecutiveProgress; // How many times in a row the habit is done
  final int habitTotalProgress; // How many times the habit is done
  final String habitStatus; // The AI judgement of the habit

  Habit({
    required this.habitName,
    required this.habitDescription,
    required this.habitConsecutiveProgress,
    required this.habitTotalProgress,
    required this.habitStatus,
  });
}
