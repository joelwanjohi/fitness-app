// lib/shared/constants.dart
class AppConstants {
  static const String appName = 'Fitness Admin';
  static const int paginationLimit = 20;
  static const Duration sessionTimeout = Duration(minutes: 30);
  
  // Firebase collection names
  static const String usersCollection = 'Users';
  static const String mealsCollection = 'mealPlans';
  static const String workoutsCollection = 'workouts';
  static const String progressCollection = 'progress';
}