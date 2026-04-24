import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2563EB);    // Blue
  static const Color accent = Color(0xFF3B82F6);     // Blue
  
  static const Color gain = Color(0xFF10B981);       // Emerald (keep green for gains)
  static const Color loss = Color(0xFFEF4444);       // Rose/Red
  
  static const Color lightBackground = Color(0xFFEFF6FF);
  static const Color lightCard = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
}

class AppTheme {
  // ---------- Colors ----------
  static const Color primary = Color(0xFF2563EB);          // Bright Blue
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);

  static const Color accent = Color(0xFF3B82F6);            // Blue
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);          // Keep green for success
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);

  // Backward compatibility for old code
  static const Color backgroundColor = Color(0xFFEFF6FF);
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color textColor = Color(0xFF1A1A1A);
  static const Color surfaceColor = Colors.white;
  static const Color gain = Color(0xFF10B981);              // Keep green for gains
  static const Color loss = Color(0xFFEF4444);
  static const Color background = Color(0xFFEFF6FF);
  static const Color successColor = Color(0xFF10B981);     // Keep green for success
  static const Color dangerColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);
  static const Color textColorDark = Color(0xFF1A1A1A);
  static const Color accentColor = Color(0xFF3B82F6);

  // ---------- Light theme ----------
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: const Color(0xFFEFF6FF),
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFF1A1A1A)),
      titleMedium: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
    ),
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: Colors.white,
      background: const Color(0xFFEFF6FF),
      error: error,
    ),
  );

  // ---------- Dark theme ----------
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: backgroundDark,
    canvasColor: backgroundDark,
    cardColor: surfaceDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: textPrimary),
      titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      bodySmall: TextStyle(color: textSecondary),
    ),
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: accent,
      error: error,
      background: backgroundDark,
      surface: surfaceDark,
      onSurface: textPrimary,
      onBackground: textPrimary,
    ),
    iconTheme: const IconThemeData(color: textPrimary),
    dividerColor: Colors.white24,
  );
}
