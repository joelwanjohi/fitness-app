class AdminStats {
  final int totalUsers;
  final int activeUsers;
  final int totalMealEntries;
  final int totalWorkoutEntries;
  final int totalProgressEntries;
  final DateTime lastUpdated;
  
  AdminStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalMealEntries,
    required this.totalWorkoutEntries,
    required this.totalProgressEntries,
    required this.lastUpdated,
  });
}