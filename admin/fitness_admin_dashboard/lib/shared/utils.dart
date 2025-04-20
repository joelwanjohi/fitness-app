// lib/shared/utils.dart
import 'package:intl/intl.dart';

class Utils {
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
  
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy h:mm a').format(date);
  }
  
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  static double calculateBmi(double heightCm, double weightKg) {
    final heightInMeters = heightCm / 100;
    return weightKg / (heightInMeters * heightInMeters);
  }
}