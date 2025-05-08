import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:fitness_admin_dashboard/admin/models/user_activity.dart';

class AnalyticsTab extends StatefulWidget {
  final List<UserActivity> activityData;

  const AnalyticsTab({
    Key? key,
    required this.activityData,
  }) : super(key: key);

  @override
  _AnalyticsTabState createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  String _timeRange = '30 days';
  String _chartType = 'line';
  bool _stackedView = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildFilterControls(),
          SizedBox(height: 30),
          Text('Activity Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Container(
            height: 350,
            padding: EdgeInsets.all(16),
            decoration: _boxDecoration(),
            child: _buildActivityChart(),
          ),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      );

  Widget _buildFilterControls() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  'Time Range:',
                  _timeRange,
                  ['7 days', '14 days', '30 days', '90 days'],
                  (val) => setState(() => _timeRange = val!),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  'Chart Type:',
                  _chartType,
                  ['line', 'bar', 'area', 'pie'],
                  (val) => setState(() => _chartType = val!),
                ),
              ),
              SizedBox(width: 16),
              Column(
                children: [
                  Text('Stacked:'),
                  Switch(
                    value: _stackedView,
                    onChanged: (val) => setState(() => _stackedView = val),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String currentValue,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.capitalize()))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildActivityChart() {
    if (widget.activityData.isEmpty) {
      return Center(child: Text('No activity data available.'));
    }

    final days = int.parse(_timeRange.split(' ')[0]);
    final data = widget.activityData.length > days
        ? widget.activityData.sublist(0, days).reversed.toList()
        : widget.activityData.reversed.toList();

    switch (_chartType) {
      case 'bar':
        return SfCartesianChart(
          legend: Legend(isVisible: true),
          primaryXAxis: DateTimeAxis(),
          primaryYAxis: NumericAxis(),
          series: _buildBarSeries(data),
        );
      case 'area':
        return SfCartesianChart(
          legend: Legend(isVisible: true),
          primaryXAxis: DateTimeAxis(),
          series: _buildAreaSeries(data),
        );
      case 'pie':
        return _buildPieChart(data.isNotEmpty ? data.last : null);
      case 'line':
      default:
        return SfCartesianChart(
          legend: Legend(isVisible: true),
          primaryXAxis: DateTimeAxis(),
          series: _buildLineSeries(data),
        );
    }
  }

  List<CartesianSeries<dynamic, dynamic>> _buildLineSeries(List<UserActivity> data) {
    return [
      LineSeries<UserActivity, DateTime>(
        name: 'Meals',
        dataSource: data,
        xValueMapper: (d, _) => d.date,
        yValueMapper: (d, _) => d.mealEntries,
      ),
      LineSeries<UserActivity, DateTime>(
        name: 'Workouts',
        dataSource: data,
        xValueMapper: (d, _) => d.date,
        yValueMapper: (d, _) => d.workoutEntries,
      ),
      LineSeries<UserActivity, DateTime>(
        name: 'Progress',
        dataSource: data,
        xValueMapper: (d, _) => d.date,
        yValueMapper: (d, _) => d.progressEntries,
      ),
      LineSeries<UserActivity, DateTime>(
        name: 'New Users',
        dataSource: data,
        xValueMapper: (d, _) => d.date,
        yValueMapper: (d, _) => d.newUsers,
      ),
    ];
  }

  List<CartesianSeries<dynamic, dynamic>> _buildBarSeries(List<UserActivity> data) {
    return [
      ColumnSeries<UserActivity, DateTime>(
        name: 'Meals',
        dataSource: data,
        xValueMapper: (d, _) => d.date,
        yValueMapper: (d, _) => d.mealEntries,
        isTrackVisible: true,
      ),
      ColumnSeries<UserActivity, DateTime>(
        name: 'Workouts',
        dataSource: data,
        xValueMapper: (d, _) => d.date,
        yValueMapper: (d, _) => d.workoutEntries,
      ),
      ColumnSeries<UserActivity, DateTime>(
        name: 'Progress',
        dataSource: data,
        xValueMapper: (d, _) => d.date,
        yValueMapper: (d, _) => d.progressEntries,
      ),
      ColumnSeries<UserActivity, DateTime>(
        name: 'New Users',
        dataSource: data,
        xValueMapper: (d, _) => d.date,
        yValueMapper: (d, _) => d.newUsers,
      ),
    ];
  }

  List<CartesianSeries<dynamic, dynamic>> _buildAreaSeries(List<UserActivity> data) {
    return [
      AreaSeries<UserActivity, DateTime>(
        name: 'Meals',
        dataSource: data,
        xValueMapper: (d, _) => d.date,
        yValueMapper: (d, _) => d.mealEntries,
      ),
      AreaSeries<UserActivity, DateTime>(
        name: 'Workouts',
        dataSource: data,
        xValueMapper: (d, _) => d.date,
        yValueMapper: (d, _) => d.workoutEntries,
      ),
      AreaSeries<UserActivity, DateTime>(
        name: 'Progress',
        dataSource: data,
        xValueMapper: (d, _) => d.date,
        yValueMapper: (d, _) => d.progressEntries,
      ),
      AreaSeries<UserActivity, DateTime>(
        name: 'New Users',
        dataSource: data,
        xValueMapper: (d, _) => d.date,
        yValueMapper: (d, _) => d.newUsers,
      ),
    ];
  }

  Widget _buildPieChart(UserActivity? latestActivity) {
    if (latestActivity == null) return Center(child: Text('No data for Pie Chart.'));

    final pieData = [
      _PieData('Meals', latestActivity.mealEntries),
      _PieData('Workouts', latestActivity.workoutEntries),
      _PieData('Progress', latestActivity.progressEntries),
      _PieData('New Users', latestActivity.newUsers),
    ];

    return SfCircularChart(
      legend: Legend(isVisible: true),
      series: <PieSeries<_PieData, String>>[
        PieSeries<_PieData, String>(
          dataSource: pieData,
          xValueMapper: (_PieData data, _) => data.label,
          yValueMapper: (_PieData data, _) => data.value,
          dataLabelSettings: DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }
}

class _PieData {
  final String label;
  final int value;

  _PieData(this.label, this.value);
}

extension StringCasingExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}
