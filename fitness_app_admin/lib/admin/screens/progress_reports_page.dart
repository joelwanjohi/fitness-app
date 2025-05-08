import 'package:flutter/material.dart';
import '../controllers/dashboard_controller.dart';
import '../models/dashboard_stats.dart';
import '../widgets/admin_drawer.dart';
import 'admin_dashboard_page.dart';
import 'user_reports_page.dart';
import 'meal_reports_page.dart';
import 'workout_reports_page.dart';

class ProgressReportsPage extends StatefulWidget {
  const ProgressReportsPage({Key? key}) : super(key: key);

  @override
  _ProgressReportsPageState createState() => _ProgressReportsPageState();
}

class _ProgressReportsPageState extends State<ProgressReportsPage> {
  final DashboardController _dashboardController = DashboardController();
  bool _isLoading = true;
  ProgressStats? _progressStats;
  
  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }
  
  Future<void> _loadProgressData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final stats = await _dashboardController.getProgressStats();
      
      setState(() {
        _progressStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading progress data: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading progress data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Progress Reports'),
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
            onPressed: _loadProgressData,
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => WorkoutReportsPage()),
          );
        },
        onProgressReportsTap: () {
          Navigator.pop(context);
        },
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _progressStats == null
              ? Center(child: Text('No progress data available'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress Tracking Reports',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Overview of all user progress tracking activities',
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
                                'Progress Overview',
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
                                    label: 'Total Entries',
                                    value: _progressStats!.totalProgressEntries.toString(),
                                    icon: Icons.photo_camera,
                                    color: Colors.blue,
                                  ),
                                  _buildStatItem(
                                    label: 'Avg. Score',
                                    value: '${_progressStats!.avgProgressScore.toStringAsFixed(1)}',
                                    icon: Icons.trending_up,
                                    color: Colors.green,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Progress Over Time Card
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
                                'Progress Scores Over Time',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              _buildProgressOverTimeChart(),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // User Progress Card
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
                                'Top User Progress',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              _buildUserProgressList(),
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
  
  Widget _buildProgressOverTimeChart() {
    if (_progressStats == null || _progressStats!.avgProgressByMonth.isEmpty) {
      return Center(
        child: Text('No progress trend data available'),
      );
    }
    
    final progressByMonth = _progressStats!.avgProgressByMonth;
    
    // Sort the entries by month/year
    final sortedEntries = progressByMonth.entries.toList()
      ..sort((a, b) {
        List<String> partsA = a.key.split('/');
        List<String> partsB = b.key.split('/');
        int yearA = int.parse(partsA[1]);
        int yearB = int.parse(partsB[1]);
        int monthA = int.parse(partsA[0]);
        int monthB = int.parse(partsB[0]);
        
        return (yearA * 12 + monthA) - (yearB * 12 + monthB);
      });
    
    // Take the last 6 months (or all if less than 6)
    final displayEntries = sortedEntries.length > 6 
        ? sortedEntries.sublist(sortedEntries.length - 6)
        : sortedEntries;
    
    return Container(
      height: 250,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: displayEntries.map((entry) {
                final parts = entry.key.split('/');
                final month = int.parse(parts[0]);
                final year = parts[1];
                final monthName = _getMonthName(month);
                
                final score = entry.value;
                
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: double.infinity,
                          height: (score / 100) * 180, // Scale height based on score (max 100)
                          decoration: BoxDecoration(
                            color: _getScoreColor(score),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          score.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: displayEntries.map((entry) {
              final parts = entry.key.split('/');
              final month = int.parse(parts[0]);
              final monthName = _getMonthName(month);
              
              return Expanded(
                child: Text(
                  monthName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Color _getScoreColor(double score) {
    if (score < 30) {
      return Colors.red;
    } else if (score < 70) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
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
      default: return '';
    }
  }
  
// Fixes for the _buildUserProgressList() method

Widget _buildUserProgressList() {
  // Mock data for user progress - replace with actual API call in production
  final userProgress = [
    {
      'userId': '1',
      'userName': 'John Smith',
      'entryCount': 12,
      'initialScore': 45.0,
      'latestScore': 68.5,
      'lastUpdated': DateTime.now().subtract(Duration(days: 2)),
    },
    {
      'userId': '2',
      'userName': 'Emma Wilson',
      'entryCount': 8,
      'initialScore': 60.0,
      'latestScore': 78.0,
      'lastUpdated': DateTime.now().subtract(Duration(days: 5)),
    },
    {
      'userId': '3',
      'userName': 'Michael Brown',
      'entryCount': 15,
      'initialScore': 32.5,
      'latestScore': 65.0,
      'lastUpdated': DateTime.now().subtract(Duration(days: 1)),
    },
    {
      'userId': '4',
      'userName': 'Sarah Johnson',
      'entryCount': 6,
      'initialScore': 72.0,
      'latestScore': 83.5,
      'lastUpdated': DateTime.now().subtract(Duration(days: 7)),
    },
  ];
  
  if (userProgress.isEmpty) {
    return Center(
      child: Text('No user progress data available'),
    );
  }
  
  return ListView.separated(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    itemCount: userProgress.length,
    separatorBuilder: (context, index) => Divider(),
    itemBuilder: (context, index) {
      final progress = userProgress[index];
      
      // Fix 1: Ensure proper type conversion for numerical values
      final double initialScore = (progress['initialScore'] as double);
      final double latestScore = (progress['latestScore'] as double);
      final double change = latestScore - initialScore;
      
      // Fix 2: Add proper type casting for the userName
      final String userName = progress['userName'] as String;
      
      // Fix 3: Add proper type casting for lastUpdated
      final DateTime lastUpdated = progress['lastUpdated'] as DateTime;
      
      return ListTile(
        title: Text(
          userName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('Entries: ${progress['entryCount']}'),
            SizedBox(height: 2),
            Row(
              children: [
                Text(
                  'Progress: ${initialScore.toStringAsFixed(1)} → ${latestScore.toStringAsFixed(1)}',
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: change >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    change >= 0 ? '+${change.toStringAsFixed(1)}' : change.toStringAsFixed(1),
                    style: TextStyle(
                      color: change >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Last Update:',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Text(
              _formatDate(lastUpdated),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    },
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
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}