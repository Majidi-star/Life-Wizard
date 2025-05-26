import 'package:flutter/material.dart';
import 'database_initializer.dart';
import 'features/schedule/schedule_repository.dart';

void main() {
  runApp(const DatabaseTestApp());
}

class DatabaseTestApp extends StatelessWidget {
  const DatabaseTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Database Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DatabaseTestScreen(),
    );
  }
}

class DatabaseTestScreen extends StatefulWidget {
  const DatabaseTestScreen({super.key});

  @override
  State<DatabaseTestScreen> createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
  String _testResults = 'Running tests...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  Future<void> _runTests() async {
    try {
      StringBuffer results = StringBuffer();

      results.writeln('===== DATABASE TEST: TimeBoxStatus Field =====');

      // Initialize the database
      final db = await DatabaseInitializer.database;

      // Create a repository instance
      final repository = ScheduleRepository(db);

      // Get all schedules
      final schedules = await repository.getAllSchedules();

      if (schedules != null && schedules.isNotEmpty) {
        results.writeln('Found ${schedules.length} schedules in the database');

        // Print the raw values and converted values for each schedule
        for (int i = 0; i < schedules.length; i++) {
          final schedule = schedules[i];
          results.writeln('\nSchedule $i (ID: ${schedule.id}):');
          results.writeln('  Activity: ${schedule.activity}');
          results.writeln(
            '  TimeBoxStatus (boolean): ${schedule.timeBoxStatus}',
          );

          // Get the raw value from the database
          final rawResults = await db.query(
            'schedule',
            columns: ['timeBoxStatus'],
            where: 'id = ?',
            whereArgs: [schedule.id],
          );

          if (rawResults.isNotEmpty) {
            final rawValue = rawResults.first['timeBoxStatus'];
            results.writeln(
              '  Raw DB value: $rawValue (type: ${rawValue.runtimeType})',
            );
          }
        }

        // Test updating a timeBoxStatus
        if (schedules.isNotEmpty) {
          final firstSchedule = schedules.first;
          final newStatus = !firstSchedule.timeBoxStatus;

          results.writeln('\n--- Testing timeBoxStatus update ---');
          results.writeln(
            'Updating schedule ${firstSchedule.id} status from ${firstSchedule.timeBoxStatus} to $newStatus',
          );

          // Update using the repository method
          await repository.updateScheduleTimeBoxStatus(
            firstSchedule.id!,
            newStatus,
          );

          // Verify the update
          final updatedSchedule = await repository.getScheduleById(
            firstSchedule.id!,
          );
          results.writeln(
            'After update - Status in model: ${updatedSchedule?.timeBoxStatus}',
          );

          // Get the raw value from the database
          final rawResults = await db.query(
            'schedule',
            columns: ['timeBoxStatus'],
            where: 'id = ?',
            whereArgs: [firstSchedule.id],
          );

          if (rawResults.isNotEmpty) {
            final rawValue = rawResults.first['timeBoxStatus'];
            results.writeln(
              'After update - Raw DB value: $rawValue (type: ${rawValue.runtimeType})',
            );
          }
        }
      } else {
        results.writeln('No schedules found in the database');
      }

      results.writeln('\n===== TEST COMPLETE =====');

      setState(() {
        _testResults = results.toString();
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _testResults = 'Error: $e\n\nStack trace:\n$stackTrace';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Database Test')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Results:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _testResults,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isLoading = true;
          });
          _runTests();
        },
        tooltip: 'Run Tests Again',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
