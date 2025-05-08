import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dashboard_stats.dart';

class ProgressController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get progress statistics
  Future<ProgressStats> getProgressStats({String? timeFilter}) async {
    try {
      final usersSnapshot = await _firestore.collection('Users').get();
      
      int totalProgressEntries = 0;
      double totalProgressScore = 0;
      Map<String, List<double>> progressScoresByMonth = {};
      
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
        
        // Create query for progress entries
        Query progressQuery = _firestore
            .collection('Users')
            .doc(userId)
            .collection('progress');
        
        // Apply date filter if specified
        if (startTimestamp != null) {
          progressQuery = progressQuery.where('date', isGreaterThanOrEqualTo: startTimestamp);
        }
        
        // Get progress entries for this user
        final progressSnapshot = await progressQuery.get();
            
        for (var progressDoc in progressSnapshot.docs) {
          totalProgressEntries++;
          final progressData = progressDoc.data();
          
// Sum up progress scores
double progressScore = 0;
if (progressData != null) {
  final data = progressData as Map<String, dynamic>;
  progressScore = (data['progressScore'] as num?)?.toDouble() ?? 0;
  totalProgressScore += progressScore;
}
          
// Track by month
if (progressData != null) {
  final data = progressData as Map<String, dynamic>;
  
  if (data['date'] != null) {
    final progressDate = DateTime.fromMillisecondsSinceEpoch(data['date']);
    final monthYear = '${progressDate.month}/${progressDate.year}';
    
    if (!progressScoresByMonth.containsKey(monthYear)) {
      progressScoresByMonth[monthYear] = [];
    }
    progressScoresByMonth[monthYear]!.add(progressScore);
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
  
  // Get user progress summary
  Future<List<Map<String, dynamic>>> getUserProgressSummary() async {
    try {
      final usersSnapshot = await _firestore.collection('Users').get();
      List<Map<String, dynamic>> userProgressSummary = [];
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userData = userDoc.data();
        
        // Get progress entries for this user
        final progressSnapshot = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('progress')
            .orderBy('date')
            .get();
        
        // Skip users with no progress entries
        if (progressSnapshot.docs.isEmpty) continue;
        
        // Calculate stats
        int entryCount = progressSnapshot.docs.length;
        
        // Get initial and latest progress scores
        double initialScore = 0;
        double latestScore = 0;
        DateTime? initialDate;
        DateTime? latestDate;
        
        if (progressSnapshot.docs.isNotEmpty) {
          // First entry (chronologically)
          final firstDoc = progressSnapshot.docs.first;
          final firstData = firstDoc.data();
          initialScore = (firstData['progressScore'] as num?)?.toDouble() ?? 0;
          initialDate = firstData['date'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(firstData['date']) 
              : null;
          
          // Latest entry
          final lastDoc = progressSnapshot.docs.last;
          final lastData = lastDoc.data();
          latestScore = (lastData['progressScore'] as num?)?.toDouble() ?? 0;
          latestDate = lastData['date'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(lastData['date']) 
              : null;
        }
        
        // Calculate change
        double scoreChange = latestScore - initialScore;
        double percentChange = initialScore > 0 ? (scoreChange / initialScore) * 100 : 0;
        
        // Add to summary list
        userProgressSummary.add({
          'userId': userId,
          'userName': userData['name'] ?? 'Unknown',
          'entryCount': entryCount,
          'initialScore': initialScore,
          'latestScore': latestScore,
          'scoreChange': scoreChange,
          'percentChange': percentChange,
          'initialDate': initialDate,
          'latestDate': latestDate,
        });
      }
      
      // Sort by score change (descending)
      userProgressSummary.sort((a, b) => (b['scoreChange'] as double).compareTo(a['scoreChange'] as double));
      
      return userProgressSummary;
    } catch (e) {
      print('Error getting user progress summary: $e');
      return [];
    }
  }
  
  // Get progress trends by date
  Future<Map<String, double>> getProgressTrendsByDate({
    required DateTime startDate,
    required DateTime endDate,
    String? groupBy, // 'day', 'week', 'month'
  }) async {
    try {
      final usersSnapshot = await _firestore.collection('Users').get();
      
      // Maps to track progress scores by date
      Map<String, List<double>> scoresByDate = {};
      
      final startTimestamp = startDate.millisecondsSinceEpoch;
      final endTimestamp = endDate.millisecondsSinceEpoch;
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        
        // Get progress entries for this user within date range
        final progressSnapshot = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('progress')
            .where('date', isGreaterThanOrEqualTo: startTimestamp)
            .where('date', isLessThanOrEqualTo: endTimestamp)
            .get();
            
        for (var progressDoc in progressSnapshot.docs) {
          final progressData = progressDoc.data();
          final progressDate = DateTime.fromMillisecondsSinceEpoch(progressData['date'] ?? 0);
          final progressScore = (progressData['progressScore'] as num?)?.toDouble() ?? 0;
          
          String dateKey;
          if (groupBy == 'week') {
            // Get week number (1-52)
            final weekNumber = (progressDate.difference(DateTime(progressDate.year, 1, 1)).inDays / 7).ceil();
            dateKey = '${progressDate.year}-W$weekNumber';
          } else if (groupBy == 'month') {
            // Format as YYYY-MM
            dateKey = '${progressDate.year}-${progressDate.month.toString().padLeft(2, '0')}';
          } else {
            // Default to day: YYYY-MM-DD
            dateKey = '${progressDate.year}-${progressDate.month.toString().padLeft(2, '0')}-${progressDate.day.toString().padLeft(2, '0')}';
          }
          
          if (!scoresByDate.containsKey(dateKey)) {
            scoresByDate[dateKey] = [];
          }
          scoresByDate[dateKey]!.add(progressScore);
        }
      }
      
      // Calculate average score for each date
      Map<String, double> avgScoresByDate = {};
      scoresByDate.forEach((date, scores) {
        if (scores.isNotEmpty) {
          double sum = scores.reduce((a, b) => a + b);
          avgScoresByDate[date] = sum / scores.length;
        }
      });
      
      return avgScoresByDate;
    } catch (e) {
      print('Error getting progress trends: $e');
      return {};
    }
  }
  
  // Get aggregate statistics for progress photos
  Future<Map<String, dynamic>> getProgressPhotoStats() async {
    try {
      final usersSnapshot = await _firestore.collection('Users').get();
      
      int totalPhotos = 0;
      int usersWithPhotos = 0;
      double avgPhotosPerUser = 0;
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        
        // Get progress entries for this user
        final progressSnapshot = await _firestore
            .collection('Users')
            .doc(userId)
            .collection('progress')
            .get();
        
        int userPhotoCount = progressSnapshot.docs.length;
        totalPhotos += userPhotoCount;
        
        if (userPhotoCount > 0) {
          usersWithPhotos++;
        }
      }
      
      // Calculate average
      avgPhotosPerUser = usersWithPhotos > 0 ? totalPhotos / usersWithPhotos : 0;
      
      return {
        'totalPhotos': totalPhotos,
        'usersWithPhotos': usersWithPhotos,
        'avgPhotosPerUser': avgPhotosPerUser,
      };
    } catch (e) {
      print('Error getting progress photo stats: $e');
      return {
        'totalPhotos': 0,
        'usersWithPhotos': 0,
        'avgPhotosPerUser': 0,
      };
    }
  }
}