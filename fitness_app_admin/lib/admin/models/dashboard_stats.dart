class DashboardStats {
  final int totalUsers;
  final int totalMeals;
  final int totalWorkouts;
  final int totalProgressEntries;
  final int activeUsersLast7Days;
  final int mealsTrackedLast7Days;
  final int workoutsCompletedLast7Days;
  final Map<String, int> userRegistrationByMonth;
  final Map<String, double> avgProgressScoreByMonth;

  DashboardStats({
    required this.totalUsers,
    required this.totalMeals,
    required this.totalWorkouts,
    required this.totalProgressEntries,
    required this.activeUsersLast7Days,
    required this.mealsTrackedLast7Days,
    required this.workoutsCompletedLast7Days,
    required this.userRegistrationByMonth,
    required this.avgProgressScoreByMonth,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      totalUsers: 0,
      totalMeals: 0,
      totalWorkouts: 0,
      totalProgressEntries: 0,
      activeUsersLast7Days: 0,
      mealsTrackedLast7Days: 0,
      workoutsCompletedLast7Days: 0,
      userRegistrationByMonth: {},
      avgProgressScoreByMonth: {},
    );
  }
}

class UserActivityStats {
  final String userId;
  final String userName;
  final String userEmail;
  final int mealCount;
  final int workoutCount;
  final int progressCount;
  final DateTime lastActive;

  UserActivityStats({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.mealCount,
    required this.workoutCount,
    required this.progressCount,
    required this.lastActive,
  });
}

class MealStats {
  final int totalMeals;
  final double avgCaloriesPerMeal;
  final double avgProteinPerMeal;
  final double avgFatPerMeal;
  final Map<String, int> mealsByType; // Breakfast, lunch, dinner, etc.
  final Map<String, int> mealsByDayOfWeek;

  MealStats({
    required this.totalMeals,
    required this.avgCaloriesPerMeal,
    required this.avgProteinPerMeal,
    required this.avgFatPerMeal,
    required this.mealsByType,
    required this.mealsByDayOfWeek,
  });

  factory MealStats.empty() {
    return MealStats(
      totalMeals: 0,
      avgCaloriesPerMeal: 0,
      avgProteinPerMeal: 0,
      avgFatPerMeal: 0,
      mealsByType: {},
      mealsByDayOfWeek: {},
    );
  }
}

class WorkoutStats {
  final int totalWorkouts;
  final Map<String, int> workoutsByType;
  final Map<String, int> workoutsByDayOfWeek;
  final double avgWorkoutDuration;

  WorkoutStats({
    required this.totalWorkouts,
    required this.workoutsByType,
    required this.workoutsByDayOfWeek,
    required this.avgWorkoutDuration,
  });

  factory WorkoutStats.empty() {
    return WorkoutStats(
      totalWorkouts: 0,
      workoutsByType: {},
      workoutsByDayOfWeek: {},
      avgWorkoutDuration: 0,
    );
  }
}

class ProgressStats {
  final int totalProgressEntries;
  final double avgProgressScore;
  final Map<String, double> avgProgressByMonth;

  ProgressStats({
    required this.totalProgressEntries,
    required this.avgProgressScore,
    required this.avgProgressByMonth,
  });

  factory ProgressStats.empty() {
    return ProgressStats(
      totalProgressEntries: 0,
      avgProgressScore: 0,
      avgProgressByMonth: {},
    );
  }
}