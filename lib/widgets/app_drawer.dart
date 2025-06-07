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
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            FutureBuilder<Map<String, dynamic>>(
              future: RewardRepository().getRewards(),
              builder: (context, snapshot) {
                final points = snapshot.data?['points'] ?? 0;
                final badges = snapshot.data?['badges'] ?? 'beginner';
                final cookieJar = snapshot.data?['cookie_jar'] ?? [];
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
                        Icons.military_tech,
                        color: Colors.lightBlueAccent,
                      ),
                      title: const Text(
                        'Badge',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Text(
                        badges.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.cookie, color: Colors.brown),
                      title: const Text(
                        'Cookie Jar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.brown[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${cookieJar.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor:
                                  Theme.of(context).colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.cookie,
                                    color: Colors.brown,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'My Cookie Jar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              content:
                                  cookieJar.isEmpty
                                      ? const Text('No accomplishments yet!')
                                      : SizedBox(
                                        width: 300,
                                        child: ListView.separated(
                                          shrinkWrap: true,
                                          itemCount: cookieJar.length,
                                          separatorBuilder:
                                              (_, __) => const Divider(),
                                          itemBuilder: (context, idx) {
                                            return ListTile(
                                              leading: Icon(
                                                Icons.check_circle,
                                                color: Colors.greenAccent,
                                              ),
                                              title: Text(
                                                cookieJar[idx],
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Close'),
                                ),
                              ],
                            );
                          },
                        );
                      },
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
