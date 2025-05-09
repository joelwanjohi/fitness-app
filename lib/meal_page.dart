import 'package:fitness_app/meal/meal_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'meal_card.dart';
import 'meal.dart';
import 'meal.api.dart';
import 'package:fitness_app/meal/meal_plan_model.dart';

import 'package:fitness_app/meal/mealplan_db_service.dart';

class MealPage extends StatefulWidget {
  const MealPage({Key? key}) : super(key: key);

  @override
  _MealPageState createState() => _MealPageState();
}

class _MealPageState extends State<MealPage> {
  final TextEditingController _searchController = TextEditingController();
  Recipe? _recipe;
  double _totalCalories = 0.0;
  double _totalProtein = 0.0;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedMealType = 'Breakfast'; // Default value

  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      _errorMessage = 'GEMINI_API_KEY not found in .env file';
    }
  }

  void _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a food item';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Map<String, dynamic> nutritionData =
          await MealApi.fetchNutritionInfo(query);
      setState(() {
        _recipe = Recipe.fromJson(nutritionData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get nutrition data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _addCurrentMeal() async {
    if (_recipe == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search for a meal first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      // Create a MealPlanEntry using the selected meal type
      final mealPlanEntry = MealPlanEntry.fromRecipe(_recipe!, _selectedMealType);
      
      print('Creating meal plan entry: ${mealPlanEntry.name}, Type: ${mealPlanEntry.mealType}');
      
      // Use the Firebase service to add the meal to the plan
      final MealPlanService mealPlanService = MealPlanService();
      final String mealId = await mealPlanService.addMealToPlan(mealPlanEntry);
      
      print('Successfully saved meal with ID: $mealId');
      
      // Update local state
      setState(() {
        _totalCalories += _recipe!.calories;
        _totalProtein += _recipe!.protein_g;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_recipe!.name} added as $_selectedMealType'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Future.delayed(Duration(seconds: 2), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MealPlanPage()),
        );
      });
    } catch (e) {
      print('Error adding meal to plan: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to add meal to plan: ${e.toString()}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildMealTypeSelector() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meal Type:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMealType,
                isExpanded: true,
                items: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedMealType = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_rounded),
            SizedBox(width: 10),
            Text('Meal Nutrition'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null && _errorMessage!.contains('API_KEY'))
              _buildErrorBox(_errorMessage!, Colors.red.shade100, Colors.red.shade900),

            Padding(
              padding: EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Enter food or meal...',
                  suffixIcon: _isLoading
                      ? Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () => _search(_searchController.text),
                        ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                ),
                onSubmitted: _search,
              ),
            ),

            if (_errorMessage != null && !_errorMessage!.contains('API_KEY'))
              _buildErrorBox(_errorMessage!, Colors.orange.shade100, Colors.orange.shade900),

            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircularProgressBar('Total Calories', _totalCalories, 2000),
                _buildCircularProgressBar('Total Protein (g)', _totalProtein, 50),
              ],
            ),

            SizedBox(height: 20),

            if (_recipe != null) ...[
              RecipeCard(recipe: _recipe!),
              SizedBox(height: 20),
              _buildMealTypeSelector(), // Add meal type selector
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: ElevatedButton(
                  onPressed: _addCurrentMeal,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.green,
                  ),
                  child: Text(
                    'Add to Meal Plan',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],

            SizedBox(height: 20),

            _buildRecipeList(),

            SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MealPlanPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(Icons.fastfood_rounded),
                label: Text(
                  'View Meal Plan',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBox(String text, Color bgColor, Color textColor) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor),
      ),
    );
  }

  Widget _buildCircularProgressBar(String label, double value, double max) {
    double progress = (value / max).clamp(0.0, 1.0);
    Color progressColor = progress < 0.5
        ? Colors.green
        : (progress < 0.75 ? Colors.orange : Colors.red);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  strokeWidth: 15,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '${value.toStringAsFixed(1)} / $max',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeList() {
    final List<Map<String, String>> suggestedMeals = [
      {'name': 'Breakfast', 'image': 'assets/images/breakfast.png', 'query': 'Oatmeal with fruit'},
      {'name': 'Salad', 'image': 'assets/images/salad.png', 'query': 'Kale salad with chicken'},
      {'name': 'Smoothie', 'image': 'assets/images/smoothie.png', 'query': 'Banana protein smoothie'},
      {'name': 'Lunch', 'image': 'assets/images/lunch.png', 'query': 'Brown rice with vegetables'},
      {'name': 'Dinner', 'image': 'assets/images/dinner.png', 'query': 'Grilled salmon with vegetables'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Quick Suggestions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: suggestedMeals.length,
            itemBuilder: (context, index) {
              final meal = suggestedMeals[index];
              return _buildRecipeItem(
                meal['name'] ?? 'Meal',
                meal['image'] ?? 'assets/images/breakfast.png',
                onTap: () {
                  _searchController.text = meal['query'] ?? '';
                  _search(_searchController.text);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeItem(String name, String imagePath, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.asset(
                imagePath,
                width: 150,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 150,
                  height: 150,
                  color: Colors.grey[300],
                  child: Icon(Icons.restaurant, size: 50, color: Colors.grey[600]),
                ),
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}