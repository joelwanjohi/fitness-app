import 'package:flutter/material.dart';
import '../controllers/dashboard_controller.dart';
import '../models/dashboard_stats.dart';
import '../widgets/admin_drawer.dart';
import 'admin_dashboard_page.dart';
import 'user_reports_page.dart';
import 'meal_reports_page.dart';
import 'progress_reports_page.dart';

class WorkoutReportsPage extends StatefulWidget {
  const WorkoutReportsPage({Key? key}) : super(key: key);

  @override
  _WorkoutReportsPageState createState() => _WorkoutReportsPageState();
}

class _WorkoutReportsPageState extends State<WorkoutReportsPage> {
  final DashboardController _dashboardController = DashboardController();
  bool _isLoading = true;
  WorkoutStats? _workoutStats;
  
  @override
  void initState() {
    super.initState();
    _loadWorkoutData();
  }
  
  Future<void> _loadWorkoutData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final stats = await _dashboardController.getWorkoutStats();
      
      setState(() {
        _workoutStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading workout data: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading workout data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout Reports'),
        actions: [
          IconButton(
            icon: Icon(Icons.file_download),
            tooltip: 'Export Report',
            onPressed: () {
              // TODO: Implement export functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _loadWorkoutData,
          ),
        ],
      ),
      drawer: AdminDrawer(
        onDashboardTap: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminDashboardPage()),
          );
        },
        onUserReportsTap: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => UserReportsPage()),
          );
        },
        onMealReportsTap: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MealReportsPage()),
          );
        },
        onWorkoutReportsTap: () {
          Navigator.pop(context);
        },
        onProgressReportsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProgressReportsPage()),
          );
        },
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _workoutStats == null
              ? Center(child: Text('No workout data available'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workout Reports',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Overview of all user workout activities',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 24),
                      
                      // Overview Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Workout Overview',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    label: 'Total Workouts',
                                    value: _workoutStats!.totalWorkouts.toString(),
                                    icon: Icons.fitness_center,
                                    color: Colors.blue,
                                  ),
                                  _buildStatItem(
                                    label: 'Avg. Duration',
                                    value: '${_workoutStats!.avgWorkoutDuration.toStringAsFixed(1)} min',
                                    icon: Icons.timer,
                                    color: Colors.orange,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Workout Types Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Workout Types',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              _buildWorkoutTypesList(),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Workout by Day of Week Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Workouts by Day of Week',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              _buildWorkoutsByDayChart(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
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
          label,
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
            fontSize: 18,
          ),
        ),
      ],
    );
  }
  
  Widget _buildWorkoutTypesList() {
    if (_workoutStats == null || _workoutStats!.workoutsByType.isEmpty) {
      return Center(
        child: Text('No workout type data available'),
      );
    }
    
    final workoutsByType = _workoutStats!.workoutsByType;
    final totalWorkouts = _workoutStats!.totalWorkouts;
    
    return Column(
      children: workoutsByType.entries.map((entry) {
        final percentage = totalWorkouts > 0 
            ? (entry.value / totalWorkouts * 100) 
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
    );
  }
  
  Widget _buildWorkoutsByDayChart() {
    if (_workoutStats == null || _workoutStats!.workoutsByDayOfWeek.isEmpty) {
      return Center(
        child: Text('No workout day data available'),
      );
    }
    
    final workoutsByDay = _workoutStats!.workoutsByDayOfWeek;
    
    return Container(
      height: 200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: workoutsByDay.entries.map((entry) {
              final dayName = entry.key;
              final count = entry.value;
              
              // Find max count for scaling
              final maxCount = workoutsByDay.values
                  .reduce((a, b) => a > b ? a : b);
              
              final percentage = maxCount > 0 ? count / maxCount : 0;
              
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 30,
                      height: 150 * percentage.toDouble(),

                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      dayName.substring(0, 3), // Show first 3 letters only
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}