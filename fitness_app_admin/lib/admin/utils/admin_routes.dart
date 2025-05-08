import 'package:flutter/material.dart';
import '../screens/admin_login_page.dart';
import '../screens/admin_dashboard_page.dart';
import '../screens/user_reports_page.dart';
import '../screens/meal_reports_page.dart';
import '../screens/workout_reports_page.dart';
import '../screens/progress_reports_page.dart';

class AdminRoutes {
  // Define route names for the standalone app
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String usersRoute = '/users';
  static const String mealsRoute = '/meals';
  static const String workoutsRoute = '/workouts';
  static const String progressRoute = '/progress';
  
  // Get all admin routes for the standalone app
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      loginRoute: (context) => AdminLoginPage(),
      dashboardRoute: (context) => AdminDashboardPage(),
      usersRoute: (context) => UserReportsPage(),
      mealsRoute: (context) => MealReportsPage(),
      workoutsRoute: (context) => WorkoutReportsPage(),
      progressRoute: (context) => ProgressReportsPage(),
    };
  }
  
  // Navigate to dashboard
  static void navigateToDashboard(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(dashboardRoute);
  }
  
  // Navigate to user reports
  static void navigateToUserReports(BuildContext context) {
    Navigator.of(context).pushNamed(usersRoute);
  }
  
  // Navigate to meal reports
  static void navigateToMealReports(BuildContext context) {
    Navigator.of(context).pushNamed(mealsRoute);
  }
  
  // Navigate to workout reports
  static void navigateToWorkoutReports(BuildContext context) {
    Navigator.of(context).pushNamed(workoutsRoute);
  }
  
  // Navigate to progress reports
  static void navigateToProgressReports(BuildContext context) {
    Navigator.of(context).pushNamed(progressRoute);
  }
  
  // Navigate back to login (for logout)
  static void navigateToLogin(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      loginRoute, 
      (route) => false // This clears the navigation stack
    );
  }
}