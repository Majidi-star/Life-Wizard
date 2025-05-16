import 'package:flutter/material.dart';

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
            icon: Icons.dashboard,
            text: 'Progress Dashboard',
            onTap: () => _navigateToNamed(context, '/progress'),
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
