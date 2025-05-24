import 'dart:convert';
import 'goals_model.dart';
import 'goals_state.dart';

void main() {
  testGoalsState();
}

void testGoalsState() {
  // Create test data
  final goalsCard = GoalsCard(
    goalName: "Learn Flutter",
    goalDescription: "Master Flutter development",
    startingScore: 0,
    currentScore: 45,
    futureScore: 100,
    createdAt: DateTime.now().toIso8601String(),
    goalProgress: 45,
    planInfo: jsonEncode({
      "milestones": [
        {
          "milestoneDate": "2025-05-30",
          "milestoneName": "Complete Phase 1",
          "milestoneDescription": "Finish initial development",
          "milestoneProgress": "70%",
          "isCompleted": false,
          "milestoneTasks": [],
        },
      ],
    }),
    priority: 8,
  );

  final goalsModel = GoalsModel(goals: [goalsCard]);
  final state = GoalsLoaded(goalsModel: goalsModel);

  print('\n===== Goals State =====');
  print('GoalsModel contains ${state.goalsModel.goals.length} goals');
  if (state.goalsModel.goals.isNotEmpty) {
    final goal = state.goalsModel.goals[0];
    print('Goal Name: ${goal.goalName}');
    print('Goal Description: ${goal.goalDescription}');
    print('Progress: ${goal.goalProgress}%');
    print(
      'Scores: ${goal.startingScore} → ${goal.currentScore} → ${goal.futureScore}',
    );
    print('Priority: ${goal.priority}');
    print('Created At: ${goal.createdAt}');

    final decodedPlan = jsonDecode(goal.planInfo);
    print('Plan Info contains ${decodedPlan['milestones'].length} milestones');
  }

  final expandedState = state.copyWith(
    expandedGoals: {0: true},
    expandedMilestones: {
      0: {0: true},
    },
    timelineViewTasks: {
      0: {
        0: {0: true},
      },
    },
  );

  print('\nExpanded state:');
  print('Goal 0 expanded: ${expandedState.expandedGoals[0]}');
  print(
    'Milestone 0 of Goal 0 expanded: ${expandedState.expandedMilestones[0]?[0]}',
  );
  print(
    'Timeline view for Task 0: ${expandedState.timelineViewTasks[0]?[0]?[0]}',
  );
  print('=======================\n');
}
