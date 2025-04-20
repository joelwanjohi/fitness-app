import 'package:fitness_admin_dashboard/admin/widgets/AnalyticsTab.dart';
import 'package:fitness_admin_dashboard/admin/widgets/ReportsTab.dart';
import 'package:fitness_admin_dashboard/admin/widgets/UserManagementTab.dart';
import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/analytics_service.dart';
import '../models/admin_stats.dart';
import '../models/app_user.dart';
import '../models/user_activity.dart';
import 'overview_tab.dart';


class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AdminService _adminService = AdminService();
  final AnalyticsService _analyticsService = AnalyticsService();
  
  int _selectedIndex = 0;
  bool _isLoading = true;
  
  // Data
  AdminStats? _stats;
  List<AppUser> _users = [];
  List<UserActivity> _activityData = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load all data at once
      final Future<AdminStats> statsFuture = _adminService.getAdminStats();
      final Future<List<AppUser>> usersFuture = _adminService.getAllUsers();
      final Future<List<UserActivity>> activityFuture = _analyticsService.getActivityData(30);
      
      // Wait for all futures to complete
      final results = await Future.wait([
        statsFuture,
        usersFuture,
        activityFuture,
      ]);
      
      setState(() {
        _stats = results[0] as AdminStats;
        _users = results[1] as List<AppUser>;
        _activityData = results[2] as List<UserActivity>;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading admin dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading dashboard data: ${e.toString()}'),
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
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildContent(),
bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.summarize),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent() {
    if (_stats == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text('Failed to load dashboard data'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    switch (_selectedIndex) {
      case 0:
        return OverviewTab(stats: _stats!, users: _users, activityData: _activityData);
      case 1:
        return UserManagementTab(
          users: _users,
          onStatusChanged: _updateUserStatus,
          onAdminToggled: _toggleAdminStatus,
          onUserDeleted: _deleteUser,
        );
      case 2:
        return AnalyticsTab(activityData: _activityData);
      case 3:
        return ReportsTab(
          stats: _stats!,
          users: _users,
          activityData: _activityData,
        );
      default:
        return Center(child: Text('Unknown tab'));
    }
  }
  
  Future<void> _updateUserStatus(String userId, UserStatus newStatus) async {
    try {
      await _adminService.updateUserStatus(userId, newStatus);
      
      // Update the local data
      setState(() {
        final userIndex = _users.indexWhere((user) => user.id == userId);
        if (userIndex >= 0) {
          _users = List.from(_users);
          _users[userIndex] = AppUser(
            id: _users[userIndex].id,
            name: _users[userIndex].name,
            email: _users[userIndex].email,
            createdAt: _users[userIndex].createdAt,
            lastLoginAt: _users[userIndex].lastLoginAt,
            status: newStatus,
            isAdmin: _users[userIndex].isAdmin,
            activityCounts: _users[userIndex].activityCounts,
          );
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User status updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating user status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _toggleAdminStatus(String userId, bool isAdmin) async {
    try {
      await _adminService.toggleAdminStatus(userId, isAdmin);
      
      // Update the local data
      setState(() {
        final userIndex = _users.indexWhere((user) => user.id == userId);
        if (userIndex >= 0) {
          _users = List.from(_users);
          _users[userIndex] = AppUser(
            id: _users[userIndex].id,
            name: _users[userIndex].name,
            email: _users[userIndex].email,
            createdAt: _users[userIndex].createdAt,
            lastLoginAt: _users[userIndex].lastLoginAt,
            status: _users[userIndex].status,
            isAdmin: isAdmin,
            activityCounts: _users[userIndex].activityCounts,
          );
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Admin status updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating admin status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _deleteUser(String userId) async {
    try {
      await _adminService.deleteUser(userId);
      
      // Update the local data
      setState(() {
        _users = _users.where((user) => user.id != userId).toList();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting user: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}