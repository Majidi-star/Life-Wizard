import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/theme_utils.dart';

class TodoScreen extends StatelessWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: const Text('Todo'),
        backgroundColor: ThemeUtils.getAppBarColor(context),
      ),
      drawer: const AppDrawer(),
      body: const Center(child: Text('Todo Screen')),
    );
  }
}
