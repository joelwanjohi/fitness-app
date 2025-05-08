import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_stats.dart';

class UserController {
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
  
  // Get user statistics
  Future<List<UserStats>> getUserStats() async {
    try {
      final usersSnapshot = await _firestore.collection('Users').get();
      List<UserStats> userStatsList = [];
      
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
        DateTime? lastActive = userData['createdAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(userData['createdAt'])
            : null;
        
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
          if (lastActive == null || mealDate.isAfter(lastActive)) {
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
          if (lastActive == null || workoutDate.isAfter(lastActive)) {
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
          if (lastActive == null || progressDate.isAfter(lastActive)) {
            lastActive = progressDate;
          }
        }
        
        // Create activity stats
        Map<String, dynamic> activityStats = {
          'mealCount': mealsSnapshot.count,
          'workoutCount': workoutsSnapshot.count,
          'progressCount': progressSnapshot.count,
        };
        
        // Create user stats
        userStatsList.add(UserStats(
          userId: userId,
          userName: userData['name'],
          email: userData['email'],
          age: userData['age'],
          gender: userData['gender'],
          height: userData['height'] != null ? double.parse(userData['height'].toString()) : null,
          weight: userData['weight'] != null ? double.parse(userData['weight'].toString()) : null,
          bmi: userData['bmi'] != null ? double.parse(userData['bmi'].toString()) : null,
          registrationDate: userData['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(userData['createdAt'])
              : null,
          lastActiveDate: lastActive,
          activityStats: activityStats,
        ));
      }
      
      return userStatsList;
    } catch (e) {
      print('Error getting user stats: $e');
      return [];
    }
  }
  
  // Get user activity statistics
  Future<List<Map<String, dynamic>>> getUserActivityStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final usersSnapshot = await _firestore.collection('Users').get();
      List<Map<String, dynamic>> userActivityStats = [];
      
      final startTimestamp = startDate?.millisecondsSinceEpoch;
      final endTimestamp = endDate?.millisecondsSinceEpoch;
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userData = userDoc.data();
        
        // Queries for different activity types
        Query mealQuery = _firestore
            .collection('Users')
            .doc(userId)
            .collection('mealPlans');
            
        Query workoutQuery = _firestore
            .collection('Users')
            .doc(userId)
            .collection('workouts');
            
        Query progressQuery = _firestore
            .collection('Users')
            .doc(userId)
            .collection('progress');
        
        // Apply date filters if specified
        if (startTimestamp != null) {
          mealQuery = mealQuery.where('dateAdded', isGreaterThanOrEqualTo: startTimestamp);
          workoutQuery = workoutQuery.where('dateAdded', isGreaterThanOrEqualTo: startTimestamp);
          progressQuery = progressQuery.where('date', isGreaterThanOrEqualTo: startTimestamp);
        }
        
        if (endTimestamp != null) {
          mealQuery = mealQuery.where('dateAdded', isLessThanOrEqualTo: endTimestamp);
          workoutQuery = workoutQuery.where('dateAdded', isLessThanOrEqualTo: endTimestamp);
          progressQuery = progressQuery.where('date', isLessThanOrEqualTo: endTimestamp);
        }
        
        // Get counts
        final mealCount = await mealQuery.count().get();
        final workoutCount = await workoutQuery.count().get();
        final progressCount = await progressQuery.count().get();
        
        // Add to stats
        userActivityStats.add({
          'userId': userId,
          'userName': userData['name'] ?? 'Unknown',
          'email': userData['email'] ?? 'No email',
          'mealCount': mealCount.count,
          'workoutCount': workoutCount.count,
'progressCount': progressCount.count ?? 0,
'totalActivityCount': (mealCount.count ?? 0) + (workoutCount.count ?? 0) + (progressCount.count ?? 0),
        });
      }
      
      // Sort by total activity count (descending)
      userActivityStats.sort((a, b) {
        return (b['totalActivityCount'] as int).compareTo(a['totalActivityCount'] as int);
      });
      
      return userActivityStats;
    } catch (e) {
      print('Error getting user activity stats: $e');
      return [];
    }
  }
  
  // Get user registration trends
  Future<Map<String, int>> getUserRegistrationTrends({
    required DateTime startDate,
    required DateTime endDate,
    String? groupBy, // 'day', 'week', 'month'
  }) async {
    try {
      final usersSnapshot = await _firestore
          .collection('Users')
          .where('createdAt', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
          .where('createdAt', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch)
          .get();
      
      // Map to track registrations by date
      Map<String, int> registrationsByDate = {};
      
      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final createdAt = userData['createdAt'] as int?;
        
        if (createdAt != null) {
          final registrationDate = DateTime.fromMillisecondsSinceEpoch(createdAt);
          
          String dateKey;
          if (groupBy == 'week') {
            // Get week number (1-52)
            final weekNumber = (registrationDate.difference(DateTime(registrationDate.year, 1, 1)).inDays / 7).ceil();
            dateKey = '${registrationDate.year}-W$weekNumber';
          } else if (groupBy == 'month') {
            // Format as YYYY-MM
            dateKey = '${registrationDate.year}-${registrationDate.month.toString().padLeft(2, '0')}';
          } else {
            // Default to day: YYYY-MM-DD
            dateKey = '${registrationDate.year}-${registrationDate.month.toString().padLeft(2, '0')}-${registrationDate.day.toString().padLeft(2, '0')}';
          }
          
          registrationsByDate[dateKey] = (registrationsByDate[dateKey] ?? 0) + 1;
        }
      }
      
      return registrationsByDate;
    } catch (e) {
      print('Error getting user registration trends: $e');
      return {};
    }
  }
  
  // Get active users count
  Future<Map<String, int>> getActiveUsersCount({
    required int daysBack, // Number of days to consider for "active"
  }) async {
    try {
      final usersSnapshot = await _firestore.collection('Users').get();
      final now = DateTime.now();
      final cutoffDate = now.subtract(Duration(days: daysBack));
      final cutoffTimestamp = cutoffDate.millisecondsSinceEpoch;
      
      int activeUserCount = 0;
      int inactiveUserCount = 0;
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        bool isActive = false;
        
        // Check meals
        final latestMealQuery = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('mealPlans')
            .where('dateAdded', isGreaterThanOrEqualTo: cutoffTimestamp)
            .limit(1)
            .get();
            
        isActive = isActive || latestMealQuery.docs.isNotEmpty;
        
        // If not already active, check workouts
        if (!isActive) {
          final latestWorkoutQuery = await _firestore
              .collection('Users')
              .doc(userId)
              .collection('workouts')
              .where('dateAdded', isGreaterThanOrEqualTo: cutoffTimestamp)
              .limit(1)
              .get();
              
          isActive = isActive || latestWorkoutQuery.docs.isNotEmpty;
        }
        
        // If not already active, check progress
        if (!isActive) {
          final latestProgressQuery = await _firestore
              .collection('Users')
              .doc(userId)
              .collection('progress')
              .where('date', isGreaterThanOrEqualTo: cutoffTimestamp)
              .limit(1)
              .get();
              
          isActive = isActive || latestProgressQuery.docs.isNotEmpty;
        }
        
        if (isActive) {
          activeUserCount++;
        } else {
          inactiveUserCount++;
        }
      }
      
      return {
        'activeUsers': activeUserCount,
        'inactiveUsers': inactiveUserCount,
        'totalUsers': activeUserCount + inactiveUserCount,
        'activePercentage': (activeUserCount + inactiveUserCount) > 0
            ? (activeUserCount / (activeUserCount + inactiveUserCount) * 100).round()
            : 0,
      };
    } catch (e) {
      print('Error getting active users count: $e');
      return {
        'activeUsers': 0,
        'inactiveUsers': 0,
        'totalUsers': 0,
        'activePercentage': 0,
      };
    }
  }
}