import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import '../../widgets/app_drawer.dart';
import '../../utils/theme_utils.dart';
import 'goals_bloc.dart';
import 'goals_event.dart';
import 'goals_state.dart';
import 'goals_model.dart';
import '../../main.dart' as app_main;
import '../../features/settings/settings_state.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  // Get color based on index - similar to the referenced function
  Color _getTaskColor(int index) {
    switch (index % 6) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.red;
      case 3:
        return Colors.purple;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.teal;
      default:
        return Colors.green;
    }
  }

  // Add a color getter for the color order (green, blue, red, purple, orange, teal)
  Color _getColorByIndex(int index) {
    switch (index % 6) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.red;
      case 3:
        return Colors.purple;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.teal;
      default:
        return Colors.green;
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<GoalsBloc>().setIsOnGoalsScreen(true);
    context.read<GoalsBloc>().add(const LoadGoals());
  }

  @override
  void dispose() {
    context.read<GoalsBloc>().setIsOnGoalsScreen(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Goals'),
        backgroundColor: ThemeUtils.getAppBarColor(context),
      ),
      drawer: const AppDrawer(),
      body: BlocBuilder<GoalsBloc, GoalsState>(
        builder: (context, state) {
          if (state is GoalsInitial || state is GoalsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is GoalsError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is GoalsLoaded) {
            return _buildContent(context, state);
          } else {
            return const Center(child: Text('Unknown state'));
          }
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, GoalsLoaded state) {
    final goals = state.goalsModel.goals;

    return Column(
      children: [
        Expanded(
          child:
              goals.isEmpty
                  ? const Center(
                    child: Text(
                      'No goals available. Add a goal to get started!',
                    ),
                  )
                  : ListView.builder(
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      final goal = goals[index];
                      final isExpanded = state.expandedGoals[index] ?? false;

                      return _buildGoalCard(
                        context,
                        goal,
                        index,
                        isExpanded,
                        state,
                      );
                    },
                  ),
        ),
        _buildDebugButton(context, state),
      ],
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    GoalsCard goal,
    int index,
    bool isExpanded,
    GoalsLoaded state,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final priorityColor = _getPriorityColor(goal.priority, colorScheme);
    final circleColor = _getTaskColor(index); // Use color order for circle

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              context.read<GoalsBloc>().add(ToggleGoalExpansion(index));
            },
            child: _buildGoalHeader(context, goal, priorityColor, index),
          ),
          // Use AnimatedContainer for smooth height animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            height:
                isExpanded
                    ? null
                    : 0, // Auto height when expanded, zero when collapsed
            child: AnimatedOpacity(
              opacity: isExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: _buildExpandedContent(context, goal, index, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalHeader(
    BuildContext context,
    GoalsCard goal,
    Color priorityColor,
    int? goalIndex,
  ) {
    final circleColor =
        goalIndex != null ? _getTaskColor(goalIndex) : priorityColor;
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: _getTaskColor(goalIndex ?? 0), width: 4.0),
        ),
      ),
      child: Row(
        children: [
          _buildPriorityCircle(
            goal.priority,
            circleColor,
          ), // Use color order for circle
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.goalName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                // Text('Progress: ${goal.goalProgress}%'),
              ],
            ),
          ),
          // Make the arrows and numbers clearer
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildScoreWithLabel(
                Icons.arrow_downward,
                goal.startingScore,
                'Previous',
              ),
              _buildScoreWithLabel(
                Icons.arrow_forward,
                goal.currentScore,
                'Current',
              ),
              _buildScoreWithLabel(
                Icons.arrow_upward,
                goal.futureScore,
                'Target',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreWithLabel(IconData icon, int value, String label) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 2),
            Text('$value'),
          ],
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildExpandedContent(
    BuildContext context,
    GoalsCard goal,
    int goalIndex,
    GoalsLoaded state,
  ) {
    final decodedPlan = jsonDecode(goal.planInfo) as Map<String, dynamic>;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description section
          _buildSectionHeader('Description'),
          Text(goal.goalDescription),
          const SizedBox(height: 16),

          // Milestones section
          _buildSectionHeader('Milestones'),
          if (decodedPlan.containsKey('milestones') &&
              decodedPlan['milestones'] is List)
            _buildMilestones(
              context,
              goalIndex,
              decodedPlan['milestones'],
              state,
            ),

          // Overall Plan section
          if (decodedPlan.containsKey('overallPlan') &&
              decodedPlan['overallPlan'] is Map)
            _buildOverallPlan(decodedPlan['overallPlan'], goalIndex),

          // Goal Formula section
          if (decodedPlan.containsKey('goalFormula') &&
              decodedPlan['goalFormula'] is Map)
            _buildGoalFormula(decodedPlan['goalFormula']),

          // Score Chart section
          if (decodedPlan.containsKey('scoreChart') &&
              decodedPlan['scoreChart'] is Map)
            _buildScoreChart(decodedPlan['scoreChart']),

          // Comparison Card section
          if (decodedPlan.containsKey('comparisonCard') &&
              decodedPlan['comparisonCard'] is Map)
            _buildComparisonCard(
              context,
              decodedPlan['comparisonCard'],
              goal.currentScore,
            ),

          // Plan Explanation section
          if (decodedPlan.containsKey('planExplanationCard') &&
              decodedPlan['planExplanationCard'] is Map)
            _buildPlanExplanation(decodedPlan['planExplanationCard']),
        ],
      ),
    );
  }

  Widget _buildMilestones(
    BuildContext context,
    int goalIndex,
    List<dynamic> milestones,
    GoalsLoaded state,
  ) {
    return Column(
      children: List.generate(
        milestones.length,
        (milestoneIndex) => _buildMilestone(
          context,
          goalIndex,
          milestoneIndex,
          milestones[milestoneIndex],
          state,
        ),
      ),
    );
  }

  Widget _buildMilestone(
    BuildContext context,
    int goalIndex,
    int milestoneIndex,
    Map<String, dynamic> milestone,
    GoalsLoaded state,
  ) {
    final isMilestoneExpanded =
        state.expandedMilestones[goalIndex]?[milestoneIndex] ?? false;
    final theme = Theme.of(context);
    final isCompleted = milestone['isCompleted'] ?? false;
    final progressText = milestone['milestoneProgress'] ?? '0%';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              context.read<GoalsBloc>().add(
                ToggleMilestoneExpansion(goalIndex, milestoneIndex),
              );
            },
            child: ListTile(
              title: Text(milestone['milestoneName'] ?? 'Untitled Milestone'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(milestone['milestoneDescription'] ?? ''),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Due: ${milestone['milestoneDate'] ?? 'Not set'}'),
                      const Spacer(),
                      Text(
                        'Progress: $progressText',
                        style: TextStyle(
                          color: isCompleted ? theme.colorScheme.primary : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: AnimatedRotation(
                turns: isMilestoneExpanded ? 0.25 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_right),
              ),
            ),
          ),
          // Use AnimatedContainer for smooth height animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            height:
                isMilestoneExpanded && milestone['milestoneTasks'] is List
                    ? null // Auto height when expanded
                    : 0, // Zero height when collapsed
            child: AnimatedOpacity(
              opacity: isMilestoneExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child:
                  milestone['milestoneTasks'] is List
                      ? _buildMilestoneTasks(
                        context,
                        goalIndex,
                        milestoneIndex,
                        milestone['milestoneTasks'],
                        state,
                      )
                      : const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneTasks(
    BuildContext context,
    int goalIndex,
    int milestoneIndex,
    List<dynamic> tasks,
    GoalsLoaded state,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          tasks.length,
          (taskIndex) => _buildMilestoneTask(
            context,
            goalIndex,
            milestoneIndex,
            taskIndex,
            tasks[taskIndex],
            state,
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneTask(
    BuildContext context,
    int goalIndex,
    int milestoneIndex,
    int taskIndex,
    Map<String, dynamic> task,
    GoalsLoaded state,
  ) {
    final theme = Theme.of(context);
    final isCompleted = task['isCompleted'] ?? false;
    final taskTime = task['taskTime'] ?? 0;
    final taskTimeFormat = task['taskTimeFormat'] ?? 'hours';
    final settingsState = app_main.settingsBloc.state;
    final taskColor = _getTaskColor(taskIndex);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: taskColor, width: 4.0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.circle_outlined,
                    color:
                        isCompleted
                            ? settingsState.activatedColor
                            : settingsState.deactivatedBorderColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task['taskName'] ?? 'Untitled Task',
                      style: TextStyle(
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  Text('($taskTime $taskTimeFormat)'),
                ],
              ),
              if (task['taskDescription'] != null)
                Padding(
                  padding: const EdgeInsets.only(left: 32.0, top: 4.0),
                  child: Text(
                    task['taskDescription'],
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              _buildTaskTimeline(task, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskTimeline(Map<String, dynamic> task, ThemeData theme) {
    final startPercentages =
        task['taskStartPercentage'] as List<dynamic>? ?? [0];
    final endPercentages = task['taskEndPercentage'] as List<dynamic>? ?? [100];
    final settingsState = app_main.settingsBloc.state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Row(
            children: [
              Icon(
                Icons.timeline,
                size: 14,
                color: theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 4),
              Text(
                'Timeline',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 15,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Timeline baseline
                  Container(
                    height: 5,
                    width: constraints.maxWidth,
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),

                  // Timeline segments
                  ...List.generate(
                    startPercentages.length.clamp(0, endPercentages.length),
                    (i) {
                      final start =
                          (startPercentages[i] is int)
                              ? startPercentages[i] as int
                              : int.tryParse(
                                    startPercentages[i].toString().replaceAll(
                                      '%',
                                      '',
                                    ),
                                  ) ??
                                  0;

                      final end =
                          (endPercentages[i] is int)
                              ? endPercentages[i] as int
                              : int.tryParse(
                                    endPercentages[i].toString().replaceAll(
                                      '%',
                                      '',
                                    ),
                                  ) ??
                                  100;

                      return Positioned(
                        left: constraints.maxWidth * start / 100,
                        width: constraints.maxWidth * (end - start) / 100,
                        top: 0,
                        height: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: settingsState.activatedColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOverallPlan(Map<String, dynamic> overallPlan, [int? goalIndex]) {
    final theme = Theme.of(context);
    // Use the same color as the progress icon in _buildTaskGroup
    final progressIconColor = theme.textTheme.bodySmall?.color;
    final settingsState = app_main.settingsBloc.state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Overall Plan'),
        if (overallPlan.containsKey('taskGroups') &&
            overallPlan['taskGroups'] is List)
          _buildTaskGroups(overallPlan['taskGroups'], goalIndex),
        if (overallPlan.containsKey('deadline'))
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: _getTaskColor(2), width: 4.0),
                ),
              ),
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(Icons.event, color: progressIconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Deadline: ${overallPlan['deadline'] ?? 'Not set'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTaskGroups(List<dynamic> taskGroups, [int? goalIndex]) {
    return Column(
      children: List.generate(
        taskGroups.length,
        (index) => _buildTaskGroup(taskGroups[index], index, goalIndex),
      ),
    );
  }

  Widget _buildTaskGroup(
    Map<String, dynamic> taskGroup,
    int index, [
    int? goalIndex,
  ]) {
    final theme = Theme.of(context);
    final time = (taskGroup['taskGroupTime'] as int?) ?? 0;
    final timeFormat = taskGroup['taskGroupTimeFormat'] as String? ?? 'hours';
    final taskColor = _getTaskColor(index);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: taskColor, width: 4.0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(taskGroup['taskGroupName'] ?? 'Untitled Group'),
                  ),
                  Text('($time $timeFormat)'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalFormula(Map<String, dynamic> goalFormula) {
    final theme = Theme.of(context);
    final settingsState = app_main.settingsBloc.state;
    final currentScore = goalFormula['currentScore'] ?? 0;
    final goalScore = goalFormula['goalScore'] ?? 0;
    final formula = goalFormula['goalFormula'] ?? 'No formula defined';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Goal Formula'),
        Card(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: settingsState.activatedColor,
                  width: 4.0,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calculate, color: settingsState.activatedColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formula,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(
                  color: Theme.of(context).colorScheme.surfaceTint,
                  height: 24,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildScoreBox(
                      'Current Score',
                      currentScore,
                      theme,
                      settingsState,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.arrow_forward,
                        color: settingsState.activatedColor,
                      ),
                    ),
                    _buildScoreBox(
                      'Target Score',
                      goalScore,
                      theme,
                      settingsState,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildScoreBox(
    String label,
    int score,
    ThemeData theme,
    SettingsState settingsState,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: settingsState.activatedColor.withOpacity(0.5),
            ),
          ),
          child: Text(
            score.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreChart(Map<String, dynamic> scoreChart) {
    final theme = Theme.of(context);
    final scores = scoreChart['scores'] as List<dynamic>? ?? [];
    final dates = scoreChart['dates'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Progress Over Time'),
        Card(
          child: Container(
            padding: const EdgeInsets.all(12.0),
            width: double.infinity,
            height: 150,
            child:
                scores.isEmpty || dates.isEmpty
                    ? const Center(child: Text('No data available'))
                    : _buildSimpleChart(scores, dates, theme),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSimpleChart(
    List<dynamic> scores,
    List<dynamic> dates,
    ThemeData theme,
  ) {
    // This is a simple chart representation, in a real app a chart library should be used
    final settingsState = app_main.settingsBloc.state;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxScore = scores.fold(
          0,
          (max, score) => score > max ? score : max,
        );
        final height = constraints.maxHeight;
        final width = constraints.maxWidth;

        return CustomPaint(
          size: Size(width, height),
          painter: SimpleChartPainter(
            scores: scores.map((s) => s as int).toList(),
            dates: dates.map((d) => d as String).toList(),
            maxScore: maxScore,
            color: settingsState.activatedColor,
          ),
        );
      },
    );
  }

  Widget _buildComparisonCard(
    BuildContext context,
    Map<String, dynamic> comparisonCard,
    int userScore,
  ) {
    final theme = Theme.of(context);
    final comparisons = comparisonCard['comparisons'] as List<dynamic>? ?? [];
    final settingsState = app_main.settingsBloc.state;
    final priorityColor = _getPriorityColor(
      7,
      theme.colorScheme,
    ); // Use high priority color for user

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Comparison'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // User's score
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: settingsState.activatedColor,
                    child: Icon(
                      Icons.person,
                      color: settingsState.deactivatedBorderColor,
                    ),
                  ),
                  title: const Text('You'),
                  trailing: Text(
                    userScore.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                // Divider
                Divider(color: Theme.of(context).colorScheme.surfaceTint),

                // Competitors
                ...comparisons.map((comparison) {
                  final name = comparison['name'] ?? 'Unknown';
                  final level = comparison['level'] ?? 'N/A';
                  final score = comparison['score'] ?? 0;
                  final comparisonColor = _getPriorityColor(
                    3,
                    theme.colorScheme,
                  ); // Use lower priority color for competitors

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.person_outline, color: comparisonColor),
                    ),
                    title: Text(name),
                    subtitle: Text(level),
                    trailing: Text(score.toString()),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPlanExplanation(Map<String, dynamic> planExplanationCard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Plan Explanation'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              planExplanationCard['planExplanation'] ??
                  'No explanation provided.',
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPriorityCircle(int priority, Color color) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Center(
        child: Text(
          priority.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority, ColorScheme colorScheme) {
    if (priority >= 7) return Colors.red;
    if (priority >= 4) return Colors.orange;
    return Colors.green;
  }

  Widget _buildDebugButton(BuildContext context, GoalsLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: () {
          _showDebugInfo(context, state);
        },
        icon: const Icon(Icons.bug_report),
        label: const Text('Debug Goals State'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  void _showDebugInfo(BuildContext context, GoalsLoaded state) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Goals State Debug Info'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Number of goals: ${state.goalsModel.goals.length}'),
                  Text(
                    'Selected goal index: ${state.selectedGoalIndex ?? "None"}',
                  ),
                  Text('Expanded goals: ${state.expandedGoals}'),
                  Text('Expanded milestones: ${state.expandedMilestones}'),
                  Text('Timeline view tasks: ${state.timelineViewTasks}'),
                  const Divider(),
                  const Text(
                    'Goals:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...state.goalsModel.goals.asMap().entries.map((entry) {
                    final index = entry.key;
                    final goal = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Goal $index: ${goal.goalName}'),
                          Text('   Progress: ${goal.goalProgress}%'),
                          Text('   Priority: ${goal.priority}'),
                          Text(
                            '   Scores: ${goal.startingScore} → ${goal.currentScore} → ${goal.futureScore}',
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}

class SimpleChartPainter extends CustomPainter {
  final List<int> scores;
  final List<String> dates;
  final int maxScore;
  final Color color;

  SimpleChartPainter({
    required this.scores,
    required this.dates,
    required this.maxScore,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

    final dotPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path = Path();

    // Draw the line chart
    for (var i = 0; i < scores.length; i++) {
      final x = i * size.width / (scores.length - 1);
      final y = size.height - (scores[i] / maxScore) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw dots at each data point
      canvas.drawCircle(Offset(x, y), 4, dotPaint);

      // Draw current score label on the last point
      if (i == scores.length - 1) {
        final scoreTextStyle = TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        );

        final scoreSpan = TextSpan(
          text: scores[i].toString(),
          style: scoreTextStyle,
        );

        final scorePainter = TextPainter(
          text: scoreSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        // Position the score above the point
        scorePainter.paint(
          canvas,
          Offset(x - scorePainter.width / 2, y - scorePainter.height - 5),
        );
      }
    }

    canvas.drawPath(path, paint);

    // Draw labels for the first and last date
    if (dates.isNotEmpty) {
      final textStyle = TextStyle(color: Colors.grey[600], fontSize: 10);
      final firstDateSpan = TextSpan(
        text: _formatDate(dates.first),
        style: textStyle,
      );
      final lastDateSpan = TextSpan(
        text: _formatDate(dates.last),
        style: textStyle,
      );

      final firstDatePainter = TextPainter(
        text: firstDateSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final lastDatePainter = TextPainter(
        text: lastDateSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      firstDatePainter.paint(canvas, Offset(0, size.height + 5));
      lastDatePainter.paint(
        canvas,
        Offset(size.width - lastDatePainter.width, size.height + 5),
      );
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.tryParse(dateString);
    if (date == null) return dateString;

    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  bool shouldRepaint(SimpleChartPainter oldDelegate) =>
      oldDelegate.scores != scores ||
      oldDelegate.dates != dates ||
      oldDelegate.maxScore != maxScore ||
      oldDelegate.color != color;
}
