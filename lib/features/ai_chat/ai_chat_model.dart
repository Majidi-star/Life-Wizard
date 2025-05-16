// AI Chat model
import 'dart:ffi';

// Define a list of chat items (text, process, milestone) and the mode (conversation or text)
class AIChatScreenModel {
  // Define the mode (conversation or text)
  final String mode;

  // Define a list of chat items
  final List chat;

  AIChatScreenModel({required this.mode, required this.chat});
}

// Define the content to show in the chat as sent messages
class Text {
  final String content; // Content of the text message
  final bool userInput; // Is the message from the user or AI

  Text({required this.content, required this.userInput});
}

// Define the process that AI is going throuhg while planning or constructing the answer
class AIProcess {
  final List processes; // List of processes names  e.g. ["process1", ...]
  final int processNum; // number of processes
  final int currentProcessNum; // current process number
  final String currentProcessName; // current process name

  AIProcess({
    required this.processes,
    required this.processNum,
    required this.currentProcessNum,
    required this.currentProcessName,
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
  milestoneTasks; // List of milestone tasks (class MilestoneTask)

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
  final Int taskTime; // How many hours or minutes the task will take
  final String taskTimeFormat; // Format of the timeTask (minutes or hours)
  final Int
  taskStartPercentage; // Compared to other tasks when the task will start
  final Int taskEndPercentage; // Compared to other tasks when the task will end

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
  final Int taskGroupProgress; // The progress of task group in percentage
  final Int
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
  final Int currentScore;
  final Int goalScore;

  GoalFormula({
    required this.goalFormula,
    required this.currentScore,
    required this.goalScore,
  });
}

// Define the chart of scores over time
class ScoreChart {
  final List scores;

  ScoreChart({required this.scores});
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
  final Int score; // The score of the imagenary person

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
