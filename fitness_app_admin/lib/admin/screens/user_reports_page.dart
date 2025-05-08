import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/dashboard_controller.dart';
import '../models/dashboard_stats.dart';
import '../widgets/admin_drawer.dart';
import 'admin_dashboard_page.dart';
import 'meal_reports_page.dart';
import 'workout_reports_page.dart';
import 'progress_reports_page.dart';
import '../utils/pdf_generator.dart';

class UserReportsPage extends StatefulWidget {
  const UserReportsPage({Key? key}) : super(key: key);

  @override
  _UserReportsPageState createState() => _UserReportsPageState();
}

class _UserReportsPageState extends State<UserReportsPage> {
  final DashboardController _dashboardController = DashboardController();
  bool _isLoading = true;
  List<UserActivityStats> _userStats = [];
  List<Map<String, dynamic>> _allUsers = [];
  
  // Filtering and sorting
  String _searchQuery = '';
  String _sortBy = 'lastActive'; // Options: lastActive, name, mealCount, workoutCount, progressCount
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userStats = await _dashboardController.getUserActivityStats();
      final allUsers = await _dashboardController.getAllUsers();
      
      setState(() {
        _userStats = userStats;
        _allUsers = allUsers;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading user data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Sort user stats
  List<UserActivityStats> _getSortedUserStats() {
    List<UserActivityStats> sortedList = List.from(_userStats);
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      sortedList = sortedList.where((user) {
        return user.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               user.userEmail.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Sort the list
    sortedList.sort((a, b) {
      if (_sortBy == 'lastActive') {
        return _sortAscending
            ? a.lastActive.compareTo(b.lastActive)
            : b.lastActive.compareTo(a.lastActive);
      } else if (_sortBy == 'name') {
        return _sortAscending
            ? a.userName.compareTo(b.userName)
            : b.userName.compareTo(a.userName);
      } else if (_sortBy == 'mealCount') {
        return _sortAscending
            ? a.mealCount.compareTo(b.mealCount)
            : b.mealCount.compareTo(a.mealCount);
      } else if (_sortBy == 'workoutCount') {
        return _sortAscending
            ? a.workoutCount.compareTo(b.workoutCount)
            : b.workoutCount.compareTo(a.workoutCount);
      } else if (_sortBy == 'progressCount') {
        return _sortAscending
            ? a.progressCount.compareTo(b.progressCount)
            : b.progressCount.compareTo(a.progressCount);
      }
      return 0;
    });
    
    return sortedList;
  }

  // Export data to PDF
  Future<void> _exportUserReport() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final generator = PdfGenerator();
      await generator.generateUserActivityReport(_getSortedUserStats());
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User report exported successfully'),
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
    final sortedUsers = _getSortedUserStats();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('User Reports'),
        actions: [
          IconButton(
            icon: Icon(Icons.file_download),
            tooltip: 'Export Report',
            onPressed: _exportUserReport,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _loadUserData,
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
          : Column(
              children: [
                _buildSearchAndFilterBar(sortedUsers.length),
                Expanded(
                  child: _buildUsersList(sortedUsers),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilterBar(int userCount) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Activity Report',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name or email',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              SizedBox(width: 16),
              DropdownButton<String>(
                value: _sortBy,
                icon: Icon(Icons.sort),
                underline: Container(
                  height: 2,
                  color: Colors.blue,
                ),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      if (_sortBy == newValue) {
                        _sortAscending = !_sortAscending;
                      } else {
                        _sortBy = newValue;
                        _sortAscending = false; // Default to descending for new sort
                      }
                    });
                  }
                },
                items: [
                  DropdownMenuItem(
                    value: 'lastActive',
                    child: Text('Recent Activity'),
                  ),
                  DropdownMenuItem(
                    value: 'name',
                    child: Text('Name'),
                  ),
                  DropdownMenuItem(
                    value: 'mealCount',
                    child: Text('Meal Count'),
                  ),
                  DropdownMenuItem(
                    value: 'progressCount',
                    child: Text('Progress Entries'),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Showing $userCount users',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<UserActivityStats> users) {
    if (users.isEmpty) {
      return Center(
        child: Text('No users found'),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: users.length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(UserActivityStats user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    user.userName.isNotEmpty ? user.userName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.userName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        user.userEmail,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Last active:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatDate(user.lastActive),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActivityCounter(
                  label: 'Meals',
                  count: user.mealCount,
                  icon: Icons.restaurant,
                  color: Colors.green,
                ),
                _buildActivityCounter(
                  label: 'Progress',
                  count: user.progressCount,
                  icon: Icons.trending_up,
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCounter({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hr ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}