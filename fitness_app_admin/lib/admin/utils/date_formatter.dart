import 'package:intl/intl.dart';

class DateFormatter {
  // Format a date as YYYY-MM-DD
  static String formatYMD(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
  
  // Format a date as Month DD, YYYY
  static String formatMDY(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date);
  }
  
  // Format a date as Month DD, YYYY HH:MM AM/PM
  static String formatMDYHM(DateTime date) {
    return DateFormat('MMMM d, yyyy h:mm a').format(date);
  }
  
  // Format a time as HH:MM AM/PM
  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }
  
  // Format a date relative to now (today, yesterday, X days ago, or date)
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return formatMDY(date);
    }
  }
  
  // Format a date as Month name only
  static String formatMonth(DateTime date) {
    return DateFormat('MMMM').format(date);
  }
  
  // Format a date as Short Month name only (Jan, Feb, etc.)
  static String formatShortMonth(DateTime date) {
    return DateFormat('MMM').format(date);
  }
  
  // Format as Month YYYY
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }
  
  // Get the day name
  static String getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }
  
  // Get the short day name
  static String getShortDayName(DateTime date) {
    return DateFormat('E').format(date);
  }
  
  // Format date range as "Jan 1 - Jan 5, 2023"
  static String formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      return '${DateFormat('MMM d').format(start)} - ${DateFormat('d, yyyy').format(end)}';
    } else if (start.year == end.year) {
      return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}';
    } else {
      return '${DateFormat('MMM d, yyyy').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}';
    }
  }
  
  // Parse date string in format YYYY-MM-DD
  static DateTime? parseYMD(String dateStr) {
    try {
      return DateFormat('yyyy-MM-dd').parse(dateStr);
    } catch (e) {
      return null;
    }
  }
  
  // Get first day of month
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  // Get last day of month
  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }
  
  // Get first day of week (assuming week starts on Monday)
  static DateTime getFirstDayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }
  
  // Get last day of week (assuming week ends on Sunday)
  static DateTime getLastDayOfWeek(DateTime date) {
    return date.add(Duration(days: 7 - date.weekday));
  }
}