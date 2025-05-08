import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dashboard_stats.dart';

class MealController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get meal statistics
  Future<MealStats> getMealStats({String? timeFilter}) async {
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
        
        // Create query for meals
        Query mealsQuery = _firestore
            .collection('Users')
            .doc(userId)
            .collection('mealPlans');
        
        // Apply date filter if specified
        if (startTimestamp != null) {
          mealsQuery = mealsQuery.where('dateAdded', isGreaterThanOrEqualTo: startTimestamp);
        }
        
        // Get meals for this user
        final mealsSnapshot = await mealsQuery.get();
            
        for (var mealDoc in mealsSnapshot.docs) {
          totalMeals++;
          final mealData = mealDoc.data();
          
// Before accessing mealData properties, check if it's not null and cast it to Map
if (mealData != null) {
  final mealMap = mealData as Map<String, dynamic>;
  
  // Sum up nutritional values
  totalCalories += (mealMap['calories'] as num?)?.toDouble() ?? 0;
  totalProtein += (mealMap['protein'] as num?)?.toDouble() ?? 0;
  totalFat += (mealMap['fat'] as num?)?.toDouble() ?? 0;
  
  // Count by meal type
  final mealType = mealMap['mealType'] ?? 'Other';
  mealsByType[mealType] = (mealsByType[mealType] ?? 0) + 1;
  
  // Count by day of week
  if (mealMap['dateAdded'] != null) {
    final mealDate = DateTime.fromMillisecondsSinceEpoch(mealMap['dateAdded']);
    final dayName = _getDayOfWeekName(mealDate.weekday);
    mealsByDayOfWeek[dayName] = (mealsByDayOfWeek[dayName] ?? 0) + 1;
  }
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
  
  // Get top meals
  Future<List<Map<String, dynamic>>> getTopMeals({int limit = 10}) async {
    try {
      final usersSnapshot = await _firestore.collection('Users').get();
      
      // Map to track meal frequency
      Map<String, Map<String, dynamic>> mealFrequency = {};
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        
        // Get meals for this user
        final mealsSnapshot = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('mealPlans')
            .get();
            
        for (var mealDoc in mealsSnapshot.docs) {
          final mealData = mealDoc.data();
          final mealName = mealData['name'] ?? 'Unknown Meal';
          
          if (!mealFrequency.containsKey(mealName)) {
            mealFrequency[mealName] = {
              'name': mealName,
              'type': mealData['mealType'] ?? 'Other',
              'calories': mealData['calories'] ?? 0,
              'protein': mealData['protein'] ?? 0,
              'count': 1,
            };
          } else {
            mealFrequency[mealName]!['count'] = (mealFrequency[mealName]!['count'] as int) + 1;
          }
        }
      }
      
      // Sort meals by frequency and limit
      final sortedMeals = mealFrequency.values.toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      
      return sortedMeals.take(limit).toList();
    } catch (e) {
      print('Error getting top meals: $e');
      return [];
    }
  }
  
  // Get meal trends by date
  Future<Map<String, int>> getMealTrendsByDate({
    required DateTime startDate,
    required DateTime endDate,
    String? groupBy, // 'day', 'week', 'month'
  }) async {
    try {
      final usersSnapshot = await _firestore.collection('Users').get();
      
      // Map to track meals by date
      Map<String, int> mealsByDate = {};
      
      final startTimestamp = startDate.millisecondsSinceEpoch;
      final endTimestamp = endDate.millisecondsSinceEpoch;
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        
        // Get meals for this user within date range
        final mealsSnapshot = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('mealPlans')
            .where('dateAdded', isGreaterThanOrEqualTo: startTimestamp)
            .where('dateAdded', isLessThanOrEqualTo: endTimestamp)
            .get();
            
        for (var mealDoc in mealsSnapshot.docs) {
          final mealData = mealDoc.data();
          final mealDate = DateTime.fromMillisecondsSinceEpoch(mealData['dateAdded'] ?? 0);
          
          String dateKey;
          if (groupBy == 'week') {
            // Get week number (1-52)
            final weekNumber = (mealDate.difference(DateTime(mealDate.year, 1, 1)).inDays / 7).ceil();
            dateKey = '${mealDate.year}-W$weekNumber';
          } else if (groupBy == 'month') {
            // Format as YYYY-MM
            dateKey = '${mealDate.year}-${mealDate.month.toString().padLeft(2, '0')}';
          } else {
            // Default to day: YYYY-MM-DD
            dateKey = '${mealDate.year}-${mealDate.month.toString().padLeft(2, '0')}-${mealDate.day.toString().padLeft(2, '0')}';
          }
          
          mealsByDate[dateKey] = (mealsByDate[dateKey] ?? 0) + 1;
        }
      }
      
      return mealsByDate;
    } catch (e) {
      print('Error getting meal trends: $e');
      return {};
    }
  }
  
  // Get user meal summary
  Future<List<Map<String, dynamic>>> getUserMealSummary() async {
    try {
      final usersSnapshot = await _firestore.collection('Users').get();
      List<Map<String, dynamic>> userMealSummary = [];
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userData = userDoc.data();
        
        // Get meals for this user
        final mealsSnapshot = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('mealPlans')
            .get();
        
        // Calculate totals
        int totalMeals = mealsSnapshot.docs.length;
        double totalCalories = 0;
        double totalProtein = 0;
        
        for (var mealDoc in mealsSnapshot.docs) {
          final mealData = mealDoc.data();
          totalCalories += (mealData['calories'] as num?)?.toDouble() ?? 0;
          totalProtein += (mealData['protein'] as num?)?.toDouble() ?? 0;
        }
        
        // Add to summary list
        userMealSummary.add({
          'userId': userId,
          'userName': userData['name'] ?? 'Unknown',
          'mealCount': totalMeals,
          'avgCaloriesPerMeal': totalMeals > 0 ? totalCalories / totalMeals : 0,
          'avgProteinPerMeal': totalMeals > 0 ? totalProtein / totalMeals : 0,
          'lastMealDate': mealsSnapshot.docs.isNotEmpty
              ? DateTime.fromMillisecondsSinceEpoch(
                  mealsSnapshot.docs
                      .map((doc) => doc.data()['dateAdded'] as int? ?? 0)
                      .reduce((a, b) => a > b ? a : b)
                )
              : null,
        });
      }
      
      // Sort by meal count (descending)
      userMealSummary.sort((a, b) => (b['mealCount'] as int).compareTo(a['mealCount'] as int));
      
      return userMealSummary;
    } catch (e) {
      print('Error getting user meal summary: $e');
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