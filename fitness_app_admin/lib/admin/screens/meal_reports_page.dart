import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/dashboard_controller.dart';
import '../models/dashboard_stats.dart';
import '../widgets/admin_drawer.dart';
import '../utils/pdf_generator.dart';
import 'admin_dashboard_page.dart';
import 'user_reports_page.dart';
import 'workout_reports_page.dart';
import 'progress_reports_page.dart';

class MealReportsPage extends StatefulWidget {
  const MealReportsPage({Key? key}) : super(key: key);

  @override
  _MealReportsPageState createState() => _MealReportsPageState();
}

class _MealReportsPageState extends State<MealReportsPage> {
  final DashboardController _dashboardController = DashboardController();
  bool _isLoading = true;
  MealStats? _mealStats;
  List<Map<String, dynamic>> _topMeals = [];
  
  // Filter options
  String _timeFilter = 'all'; // Options: all, week, month, year
  
  @override
  void initState() {
    super.initState();
    _loadMealData();
  }
  
  Future<void> _loadMealData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final stats = await _dashboardController.getMealStats();
      
      // Mock data for top meals - replace with actual data in production
      final topMeals = [
        {
          'name': 'Grilled Chicken Salad',
          'type': 'Lunch',
          'calories': 350,
          'protein': 32,
          'count': 45,
        },
        {
          'name': 'Protein Smoothie',
          'type': 'Breakfast',
          'calories': 290,
          'protein': 25,
          'count': 38,
        },
        {
          'name': 'Oatmeal with Fruits',
          'type': 'Breakfast',
          'calories': 320,
          'protein': 12,
          'count': 36,
        },
        {
          'name': 'Salmon with Vegetables',
          'type': 'Dinner',
          'calories': 420,
          'protein': 35,
          'count': 30,
        },
        {
          'name': 'Greek Yogurt with Berries',
          'type': 'Snack',
          'calories': 180,
          'protein': 15,
          'count': 28,
        },
      ];
      
      setState(() {
        _mealStats = stats;
        _topMeals = topMeals;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading meal data: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading meal data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Export meal report to PDF
  Future<void> _exportMealReport() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      if (_mealStats == null) {
        throw Exception('No meal data available');
      }
      
      final generator = PdfGenerator();
      await generator.generateMealReport(_mealStats!, _topMeals);
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meal report exported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meal Reports'),
        actions: [
          IconButton(
            icon: Icon(Icons.file_download),
            tooltip: 'Export Report',
            onPressed: _exportMealReport,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _loadMealData,
          ),
        ],
      ),
      drawer: AdminDrawer(
        onDashboardTap: () {
          Navigator.pop(context); // Close drawer
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminDashboardPage()),
          );
        },
        onUserReportsTap: () {
          Navigator.pop(context); // Close drawer
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => UserReportsPage()),
          );
        },
        onMealReportsTap: () {
          Navigator.pop(context); // Close drawer
        },
        onWorkoutReportsTap: () {
          Navigator.pop(context); // Close drawer
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WorkoutReportsPage()),
          );
        },
        onProgressReportsTap: () {
          Navigator.pop(context); // Close drawer
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProgressReportsPage()),
          );
        },
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _mealStats == null
              ? Center(child: Text('No meal data available'))
              : RefreshIndicator(
                  onRefresh: _loadMealData,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildReportHeader(),
                        SizedBox(height: 24),
                        _buildMealOverview(),
                        SizedBox(height: 24),
                        _buildNutritionAnalysis(),
                        SizedBox(height: 24),
                        _buildMealTypeDistribution(),
                        SizedBox(height: 24),
                        _buildTopMealsSection(),
                      ],
                    ),
                  ),
                ),
    );
  }
  
  Widget _buildReportHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meal Tracking Report',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Overview of all user meal tracking activities',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                _buildTimeFilterChip('All Time', 'all'),
                SizedBox(width: 8),
                _buildTimeFilterChip('This Week', 'week'),
                SizedBox(width: 8),
                _buildTimeFilterChip('This Month', 'month'),
                SizedBox(width: 8),
                _buildTimeFilterChip('This Year', 'year'),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimeFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _timeFilter == value,
      onSelected: (selected) {
        setState(() {
          _timeFilter = value;
        });
        _loadMealData(); // Reload data with new filter
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue.withOpacity(0.2),
      checkmarkColor: Colors.blue,
    );
  }
  
  Widget _buildMealOverview() {
    if (_mealStats == null) {
      return SizedBox();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meal Tracking Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildOverviewItem(
                      icon: Icons.restaurant,
                      title: 'Total Meals',
                      value: _mealStats!.totalMeals.toString(),
                      color: Colors.blue,
                    ),
                    _buildOverviewItem(
                      icon: Icons.breakfast_dining,
                      title: 'Breakfast',
                      value: _mealStats!.mealsByType['Breakfast']?.toString() ?? '0',
                      color: Colors.orange,
                    ),
                    _buildOverviewItem(
                      icon: Icons.lunch_dining,
                      title: 'Lunch',
                      value: _mealStats!.mealsByType['Lunch']?.toString() ?? '0',
                      color: Colors.green,
                    ),
                    _buildOverviewItem(
                      icon: Icons.dinner_dining,
                      title: 'Dinner',
                      value: _mealStats!.mealsByType['Dinner']?.toString() ?? '0',
                      color: Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildOverviewItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
  
  Widget _buildNutritionAnalysis() {
    if (_mealStats == null) {
      return SizedBox();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutrition Analysis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildNutritionItem(
                        title: 'Avg. Calories',
                        value: '${_mealStats!.avgCaloriesPerMeal.toStringAsFixed(1)} kcal',
                        icon: Icons.local_fire_department,
                        color: Colors.red,
                      ),
                    ),
                    Expanded(
                      child: _buildNutritionItem(
                        title: 'Avg. Protein',
                        value: '${_mealStats!.avgProteinPerMeal.toStringAsFixed(1)} g',
                        icon: Icons.fitness_center,
                        color: Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildNutritionItem(
                        title: 'Avg. Fat',
                        value: '${_mealStats!.avgFatPerMeal.toStringAsFixed(1)} g',
                        icon: Icons.egg_alt,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildNutritionItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 32,
        ),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMealTypeDistribution() {
    if (_mealStats == null) {
      return SizedBox();
    }
    
    // Calculate percentages
    final mealsByType = _mealStats!.mealsByType;
    final totalMeals = _mealStats!.totalMeals;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meal Type Distribution',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                ...mealsByType.entries.map((entry) {
                  final percentage = totalMeals > 0 
                      ? (entry.value / totalMeals * 100) 
                      : 0.0;
                  
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey[200],
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTopMealsSection() {
    if (_topMeals.isEmpty) {
      return SizedBox();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Most Popular Meals',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _topMeals.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final meal = _topMeals[index];
                    
                    return ListTile(
                      title: Text(
                        meal['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Type: ${meal['type']} | ${meal['calories']} kcal | ${meal['protein']}g protein',
                      ),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${meal['count']} times',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}