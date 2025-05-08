import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/dashboard_controller.dart';
import '../models/dashboard_stats.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/stat_card.dart';
import '../widgets/line_chart_widget.dart';
import '../widgets/bar_chart_widget.dart';
import 'user_reports_page.dart';
import 'meal_reports_page.dart';
import 'workout_reports_page.dart';
import 'progress_reports_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final DashboardController _dashboardController = DashboardController();
  bool _isLoading = true;
  DashboardStats? _dashboardStats;
  List<UserActivityStats> _userActivityStats = [];
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final stats = await _dashboardController.getDashboardStats();
      final userStats = await _dashboardController.getUserActivityStats();
      
      setState(() {
        _dashboardStats = stats;
        _userActivityStats = userStats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading dashboard data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      drawer: AdminDrawer(
        onDashboardTap: () {
          Navigator.pop(context); // Close drawer
        },
        onUserReportsTap: () {
          Navigator.pop(context); // Close drawer
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UserReportsPage()),
          );
        },
        onMealReportsTap: () {
          Navigator.pop(context); // Close drawer
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MealReportsPage()),
          );
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
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 16),
                    _buildOverviewStats(),
                    SizedBox(height: 24),
                    _buildWeeklyActivitySection(),
                    SizedBox(height: 24),
                    _buildCharts(),
                    SizedBox(height: 24),
                    _buildActiveUsersSection(),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildHeader() {
    return Card(
      color: Color(0xFF2E7D32),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dashboard,
                  color: Colors.white,
                  size: 36,
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fitness App Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Dashboard Overview',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Today: ${DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now())}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOverviewStats() {
    if (_dashboardStats == null) {
      return SizedBox();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Platform Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: [
            StatCard(
              title: 'Total Users',
              value: _dashboardStats!.totalUsers.toString(),
              icon: Icons.people,
              color: Colors.blue,
            ),
            StatCard(
              title: 'Total Meals',
              value: _dashboardStats!.totalMeals.toString(),
              icon: Icons.restaurant,
              color: Colors.green,
            ),
            StatCard(
              title: 'Total Workouts',
              value: _dashboardStats!.totalWorkouts.toString(),
              icon: Icons.fitness_center,
              color: Colors.orange,
            ),
            StatCard(
              title: 'Progress Entries',
              value: _dashboardStats!.totalProgressEntries.toString(),
              icon: Icons.trending_up,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildWeeklyActivitySection() {
    if (_dashboardStats == null) {
      return SizedBox();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Last 7 Days',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: [
            StatCard(
              title: 'Active Users',
              value: _dashboardStats!.activeUsersLast7Days.toString(),
              icon: Icons.person_outline,
              color: Colors.teal,
              compact: true,
            ),
            StatCard(
              title: 'Meals Tracked',
              value: _dashboardStats!.mealsTrackedLast7Days.toString(),
              icon: Icons.lunch_dining,
              color: Colors.amber,
              compact: true,
            ),
            StatCard(
              title: 'Workouts',
              value: _dashboardStats!.workoutsCompletedLast7Days.toString(),
              icon: Icons.directions_run,
              color: Colors.deepOrange,
              compact: true,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildCharts() {
    if (_dashboardStats == null) {
      return SizedBox();
    }
    
    // Convert registration data for chart
    final registrationData = _prepareRegistrationChartData();
    
    // Convert progress score data for chart
    final progressData = _prepareProgressChartData();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User Registration Chart
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Registration Trend',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: BarChartWidget(data: registrationData),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 16),
        
        // Progress Score Chart
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Average Progress Score Trend',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: LineChartWidget(data: progressData),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  List<Map<String, dynamic>> _prepareRegistrationChartData() {
    final Map<String, int> sortedData = {};
    
    // Sort keys chronologically
    final sortedKeys = _dashboardStats!.userRegistrationByMonth.keys.toList()
      ..sort((a, b) {
        List<String> partsA = a.split('/');
        List<String> partsB = b.split('/');
        int yearA = int.parse(partsA[1]);
        int yearB = int.parse(partsB[1]);
        int monthA = int.parse(partsA[0]);
        int monthB = int.parse(partsB[0]);
        
        return (yearA * 12 + monthA) - (yearB * 12 + monthB);
      });
    
    // Get last 6 months of data
    final lastSixMonths = sortedKeys.length > 6 
        ? sortedKeys.sublist(sortedKeys.length - 6)
        : sortedKeys;
    
    // Create sorted map
    for (var key in lastSixMonths) {
      sortedData[key] = _dashboardStats!.userRegistrationByMonth[key]!;
    }
    
    // Convert to chart format
    return sortedData.entries.map((entry) {
      final parts = entry.key.split('/');
      final month = _getMonthName(int.parse(parts[0]));
      return {
        'month': month,
        'registrations': entry.value,
      };
    }).toList();
  }
  
  List<Map<String, dynamic>> _prepareProgressChartData() {
    final Map<String, double> sortedData = {};
    
    // Sort keys chronologically
    final sortedKeys = _dashboardStats!.avgProgressScoreByMonth.keys.toList()
      ..sort((a, b) {
        List<String> partsA = a.split('/');
        List<String> partsB = b.split('/');
        int yearA = int.parse(partsA[1]);
        int yearB = int.parse(partsB[1]);
        int monthA = int.parse(partsA[0]);
        int monthB = int.parse(partsB[0]);
        
        return (yearA * 12 + monthA) - (yearB * 12 + monthB);
      });
    
    // Get last 6 months of data
    final lastSixMonths = sortedKeys.length > 6 
        ? sortedKeys.sublist(sortedKeys.length - 6)
        : sortedKeys;
    
    // Create sorted map
    for (var key in lastSixMonths) {
      sortedData[key] = _dashboardStats!.avgProgressScoreByMonth[key]!;
    }
    
    // Convert to chart format
    return sortedData.entries.map((entry) {
      final parts = entry.key.split('/');
      final month = _getMonthName(int.parse(parts[0]));
      return {
        'month': month,
        'score': entry.value,
      };
    }).toList();
  }
  
  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'Jan';
      case 2: return 'Feb';
      case 3: return 'Mar';
      case 4: return 'Apr';
      case 5: return 'May';
      case 6: return 'Jun';
      case 7: return 'Jul';
      case 8: return 'Aug';
      case 9: return 'Sep';
      case 10: return 'Oct';
      case 11: return 'Nov';
      case 12: return 'Dec';
      default: return 'Unknown';
    }
  }
  
  Widget _buildActiveUsersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Most Active Users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserReportsPage()),
                );
              },
              child: Text('View All'),
            ),
          ],
        ),
        SizedBox(height: 8),
        _buildActiveUsersList(),
      ],
    );
  }
  
  Widget _buildActiveUsersList() {
    if (_userActivityStats.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No user activity data available'),
        ),
      );
    }
    
    // Show only top 5 users
    final users = _userActivityStats.take(5).toList();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: users.length,
        separatorBuilder: (context, index) => Divider(height: 1),
        itemBuilder: (context, index) {
          final user = users[index];
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                user.userName.isNotEmpty ? user.userName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(user.userName),
            subtitle: Text(user.userEmail),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Last active: ${_formatDate(user.lastActive)}',
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  '${user.mealCount} meals, ${user.workoutCount} workouts',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}