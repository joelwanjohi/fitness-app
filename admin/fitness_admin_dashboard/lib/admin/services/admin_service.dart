import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_stats.dart';
import '../models/app_user.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get basic stats for the dashboard
  Future<AdminStats> getAdminStats() async {
    try {
      // Get user counts
      final usersSnapshot = await _firestore.collection('Users').get();
      final int totalUsers = usersSnapshot.docs.length;
      
      // Get active users (logged in within 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30)).millisecondsSinceEpoch;
      final activeUsersSnapshot = await _firestore.collection('Users')
          .where('lastLoginAt', isGreaterThan: thirtyDaysAgo)
          .get();
      final int activeUsers = activeUsersSnapshot.docs.length;
      
      // Count totals
      int mealEntries = 0;
      int workoutEntries = 0;
      int progressEntries = 0;
      
      for (var userDoc in usersSnapshot.docs) {
        final userMealSnapshot = await _firestore.collection('Users')
            .doc(userDoc.id)
            .collection('mealPlans')
            .count()
            .get();
        mealEntries += userMealSnapshot.count!;
        
        final userWorkoutSnapshot = await _firestore.collection('Users')
            .doc(userDoc.id)
            .collection('workouts')
            .count()
            .get();
        workoutEntries += userWorkoutSnapshot.count!;
        
        final userProgressSnapshot = await _firestore.collection('Users')
            .doc(userDoc.id)
            .collection('progress')
            .count()
            .get();
        progressEntries += userProgressSnapshot.count!;
      }
      
      return AdminStats(
        totalUsers: totalUsers,
        activeUsers: activeUsers,
        totalMealEntries: mealEntries,
        totalWorkoutEntries: workoutEntries,
        totalProgressEntries: progressEntries,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('Error getting admin stats: $e');
      throw Exception('Failed to load admin stats: $e');
    }
  }
  
  // Get all users with their activity stats
  Future<List<AppUser>> getAllUsers() async {
    try {
      final usersSnapshot = await _firestore.collection('Users').get();
      List<AppUser> users = [];
      
      for (var doc in usersSnapshot.docs) {
        final userData = doc.data();
        
        // Get activity counts
        int? mealCount = 0;
        int? workoutCount = 0;
        int? progressCount = 0;
        
        try {
          final mealSnapshot = await _firestore.collection('Users')
              .doc(doc.id)
              .collection('mealPlans')
              .count()
              .get();
          mealCount = mealSnapshot.count;
          
          final workoutSnapshot = await _firestore.collection('Users')
              .doc(doc.id)
              .collection('workouts')
              .count()
              .get();
          workoutCount = workoutSnapshot.count;
          
          final progressSnapshot = await _firestore.collection('Users')
              .doc(doc.id)
              .collection('progress')
              .count()
              .get();
          progressCount = progressSnapshot.count;
        } catch (e) {
          print('Error counting activities for user ${doc.id}: $e');
        }
        
        // Add activity counts to user data
        final Map<String, dynamic> enrichedData = {
          ...userData,
          'mealCount': mealCount,
          'workoutCount': workoutCount,
          'progressCount': progressCount,
        };
        
        users.add(AppUser.fromFirestore(doc.id, enrichedData));
      }
      
      return users;
    } catch (e) {
      print('Error getting all users: $e');
      throw Exception('Failed to load users: $e');
    }
  }
  
  // Update user status (active/inactive/blocked)
  Future<void> updateUserStatus(String userId, UserStatus status) async {
    try {
      await _firestore.collection('Users').doc(userId).update({
        'status': status.toString().split('.').last,
      });
    } catch (e) {
      print('Error updating user status: $e');
      throw Exception('Failed to update user status: $e');
    }
  }
  
  // Toggle admin status
  Future<void> toggleAdminStatus(String userId, bool isAdmin) async {
    try {
      await _firestore.collection('Users').doc(userId).update({
        'isAdmin': isAdmin,
      });
    } catch (e) {
      print('Error toggling admin status: $e');
      throw Exception('Failed to update admin status: $e');
    }
  }
  
  // Delete user (use with caution!)
  Future<void> deleteUser(String userId) async {
    try {
      // Delete user data
      await _firestore.collection('Users').doc(userId).delete();
    } catch (e) {
      print('Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }
}