import 'package:fitness_app/meal/meal_plan_model.dart';
import 'package:fitness_app/meal/mealplan_db_service.dart';
import 'package:fitness_app/meal/meal_page.dart';
import 'package:fitness_app/meal_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class MealPlanPage extends StatefulWidget {
  const MealPlanPage({Key? key}) : super(key: key);

  @override
  _MealPlanPageState createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  final MealPlanService _mealPlanService = MealPlanService();
  List<MealPlanEntry> _meals = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();
    _loadMealsForSelectedDate();
  }

  Future<void> _loadMealsForSelectedDate() async {
    print('Loading meals for date: ${_selectedDay.toString()}');
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final meals = await _mealPlanService.getMealsForDate(_selectedDay);
      
      print('Successfully loaded ${meals.length} meals');
      for (var meal in meals) {
        print('Meal: ${meal.name}, Type: ${meal.mealType}, Date: ${meal.dateAdded}');
      }
      
      setState(() {
        _meals = meals;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading meals: $e');
      setState(() {
        _errorMessage = 'Failed to load meals: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meal Plan'),
      ),
      body: Column(
        children: [
          // Calendar for date selection
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            focusedDay: _selectedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
              _loadMealsForSelectedDate();
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
          ),
          
          // Nutritional summary for selected day
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildNutritionalSummary(),
          ),
          
          // Meals list for selected date
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator())
              : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                : _meals.isEmpty
                  ? Center(
                      child: Text(
                        'No meals planned for ${DateFormat('MMM d, yyyy').format(_selectedDay)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _meals.length,
                      itemBuilder: (context, index) {
                        return _buildMealCard(_meals[index]);
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MealPage()),
          ).then((_) => _loadMealsForSelectedDate());
        },
        child: Icon(Icons.add),
        tooltip: 'Add Meal',
      ),
    );
  }

  Widget _buildNutritionalSummary() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    double totalCalories = 0;
    double totalProtein = 0;
    double totalFat = 0;
    
    for (var meal in _meals) {
      totalCalories += meal.calories;
      totalProtein += meal.protein;
      totalFat += meal.fat;
    }
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutritional Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientIndicator('Calories', totalCalories.toStringAsFixed(0), Colors.red),
                _buildNutrientIndicator('Protein', '${totalProtein.toStringAsFixed(1)}g', Colors.blue),
                _buildNutrientIndicator('Fat', '${totalFat.toStringAsFixed(1)}g', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientIndicator(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(MealPlanEntry meal) {
    // Get icon based on meal type
    IconData mealIcon;
    Color mealColor;
    
    switch (meal.mealType.toLowerCase()) {
      case 'breakfast':
        mealIcon = Icons.free_breakfast;
        mealColor = Colors.orange;
        break;
      case 'lunch':
        mealIcon = Icons.lunch_dining;
        mealColor = Colors.green;
        break;
      case 'dinner':
        mealIcon = Icons.dinner_dining;
        mealColor = Colors.blue;
        break;
      case 'snack':
        mealIcon = Icons.icecream;
        mealColor = Colors.purple;
        break;
      default:
        mealIcon = Icons.restaurant;
        mealColor = Colors.grey;
    }
    
    return Dismissible(
      key: Key(meal.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete Meal'),
            content: Text('Are you sure you want to remove this meal from your plan?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        try {
          print('Deleting meal: ${meal.id}');
          await _mealPlanService.deleteMealFromPlan(meal.id);
          setState(() {
            _meals.removeWhere((m) => m.id == meal.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${meal.name} removed from meal plan'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          print('Error deleting meal: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove meal: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: mealColor.withOpacity(0.2),
            child: Icon(mealIcon, color: mealColor),
          ),
          title: Text(
            meal.name,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Calories: ${meal.calories.toStringAsFixed(0)} • ' +
            'Protein: ${meal.protein.toStringAsFixed(1)}g • ' +
            'Fat: ${meal.fat.toStringAsFixed(1)}g',
          ),
          trailing: Text(
            DateFormat('h:mm a').format(meal.dateAdded),
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}