import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/theme_utils.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: ThemeUtils.getAppBarColor(context),
      ),
      drawer: const AppDrawer(),
      body: const Center(child: Text('Schedule Screen')),
    );
  }
}
