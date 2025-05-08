import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../models/admin_stats.dart';
import '../models/app_user.dart';
import '../models/user_activity.dart';
import '../widgets/stat_card.dart';

class OverviewTab extends StatelessWidget {
  final AdminStats stats;
  final List<AppUser> users;
  final List<UserActivity> activityData;

  const OverviewTab({
    Key? key,
    required this.stats,
    required this.users,
    required this.activityData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sort users by activity count
    final topUsers = List<AppUser>.from(users)
      ..sort((a, b) => b.totalActivity.compareTo(a.totalActivity));

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Last updated: ${DateFormat('MMM d, yyyy h:mm a').format(stats.lastUpdated)}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Users',
                  value: stats.totalUsers.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Active Users',
                  value: stats.activeUsers.toString(),
                  subtitle: '${(stats.activeUsers / stats.totalUsers * 100).toStringAsFixed(1)}% of total',
                  icon: Icons.person_outline,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Meal Entries',
                  value: stats.totalMealEntries.toString(),
                  icon: Icons.restaurant,
                  color: Colors.orange,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Workout Entries',
                  value: stats.totalWorkoutEntries.toString(),
                  icon: Icons.fitness_center,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          StatCard(
            title: 'Progress Entries',
            value: stats.totalProgressEntries.toString(),
            icon: Icons.trending_up,
            color: Colors.teal,
          ),

          SizedBox(height: 30),
          Text(
            'Recent Activity Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Container(
            height: 250,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: _buildActivityChart(),
          ),

          SizedBox(height: 30),
          Text(
            'Top Active Users',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          _buildTopUsersList(topUsers),
        ],
      ),
    );
  }

Widget _buildActivityChart() {
  final chartData = activityData.length > 14
      ? activityData.sublist(0, 14).reversed.toList()
      : activityData.reversed.toList();

  return SfCartesianChart(
    primaryXAxis: DateTimeCategoryAxis(
      dateFormat: DateFormat('MMM dd'),
    ),
    primaryYAxis: NumericAxis(),
    series: <CartesianSeries>[
      LineSeries<UserActivity, DateTime>(
        name: 'Meals',
        color: Colors.blue,
        xValueMapper: (UserActivity activity, _) => activity.date,
        yValueMapper: (UserActivity activity, _) => activity.mealEntries,
        dataSource: chartData,
      ),
      LineSeries<UserActivity, DateTime>(
        name: 'Workouts',
        color: Colors.purple,
        xValueMapper: (UserActivity activity, _) => activity.date,
        yValueMapper: (UserActivity activity, _) => activity.workoutEntries,
        dataSource: chartData,
      ),
      LineSeries<UserActivity, DateTime>(
        name: 'Progress',
        color: Colors.green,
        xValueMapper: (UserActivity activity, _) => activity.date,
        yValueMapper: (UserActivity activity, _) => activity.progressEntries,
        dataSource: chartData,
      ),
    ],
  );
}


  Widget _buildTopUsersList(List<AppUser> topUsers) {
    // Take top 5 users for the overview
    final displayUsers = topUsers.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < displayUsers.length; i++)
            _buildUserListItem(displayUsers[i], i + 1),

          if (users.length > 5)
            Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'and ${users.length - 5} more users',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserListItem(AppUser user, int rank) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              shape: BoxShape.circle,
            ),
            child: Text(
              rank.toString(),
              style: TextStyle(
                color: Colors.white,
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
                  user.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user.totalActivity} activities',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user.lastLoginAt != null
                    ? 'Last active: ${DateFormat('MMM d').format(user.lastLoginAt!)}'
                    : 'Never logged in',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade300;
      default:
        return Colors.blue.shade300;
    }
  }
}
