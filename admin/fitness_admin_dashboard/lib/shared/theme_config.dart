// lib/shared/theme_config.dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData getAdminTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      // ... more theme configuration
    );
  }
  
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return Colors.green;
      case 'inactive': return Colors.orange;
      case 'blocked': return Colors.red;
      default: return Colors.grey;
    }
  }
}