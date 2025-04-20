import 'package:flutter/material.dart';
import 'package:charts_flutter_new/flutter.dart' as charts;

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
    
    // Series for different activities
    final mealSeries = charts.Series<UserActivity, DateTime>(
      id: 'Meals',
      colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
      domainFn: (UserActivity activity, _) => activity.date,
      measureFn: (UserActivity activity, _) => activity.mealEntries,
      data: displayData,
    );
    
    final workoutSeries = charts.Series<UserActivity, DateTime>(
      id: 'Workouts',
      colorFn: (_, __) => charts.MaterialPalette.purple.shadeDefault,
      domainFn: (UserActivity activity, _) => activity.date,
      measureFn: (UserActivity activity, _) => activity.workoutEntries,
      data: displayData,
    );
    
    final progressSeries = charts.Series<UserActivity, DateTime>(
      id: 'Progress',
      colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
      domainFn: (UserActivity activity, _) => activity.date,
      measureFn: (UserActivity activity, _) => activity.progressEntries,
      data: displayData,
    );
    
    final newUsersSeries = charts.Series<UserActivity, DateTime>(
      id: 'New Users',
      colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
      domainFn: (UserActivity activity, _) => activity.date,
      measureFn: (UserActivity activity, _) => activity.newUsers,
      data: displayData,
    );
    
    final seriesList = [mealSeries, workoutSeries, progressSeries, newUsersSeries];
    
    // Create the appropriate chart based on selected type
    switch (chartType) {
      case 'bar':
        return charts.TimeSeriesChart(
          seriesList,
          animate: true,
          dateTimeFactory: const charts.LocalDateTimeFactory(),
          defaultRenderer: charts.BarRendererConfig<DateTime>(
            groupingType: stackedView
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
            stacked: stackedView,
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
}