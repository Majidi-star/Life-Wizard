// Goals model

// Define the GoalsModel to be displayed in the GoalsScreen
class GoalsModel {
  final List<GoalsCard> goals; // List of goals cards

  GoalsModel({required this.goals});
}

// Define the GoalsCard to be used in the GoalsModel
class GoalsCard {
  final String goalName; // Name of the goal
  final String goalDescription; // Description of the goal
  final int startingScore; // Starting score of the goal
  final int currentScore; // Current score of the goal
  final int futureScore; // Future score of the goal
  final String createdAt; // Date of creation of the goal
  final int goalProgress; // Progress of the goal
  final String
  planInfo; // the plan info of the goal (e.g. milestones, tasks, etc.) as JSON string
  final int priority; // Priority of the goal

  GoalsCard({
    required this.goalName,
    required this.goalDescription,
    required this.startingScore,
    required this.currentScore,
    required this.futureScore,
    required this.createdAt,
    required this.goalProgress,
    required this.planInfo,
    required this.priority,
  });
}

// Define a list of milestones to display on chat
class Milestone {
  final List<MilestoneCard> milestones; // The list of milestones

  Milestone({required this.milestones});
}

// Define a milestone card to display the milestone info on chat
class MilestoneCard {
  final String milestoneDate; // Deadline of the milestone
  final String milestoneName; // Name of the milestone
  final String milestoneDescription; // Description of the milestone
  final String milestoneProgress; // The percentage of milestone progress
  final bool isCompleted; // Is the milestone completed
  final List<MilestoneTask>
  milestoneTasks; // List of milestone tasks (MilestoneTask model)

  MilestoneCard({
    required this.milestoneDate,
    required this.milestoneName,
    required this.milestoneDescription,
    required this.milestoneProgress,
    required this.isCompleted,
    required this.milestoneTasks,
  });
}

// Define the task inside a milestone card and its attributes
class MilestoneTask {
  final String taskName; // Name of the task
  final String taskDescription; // Description of the task
  final bool isCompleted; // Is the task completed
  final int taskTime; // How many hours or minutes the task will take
  final String taskTimeFormat; // Format of the timeTask (minutes or hours)
  final List
  taskStartPercentage; // Compared to other tasks when the task will start
  final List
  taskEndPercentage; // Compared to other tasks when the task will end

  MilestoneTask({
    required this.taskName,
    required this.taskDescription,
    required this.isCompleted,
    required this.taskTime,
    required this.taskTimeFormat,
    required this.taskStartPercentage,
    required this.taskEndPercentage,
  });
}

// Define the overall plan on chat
class OverallPlan {
  final List<TaskGroup> taskGroups; // List of task groups to display
  final String deadline;

  OverallPlan({required this.taskGroups, required this.deadline});
}

// Define task groups for the overall plan
class TaskGroup {
  final String taskGroupName; // Name of the task group
  final int taskGroupProgress; // The progress of task group in percentage
  final int
  taskGroupTime; // The amount of time the task group needs (hours or minutes)
  final String
  taskGroupTimeFormat; // The format of taskGroupTime (hours or minutes)

  TaskGroup({
    required this.taskGroupName,
    required this.taskGroupProgress,
    required this.taskGroupTime,
    required this.taskGroupTimeFormat,
  });
}

// Define the formula for measuring the goal
class GoalFormula {
  final String goalFormula;
  final int currentScore;
  final int goalScore;

  GoalFormula({
    required this.goalFormula,
    required this.currentScore,
    required this.goalScore,
  });
}

// Define the chart of scores over time
class ScoreChart {
  final List scores;
  final List dates;

  ScoreChart({required this.scores, required this.dates});
}

// Define the comparison card
class ComparisonCard {
  final List<ComparisonItem> comparisons; // The list of persons to compare

  ComparisonCard({required this.comparisons});
}

// Define the comparison items to be used in comparison cards
class ComparisonItem {
  final String name; // Name of the imagenary person to compare
  final String level; // The level of the imagenary person
  final int score; // The score of the imagenary person

  ComparisonItem({
    required this.name,
    required this.level,
    required this.score,
  });
}

// Define plan explanation card
class PlanExplanationCard {
  final String planExplanation; // The explanation of the plan

  PlanExplanationCard({required this.planExplanation});
}
