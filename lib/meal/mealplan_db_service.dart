import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/meal/meal_plan_model.dart';

class MealPlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

// Reference to the meal plans collection
CollectionReference get _mealPlansCollection {
  final userId = _auth.currentUser?.uid;
  if (userId == null) {
    throw Exception('User not authenticated');
  }
  // Change 'users' to 'Users' to match your signup code
  return _firestore.collection('Users').doc(userId).collection('mealPlans');
}

  // Add a meal to the meal plan
  Future<String> addMealToPlan(MealPlanEntry meal) async {
    try {
      print('Adding meal to Firebase: ${meal.name}, Type: ${meal.mealType}, Date: ${meal.dateAdded}');
      final docRef = await _mealPlansCollection.add(meal.toJson());
      print('Meal added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error adding meal to plan: $e');
      throw Exception('Failed to add meal to plan: $e');
    }
  }

  // Get all meals for a specific date
  Future<List<MealPlanEntry>> getMealsForDate(DateTime date) async {
    try {
      // Normalize date to start and end of day for query
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      print('Querying meals between: ${startDate.toIso8601String()} and ${endDate.toIso8601String()}');
      print('Timestamps: ${startDate.millisecondsSinceEpoch} - ${endDate.millisecondsSinceEpoch}');

      // Query meals between start and end of the specified day
      final querySnapshot = await _mealPlansCollection
          .where('dateAdded', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
          .where('dateAdded', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch)
          .get();
          
      print('Found ${querySnapshot.docs.length} meals for selected date');
      
      return querySnapshot.docs
          .map((doc) => MealPlanEntry.fromJson(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting meals for date: $e');
      throw Exception('Failed to load meals: $e');
    }
  }

  // Get all meals for the current week
  Future<List<MealPlanEntry>> getMealsForCurrentWeek() async {
    try {
      // Calculate start of week (Sunday) and end of week (Saturday)
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
      final endOfWeek = startOfWeek.add(Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      
      print('Querying meals for week: ${startOfWeek.toIso8601String()} to ${endOfWeek.toIso8601String()}');

      final querySnapshot = await _mealPlansCollection
          .where('dateAdded', isGreaterThanOrEqualTo: startOfWeek.millisecondsSinceEpoch)
          .where('dateAdded', isLessThanOrEqualTo: endOfWeek.millisecondsSinceEpoch)
          .orderBy('dateAdded')
          .get();

      return querySnapshot.docs
          .map((doc) => MealPlanEntry.fromJson(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting meals for week: $e');
      throw Exception('Failed to load weekly meals: $e');
    }
  }

  // Delete a meal from the plan
  Future<void> deleteMealFromPlan(String mealId) async {
    try {
      print('Deleting meal with ID: $mealId');
      await _mealPlansCollection.doc(mealId).delete();
      print('Successfully deleted meal');
    } catch (e) {
      print('Error deleting meal: $e');
      throw Exception('Failed to delete meal: $e');
    }
  }

  // Get nutritional totals for a specific date
  Future<Map<String, double>> getNutritionalTotalsForDate(DateTime date) async {
    try {
      final meals = await getMealsForDate(date);
      
      double totalCalories = 0;
      double totalProtein = 0;
      double totalFat = 0;
      
      for (var meal in meals) {
        totalCalories += meal.calories;
        totalProtein += meal.protein;
        totalFat += meal.fat;
      }
      
      return {
        'calories': totalCalories,
        'protein': totalProtein,
        'fat': totalFat,
      };
    } catch (e) {
      print('Error calculating nutritional totals: $e');
      throw Exception('Failed to calculate nutritional totals: $e');
    }
  }
}