import 'package:flutter/material.dart';
import '../features/ai_chat/ai_chat_screen.dart';
import '../features/schedule/schedule_screen.dart';
import '../features/goals/goals_screen.dart';
import '../features/skills/skills_screen.dart';
import '../features/habits/habits_screen.dart';
import '../features/todo/todo_screen.dart';
import '../features/progress_dashboard/progress_dashboard_screen.dart';
import '../features/pro_clock/pro_clock_screen.dart';
import '../features/fitness_tracker/fitness_tracker_screen.dart';
import '../features/mood_data/mood_data_screen.dart';
import '../features/settings/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Text(
              'Life Wizard',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          _createDrawerItem(
            icon: Icons.chat,
            text: 'AI Chat',
            onTap: () => _navigateTo(context, const AIChatScreen()),
          ),
          _createDrawerItem(
            icon: Icons.calendar_today,
            text: 'Schedule',
            onTap: () => _navigateTo(context, const ScheduleScreen()),
          ),
          _createDrawerItem(
            icon: Icons.flag,
            text: 'Goals',
            onTap: () => _navigateTo(context, const GoalsScreen()),
          ),
          _createDrawerItem(
            icon: Icons.psychology,
            text: 'Skills',
            onTap: () => _navigateTo(context, const SkillsScreen()),
          ),
          _createDrawerItem(
            icon: Icons.repeat,
            text: 'Habits',
            onTap: () => _navigateTo(context, const HabitsScreen()),
          ),
          _createDrawerItem(
            icon: Icons.check_box,
            text: 'Todo',
            onTap: () => _navigateTo(context, const TodoScreen()),
          ),
          _createDrawerItem(
            icon: Icons.dashboard,
            text: 'Progress Dashboard',
            onTap: () => _navigateTo(context, const ProgressDashboardScreen()),
          ),
          _createDrawerItem(
            icon: Icons.timer,
            text: 'Pro Clock',
            onTap: () => _navigateTo(context, const ProClockScreen()),
          ),
          _createDrawerItem(
            icon: Icons.fitness_center,
            text: 'Fitness Tracker',
            onTap: () => _navigateTo(context, const FitnessTrackerScreen()),
          ),
          _createDrawerItem(
            icon: Icons.mood,
            text: 'Mood Data',
            onTap: () => _navigateTo(context, const MoodDataScreen()),
          ),
          _createDrawerItem(
            icon: Icons.settings,
            text: 'Settings',
            onTap: () => _navigateTo(context, const SettingsScreen()),
          ),
        ],
      ),
    );
  }

  Widget _createDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(leading: Icon(icon), title: Text(text), onTap: onTap);
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close the drawer
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}
