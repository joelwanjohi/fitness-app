import 'package:fitness_app/meal.dart';

class MealPlanEntry {
  final String id;
  final String name;
  final double calories;
  final double protein;
  final double fat;
  final double servingSize;
  final DateTime dateAdded;
  final String mealType; // breakfast, lunch, dinner, snack

  MealPlanEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.servingSize,
    required this.dateAdded,
    required this.mealType,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'servingSize': servingSize,
      'dateAdded': dateAdded.millisecondsSinceEpoch,
      'mealType': mealType,
    };
  }

  // Create from Firestore document
  factory MealPlanEntry.fromJson(String id, Map<String, dynamic> json) {
    return MealPlanEntry(
      id: id,
      name: json['name'] ?? 'Unknown',
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      servingSize: (json['servingSize'] ?? 0).toDouble(),
      dateAdded: DateTime.fromMillisecondsSinceEpoch(json['dateAdded'] ?? DateTime.now().millisecondsSinceEpoch),
      mealType: json['mealType'] ?? 'other',
    );
  }

  // Create from Recipe
  factory MealPlanEntry.fromRecipe(Recipe recipe, String mealType) {
    return MealPlanEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: recipe.name,
      calories: recipe.calories,
      protein: recipe.protein_g,
      fat: recipe.fat_total_g,
      servingSize: recipe.serving_size_g,
      dateAdded: DateTime.now(),
      mealType: mealType,
    );
  }
}