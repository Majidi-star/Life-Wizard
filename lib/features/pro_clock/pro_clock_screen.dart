import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

class ProClockScreen extends StatelessWidget {
  const ProClockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pro Clock'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: const AppDrawer(),
      body: const Center(child: Text('Pro Clock Screen')),
    );
  }
}
