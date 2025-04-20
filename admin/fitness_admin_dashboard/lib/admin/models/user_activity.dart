class UserActivity {
  final DateTime date;
  final int newUsers;
  final int mealEntries;
  final int workoutEntries;
  final int progressEntries;
  
  UserActivity({
    required this.date,
    required this.newUsers,
    required this.mealEntries,
    required this.workoutEntries,
    required this.progressEntries,
  });
  
  int get totalActivity => mealEntries + workoutEntries + progressEntries;
}