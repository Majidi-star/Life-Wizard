import 'package:flutter/material.dart';
import '../progress_dashboard/reward_repository.dart';

/// Service for handling points calculations and notifications
class PointsService {
  static final PointsService _instance = PointsService._internal();
  final RewardRepository _rewardRepository = RewardRepository();

  factory PointsService() {
    return _instance;
  }

  PointsService._internal();

  /// Calculate points for completing a task in the schedule
  /// Returns the number of points earned
  Future<int> calculateScheduleTaskPoints(
    DateTime startTime,
    DateTime endTime,
  ) async {
    // Calculate duration in minutes
    final durationInMinutes = endTime.difference(startTime).inMinutes;

    // If less than 2 minutes, no points
    if (durationInMinutes < 2) {
      return 0;
    }

    // Calculate points based on hours (1 point per hour, minimum 1 point for tasks >= 2 minutes)
    final points = (durationInMinutes / 60).ceil();
    return points;
  }

  /// Calculate hours for a schedule task
  /// Returns the number of hours worked (in decimal form)
  double calculateHoursWorked(DateTime startTime, DateTime endTime) {
    // Calculate duration in minutes
    final durationInMinutes = endTime.difference(startTime).inMinutes;

    // Convert to hours with decimal precision
    final hours = durationInMinutes / 60.0;

    // Round to 2 decimal places for cleaner display
    return double.parse(hours.toStringAsFixed(2));
  }

  /// Add hours worked for completing a schedule task
  /// Returns the number of hours added
  Future<double> addHoursWorked(DateTime startTime, DateTime endTime) async {
    final hours = calculateHoursWorked(startTime, endTime);
    if (hours > 0) {
      await _rewardRepository.addHoursWorked(hours);
      print('Added $hours hours to total hours worked');
    }
    return hours;
  }

  /// Remove hours worked for uncompleting a schedule task
  /// Returns the number of hours removed (negative value)
  Future<double> removeHoursWorked(DateTime startTime, DateTime endTime) async {
    final hours = calculateHoursWorked(startTime, endTime);
    if (hours > 0) {
      await _rewardRepository.addHoursWorked(-hours);
      print('Removed $hours hours from total hours worked');
    }
    return -hours;
  }

  /// Get the total hours worked
  Future<double> getTotalHoursWorked() async {
    return await _rewardRepository.getHoursWorked();
  }

  /// Add points for completing a todo or habit
  /// Returns the number of points added (always 1 for todo/habit)
  Future<int> addPointsForCompletion() async {
    const int points = 1;
    await _rewardRepository.addPoints(points);
    return points;
  }

  /// Remove points for uncompleting a todo or habit
  /// Returns the number of points removed (always -1 for todo/habit)
  Future<int> removePointsForUncompletion() async {
    const int points = -1;
    await _rewardRepository.addPoints(points);
    return points;
  }

  /// Add points for completing a schedule task
  /// Returns the number of points added
  Future<int> addPointsForScheduleTask(
    DateTime startTime,
    DateTime endTime,
  ) async {
    final points = await calculateScheduleTaskPoints(startTime, endTime);
    if (points > 0) {
      await _rewardRepository.addPoints(points);
    }
    return points;
  }

  /// Remove points for uncompleting a schedule task
  /// Returns the number of points removed
  Future<int> removePointsForScheduleTask(
    DateTime startTime,
    DateTime endTime,
  ) async {
    final points = await calculateScheduleTaskPoints(startTime, endTime);
    if (points > 0) {
      await _rewardRepository.addPoints(-points);
    }
    return -points;
  }

  /// Show a snackbar with points notification
  void showPointsNotification(BuildContext context, int points) {
    if (points == 0) return;

    final String message =
        points > 0
            ? "You earned $points point${points > 1 ? 's' : ''}!"
            : "You lost ${points.abs()} point${points < -1 ? 's' : ''}";

    final Color backgroundColor =
        points > 0 ? Colors.green.shade700 : Colors.red.shade700;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              points > 0 ? Icons.arrow_upward : Icons.arrow_downward,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show a snackbar with hours worked notification
  void showHoursWorkedNotification(BuildContext context, double hours) {
    if (hours == 0) return;

    final String message =
        hours > 0
            ? "You logged ${hours.toStringAsFixed(1)} hour${hours != 1.0 ? 's' : ''} of work!"
            : "Removed ${hours.abs().toStringAsFixed(1)} hour${hours != -1.0 ? 's' : ''} from your total";

    final Color backgroundColor =
        hours > 0 ? Colors.blue.shade700 : Colors.orange.shade700;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              hours > 0 ? Icons.timer : Icons.timer_off,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
