import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dashboard_stats.dart';

class DashboardController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final usersSnapshot = await _firestore.collection('Users').get();
      
      return usersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'email': data['email'] ?? 'No email',
          'age': data['age'],
          'gender': data['gender'],
          'height': data['height'],
          'weight': data['weight'],
          'createdAt': data['createdAt'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(data['createdAt']) 
              : null,
        };
      }).toList();
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  // Get dashboard stats
  Future<DashboardStats> getDashboardStats() async {
    try {
      // Get all users
      final usersSnapshot = await _firestore.collection('Users').get();
      final int totalUsers = usersSnapshot.docs.length;
      
      // Calculate user registrations by month
      Map<String, int> userRegistrationByMonth = {};
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        if (data['createdAt'] != null) {
          final createdAt = DateTime.fromMillisecondsSinceEpoch(data['createdAt']);
          final monthYear = '${createdAt.month}/${createdAt.year}';
          
          if (userRegistrationByMonth.containsKey(monthYear)) {
            userRegistrationByMonth[monthYear] = userRegistrationByMonth[monthYear]! + 1;
          } else {
            userRegistrationByMonth[monthYear] = 1;
          }
        }
      }
      
      // Initialize counters
      int totalMeals = 0;
      int totalWorkouts = 0;
      int totalProgressEntries = 0;
      int activeUsersLast7Days = 0;
      int mealsTrackedLast7Days = 0;
      int workoutsCompletedLast7Days = 0;
      Map<String, List<double>> progressScoresByMonth = {};
      
      // Get date 7 days ago
      final DateTime sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
      final int sevenDaysAgoMs = sevenDaysAgo.millisecondsSinceEpoch;
      
      // Process each user's data
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        bool userActiveInLast7Days = false;
        
        // Get meals for this user
        final mealsSnapshot = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('mealPlans')
            .get();
            
        totalMeals += mealsSnapshot.docs.length;
        
        // Check for meals in last 7 days
        int userMealsLast7Days = 0;
        for (var mealDoc in mealsSnapshot.docs) {
          final mealData = mealDoc.data();
          if (mealData['dateAdded'] != null && mealData['dateAdded'] >= sevenDaysAgoMs) {
            userMealsLast7Days++;
            userActiveInLast7Days = true;
          }
        }
        mealsTrackedLast7Days += userMealsLast7Days;
        
        // Get workouts for this user
        final workoutsSnapshot = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('workouts')
            .get();
            
        totalWorkouts += workoutsSnapshot.docs.length;
        
        // Check for workouts in last 7 days
        int userWorkoutsLast7Days = 0;
        for (var workoutDoc in workoutsSnapshot.docs) {
          final workoutData = workoutDoc.data();
          if (workoutData['dateAdded'] != null && workoutData['dateAdded'] >= sevenDaysAgoMs) {
            userWorkoutsLast7Days++;
            userActiveInLast7Days = true;
          }
        }
        workoutsCompletedLast7Days += userWorkoutsLast7Days;
        
        // Get progress entries for this user
        final progressSnapshot = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('progress')
            .get();
            
        totalProgressEntries += progressSnapshot.docs.length;
        
        // Process progress scores by month
        for (var progressDoc in progressSnapshot.docs) {
          final progressData = progressDoc.data();
          if (progressData['date'] != null && progressData['progressScore'] != null) {
            final date = DateTime.fromMillisecondsSinceEpoch(progressData['date']);
            final monthYear = '${date.month}/${date.year}';
            final score = (progressData['progressScore'] as num).toDouble();
            
            if (progressScoresByMonth.containsKey(monthYear)) {
              progressScoresByMonth[monthYear]!.add(score);
            } else {
              progressScoresByMonth[monthYear] = [score];
            }
            
            // Check if any progress entry was in the last 7 days
            if (progressData['date'] >= sevenDaysAgoMs) {
              userActiveInLast7Days = true;
            }
          }
        }
        
        // Count active user if they had any activity in the last 7 days
        if (userActiveInLast7Days) {
          activeUsersLast7Days++;
        }
      }
      
      // Calculate average progress scores by month
      Map<String, double> avgProgressScoreByMonth = {};
      progressScoresByMonth.forEach((month, scores) {
        if (scores.isNotEmpty) {
          double sum = scores.reduce((a, b) => a + b);
          avgProgressScoreByMonth[month] = sum / scores.length;
        }
      });
      
      return DashboardStats(
        totalUsers: totalUsers,
        totalMeals: totalMeals,
        totalWorkouts: totalWorkouts,
        totalProgressEntries: totalProgressEntries,
        activeUsersLast7Days: activeUsersLast7Days,
        mealsTrackedLast7Days: mealsTrackedLast7Days,
        workoutsCompletedLast7Days: workoutsCompletedLast7Days,
        userRegistrationByMonth: userRegistrationByMonth,
        avgProgressScoreByMonth: avgProgressScoreByMonth,
      );
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return DashboardStats.empty();
    }
  }

// Get user activity stats
  Future<List<UserActivityStats>> getUserActivityStats() async {
    try {
      final usersSnapshot = await _firestore.collection('Users').get();
      List<UserActivityStats> userStats = [];
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userData = userDoc.data();
        
        // Get meal count
        final mealsSnapshot = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('mealPlans')
            .count()
            .get();
            
        // Get workout count
        final workoutsSnapshot = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('workouts')
            .count()
            .get();
            
        // Get progress count
        final progressSnapshot = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('progress')
            .count()
            .get();
            
        // Determine last active date
        DateTime lastActive = DateTime.fromMillisecondsSinceEpoch(userData['createdAt'] ?? 0);
        
        // Check latest meal
        final latestMealQuery = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('mealPlans')
            .orderBy('dateAdded', descending: true)
            .limit(1)
            .get();
            
        if (latestMealQuery.docs.isNotEmpty) {
          final mealDate = DateTime.fromMillisecondsSinceEpoch(
              latestMealQuery.docs.first.data()['dateAdded'] ?? 0);
          if (mealDate.isAfter(lastActive)) {
            lastActive = mealDate;
          }
        }
        
        // Check latest workout
        final latestWorkoutQuery = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('workouts')
            .orderBy('dateAdded', descending: true)
            .limit(1)
            .get();
            
        if (latestWorkoutQuery.docs.isNotEmpty) {
          final workoutDate = DateTime.fromMillisecondsSinceEpoch(
              latestWorkoutQuery.docs.first.data()['dateAdded'] ?? 0);
          if (workoutDate.isAfter(lastActive)) {
            lastActive = workoutDate;
          }
        }
        
        // Check latest progress
        final latestProgressQuery = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('progress')
            .orderBy('date', descending: true)
            .limit(1)
            .get();
            
        if (latestProgressQuery.docs.isNotEmpty) {
          final progressDate = DateTime.fromMillisecondsSinceEpoch(
              latestProgressQuery.docs.first.data()['date'] ?? 0);
          if (progressDate.isAfter(lastActive)) {
            lastActive = progressDate;
          }
        }
        
        userStats.add(UserActivityStats(
          userId: userId,
          userName: userData['name'] ?? 'Unknown',
          userEmail: userData['email'] ?? 'No email',
          mealCount: mealsSnapshot.count ?? 0, // Using null-aware operator to default to 0
          workoutCount: workoutsSnapshot.count ?? 0, // Using null-aware operator to default to 0
          progressCount: progressSnapshot.count ?? 0, // Using null-aware operator to default to 0
          lastActive: lastActive,
        ));
      }
      
      // Sort by last active, most recent first
      userStats.sort((a, b) => b.lastActive.compareTo(a.lastActive));
      
      return userStats;
    } catch (e) {
      print('Error getting user activity stats: $e');
      return [];
    }
  }

  // Get meal statistics
  Future<MealStats> getMealStats() async {
    try {
      final usersSnapshot = await _firestore.collection('Users').get();
      
      int totalMeals = 0;
      double totalCalories = 0;
      double totalProtein = 0;
      double totalFat = 0;
      Map<String, int> mealsByType = {};
      Map<String, int> mealsByDayOfWeek = {
        'Monday': 0,
        'Tuesday': 0,
        'Wednesday': 0,
        'Thursday': 0,
        'Friday': 0,
        'Saturday': 0,
        'Sunday': 0,
      };
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        
        // Get meals for this user
        final mealsSnapshot = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('mealPlans')
            .get();
            
        for (var mealDoc in mealsSnapshot.docs) {
          totalMeals++;
          final mealData = mealDoc.data();
          
          // Sum up nutritional values
          totalCalories += (mealData['calories'] as num?)?.toDouble() ?? 0;
          totalProtein += (mealData['protein'] as num?)?.toDouble() ?? 0;
          totalFat += (mealData['fat'] as num?)?.toDouble() ?? 0;
          
          // Count by meal type
          final mealType = mealData['mealType'] ?? 'Other';
          if (mealsByType.containsKey(mealType)) {
            mealsByType[mealType] = mealsByType[mealType]! + 1;
          } else {
            mealsByType[mealType] = 1;
          }
          
          // Count by day of week
          if (mealData['dateAdded'] != null) {
            final mealDate = DateTime.fromMillisecondsSinceEpoch(mealData['dateAdded']);
            final dayName = _getDayOfWeekName(mealDate.weekday);
            mealsByDayOfWeek[dayName] = (mealsByDayOfWeek[dayName] ?? 0) + 1;
          }
        }
      }
      
      // Calculate averages
      double avgCaloriesPerMeal = totalMeals > 0 ? totalCalories / totalMeals : 0;
      double avgProteinPerMeal = totalMeals > 0 ? totalProtein / totalMeals : 0;
      double avgFatPerMeal = totalMeals > 0 ? totalFat / totalMeals : 0;
      
      return MealStats(
        totalMeals: totalMeals,
        avgCaloriesPerMeal: avgCaloriesPerMeal,
        avgProteinPerMeal: avgProteinPerMeal,
        avgFatPerMeal: avgFatPerMeal,
        mealsByType: mealsByType,
        mealsByDayOfWeek: mealsByDayOfWeek,
      );
    } catch (e) {
      print('Error getting meal stats: $e');
      return MealStats.empty();
    }
  }

  // Get workout statistics
  Future<WorkoutStats> getWorkoutStats() async {
    try {
      final usersSnapshot = await _firestore.collection('Users').get();
      
      int totalWorkouts = 0;
      Map<String, int> workoutsByType = {};
      Map<String, int> workoutsByDayOfWeek = {
        'Monday': 0,
        'Tuesday': 0,
        'Wednesday': 0,
        'Thursday': 0,
        'Friday': 0,
        'Saturday': 0,
        'Sunday': 0,
      };
      double totalDuration = 0;
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        
        // Get workouts for this user
        final workoutsSnapshot = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('workouts')
            .get();
            
        for (var workoutDoc in workoutsSnapshot.docs) {
          totalWorkouts++;
          final workoutData = workoutDoc.data();
          
          // Track workout type
          final workoutType = workoutData['type'] ?? 'Other';
          if (workoutsByType.containsKey(workoutType)) {
            workoutsByType[workoutType] = workoutsByType[workoutType]! + 1;
          } else {
            workoutsByType[workoutType] = 1;
          }
          
          // Track by day of week
          if (workoutData['dateAdded'] != null) {
            final workoutDate = DateTime.fromMillisecondsSinceEpoch(workoutData['dateAdded']);
            final dayName = _getDayOfWeekName(workoutDate.weekday);
            workoutsByDayOfWeek[dayName] = (workoutsByDayOfWeek[dayName] ?? 0) + 1;
          }
          
          // Sum up duration
          totalDuration += (workoutData['duration'] as num?)?.toDouble() ?? 0;
        }
      }
      
      // Calculate average duration
      double avgDuration = totalWorkouts > 0 ? totalDuration / totalWorkouts : 0;
      
      return WorkoutStats(
        totalWorkouts: totalWorkouts,
        workoutsByType: workoutsByType,
        workoutsByDayOfWeek: workoutsByDayOfWeek,
        avgWorkoutDuration: avgDuration,
      );
    } catch (e) {
      print('Error getting workout stats: $e');
      return WorkoutStats.empty();
    }
  }
  
  // Get progress statistics
  Future<ProgressStats> getProgressStats() async {
    try {
      final usersSnapshot = await _firestore.collection('Users').get();
      
      int totalProgressEntries = 0;
      double totalProgressScore = 0;
      Map<String, List<double>> progressScoresByMonth = {};
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        
        // Get progress entries for this user
        final progressSnapshot = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('progress')
            .get();
            
        for (var progressDoc in progressSnapshot.docs) {
          totalProgressEntries++;
          final progressData = progressDoc.data();
          
          // Sum up progress scores
          final progressScore = (progressData['progressScore'] as num?)?.toDouble() ?? 0;
          totalProgressScore += progressScore;
          
          // Track by month
          if (progressData['date'] != null) {
            final progressDate = DateTime.fromMillisecondsSinceEpoch(progressData['date']);
            final monthYear = '${progressDate.month}/${progressDate.year}';
            
            if (progressScoresByMonth.containsKey(monthYear)) {
              progressScoresByMonth[monthYear]!.add(progressScore);
            } else {
              progressScoresByMonth[monthYear] = [progressScore];
            }
          }
        }
      }
      
      // Calculate average progress score
      double avgProgressScore = totalProgressEntries > 0 ? totalProgressScore / totalProgressEntries : 0;
      
      // Calculate average progress scores by month
      Map<String, double> avgProgressByMonth = {};
      progressScoresByMonth.forEach((month, scores) {
        if (scores.isNotEmpty) {
          double sum = scores.reduce((a, b) => a + b);
          avgProgressByMonth[month] = sum / scores.length;
        }
      });
      
      return ProgressStats(
        totalProgressEntries: totalProgressEntries,
        avgProgressScore: avgProgressScore,
        avgProgressByMonth: avgProgressByMonth,
      );
    } catch (e) {
      print('Error getting progress stats: $e');
      return ProgressStats.empty();
    }
  }
  
  // Helper method to get day of week name
  String _getDayOfWeekName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Unknown';
    }
  }
}