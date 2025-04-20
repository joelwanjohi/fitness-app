import 'package:fitness_admin_dashboard/admin/models/admin_stats.dart';
import 'package:fitness_admin_dashboard/admin/models/app_user.dart';
import 'package:fitness_admin_dashboard/admin/models/user_activity.dart';
import 'package:fitness_admin_dashboard/admin/services/report_service.dart';
import 'package:flutter/material.dart';


class ReportsTab extends StatefulWidget {
  final AdminStats stats;
  final List<AppUser> users;
  final List<UserActivity> activityData;
  
  const ReportsTab({
    Key? key,
    required this.stats,
    required this.users,
    required this.activityData,
  }) : super(key: key);
  
  @override
  _ReportsTabState createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  final ReportService _reportService = ReportService();
  bool _isGenerating = false;
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reports',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Generate detailed reports for your fitness app',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 30),
          
          // Analytics report
          _buildReportCard(
            title: 'Activity Analytics Report',
            description: 'A comprehensive report of user activities, app usage, and trends over time.',
            icon: Icons.analytics,
            color: Colors.blue,
            onGenerate: _generateAnalyticsReport,
          ),
          
          SizedBox(height: 20),
          
          // User management report
          _buildReportCard(
            title: 'User Management Report',
            description: 'Detailed information about all users, their status, and activity levels.',
            icon: Icons.people,
            color: Colors.green,
            onGenerate: _generateUserReport,
          ),
          
          SizedBox(height: 20),
          
          // Custom report
          _buildCustomReportCard(),
        ],
      ),
    );
  }
  
  Widget _buildReportCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onGenerate,
  }) {
    return Card(
      elevation: 4,
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
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(icon, color: color),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Generated as PDF',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(description),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _isGenerating ? null : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Generate report with sample data'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(Icons.remove_red_eye),
                  label: Text('Preview'),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : () async {
                    setState(() {
                      _isGenerating = true;
                    });
                    
                    try {
                      onGenerate();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error generating report: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      setState(() {
                        _isGenerating = false;
                      });
                    }
                  },
                  icon: _isGenerating
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.picture_as_pdf),
                  label: Text('Generate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCustomReportCard() {
    return Card(
      elevation: 4,
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
                  backgroundColor: Colors.orange.withOpacity(0.2),
                  child: Icon(Icons.build, color: Colors.orange),
                ),
                SizedBox(width: 16),
                Text(
                  'Custom Report',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text('Generate a customized report with specific parameters and date ranges.'),
            SizedBox(height: 16),
            ExpansionTile(
              title: Text('Configure Custom Report'),
              tilePadding: EdgeInsets.zero,
              children: [
                // Date range selector
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Start Date',
                          helperText: 'MM/DD/YYYY',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'End Date',
                          helperText: 'MM/DD/YYYY',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Report sections
                Text(
                  'Include Sections:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                CheckboxListTile(
                  title: Text('User Statistics'),
                  value: true,
                  onChanged: (value) {},
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: Text('Activity Analysis'),
                  value: true,
                  onChanged: (value) {},
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: Text('Top Users'),
                  value: true,
                  onChanged: (value) {},
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Custom report generation not implemented yet'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text('Generate Custom Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _generateAnalyticsReport() async {
    // Sort users by activity count for the report
    final topUsers = List<AppUser>.from(widget.users)
      ..sort((a, b) => b.totalActivity.compareTo(a.totalActivity));
    
    await _reportService.generateAnalyticsReport(
      stats: widget.stats,
      topUsers: topUsers,
      activityData: widget.activityData,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Analytics report generated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  Future<void> _generateUserReport() async {
    await _reportService.generateUserReport(widget.users);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User report generated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}