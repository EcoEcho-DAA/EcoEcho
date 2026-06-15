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
    cardColor: Colors.white,
    
    colorScheme: const ColorScheme.light(
      primary: primaryGreen,
      secondary: secondaryGreen,
      surface: Colors.white,
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
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF154212),
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFF154212)),
      actionsIconTheme: IconThemeData(color: Color(0xFF154212)),
      titleTextStyle: TextStyle(
        fontSize: 20.0, 
        fontWeight: FontWeight.bold, 
        color: Color(0xFF154212),
        fontFamily: 'Be Vietnam Pro',
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF154212),
      unselectedItemColor: Color(0xFF72796E),
      elevation: 8,
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

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    iconTheme: const IconThemeData(color: Color(0xFFF5F5F5)),
    primaryIconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
    
    colorScheme: const ColorScheme.dark(
      primary: primaryGreen,
      secondary: secondaryGreen,
      surface: Color(0xFF1E1E1E),
      error: Color(0xFFBA1A1A),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32.0, 
        fontWeight: FontWeight.bold, 
        color: Color(0xFFFFFFFF),
      ),
      displayMedium: TextStyle(
        fontSize: 24.0, 
        fontWeight: FontWeight.bold, 
        color: Color(0xFFFFFFFF),
      ),
      bodyLarge: TextStyle(
        fontSize: 16.0, 
        color: Color(0xFFFFFFFF),
      ),
      bodyMedium: TextStyle(
        fontSize: 14.0, 
        color: Color(0xFFF5F5F5),
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        fontSize: 20.0, 
        fontWeight: FontWeight.bold, 
        color: Colors.white,
        fontFamily: 'Be Vietnam Pro',
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.white70,
      elevation: 8,
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
      fillColor: const Color(0xFF1B1F1A),
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
        borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
      ),
    ),
  );
}