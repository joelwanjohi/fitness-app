import 'package:flutter/material.dart';

class AdminTheme {
  // Primary colors - Vibrant green as base
  static const Color primaryColor = Color(0xFF2E7D32); // Rich forest green
  static const Color primaryLightColor = Color(0xFFE8F5E9); // Light mint
  static const Color primaryDarkColor = Color(0xFF1B5E20); // Deep forest green
  static const Color accentColor = Color(0xFFFFD600); // Vibrant yellow
  
  // Secondary colors - Complementary palette
  static const Color successColor = Color(0xFF00C853); // Bright green
  static const Color warningColor = Color(0xFFFFAB00); // Golden amber
  static const Color errorColor = Color(0xFFD50000); // Bright red
  static const Color infoColor = Color(0xFF00B8D4); // Bright cyan
  
  // Neutral palette
  static const Color scaffoldBackgroundColor = Color(0xFFF9FBF7); // Off-white with slight green tint
  static const Color cardColor = Colors.white;
  static const Color surfaceColor = Color(0xFFFAFCF8); // Very light mint
  static const Color borderColor = Color(0xFFDCE6D7); // Light green-gray
  static const Color dividerColor = Color(0xFFEAF2E6); // Lighter green-gray
  
  // Text colors - Adjusted for green theme
  static const Color textPrimaryColor = Color(0xFF1C2A19); // Very dark green-black
  static const Color textSecondaryColor = Color(0xFF4C6447); // Dark green-gray
  static const Color textTertiaryColor = Color(0xFF7D907A); // Medium green-gray
  static const Color textOnPrimaryColor = Colors.white;
  static const Color textOnAccentColor = Color(0xFF1C2A19); // Dark text on yellow
  
  // Stat card colors - Green-yellow harmony
  static const List<Color> statCardColors = [
    Color(0xFF2E7D32), // Forest green (primary)
    Color(0xFFFFD600), // Yellow (accent)
    Color(0xFF388E3C), // Medium green
    Color(0xFF43A047), // Light green
    Color(0xFF1B5E20), // Dark green
    Color(0xFFF9A825), // Dark yellow
  ];
  
  // Gradients for visual interest
  static const List<List<Color>> gradients = [
    [Color(0xFF1B5E20), Color(0xFF388E3C)], // Green gradient
    [Color(0xFFFFD600), Color(0xFFFBC02D)], // Yellow gradient
    [Color(0xFF00C853), Color(0xFF69F0AE)], // Success gradient
    [Color(0xFFD50000), Color(0xFFFF5252)], // Error gradient
    [Color(0xFF4CAF50), Color(0xFF8BC34A)], // Green-lime gradient
  ];

  // Shadows with slight green tint
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF1B5E20).withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: const Color(0xFF1B5E20).withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // Create theme data for admin dashboard
  static ThemeData getThemeData() {
    return ThemeData(
      useMaterial3: true, // Using Material 3 for a more modern look
      colorScheme: ColorScheme(
        primary: primaryColor,
        onPrimary: textOnPrimaryColor,
        primaryContainer: primaryLightColor,
        onPrimaryContainer: primaryDarkColor,
        secondary: accentColor,
        onSecondary: textOnAccentColor,
        secondaryContainer: const Color(0xFFFFF9C4), // Light yellow
        onSecondaryContainer: const Color(0xFF33691E), // Dark green
        tertiary: const Color(0xFF558B2F), // Lime green
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFFDCEDC8), // Light lime
        onTertiaryContainer: const Color(0xFF33691E), // Dark green
        error: errorColor,
        onError: Colors.white,
        errorContainer: const Color(0xFFFFCDD2), // Light red
        onErrorContainer: const Color(0xFFB71C1C), // Dark red
        background: scaffoldBackgroundColor,
        onBackground: textPrimaryColor,
        surface: surfaceColor,
        onSurface: textPrimaryColor,
        surfaceVariant: const Color(0xFFEEF1EB), // Slight green tint
        onSurfaceVariant: textSecondaryColor,
        outline: borderColor,
        shadow: const Color(0xFF1B5E20).withOpacity(0.1),
        inverseSurface: textPrimaryColor,
        onInverseSurface: Colors.white,
        inversePrimary: primaryLightColor,
        brightness: Brightness.light,
      ),
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      cardColor: cardColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: primaryColor.withOpacity(0.4),
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: textOnPrimaryColor,
          backgroundColor: primaryColor,
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: TextStyle(color: textSecondaryColor),
        hintStyle: TextStyle(color: textTertiaryColor),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor.withOpacity(0.5), width: 1),
        ),
        color: cardColor,
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.all(8),
      ),
      dividerTheme: DividerThemeData(
        space: 24,
        thickness: 1,
        color: dividerColor,
      ),
      fontFamily: 'Poppins',
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
          letterSpacing: -0.25,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
          letterSpacing: 0.1,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimaryColor,
          letterSpacing: 0.15,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimaryColor,
          letterSpacing: 0.25,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textSecondaryColor,
          letterSpacing: 0.4,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondaryColor,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textSecondaryColor,
          letterSpacing: 0.5,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryDarkColor,
        contentTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondaryColor,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: primaryColor, width: 2),
          ),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryLightColor,
        disabledColor: dividerColor,
        selectedColor: primaryColor,
        secondarySelectedColor: accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          color: textPrimaryColor,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        brightness: Brightness.light,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: textOnAccentColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
  
  // Get color based on index - more consistent with design
  static Color getStatCardColor(int index) {
    return statCardColors[index % statCardColors.length];
  }
  
  // Get gradient based on index
  static List<Color> getGradient(int index) {
    return gradients[index % gradients.length];
  }
  
  // More sophisticated color mapping for dashboards
  static Color getProgressColor(double percentage) {
    if (percentage < 0.3) {
      return errorColor;
    } else if (percentage < 0.6) {
      return warningColor;
    } else if (percentage < 0.8) {
      return const Color(0xFF66BB6A); // Light green
    } else {
      return successColor;
    }
  }
  
  // Get color based on value for charts with more nuanced ranges
  static Color getColorForValue(double value, double max) {
    if (value <= max * 0.25) {
      return errorColor;
    } else if (value <= max * 0.5) {
      return warningColor;
    } else if (value <= max * 0.75) {
      return const Color(0xFF8BC34A); // Lime green
    } else {
      return successColor;
    }
  }
  
  // Get text color based on background for better accessibility
  static Color getTextColorForBackground(Color backgroundColor) {
    final double luminance = backgroundColor.computeLuminance();
    // Following WCAG recommendations for contrast
    return luminance > 0.55 ? textPrimaryColor : Colors.white;
  }
  
  // Get elevation shadow based on elevation level
  static List<BoxShadow> getShadowForElevation(int elevation) {
    switch (elevation) {
      case 0:
        return [];
      case 1:
        return [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ];
      case 2:
        return cardShadow;
      case 3:
      default:
        return elevatedShadow;
    }
  }
  
  // Get theme variant (for switching between themes)
  static ThemeMode getThemeMode(String mode) {
    switch (mode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }
  
  // Get semantic status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'online':
      case 'completed':
        return successColor;
      case 'pending':
      case 'in progress':
      case 'processing':
        return warningColor;
      case 'inactive':
      case 'offline':
      case 'failed':
        return errorColor;
      case 'draft':
      case 'delayed':
        return infoColor;
      default:
        return textTertiaryColor;
    }
  }
}