import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dashboard_stats.dart';

class WorkoutController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get workout statistics
  Future<WorkoutStats> getWorkoutStats({String? timeFilter}) async {
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
      
      // Get date filters based on timeFilter parameter
      DateTime? startDate;
      if (timeFilter != null) {
        final now = DateTime.now();
        switch (timeFilter) {
          case 'week':
            // Last 7 days
            startDate = now.subtract(Duration(days: 7));
            break;
          case 'month':
            // Last 30 days
            startDate = now.subtract(Duration(days: 30));
            break;
          case 'year':
            // Last 365 days
            startDate = now.subtract(Duration(days: 365));
            break;
          default:
            // All time
            startDate = null;
        }
      }
      
      final startTimestamp = startDate?.millisecondsSinceEpoch;
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        
        // Create query for workouts
        Query workoutsQuery = _firestore
            .collection('Users')
            .doc(userId)
            .collection('workouts');
        
        // Apply date filter if specified
        if (startTimestamp != null) {
          workoutsQuery = workoutsQuery.where('dateAdded', isGreaterThanOrEqualTo: startTimestamp);
        }
        
        // Get workouts for this user
        final workoutsSnapshot = await workoutsQuery.get();
            
        for (var workoutDoc in workoutsSnapshot.docs) {
          totalWorkouts++;
          final workoutData = workoutDoc.data();
          
          // Track workout type
if (workoutData != null) {
  // Cast to Map<String, dynamic> first
  final data = workoutData as Map<String, dynamic>;
  
  final workoutType = data['type'] ?? 'Other';
  workoutsByType[workoutType] = (workoutsByType[workoutType] ?? 0) + 1;
  
  // Track by day of week
  if (data['dateAdded'] != null) {
    final workoutDate = DateTime.fromMillisecondsSinceEpoch(data['dateAdded']);
    final dayName = _getDayOfWeekName(workoutDate.weekday);
    workoutsByDayOfWeek[dayName] = (workoutsByDayOfWeek[dayName] ?? 0) + 1;
  }
  
  // Sum up duration
  totalDuration += (data['duration'] as num?)?.toDouble() ?? 0;
}
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
  
  // Get top workouts
  Future<List<Map<String, dynamic>>> getTopWorkouts({int limit = 10}) async {
    try {
      final usersSnapshot = await _firestore.collection('Users').get();
      
      // Map to track workout frequency
      Map<String, Map<String, dynamic>> workoutFrequency = {};
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        
        // Get workouts for this user
        final workoutsSnapshot = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('workouts')
            .get();
            
        for (var workoutDoc in workoutsSnapshot.docs) {
          final workoutData = workoutDoc.data();
          final workoutName = workoutData['name'] ?? 'Unknown Workout';
          
          if (!workoutFrequency.containsKey(workoutName)) {
            workoutFrequency[workoutName] = {
              'name': workoutName,
              'type': workoutData['type'] ?? 'Other',
              'duration': workoutData['duration'] ?? 0,
              'count': 1,
            };
          } else {
            workoutFrequency[workoutName]!['count'] = (workoutFrequency[workoutName]!['count'] as int) + 1;
          }
        }
      }
      
      // Sort workouts by frequency and limit
      final sortedWorkouts = workoutFrequency.values.toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      
      return sortedWorkouts.take(limit).toList();
    } catch (e) {
      print('Error getting top workouts: $e');
      return [];
    }
  }
  
  // Get workout trends by date
  Future<Map<String, int>> getWorkoutTrendsByDate({
    required DateTime startDate,
    required DateTime endDate,
    String? groupBy, // 'day', 'week', 'month'
  }) async {
    try {
      final usersSnapshot = await _firestore.collection('Users').get();
      
      // Map to track workouts by date
      Map<String, int> workoutsByDate = {};
      
      final startTimestamp = startDate.millisecondsSinceEpoch;
      final endTimestamp = endDate.millisecondsSinceEpoch;
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        
        // Get workouts for this user within date range
        final workoutsSnapshot = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('workouts')
            .where('dateAdded', isGreaterThanOrEqualTo: startTimestamp)
            .where('dateAdded', isLessThanOrEqualTo: endTimestamp)
            .get();
            
        for (var workoutDoc in workoutsSnapshot.docs) {
          final workoutData = workoutDoc.data();
          final workoutDate = DateTime.fromMillisecondsSinceEpoch(workoutData['dateAdded'] ?? 0);
          
          String dateKey;
          if (groupBy == 'week') {
            // Get week number (1-52)
            final weekNumber = (workoutDate.difference(DateTime(workoutDate.year, 1, 1)).inDays / 7).ceil();
            dateKey = '${workoutDate.year}-W$weekNumber';
          } else if (groupBy == 'month') {
            // Format as YYYY-MM
            dateKey = '${workoutDate.year}-${workoutDate.month.toString().padLeft(2, '0')}';
          } else {
            // Default to day: YYYY-MM-DD
            dateKey = '${workoutDate.year}-${workoutDate.month.toString().padLeft(2, '0')}-${workoutDate.day.toString().padLeft(2, '0')}';
          }
          
          workoutsByDate[dateKey] = (workoutsByDate[dateKey] ?? 0) + 1;
        }
      }
      
      return workoutsByDate;
    } catch (e) {
      print('Error getting workout trends: $e');
      return {};
    }
  }
  
  // Get user workout summary
  Future<List<Map<String, dynamic>>> getUserWorkoutSummary() async {
    try {
      final usersSnapshot = await _firestore.collection('Users').get();
      List<Map<String, dynamic>> userWorkoutSummary = [];
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userData = userDoc.data();
        
        // Get workouts for this user
        final workoutsSnapshot = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('workouts')
            .get();
        
        // Calculate totals
        int totalWorkouts = workoutsSnapshot.docs.length;
        double totalDuration = 0;
        Map<String, int> workoutTypes = {};
        
        for (var workoutDoc in workoutsSnapshot.docs) {
          final workoutData = workoutDoc.data();
          totalDuration += (workoutData['duration'] as num?)?.toDouble() ?? 0;
          
          // Count workout types
          final workoutType = workoutData['type'] ?? 'Other';
          workoutTypes[workoutType] = (workoutTypes[workoutType] ?? 0) + 1;
        }
        
        // Find most frequent workout type
        String? mostFrequentType;
        int maxCount = 0;
        workoutTypes.forEach((type, count) {
          if (count > maxCount) {
            maxCount = count;
            mostFrequentType = type;
          }
        });
        
        // Add to summary list
        userWorkoutSummary.add({
          'userId': userId,
          'userName': userData['name'] ?? 'Unknown',
          'workoutCount': totalWorkouts,
          'avgDuration': totalWorkouts > 0 ? totalDuration / totalWorkouts : 0,
          'totalDuration': totalDuration,
          'preferredWorkoutType': mostFrequentType ?? 'N/A',
          'lastWorkoutDate': workoutsSnapshot.docs.isNotEmpty
              ? DateTime.fromMillisecondsSinceEpoch(
                  workoutsSnapshot.docs
                      .map((doc) => doc.data()['dateAdded'] as int? ?? 0)
                      .reduce((a, b) => a > b ? a : b)
                )
              : null,
        });
      }
      
      // Sort by workout count (descending)
      userWorkoutSummary.sort((a, b) => (b['workoutCount'] as int).compareTo(a['workoutCount'] as int));
      
      return userWorkoutSummary;
    } catch (e) {
      print('Error getting user workout summary: $e');
      return [];
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