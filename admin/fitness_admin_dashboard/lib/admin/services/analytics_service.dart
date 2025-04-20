import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_activity.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get activity data for the last 30 days
  Future<List<UserActivity>> getActivityData(int days) async {
    try {
      List<UserActivity> result = [];
      
      for (int i = 0; i < days; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final normalizedDate = DateTime(date.year, date.month, date.day);
        final dayStart = normalizedDate.millisecondsSinceEpoch;
        final dayEnd = dayStart + Duration(days: 1).inMilliseconds - 1;
        
        // Count new users for this day
        final newUsersQuery = await _firestore.collection('Users')
            .where('createdAt', isGreaterThanOrEqualTo: dayStart)
            .where('createdAt', isLessThanOrEqualTo: dayEnd)
            .count()
            .get();
        final newUsersCount = newUsersQuery.count;
        
        // Count activity entries for each type
        int mealEntries = 0;
        int workoutEntries = 0;
        int progressEntries = 0;
        
        final usersSnapshot = await _firestore.collection('Users').get();
        
        for (var userDoc in usersSnapshot.docs) {
          // Count meal entries
          final mealQuery = await _firestore.collection('Users')
              .doc(userDoc.id)
              .collection('mealPlans')
              .where('dateAdded', isGreaterThanOrEqualTo: dayStart)
              .where('dateAdded', isLessThanOrEqualTo: dayEnd)
              .count()
              .get();
          mealEntries += mealQuery.count ?? 0;
          
          // Count workout entries
          final workoutQuery = await _firestore.collection('Users')
              .doc(userDoc.id)
              .collection('workouts')
              .where('dateAdded', isGreaterThanOrEqualTo: dayStart)
              .where('dateAdded', isLessThanOrEqualTo: dayEnd)
              .count()
              .get();
          workoutEntries += workoutQuery.count ?? 0;
          
          // Count progress entries
          final progressQuery = await _firestore.collection('Users')
              .doc(userDoc.id)
              .collection('progress')
              .where('date', isGreaterThanOrEqualTo: dayStart)
              .where('date', isLessThanOrEqualTo: dayEnd)
              .count()
              .get();
          progressEntries += progressQuery.count ?? 0;
        }
        
        result.add(UserActivity(
          date: normalizedDate,
          newUsers: newUsersCount ?? 0,
          mealEntries: mealEntries,
          workoutEntries: workoutEntries,
          progressEntries: progressEntries,
        ));
      }
      
      // Sort by date
      result.sort((a, b) => a.date.compareTo(b.date));
      
      return result;
    } catch (e) {
      print('Error getting activity data: $e');
      throw Exception('Failed to load activity data: $e');
    }
  }
  
  // Get user retention data
  Future<Map<String, dynamic>> getUserRetentionData() async {
    try {
      final now = DateTime.now();
      final allUsers = await _firestore.collection('Users').get();
      
      // Calculate the various retention periods
      Map<String, int> retentionCounts = {
        'Total': allUsers.docs.length,
        'Day 1': 0,
        'Day 7': 0,
        'Day 30': 0,
        'Day 90': 0,
      };
      
      // Calculate retention for each user
      for (var userDoc in allUsers.docs) {
        // Get user creation timestamp
        final userData = userDoc.data();
        if (userData.containsKey('createdAt')) {
          final createdAt = userData['createdAt'];
          if (createdAt is int) {
            final creationDate = DateTime.fromMillisecondsSinceEpoch(createdAt);
            final daysSinceCreation = now.difference(creationDate).inDays;
            
            // Get last activity timestamp from user's activity collection
            final lastActivity = await getLastActivityTimestamp(userDoc.id);
            
            if (lastActivity != null) {
              final daysBetweenCreationAndLastActivity = 
                  lastActivity.difference(creationDate).inDays;
              
              // Count retained users for different periods
              if (daysSinceCreation >= 1 && daysBetweenCreationAndLastActivity >= 1) {
                retentionCounts['Day 1'] = retentionCounts['Day 1']! + 1;
              }
              
              if (daysSinceCreation >= 7 && daysBetweenCreationAndLastActivity >= 7) {
                retentionCounts['Day 7'] = retentionCounts['Day 7']! + 1;
              }
              
              if (daysSinceCreation >= 30 && daysBetweenCreationAndLastActivity >= 30) {
                retentionCounts['Day 30'] = retentionCounts['Day 30']! + 1;
              }
              
              if (daysSinceCreation >= 90 && daysBetweenCreationAndLastActivity >= 90) {
                retentionCounts['Day 90'] = retentionCounts['Day 90']! + 1;
              }
            }
          }
        }
      }
      
      // Convert to percentages
      final totalUsers = retentionCounts['Total']!;
      Map<String, dynamic> retentionPercentages = {};
      
      if (totalUsers > 0) {
        retentionPercentages = {
          'Day 1': (retentionCounts['Day 1']! / totalUsers * 100).round(),
          'Day 7': (retentionCounts['Day 7']! / totalUsers * 100).round(),
          'Day 30': (retentionCounts['Day 30']! / totalUsers * 100).round(),
          'Day 90': (retentionCounts['Day 90']! / totalUsers * 100).round(),
        };
      } else {
        retentionPercentages = {
          'Day 1': 0,
          'Day 7': 0,
          'Day 30': 0,
          'Day 90': 0,
        };
      }
      
      return retentionPercentages;
    } catch (e) {
      print('Error getting retention data: $e');
      return {
        'Day 1': 0,
        'Day 7': 0,
        'Day 30': 0,
        'Day 90': 0,
      };
    }
  }
  
  // Helper method to get the last activity timestamp for a user
  Future<DateTime?> getLastActivityTimestamp(String userId) async {
    DateTime? lastActivity;
    
    try {
      // Check last meal entry
      final lastMeal = await _firestore.collection('Users')
          .doc(userId)
          .collection('mealPlans')
          .orderBy('dateAdded', descending: true)
          .limit(1)
          .get();
      
      // Check last workout entry
      final lastWorkout = await _firestore.collection('Users')
          .doc(userId)
          .collection('workouts')
          .orderBy('dateAdded', descending: true)
          .limit(1)
          .get();
      
      // Check last progress entry
      final lastProgress = await _firestore.collection('Users')
          .doc(userId)
          .collection('progress')
          .orderBy('date', descending: true)
          .limit(1)
          .get();
      
      // Find the most recent activity
      if (lastMeal.docs.isNotEmpty) {
        final mealDate = DateTime.fromMillisecondsSinceEpoch(
            lastMeal.docs.first.data()['dateAdded'] ?? 0);
        lastActivity = mealDate;
      }
      
      if (lastWorkout.docs.isNotEmpty) {
        final workoutDate = DateTime.fromMillisecondsSinceEpoch(
            lastWorkout.docs.first.data()['dateAdded'] ?? 0);
        if (lastActivity == null || workoutDate.isAfter(lastActivity)) {
          lastActivity = workoutDate;
        }
      }
      
      if (lastProgress.docs.isNotEmpty) {
        final progressDate = DateTime.fromMillisecondsSinceEpoch(
            lastProgress.docs.first.data()['date'] ?? 0);
        if (lastActivity == null || progressDate.isAfter(lastActivity)) {
          lastActivity = progressDate;
        }
      }
      
      // Check login history if available
      final loginHistory = await _firestore.collection('Users')
          .doc(userId)
          .collection('loginHistory')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      
      if (loginHistory.docs.isNotEmpty) {
        final loginDate = DateTime.fromMillisecondsSinceEpoch(
            loginHistory.docs.first.data()['timestamp'] ?? 0);
        if (lastActivity == null || loginDate.isAfter(lastActivity)) {
          lastActivity = loginDate;
        }
      }
      
      return lastActivity;
    } catch (e) {
      print('Error getting last activity for user $userId: $e');
      return null;
    }
  }
  
  // Get most active users
  Future<List<Map<String, dynamic>>> getMostActiveUsers(int limit) async {
    try {
      final usersSnapshot = await _firestore.collection('Users').get();
      List<Map<String, dynamic>> userActivity = [];
      
      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userId = userDoc.id;
        
        // Count total activities in the last 30 days
        final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
        final timestamp = thirtyDaysAgo.millisecondsSinceEpoch;
        
        // Count meals
        final mealCount = await _firestore.collection('Users')
            .doc(userId)
            .collection('mealPlans')
            .where('dateAdded', isGreaterThanOrEqualTo: timestamp)
            .count()
            .get();
            
        // Count workouts
        final workoutCount = await _firestore.collection('Users')
            .doc(userId)
            .collection('workouts')
            .where('dateAdded', isGreaterThanOrEqualTo: timestamp)
            .count()
            .get();
            
        // Count progress entries
        final progressCount = await _firestore.collection('Users')
            .doc(userId)
            .collection('progress')
            .where('date', isGreaterThanOrEqualTo: timestamp)
            .count()
            .get();
            
        final totalActivities = (mealCount.count ?? 0) + 
                               (workoutCount.count ?? 0) + 
                               (progressCount.count ?? 0);
                               
        userActivity.add({
          'userId': userId,
          'name': userData['name'] ?? 'Unknown User',
          'email': userData['email'] ?? 'No Email',
          'activityCount': totalActivities,
          'lastActive': await getLastActivityTimestamp(userId),
        });
      }
      
      // Sort by activity count
      userActivity.sort((a, b) => b['activityCount'].compareTo(a['activityCount']));
      
      // Return top users
      return userActivity.take(limit).toList();
    } catch (e) {
      print('Error getting most active users: $e');
      return [];
    }
  }
  
  // Get activity trends by hour of day
  Future<Map<int, int>> getActivityByHourOfDay() async {
    try {
      // Initialize hours map (0-23)
      Map<int, int> hourlyActivity = {};
      for (int i = 0; i < 24; i++) {
        hourlyActivity[i] = 0;
      }
      
      final lastWeek = DateTime.now().subtract(Duration(days: 7));
      final lastWeekTimestamp = lastWeek.millisecondsSinceEpoch;
      
      // Fetch all users
      final usersSnapshot = await _firestore.collection('Users').get();
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        
        // Function to process activity collections
        Future<void> processCollection(String collectionName, String dateField) async {
          final snapshot = await _firestore.collection('Users')
              .doc(userId)
              .collection(collectionName)
              .where(dateField, isGreaterThanOrEqualTo: lastWeekTimestamp)
              .get();
              
          for (var doc in snapshot.docs) {
            final timestamp = doc.data()[dateField];
            if (timestamp != null) {
              final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
              final hour = dateTime.hour;
              hourlyActivity[hour] = hourlyActivity[hour]! + 1;
            }
          }
        }
        
        // Process each activity collection
        await processCollection('mealPlans', 'dateAdded');
        await processCollection('workouts', 'dateAdded');
        await processCollection('progress', 'date');
      }
      
      return hourlyActivity;
    } catch (e) {
      print('Error getting hourly activity data: $e');
      return {};
    }
  }
}