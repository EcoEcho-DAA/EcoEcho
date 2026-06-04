import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF2E7D32); 
  static const Color secondaryGreen = Color(0xFF66BB6A); 
  static const Color earthBrown = Color(0xFF5D4037); 
  static const Color backgroundOffWhite = Color(0xFFF8F9FA); 
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: backgroundOffWhite,
    
    colorScheme: const ColorScheme.light(
      primary: primaryGreen,
      secondary: secondaryGreen,
      surface: backgroundOffWhite,
      error: Color(0xFFD32F2F),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32.0, 
        fontWeight: FontWeight.bold, 
        color: primaryGreen,
      ),
      displayMedium: TextStyle(
        fontSize: 24.0, 
        fontWeight: FontWeight.bold, 
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16.0, 
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.0, 
        color: textSecondary,
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20.0, 
        fontWeight: FontWeight.w600, 
        color: Colors.white,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
        textStyle: const TextStyle(
          fontSize: 16.0, 
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: secondaryGreen),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: secondaryGreen),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: primaryGreen, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFFD32F2F)),
      ),
    ),
  );
}