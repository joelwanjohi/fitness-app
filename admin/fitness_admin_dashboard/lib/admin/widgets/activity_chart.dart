import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/user_activity.dart';

class ActivityChart extends StatelessWidget {
  final List<UserActivity> activityData;
  final String chartType;
  final bool stackedView;

  const ActivityChart({
    Key? key,
    required this.activityData,
    this.chartType = 'line',
    this.stackedView = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Reverse list to show oldest first
    final displayData = activityData.reversed.toList();

    final List<ChartData> mealData = displayData.map((activity) =>
        ChartData(activity.date, activity.mealEntries.toDouble())).toList();
    final List<ChartData> workoutData = displayData.map((activity) =>
        ChartData(activity.date, activity.workoutEntries.toDouble())).toList();
    final List<ChartData> progressData = displayData.map((activity) =>
        ChartData(activity.date, activity.progressEntries.toDouble())).toList();
    final List<ChartData> newUsersData = displayData.map((activity) =>
        ChartData(activity.date, activity.newUsers.toDouble())).toList();

    // Create series list (using CartesianSeries instead of ChartSeries)
    List<CartesianSeries<ChartData, DateTime>> seriesList = [
      LineSeries<ChartData, DateTime>(
        dataSource: mealData,
        xValueMapper: (ChartData data, _) => data.date,
        yValueMapper: (ChartData data, _) => data.value,
        name: 'Meals',
        color: Colors.blue,
      ),
      LineSeries<ChartData, DateTime>(
        dataSource: workoutData,
        xValueMapper: (ChartData data, _) => data.date,
        yValueMapper: (ChartData data, _) => data.value,
        name: 'Workouts',
        color: Colors.purple,
      ),
      LineSeries<ChartData, DateTime>(
        dataSource: progressData,
        xValueMapper: (ChartData data, _) => data.date,
        yValueMapper: (ChartData data, _) => data.value,
        name: 'Progress',
        color: Colors.green,
      ),
      LineSeries<ChartData, DateTime>(
        dataSource: newUsersData,
        xValueMapper: (ChartData data, _) => data.date,
        yValueMapper: (ChartData data, _) => data.value,
        name: 'New Users',
        color: Colors.red,
      ),
    ];

    // Based on chartType, return different chart types
    switch (chartType) {
      case 'bar':
        return SfCartesianChart(
          primaryXAxis: DateTimeAxis(),
          primaryYAxis: NumericAxis(),
          series: <CartesianSeries>[
            ColumnSeries<ChartData, DateTime>(
              dataSource: mealData,
              xValueMapper: (ChartData data, _) => data.date,
              yValueMapper: (ChartData data, _) => data.value,
              name: 'Meals',
            ),
            ColumnSeries<ChartData, DateTime>(
              dataSource: workoutData,
              xValueMapper: (ChartData data, _) => data.date,
              yValueMapper: (ChartData data, _) => data.value,
              name: 'Workouts',
            ),
            ColumnSeries<ChartData, DateTime>(
              dataSource: progressData,
              xValueMapper: (ChartData data, _) => data.date,
              yValueMapper: (ChartData data, _) => data.value,
              name: 'Progress',
            ),
            ColumnSeries<ChartData, DateTime>(
              dataSource: newUsersData,
              xValueMapper: (ChartData data, _) => data.date,
              yValueMapper: (ChartData data, _) => data.value,
              name: 'New Users',
            ),
          ],
        );
      case 'area':
        return SfCartesianChart(
          primaryXAxis: DateTimeAxis(),
          primaryYAxis: NumericAxis(),
          series: <CartesianSeries>[
            AreaSeries<ChartData, DateTime>(
              dataSource: mealData,
              xValueMapper: (ChartData data, _) => data.date,
              yValueMapper: (ChartData data, _) => data.value,
              name: 'Meals',
              opacity: 0.4,
            ),
            AreaSeries<ChartData, DateTime>(
              dataSource: workoutData,
              xValueMapper: (ChartData data, _) => data.date,
              yValueMapper: (ChartData data, _) => data.value,
              name: 'Workouts',
              opacity: 0.4,
            ),
            AreaSeries<ChartData, DateTime>(
              dataSource: progressData,
              xValueMapper: (ChartData data, _) => data.date,
              yValueMapper: (ChartData data, _) => data.value,
              name: 'Progress',
              opacity: 0.4,
            ),
            AreaSeries<ChartData, DateTime>(
              dataSource: newUsersData,
              xValueMapper: (ChartData data, _) => data.date,
              yValueMapper: (ChartData data, _) => data.value,
              name: 'New Users',
              opacity: 0.4,
            ),
          ],
        );
      case 'line':
      default:
        return SfCartesianChart(
          primaryXAxis: DateTimeAxis(),
          primaryYAxis: NumericAxis(),
          series: seriesList,
        );
    }
  }
}

class ChartData {
  final DateTime date;
  final double value;

  ChartData(this.date, this.value);
}
