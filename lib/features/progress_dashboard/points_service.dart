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
}
