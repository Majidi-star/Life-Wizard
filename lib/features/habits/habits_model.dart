// Habits model

class HabitsModel {
  final List<HabitsCard> habits; // List of habits (HabitsCard model)

  HabitsModel({required this.habits});
}

// Define the HabitsCard to be used in the HabitsModel
class HabitsCard {
  final String habitName; // Name of the habit
  final String habitDescription; // Description of the habit
  final int
  habitConsecutiveProgress; // The most previous number of consecutive times the habit has been done
  final int
  habitTotalProgress; // How many times the habit has been done in total
  final String createdAt; // Date of creation of the habit
  final List
  habitStart; // Used for showing the progress of the habit on a timeline
  final List
  habitEnd; // Used for showing the progress of the habit on a timeline
  final String habitStatus; // The AI judgement of the habit frequency

  HabitsCard({
    required this.habitName,
    required this.habitDescription,
    required this.habitConsecutiveProgress,
    required this.habitTotalProgress,
    required this.createdAt,
    required this.habitStart,
    required this.habitEnd,
    required this.habitStatus,
  });
}
