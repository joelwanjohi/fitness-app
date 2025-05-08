import 'dart:html' as html;  // For web support
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import '../models/dashboard_stats.dart';

class PdfGenerator {
  // Colors for consistent branding
  final PdfColor primaryColor = PdfColors.blue700;
  final PdfColor accentColor = PdfColors.green600;
  final PdfColor bgColor = PdfColors.blue50;
  final PdfColor textColor = PdfColors.blueGrey800;
  final PdfColor lightTextColor = PdfColors.blueGrey600;
  
  // Generate user activity report
  Future<void> generateUserActivityReport(List<UserActivityStats> users) async {
    try {
      final pdf = pw.Document(
        theme: _getDocumentTheme(),
      );
      
      // Add cover page
      pdf.addPage(_buildCoverPage('User Activity Report'));
      
      // Add content pages 
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          header: (context) => _buildReportHeader('User Activity Report'),
          footer: (context) => _buildReportFooter(context),
          build: (context) => [
            _buildReportIntro(
              title: 'User Activity Report',
              description: 'Overview of user engagement and activities in the Fitness App.',
              itemCount: users.length,
              dateRange: 'All Time',
              icon: pw.IconData(0xe491), // person icon code
            ),
            pw.SizedBox(height: 20),
            _buildSummaryMetrics([
              {'label': 'Active Users', 'value': '${users.length}'},
              {'label': 'Total Meals', 'value': '${users.fold(0, (sum, user) => sum + user.mealCount)}'},
              {'label': 'Progress Entries', 'value': '${users.fold(0, (sum, user) => sum + user.progressCount)}'},
            ]),
            pw.SizedBox(height: 30),
            _buildUserStats(users),
          ],
        ),
      );
      
      // Save and download the PDF
      await _saveAndDownloadPdf(pdf, 'user_activity_report');
    } catch (e) {
      print('Error generating user activity report: $e');
    }
  }
  
  // Generate meal report
  Future<void> generateMealReport(MealStats stats, List<Map<String, dynamic>> topMeals) async {
    try {
      final pdf = pw.Document(
        theme: _getDocumentTheme(),
      );
      
      // Add cover page
      pdf.addPage(_buildCoverPage('Meal Tracking Report'));
      
      // Add content pages
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          header: (context) => _buildReportHeader('Meal Tracking Report'),
          footer: (context) => _buildReportFooter(context),
          build: (context) => [
            _buildReportIntro(
              title: 'Meal Tracking Report',
              description: 'Detailed analysis of meal tracking data across all users.',
              itemCount: stats.totalMeals,
              dateRange: 'All Time',
              icon: pw.IconData(0xe532), // restaurant icon code
            ),
            pw.SizedBox(height: 20),
            _buildSummaryMetrics([
              {'label': 'Total Meals', 'value': '${stats.totalMeals}'},
              {'label': 'Avg. Calories', 'value': '${stats.avgCaloriesPerMeal.toStringAsFixed(1)}'},
              {'label': 'Avg. Protein', 'value': '${stats.avgProteinPerMeal.toStringAsFixed(1)}g'},
            ]),
            pw.SizedBox(height: 30),
            _buildMealStats(stats),
            pw.SizedBox(height: 40),
            _buildTopMealsTable(topMeals),
            pw.SizedBox(height: 20),
            _buildNutritionDistributionChart(stats),
          ],
        ),
      );
      
      // Save and download the PDF
      await _saveAndDownloadPdf(pdf, 'meal_tracking_report');
    } catch (e) {
      print('Error generating meal report: $e');
    }
  }
  
  // Generate progress report
  Future<void> generateProgressReport(ProgressStats stats, List<Map<String, dynamic>> userProgress) async {
    try {
      final pdf = pw.Document(
        theme: _getDocumentTheme(),
      );
      
      // Add cover page
      pdf.addPage(_buildCoverPage('Progress Tracking Report'));
      
      // Add content pages
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          header: (context) => _buildReportHeader('Progress Tracking Report'),
          footer: (context) => _buildReportFooter(context),
          build: (context) => [
            _buildReportIntro(
              title: 'Progress Tracking Report',
              description: 'Detailed analysis of user progress tracking data.',
              itemCount: stats.totalProgressEntries,
              dateRange: 'All Time',
              icon: pw.IconData(0xe8e5), // trending up icon code
            ),
            pw.SizedBox(height: 20),
            _buildSummaryMetrics([
              {'label': 'Total Entries', 'value': '${stats.totalProgressEntries}'},
              {'label': 'Avg. Score', 'value': '${stats.avgProgressScore.toStringAsFixed(1)}'},
              {'label': 'Monthly Growth', 'value': '${_calculateMonthlyGrowth(stats.avgProgressByMonth)}%'},
            ]),
            pw.SizedBox(height: 30),
            _buildProgressStats(stats),
            pw.SizedBox(height: 40),
            _buildUserProgressTable(userProgress),
            pw.SizedBox(height: 20),
            _buildProgressTrendsChart(stats),
          ],
        ),
      );
      
      // Save and download the PDF
      await _saveAndDownloadPdf(pdf, 'progress_tracking_report');
    } catch (e) {
      print('Error generating progress report: $e');
    }
  }
  
  // New method for document theme
  pw.ThemeData _getDocumentTheme() {
    return pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      italic: pw.Font.helveticaOblique(),
      boldItalic: pw.Font.helveticaBoldOblique(),
    );
  }
  
  // New method to build cover page
  pw.Page _buildCoverPage(String title) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(0),
      build: (context) {
        return pw.Stack(
          children: [
            // Background gradient
            pw.Container(
              width: context.page.pageFormat.width,
              height: context.page.pageFormat.height,
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [primaryColor, PdfColors.blue900],
                  begin: pw.Alignment.topLeft,
                  end: pw.Alignment.bottomRight,
                ),
              ),
            ),
            // Content
            pw.Padding(
              padding: pw.EdgeInsets.all(40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Fitness App Logo/Text
                  pw.Container(
                    padding: pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      'FITNESS APP',
                      style: pw.TextStyle(
                        color: primaryColor,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Spacer(),
                  // Report Title
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 36,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Container(
                    width: 80,
                    height: 6,
                    decoration: pw.BoxDecoration(
                      color: accentColor,
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                  ),
                  pw.SizedBox(height: 24),
pw.Text(
  'Generated on ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
  style: pw.TextStyle(
    color: PdfColor.fromInt(0xCCFFFFFF), // 80% opacity white
    fontSize: 14,
  ),
),
pw.Spacer(),
pw.Text(
  'CONFIDENTIAL',
  style: pw.TextStyle(
    color: PdfColor.fromInt(0x99FFFFFF), // 60% opacity white
    fontSize: 10,
  ),
),

                ],
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Save and download the PDF
  Future<void> _saveAndDownloadPdf(pw.Document pdf, String fileName) async {
    try {
      // Create a timestamp for unique file naming
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fullFileName = '$fileName-$timestamp.pdf';
      
      if (kIsWeb) {
        // For web platform - implement download functionality
        final bytes = await pdf.save();
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        // Create a link element and trigger download
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fullFileName)
          ..style.display = 'none';
        
        html.document.body?.children.add(anchor);
        anchor.click();
        
        // Clean up
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
        
        print('PDF download initiated for web');
      } else {
        // For mobile platforms
        final dir = await _getDocumentsDirectory();
        if (dir == null) {
          print('Could not access document directory');
          return;
        }
        
        final file = File('${dir.path}/$fullFileName');
        await file.writeAsBytes(await pdf.save());
        
        print('PDF saved successfully at: ${file.path}');
        
        // Open the file for viewing (which allows saving)
        await OpenFile.open(file.path);
      }
    } catch (e) {
      print('Error saving/downloading PDF: $e');
    }
  }
  
  // Build report header
  pw.Widget _buildReportHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Fitness App',
              style: pw.TextStyle(
                fontSize: 22,
                color: primaryColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 14,
                color: lightTextColor,
              ),
            ),
          ],
        ),
pw.Divider(color: PdfColor.fromInt(0x802196F3)), // primaryColor with 50% opacity

      ],
    );
  }
  
  // Build report footer
  pw.Widget _buildReportFooter(pw.Context context) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      padding: pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated on ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
            style: pw.TextStyle(
              fontSize: 9,
              color: lightTextColor,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 9,
              color: lightTextColor,
            ),
          ),
        ],
      ),
    );
  }
  
  // Build report intro section
  pw.Widget _buildReportIntro({
    required String title,
    required String description,
    required int itemCount,
    required String dateRange,
    required pw.IconData icon,
  }) {
return pw.Container(
  padding: pw.EdgeInsets.all(20),
  decoration: pw.BoxDecoration(
    color: PdfColor.fromInt(0x80F4F4F4), // bgColor with 50% opacity
    borderRadius: pw.BorderRadius.circular(8),
    border: pw.Border.all(
      color: PdfColor.fromInt(0x332196F3), // primaryColor with 20% opacity
    ),
  ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                padding: pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Icon(
                  icon,
                  color: PdfColors.white,
                  size: 18,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            description,
            style: pw.TextStyle(
              fontSize: 12,
              color: lightTextColor,
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            children: [
              _buildInfoBox(
                title: 'Report Date',
                value: DateFormat('MMMM d, yyyy').format(DateTime.now()),
                iconData: pw.IconData(0xe916), // calendar icon
              ),
              pw.SizedBox(width: 20),
              _buildInfoBox(
                title: 'Items Count',
                value: itemCount.toString(),
                iconData: pw.IconData(0xe3b0), // list icon
              ),
              pw.SizedBox(width: 20),
              _buildInfoBox(
                title: 'Date Range',
                value: dateRange, 
                iconData: pw.IconData(0xe8df), // date range icon
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Build summary metrics row
  pw.Widget _buildSummaryMetrics(List<Map<String, String>> metrics) {
    return pw.Row(
      children: metrics.map((metric) {
        return pw.Expanded(
          child: pw.Container(
            padding: pw.EdgeInsets.all(16),
            margin: pw.EdgeInsets.symmetric(horizontal: 4),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
              boxShadow: [
                pw.BoxShadow(
                  color: PdfColors.grey300,
                  offset: PdfPoint(0, 2),
                  blurRadius: 3,
                ),
              ],
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  metric['value']!,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  metric['label']!,
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: lightTextColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  
  // Build info box
  pw.Widget _buildInfoBox({
    required String title,
    required String value,
    required pw.IconData iconData,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Row(
          children: [
            pw.Container(
              padding: pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: bgColor,
                shape: pw.BoxShape.circle,
              ),
              child: pw.Icon(
                iconData,
                color: primaryColor,
                size: 12,
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: lightTextColor,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    value,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build user stats section
  pw.Widget _buildUserStats(List<UserActivityStats> users) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('User Activity Summary', pw.IconData(0xe491)),
        pw.SizedBox(height: 16),
        pw.Container(
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(8),
            boxShadow: [
              pw.BoxShadow(
                color: PdfColors.grey300,
                offset: PdfPoint(0, 2),
                blurRadius: 3,
              ),
            ],
          ),
          child: pw.Table(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              verticalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              top: pw.BorderSide.none,
              bottom: pw.BorderSide.none,
              right: pw.BorderSide.none,
              left: pw.BorderSide.none,
            ),
            children: [
              // Table header
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(8),
                    topRight: pw.Radius.circular(8),
                  ),
                ),
                children: [
                  _buildTableHeader('User Name'),
                  _buildTableHeader('Email'),
                  _buildTableHeader('Meals'),
                  _buildTableHeader('Progress'),
                  _buildTableHeader('Last Active'),
                ],
              ),
              // Table data rows with alternating colors
              ...users.asMap().entries.map((entry) {
                final index = entry.key;
                final user = entry.value;
                final isEven = index % 2 == 0;
                
                return pw.TableRow(
decoration: pw.BoxDecoration(
  color: isEven 
      ? PdfColors.white 
      : PdfColor.fromInt(0x4DF4F4F4), // bgColor with 30% opacity
  borderRadius: index == users.length - 1 
      ? pw.BorderRadius.only(
          bottomLeft: pw.Radius.circular(8),
          bottomRight: pw.Radius.circular(8),
        )
      : null,
),

                  children: [
                    _buildTableCell(user.userName),
                    _buildTableCell(user.userEmail),
                    _buildTableCell(user.mealCount.toString(), align: pw.TextAlign.center),
                    _buildTableCell(user.progressCount.toString(), align: pw.TextAlign.center),
                    _buildTableCell(_formatDate(user.lastActive)),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
  
  // Build meal stats section
  pw.Widget _buildMealStats(MealStats stats) {
    // Format meal types for table
    List<pw.TableRow> mealTypeRows = [];
    stats.mealsByType.forEach((type, count) {
      final percentage = stats.totalMeals > 0 ? (count / stats.totalMeals * 100) : 0.0;
      mealTypeRows.add(
        pw.TableRow(
          children: [
            _buildTableCell(type),
            _buildTableCell(count.toString(), align: pw.TextAlign.center),
            _buildTableCell('${percentage.toStringAsFixed(1)}%', align: pw.TextAlign.center),
          ],
        ),
      );
    });
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Meal Tracking Statistics', pw.IconData(0xe532)),
        pw.SizedBox(height: 16),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildStatCard(
                    title: 'Total Meals Tracked',
                    value: stats.totalMeals.toString(),
                    icon: pw.IconData(0xe56c),
                    color: primaryColor,
                  ),
                  pw.SizedBox(height: 12),
                  _buildStatCard(
                    title: 'Avg. Calories Per Meal',
                    value: stats.avgCaloriesPerMeal.toStringAsFixed(1),
                    icon: pw.IconData(0xef2d),  // local fire icon
                    color: PdfColors.orange700,
                  ),
                  pw.SizedBox(height: 12),
                  _buildStatCard(
                    title: 'Avg. Protein Per Meal',
                    value: '${stats.avgProteinPerMeal.toStringAsFixed(1)}g',
                    icon: pw.IconData(0xe3f9),  // spa icon
                    color: PdfColors.green700,
                  ),
                  pw.SizedBox(height: 12),
                  _buildStatCard(
                    title: 'Avg. Fat Per Meal',
                    value: '${stats.avgFatPerMeal.toStringAsFixed(1)}g',
                    icon: pw.IconData(0xe30c),  // opacity icon
                    color: PdfColors.amber700,
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              flex: 3,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8),
                  boxShadow: [
                    pw.BoxShadow(
                      color: PdfColors.grey300,
                      offset: PdfPoint(0, 2),
                      blurRadius: 3,
                    ),
                  ],
                ),
                padding: pw.EdgeInsets.all(16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Meals by Type',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Table(
                        border: pw.TableBorder(
                          horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                          verticalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                          top: pw.BorderSide.none,
                          bottom: pw.BorderSide.none,
                          right: pw.BorderSide.none,
                          left: pw.BorderSide.none,
                        ),
                        children: [
                          // Table header
                          pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: bgColor,
                            ),
                            children: [
                              _buildTableHeader('Meal Type'),
                              _buildTableHeader('Count'),
                              _buildTableHeader('Percentage'),
                            ],
                          ),
                          // Table data rows
                          ...mealTypeRows,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Build top meals table
  pw.Widget _buildTopMealsTable(List<Map<String, dynamic>> topMeals) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Most Popular Meals', pw.IconData(0xe838)),
        pw.SizedBox(height: 12),
        pw.Container(
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(8),
            boxShadow: [
              pw.BoxShadow(
                color: PdfColors.grey300,
                offset: PdfPoint(0, 2),
                blurRadius: 3,
              ),
            ],
          ),
          child: pw.Table(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              verticalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              top: pw.BorderSide.none,
              bottom: pw.BorderSide.none,
              right: pw.BorderSide.none,
              left: pw.BorderSide.none,
            ),
            children: [
              // Table header
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(8),
                    topRight: pw.Radius.circular(8),
                  ),
                ),
                children: [
                  _buildTableHeader('Meal Name'),
                  _buildTableHeader('Type'),
                  _buildTableHeader('Calories'),
                  _buildTableHeader('Protein'),
                  _buildTableHeader('Frequency'),
                ],
              ),
              // Table data rows with alternating colors
              ...topMeals.asMap().entries.map((entry) {
                final index = entry.key;
                final meal = entry.value;
                final isEven = index % 2 == 0;
                
                return pw.TableRow(
decoration: pw.BoxDecoration(
  color: isEven 
      ? PdfColors.white 
      : PdfColor.fromInt(0x4D003F88), // 0x4D = 30% alpha
  borderRadius: index == topMeals.length - 1 
      ? pw.BorderRadius.only(
          bottomLeft: pw.Radius.circular(8),
          bottomRight: pw.Radius.circular(8),
        )
      : null,
),

                  children: [
                    _buildTableCell(meal['name'] ?? 'Unknown'),
                    _buildTableCell(meal['type'] ?? 'Other'),
                    _buildTableCell('${meal['calories']}', align: pw.TextAlign.center),
                    _buildTableCell('${meal['protein']}g', align: pw.TextAlign.center),
                    _buildTableCell('${meal['count']}', align: pw.TextAlign.center),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
  
  // Build progress stats section
  pw.Widget _buildProgressStats(ProgressStats stats) {
    // Format progress by month for table
    List<pw.TableRow> progressByMonthRows = [];
    stats.avgProgressByMonth.forEach((month, score) {
      progressByMonthRows.add(
        pw.TableRow(
          children: [
            _buildTableCell(month),
            _buildTableCell('${score.toStringAsFixed(1)}', align: pw.TextAlign.center),
          ],
        ),
      );
    });
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Progress Tracking Statistics', pw.IconData(0xe8e5)),
        pw.SizedBox(height: 16),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildStatCard(
                    title: 'Total Progress Entries',
                    value: stats.totalProgressEntries.toString(),
                    icon: pw.IconData(0xe97c), // note add icon
                    color: PdfColors.deepPurple600,
                  ),
                  pw.SizedBox(height: 12),
                  _buildStatCard(
                   title: 'Avg. Progress Score',
                    value: '${stats.avgProgressScore.toStringAsFixed(1)}',
                    icon: pw.IconData(0xe885), // star icon
                    color: PdfColors.amber700,
                  ),
                  pw.SizedBox(height: 12),
                  _buildStatCard(
                    title: 'Monthly Growth Rate',
                    value: '${_calculateMonthlyGrowth(stats.avgProgressByMonth)}%',
                    icon: pw.IconData(0xe8dc), // trending up icon
                    color: accentColor,
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              flex: 3,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8),
                  boxShadow: [
                    pw.BoxShadow(
                      color: PdfColors.grey300,
                      offset: PdfPoint(0, 2),
                      blurRadius: 3,
                    ),
                  ],
                ),
                padding: pw.EdgeInsets.all(16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Average Progress by Month',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Table(
                        border: pw.TableBorder(
                          horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                          verticalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                          top: pw.BorderSide.none,
                          bottom: pw.BorderSide.none,
                          right: pw.BorderSide.none,
                          left: pw.BorderSide.none,
                        ),
                        children: [
                          // Table header
                          pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: bgColor,
                            ),
                            children: [
                              _buildTableHeader('Month'),
                              _buildTableHeader('Average Score'),
                            ],
                          ),
                          // Table data rows
                          ...progressByMonthRows,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Build user progress table
  pw.Widget _buildUserProgressTable(List<Map<String, dynamic>> userProgress) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('User Progress Summary', pw.IconData(0xe877)),
        pw.SizedBox(height: 12),
        pw.Container(
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(8),
            boxShadow: [
              pw.BoxShadow(
                color: PdfColors.grey300,
                offset: PdfPoint(0, 2),
                blurRadius: 3,
              ),
            ],
          ),
          child: pw.Table(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              verticalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              top: pw.BorderSide.none,
              bottom: pw.BorderSide.none,
              right: pw.BorderSide.none,
              left: pw.BorderSide.none,
            ),
            children: [
              // Table header
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(8),
                    topRight: pw.Radius.circular(8),
                  ),
                ),
                children: [
                  _buildTableHeader('User'),
                  _buildTableHeader('Entries'),
                  _buildTableHeader('Initial Score'),
                  _buildTableHeader('Latest Score'),
                  _buildTableHeader('Change'),
                ],
              ),
              // Table data rows with alternating colors
              ...userProgress.asMap().entries.map((entry) {
                final index = entry.key;
                final progress = entry.value;
                final isEven = index % 2 == 0;
                final change = progress['latestScore'] - progress['initialScore'];
                final isPositiveChange = change >= 0;
                
                return pw.TableRow(
decoration: pw.BoxDecoration(
  color: isEven 
      ? PdfColors.white 
      : PdfColor.fromInt(0x4D003F88), // 0x4D = 30% opacity
  borderRadius: index == userProgress.length - 1 
      ? pw.BorderRadius.only(
          bottomLeft: pw.Radius.circular(8),
          bottomRight: pw.Radius.circular(8),
        )
      : null,
),

                  children: [
                    _buildTableCell(progress['userName'] ?? 'Unknown'),
                    _buildTableCell('${progress['entryCount']}', align: pw.TextAlign.center),
                    _buildTableCell('${progress['initialScore'].toStringAsFixed(1)}', align: pw.TextAlign.center),
                    _buildTableCell('${progress['latestScore'].toStringAsFixed(1)}', align: pw.TextAlign.center),
                    _buildTableCell(
                      _getProgressChangeText(change),
                      align: pw.TextAlign.center,
                      textColor: isPositiveChange ? PdfColors.green700 : PdfColors.red700,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
  
  // Build section header with icon
  pw.Widget _buildSectionHeader(String title, pw.IconData iconData) {
    return pw.Row(
      children: [
        pw.Container(
          padding: pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            color: primaryColor,
            shape: pw.BoxShape.circle,
          ),
          child: pw.Icon(
            iconData,
            color: PdfColors.white,
            size: 14,
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: textColor,
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Container(
            height: 1,
            color: PdfColors.grey300,
          ),
        ),
      ],
    );
  }
  
  // Build a stat card with icon
  pw.Widget _buildStatCard({
    required String title,
    required String value,
    required pw.IconData icon,
    required PdfColor color,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColors.grey300,
            offset: PdfPoint(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: pw.Row(
        children: [
pw.Container(
  padding: pw.EdgeInsets.all(8),
  decoration: pw.BoxDecoration(
    color: PdfColor.fromInt(0x1A003F88), // 10% opacity background
    shape: pw.BoxShape.circle,
  ),
  child: pw.Icon(
    icon,
    color: PdfColor.fromInt(0xFF003F88), // Solid icon color
    size: 18,
  ),
),

          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: lightTextColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  value,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper for table header
  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
  
  // Helper for table cells
  pw.Widget _buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? textColor,
    pw.FontWeight? fontWeight,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          color: textColor ?? this.textColor,
          fontWeight: fontWeight,
        ),
        textAlign: align,
      ),
    );
  }
  
  // Format date for reports
  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
  
  // Format progress change text
  String _getProgressChangeText(double change) {
    if (change > 0) {
      return '+${change.toStringAsFixed(1)} ↑';
    } else if (change < 0) {
      return '${change.toStringAsFixed(1)} ↓';
    } else {
      return '0.0';
    }
  }
  
  // Calculate monthly growth percentage
  String _calculateMonthlyGrowth(Map<String, double> monthlyData) {
    if (monthlyData.length < 2) return '0.0';
    
    final values = monthlyData.values.toList();
    if (values.isEmpty) return '0.0';
    
    final firstValue = values.first;
    final lastValue = values.last;
    
    if (firstValue == 0) return '0.0';
    
    final growthRate = ((lastValue - firstValue) / firstValue) * 100;
    return growthRate.toStringAsFixed(1);
  }
  
  // Add a simple nutrition distribution chart
  pw.Widget _buildNutritionDistributionChart(MealStats stats) {
    // Calculate total macros
    final totalCal = stats.avgCaloriesPerMeal;
    final proteinCal = stats.avgProteinPerMeal * 4; // 4 cal per gram
    final fatCal = stats.avgFatPerMeal * 9; // 9 cal per gram
    final carbCal = totalCal - proteinCal - fatCal;
    
    // Calculate percentages
    final proteinPct = (proteinCal / totalCal) * 100;
    final fatPct = (fatCal / totalCal) * 100;
    final carbPct = (carbCal / totalCal) * 100;
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Nutrition Distribution', pw.IconData(0xe3d1)), // pie chart icon
        pw.SizedBox(height: 16),
        pw.Container(
          padding: pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(8),
            boxShadow: [
              pw.BoxShadow(
                color: PdfColors.grey300,
                offset: PdfPoint(0, 2),
                blurRadius: 3,
              ),
            ],
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Simplified chart representation with colored bars
                    pw.Container(
                      height: 20,
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: proteinPct.round(),
                            child: pw.Container(color: PdfColors.green700),
                          ),
                          pw.Expanded(
                            flex: fatPct.round(),
                            child: pw.Container(color: PdfColors.amber700),
                          ),
                          pw.Expanded(
                            flex: carbPct.round(),
                            child: pw.Container(color: PdfColors.blue700),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    
                    // Legend
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        _buildChartLegendItem('Protein', '${proteinPct.round()}%', PdfColors.green700),
                        pw.SizedBox(width: 24),
                        _buildChartLegendItem('Fat', '${fatPct.round()}%', PdfColors.amber700),
                        pw.SizedBox(width: 24),
                        _buildChartLegendItem('Carbs', '${carbPct.round()}%', PdfColors.blue700),
                      ],
                    ),
                    
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'Average Distribution Per Meal',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: lightTextColor,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Build progress trends chart (simple visualization)
  pw.Widget _buildProgressTrendsChart(ProgressStats stats) {
    if (stats.avgProgressByMonth.isEmpty) {
      return pw.Container();
    }
    
    final months = stats.avgProgressByMonth.keys.toList();
    final values = stats.avgProgressByMonth.values.toList();
    
    // Find min and max for scaling
    double minValue = values.reduce((curr, next) => curr < next ? curr : next);
    double maxValue = values.reduce((curr, next) => curr > next ? curr : next);
    
    // Allow for some padding in the chart
    minValue = (minValue * 0.9).clamp(0, double.infinity);
    maxValue = (maxValue * 1.1).clamp(0, double.infinity);
    
    final chartHeight = 150.0;
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Progress Trends', pw.IconData(0xe6e1)), // timeline icon
        pw.SizedBox(height: 16),
        pw.Container(
          padding: pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(8),
            boxShadow: [
              pw.BoxShadow(
                color: PdfColors.grey300,
                offset: PdfPoint(0, 2),
                blurRadius: 3,
              ),
            ],
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(
                height: chartHeight,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: List.generate(values.length, (i) {
                    final normalizedHeight = ((values[i] - minValue) / (maxValue - minValue)) * chartHeight;
                    
                    return pw.Expanded(
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
pw.Container(
  height: normalizedHeight,
  margin: pw.EdgeInsets.symmetric(horizontal: 4),
  decoration: pw.BoxDecoration(
    color: PdfColor.fromInt(0xB22196F3), // primaryColor with 70% opacity
    borderRadius: pw.BorderRadius.only(
      topLeft: pw.Radius.circular(4),
      topRight: pw.Radius.circular(4),
    ),
  ),
),

                        ],
                      ),
                    );
                  }),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Row(
                children: List.generate(months.length, (i) {
                  return pw.Expanded(
                    child: pw.Text(
                      months[i],
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: lightTextColor,
                      ),
                    ),
                  );
                }),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Progress Score Trend by Month',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: lightTextColor,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Build chart legend item
  pw.Widget _buildChartLegendItem(String label, String value, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(
          width: 12,
          height: 12,
          color: color,
        ),
        pw.SizedBox(width: 6),
        pw.Text(
          '$label: $value',
          style: pw.TextStyle(
            fontSize: 10,
            color: textColor,
          ),
        ),
      ],
    );
  }
  
  // Safe way to get application directory
  Future<Directory?> _getDocumentsDirectory() async {
    try {
      if (kIsWeb) {
        // For web platform, we can't use the filesystem directly
        print('PDF generation on web platform is handled separately');
        return null;
      } else {
        // For mobile platforms
        return await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      print('Error getting directory: $e');
      return null;
    }
  }
}