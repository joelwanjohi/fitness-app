class Recipe {
  final String name;
  final double calories;
  final double serving_size_g;
  final double fat_total_g;
  final double fat_saturated_g;
  final double protein_g;
  final double sodium_mg;
  final double potassium_mg;
  final double sugar_g;

  Recipe({
    required this.name,
    required this.calories,
    required this.serving_size_g,
    required this.fat_total_g,
    required this.fat_saturated_g,
    required this.protein_g,
    required this.sodium_mg,
    required this.potassium_mg,
    required this.sugar_g,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      name: json['name'] ?? 'Unknown Food',
      calories: _parseDoubleOrZero(json['calories']),
      serving_size_g: _parseDoubleOrZero(json['serving_size_g']),
      fat_total_g: _parseDoubleOrZero(json['fat_total_g']),
      fat_saturated_g: _parseDoubleOrZero(json['fat_saturated_g']),
      protein_g: _parseDoubleOrZero(json['protein_g']),
      sodium_mg: _parseDoubleOrZero(json['sodium_mg']),
      potassium_mg: _parseDoubleOrZero(json['potassium_mg']),
      sugar_g: _parseDoubleOrZero(json['sugar_g']),
    );
  }

  // Helper method to safely parse doubles
  static double _parseDoubleOrZero(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }
}