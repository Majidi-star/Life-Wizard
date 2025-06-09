import 'package:flutter/material.dart';
import '../utils/theme_utils.dart';
import '../features/progress_dashboard/reward_repository.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Theme.of(context).colorScheme.primary,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(top: 16),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  'Life Wizard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              FutureBuilder<Map<String, dynamic>>(
                future: RewardRepository().getRewards(),
                builder: (context, snapshot) {
                  final points = snapshot.data?['points'] ?? 0;
                  final badges = snapshot.data?['badges'] ?? 'beginner';
                  final hoursWorked = snapshot.data?['hours_worked'] ?? 0.0;
                  return Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.stars, color: Colors.yellowAccent),
                        title: const Text(
                          'Points',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: Text(
                          points.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.timer,
                          color: Colors.lightGreenAccent,
                        ),
                        title: const Text(
                          'Hours Worked',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: Text(
                          (hoursWorked is double)
                              ? hoursWorked.toStringAsFixed(1)
                              : double.parse(
                                hoursWorked.toString(),
                              ).toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Divider(),
                    ],
                  );
                },
              ),
              _createDrawerItem(
                icon: Icons.chat,
                text: 'AI Chat',
                onTap: () => _navigateToNamed(context, '/'),
              ),
              _createDrawerItem(
                icon: Icons.calendar_today,
                text: 'Schedule',
                onTap: () => _navigateToNamed(context, '/schedule'),
              ),
              _createDrawerItem(
                icon: Icons.flag,
                text: 'Goals',
                onTap: () => _navigateToNamed(context, '/goals'),
              ),
              _createDrawerItem(
                icon: Icons.repeat,
                text: 'Habits',
                onTap: () => _navigateToNamed(context, '/habits'),
              ),
              _createDrawerItem(
                icon: Icons.check_box,
                text: 'Todo',
                onTap: () => _navigateToNamed(context, '/todo'),
              ),
              _createDrawerItem(
                icon: Icons.timer,
                text: 'Pro Clock',
                onTap: () => _navigateToNamed(context, '/pro_clock'),
              ),
              _createDrawerItem(
                icon: Icons.mood,
                text: 'Mood Data',
                onTap: () => _navigateToNamed(context, '/mood'),
              ),
              _createDrawerItem(
                icon: Icons.settings,
                text: 'Settings',
                onTap: () => _navigateToNamed(context, '/settings'),
              ),
            ],
          ),
        ),
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

  void _navigateToNamed(BuildContext context, String routeName) {
    Navigator.pop(context); // Close the drawer
    if (ModalRoute.of(context)?.settings.name != routeName) {
      Navigator.pushReplacementNamed(context, routeName);
    }
  }
}
