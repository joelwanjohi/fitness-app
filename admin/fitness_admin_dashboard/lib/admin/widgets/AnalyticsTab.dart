import 'package:fitness_admin_dashboard/admin/models/user_activity.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:charts_flutter_new/flutter.dart' as charts;



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
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          // Filter controls
          Container(
            padding: EdgeInsets.all(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Time Range:'),
                          DropdownButton<String>(
                            value: _timeRange,
                            isExpanded: true,
                            items: ['7 days', '14 days', '30 days', '90 days']
                                .map((range) => DropdownMenuItem(
                                  value: range,
                                  child: Text(range),
                                ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _timeRange = value ?? '30 days';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Chart Type:'),
                          DropdownButton<String>(
                            value: _chartType,
                            isExpanded: true,
                            items: ['line', 'bar', 'area']
                                .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type.capitalize()),
                                ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _chartType = value ?? 'line';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Column(
                      children: [
                        Text('Stacked:'),
                        Switch(
                          value: _stackedView,
                          onChanged: (value) {
                            setState(() {
                              _stackedView = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 30),
          
          // Activity trend chart
          Text(
            'Activity Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Container(
            height: 350,
            padding: EdgeInsets.all(16),
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
          
          // Activity distribution
          Text(
            'Activity Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 250,
                  padding: EdgeInsets.all(16),
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
                  child: _buildPieChart(),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 250,
                  padding: EdgeInsets.all(16),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activity Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildActivitySummary(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 30),
          
          // Daily activity breakdown
          Text(
            'Daily Activity Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(16),
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
            child: _buildActivityTable(),
          ),
          
          SizedBox(height: 30),
        ],
      ),
    );
  }
  
  Widget _buildActivityChart() {
    // Filter data based on selected time range
    final days = int.parse(_timeRange.split(' ')[0]);
    final filteredData = widget.activityData.length > days
        ? widget.activityData.sublist(0, days).reversed.toList()
        : widget.activityData.reversed.toList();
    
    // Series for different activities
    final mealSeries = charts.Series<UserActivity, DateTime>(
      id: 'Meals',
      colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
      domainFn: (UserActivity activity, _) => activity.date,
      measureFn: (UserActivity activity, _) => activity.mealEntries,
      data: filteredData,
    );
    
    final workoutSeries = charts.Series<UserActivity, DateTime>(
      id: 'Workouts',
      colorFn: (_, __) => charts.MaterialPalette.purple.shadeDefault,
      domainFn: (UserActivity activity, _) => activity.date,
      measureFn: (UserActivity activity, _) => activity.workoutEntries,
      data: filteredData,
    );
    
    final progressSeries = charts.Series<UserActivity, DateTime>(
      id: 'Progress',
      colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
      domainFn: (UserActivity activity, _) => activity.date,
      measureFn: (UserActivity activity, _) => activity.progressEntries,
      data: filteredData,
    );
    
    final newUsersSeries = charts.Series<UserActivity, DateTime>(
      id: 'New Users',
      colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
      domainFn: (UserActivity activity, _) => activity.date,
      measureFn: (UserActivity activity, _) => activity.newUsers,
      data: filteredData,
    );
    
    final seriesList = [mealSeries, workoutSeries, progressSeries, newUsersSeries];
    
    // Create the appropriate chart based on selected type
    switch (_chartType) {
      case 'bar':
        return charts.TimeSeriesChart(
          seriesList,
          animate: true,
          dateTimeFactory: const charts.LocalDateTimeFactory(),
          defaultRenderer: charts.BarRendererConfig<DateTime>(
            groupingType: _stackedView
                ? charts.BarGroupingType.stacked
                : charts.BarGroupingType.grouped,
            strokeWidthPx: 1.0,
          ),
          behaviors: [
            charts.SeriesLegend(
              position: charts.BehaviorPosition.bottom,
              outsideJustification: charts.OutsideJustification.middleDrawArea,
              horizontalFirst: true,
              desiredMaxRows: 2,
              cellPadding: EdgeInsets.only(right: 16, bottom: 4),
            ),
            charts.PanAndZoomBehavior(),
          ],
        );
      case 'area':
        return charts.TimeSeriesChart(
          seriesList,
          animate: true,
          dateTimeFactory: const charts.LocalDateTimeFactory(),
          defaultRenderer: charts.LineRendererConfig(
            includeArea: true,
            stacked: _stackedView,
            includeLine: true,
          ),
          behaviors: [
            charts.SeriesLegend(
              position: charts.BehaviorPosition.bottom,
              outsideJustification: charts.OutsideJustification.middleDrawArea,
              horizontalFirst: true,
              desiredMaxRows: 2,
              cellPadding: EdgeInsets.only(right: 16, bottom: 4),
            ),
            charts.PanAndZoomBehavior(),
          ],
        );
      case 'line':
      default:
        return charts.TimeSeriesChart(
          seriesList,
          animate: true,
          dateTimeFactory: const charts.LocalDateTimeFactory(),
          defaultRenderer: charts.LineRendererConfig(includeLine: true),
          behaviors: [
            charts.SeriesLegend(
              position: charts.BehaviorPosition.bottom,
              outsideJustification: charts.OutsideJustification.middleDrawArea,
              horizontalFirst: true,
              desiredMaxRows: 2,
              cellPadding: EdgeInsets.only(right: 16, bottom: 4),
            ),
            charts.PanAndZoomBehavior(),
          ],
        );
    }
  }
  
  Widget _buildPieChart() {
    // Calculate totals for each activity type
    int totalMeals = 0;
    int totalWorkouts = 0;
    int totalProgress = 0;
    
    for (var activity in widget.activityData) {
      totalMeals += activity.mealEntries;
      totalWorkouts += activity.workoutEntries;
      totalProgress += activity.progressEntries;
    }
    
    // Create data for pie chart
    final pieData = [
      _ActivityCount('Meals', totalMeals, charts.MaterialPalette.blue.shadeDefault),
      _ActivityCount('Workouts', totalWorkouts, charts.MaterialPalette.purple.shadeDefault),
      _ActivityCount('Progress', totalProgress, charts.MaterialPalette.green.shadeDefault),
    ];
    
    final series = [
      charts.Series<_ActivityCount, String>(
        id: 'Activities',
        domainFn: (_ActivityCount activity, _) => activity.type,
        measureFn: (_ActivityCount activity, _) => activity.count,
        colorFn: (_ActivityCount activity, _) => activity.color,
        data: pieData,
        labelAccessorFn: (_ActivityCount activity, _) =>
            '${activity.type}\n${activity.count}',
      )
    ];
    
    return charts.PieChart(
      series,
      animate: true,
      defaultRenderer: charts.ArcRendererConfig(
        arcWidth: 60,
        arcRendererDecorators: [
          charts.ArcLabelDecorator(
            labelPosition: charts.ArcLabelPosition.auto,
          )
        ],
      ),
      behaviors: [
        charts.DatumLegend(
          position: charts.BehaviorPosition.bottom,
          outsideJustification: charts.OutsideJustification.middleDrawArea,
          horizontalFirst: false,
          desiredMaxRows: 3,
          cellPadding: EdgeInsets.only(right: 4, bottom: 4),
          entryTextStyle: charts.TextStyleSpec(
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildActivitySummary() {
    // Calculate totals and averages
    int totalMeals = 0;
    int totalWorkouts = 0;
    int totalProgress = 0;
    int totalNewUsers = 0;
    
    for (var activity in widget.activityData) {
      totalMeals += activity.mealEntries;
      totalWorkouts += activity.workoutEntries;
      totalProgress += activity.progressEntries;
      totalNewUsers += activity.newUsers;
    }
    
    final int days = widget.activityData.length;
    final double avgMeals = days > 0 ? totalMeals / days : 0;
    final double avgWorkouts = days > 0 ? totalWorkouts / days : 0;
    final double avgProgress = days > 0 ? totalProgress / days : 0;
    final double avgNewUsers = days > 0 ? totalNewUsers / days : 0;
    
    return Column(
      children: [
        _buildSummaryItem('Total Activities', totalMeals + totalWorkouts + totalProgress),
        SizedBox(height: 8),
        _buildSummaryItem('New Users', totalNewUsers),
        SizedBox(height: 8),
        Divider(),
        SizedBox(height: 8),
        _buildSummaryItem('Daily Avg. Activities', (avgMeals + avgWorkouts + avgProgress).toStringAsFixed(1)),
        SizedBox(height: 8),
        _buildSummaryItem('Daily Avg. New Users', avgNewUsers.toStringAsFixed(1)),
        SizedBox(height: 8),
        Divider(),
        SizedBox(height: 8),
        _buildSummaryItem('Period', '${days} days'),
      ],
    );
  }
  
  Widget _buildSummaryItem(String label, dynamic value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildActivityTable() {
    // Get the most recent days (up to 14)
    final displayData = widget.activityData.length > 14
        ? widget.activityData.sublist(0, 14).reversed.toList()
        : widget.activityData.reversed.toList();
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('New Users')),
          DataColumn(label: Text('Meals')),
          DataColumn(label: Text('Workouts')),
          DataColumn(label: Text('Progress')),
          DataColumn(label: Text('Total')),
        ],
        rows: displayData.map((activity) {
          final total = activity.mealEntries + activity.workoutEntries + activity.progressEntries;
          
          return DataRow(cells: [
            DataCell(Text(DateFormat('MMM d, yyyy').format(activity.date))),
            DataCell(Text(activity.newUsers.toString())),
            DataCell(Text(activity.mealEntries.toString())),
            DataCell(Text(activity.workoutEntries.toString())),
            DataCell(Text(activity.progressEntries.toString())),
            DataCell(Text(
              total.toString(),
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
          ]);
        }).toList(),
      ),
    );
  }
}

// Helper class for the pie chart
class _ActivityCount {
  final String type;
  final int count;
  final charts.Color color;
  
  _ActivityCount(this.type, this.count, this.color);
}

// Helper extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return this.isEmpty ? this : '${this[0].toUpperCase()}${this.substring(1)}';
  }
}