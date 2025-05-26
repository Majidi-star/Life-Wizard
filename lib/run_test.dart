import 'package:flutter/material.dart';
import 'database_test.dart' as database_test;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Launcher',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TestLauncherScreen(),
    );
  }
}

class TestLauncherScreen extends StatelessWidget {
  const TestLauncherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Launcher')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                database_test.main();
              },
              child: const Text('Run Database Test'),
            ),
          ],
        ),
      ),
    );
  }
}
