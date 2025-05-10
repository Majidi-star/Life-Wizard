import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

class FitnessTrackerScreen extends StatelessWidget {
  const FitnessTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: const AppDrawer(),
      body: const Center(child: Text('Fitness Tracker Screen')),
    );
  }
}
