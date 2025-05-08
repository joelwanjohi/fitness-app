import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDrawer extends StatelessWidget {
  final VoidCallback onDashboardTap;
  final VoidCallback onUserReportsTap;
  final VoidCallback onMealReportsTap;
  final VoidCallback onWorkoutReportsTap;
  final VoidCallback onProgressReportsTap;

  const AdminDrawer({
    Key? key,
    required this.onDashboardTap,
    required this.onUserReportsTap,
    required this.onMealReportsTap,
    required this.onWorkoutReportsTap,
    required this.onProgressReportsTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final email = currentUser?.email ?? 'Admin User';

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text('Admin Dashboard'),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.admin_panel_settings,
                color: Color(0xFF2E7D32),
                size: 32,
              ),
            ),
            decoration: BoxDecoration(
              color: Color(0xFF2E7D32),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: onDashboardTap,
                ),
                Divider(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'REPORTS',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'User Reports',
                  onTap: onUserReportsTap,
                ),
                _buildDrawerItem(
                  icon: Icons.restaurant,
                  title: 'Meal Reports',
                  onTap: onMealReportsTap,
                ),

                _buildDrawerItem(
                  icon: Icons.trending_up,
                  title: 'Progress Reports',
                  onTap: onProgressReportsTap,
                ),
                Divider(),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.help,
                  title: 'Help & Support',
                  onTap: () {},
                ),
              ],
            ),
          ),
          Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}