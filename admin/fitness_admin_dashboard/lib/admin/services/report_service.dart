import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

import '../models/admin_stats.dart';
import '../models/app_user.dart';
import '../models/user_activity.dart';

class ReportService {
  // Generate and share a full analytics report
  Future<void> generateAnalyticsReport({
    required AdminStats stats,
    required List<AppUser> topUsers,
    required List<UserActivity> activityData,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Text(
          'Fitness App Analytics Report',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}'),
          ],
        ),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 20),

            // User Statistics Section
            pw.Container(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('User Statistics',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Paragraph(text: 'Total Users: ${stats.totalUsers}'),
                  pw.Paragraph(text: 'Active Users (Last 30 Days): ${stats.activeUsers}'),
                  pw.Paragraph(
                      text: 'Activity Rate: ${(stats.activeUsers / stats.totalUsers * 100).toStringAsFixed(1)}%'),
                ],
              ),
            ),

            pw.SizedBox(height: 10),

            // Activity Overview Section
            pw.Container(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Activity Overview',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text('Meal Entries', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Text('${stats.totalMealEntries}'),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text('Workout Entries', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Text('${stats.totalWorkoutEntries}'),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text('Progress Entries', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Text('${stats.totalProgressEntries}'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Top Active Users Section
            pw.Container(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Top Active Users',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Table.fromTextArray(
                    headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                    headerHeight: 25,
                    cellHeight: 40,
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerLeft,
                      2: pw.Alignment.center,
                      3: pw.Alignment.center,
                    },
                    headerStyle: pw.TextStyle(
                      color: PdfColors.black,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    headers: ['Name', 'Email', 'Status', 'Activity Count'],
                    data: topUsers.take(10).map((user) => [
                      user.name,
                      user.email,
                      user.status.toString().split('.').last,
                      user.totalActivity.toString(),
                    ]).toList(),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Activity Trend Section
            pw.Container(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Activity Trend',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Paragraph(text: 'Activity trend for the last ${activityData.length} days:'),
                  pw.SizedBox(height: 10),
                  pw.Table.fromTextArray(
                    headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.center,
                      2: pw.Alignment.center,
                      3: pw.Alignment.center,
                      4: pw.Alignment.center,
                    },
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    headers: ['Date', 'New Users', 'Meals', 'Workouts', 'Progress'],
                    data: activityData.map((activity) => [
                      DateFormat('MMM d, yyyy').format(activity.date),
                      activity.newUsers.toString(),
                      activity.mealEntries.toString(),
                      activity.workoutEntries.toString(),
                      activity.progressEntries.toString(),
                    ]).toList(),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    // Save and share the PDF
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/fitness_app_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Fitness App Analytics Report',
      subject: 'Fitness App Analytics Report ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
    );
  }

  // Generate a user management report
  Future<void> generateUserReport(List<AppUser> users) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Text(
          'Fitness App User Report',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}'),
          ],
        ),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 20),
            pw.Paragraph(text: 'Total Users: ${users.length}'),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
              headerHeight: 25,
              cellHeight: 40,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
              },
              headerStyle: pw.TextStyle(
                color: PdfColors.black,
                fontWeight: pw.FontWeight.bold,
              ),
              headers: ['Name', 'Email', 'Status', 'Created', 'Last Active', 'Activity Count'],
              data: users.map((user) => [
                user.name,
                user.email,
                user.status.toString().split('.').last,
                DateFormat('MMM d, yyyy').format(user.createdAt),
                user.lastLoginAt != null
                    ? DateFormat('MMM d, yyyy').format(user.lastLoginAt!)
                    : 'Never',
                user.totalActivity.toString(),
              ]).toList(),
            ),
          ];
        },
      ),
    );

    // Save and share the PDF
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/fitness_app_users_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Fitness App Analytics Report',
      subject: 'Fitness App Analytics Report ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
    );
  }
}
