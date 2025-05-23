import 'package:flutter/material.dart';
import 'habits_model.dart';

class HabitCard extends StatelessWidget {
  final HabitsCard habit;
  final int colorIndex;

  const HabitCard({super.key, required this.habit, required this.colorIndex});

  Color getColor() {
    switch (colorIndex % 6) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.red;
      case 3:
        return Colors.purple;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.teal;
      default:
        return Colors.green;
    }
  }

  String getTimeAgo() {
    final createdAt = DateTime.parse(habit.createdAt);
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'created $years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'created $months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return 'created ${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return 'created ${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return 'created ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'created just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getColor();
    final themeColor = Theme.of(context).colorScheme.secondary;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          border: Border(left: BorderSide(color: color, width: 8.0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 10, backgroundColor: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      habit.habitName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    getTimeAgo(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (habit.habitDescription.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(habit.habitDescription),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildProgressIndicator(
                    "Consecutive",
                    habit.habitConsecutiveProgress.toString(),
                    color,
                    context,
                  ),
                  const SizedBox(width: 16),
                  _buildProgressIndicator(
                    "Total",
                    habit.habitTotalProgress.toString(),
                    color,
                    context,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTimelineGraph(color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
    String label,
    String value,
    Color color,
    BuildContext context,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.check_circle, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineGraph(Color color) {
    // Convert start and end lists to pairs for visualization
    List<String> startList = [];
    List<String> endList = [];

    // Parse comma-separated strings if necessary
    if (habit.habitStart.length == 1 && habit.habitStart[0] is String) {
      startList = (habit.habitStart[0] as String).split(',');
    } else {
      startList = habit.habitStart.map((e) => e.toString()).toList();
    }

    if (habit.habitEnd.length == 1 && habit.habitEnd[0] is String) {
      endList = (habit.habitEnd[0] as String).split(',');
    } else {
      endList = habit.habitEnd.map((e) => e.toString()).toList();
    }

    int maxRound = 0;
    if (endList.isNotEmpty) {
      maxRound =
          int.tryParse(
            endList
                .map((s) => int.tryParse(s) ?? 0)
                .reduce((a, b) => a > b ? a : b)
                .toString(),
          ) ??
          0;
    }
    maxRound = maxRound < 10 ? 10 : maxRound;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progress Timeline',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: CustomPaint(
            size: const Size(double.infinity, 30),
            painter: TimelinePainter(
              startPoints:
                  startList.map((e) => int.tryParse(e.trim()) ?? 0).toList(),
              endPoints:
                  endList.map((e) => int.tryParse(e.trim()) ?? 0).toList(),
              color: color,
              maxRound: maxRound,
            ),
          ),
        ),
      ],
    );
  }
}

class TimelinePainter extends CustomPainter {
  final List<int> startPoints;
  final List<int> endPoints;
  final Color color;
  final int maxRound;

  TimelinePainter({
    required this.startPoints,
    required this.endPoints,
    required this.color,
    required this.maxRound,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background line paint - thin gray line
    final backgroundPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    // Filled streak paint - thicker colored line
    final streakPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5;

    // Draw timeline base (background line)
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      backgroundPaint,
    );

    final maxPoints = maxRound + 1; // +1 for visual spacing

    // Draw streak lines without circles
    for (int i = 0; i < startPoints.length; i++) {
      if (i < endPoints.length) {
        int start = startPoints[i];
        int end = endPoints[i];

        // Only draw the line connecting the streak
        final startX = start * (size.width / maxPoints);
        final endX = end * (size.width / maxPoints);
        canvas.drawLine(
          Offset(startX, size.height / 2),
          Offset(endX, size.height / 2),
          streakPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
