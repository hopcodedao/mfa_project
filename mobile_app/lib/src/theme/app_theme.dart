import 'package:flutter/material.dart';  
  
class AppTheme {  
  // CTUT Brand Colors  
  static const Color primaryBlue = Color(0xFF1976D2);  
  static const Color secondaryBlue = Color(0xFF42A5F5);  
  static const Color accentOrange = Color(0xFFFF9800);  
  static const Color successGreen = Color(0xFF4CAF50);  
  static const Color warningAmber = Color(0xFFFFC107);  
  static const Color errorRed = Color(0xFFF44336);  
    
  // Neutral Colors  
  static const Color backgroundGrey = Color(0xFFF5F7FA);  
  static const Color surfaceWhite = Color(0xFFFFFFFF);  
  static const Color textPrimary = Color(0xFF212121);  
  static const Color textSecondary = Color(0xFF757575);  
  static const Color dividerGrey = Color(0xFFE0E0E0);  
  
  static ThemeData get lightTheme {  
    return ThemeData(  
      useMaterial3: true,  
      colorScheme: ColorScheme.fromSeed(  
        seedColor: primaryBlue,  
        brightness: Brightness.light,  
        primary: primaryBlue,  
        secondary: secondaryBlue,  
        tertiary: accentOrange,  
        surface: surfaceWhite,  
        background: backgroundGrey,  
        error: errorRed,  
      ),  
        
      // AppBar Theme  
      appBarTheme: const AppBarTheme(  
        backgroundColor: primaryBlue,  
        foregroundColor: Colors.white,  
        elevation: 0,  
        centerTitle: true,  
        titleTextStyle: TextStyle(  
          fontSize: 20,  
          fontWeight: FontWeight.w600,  
          color: Colors.white,  
        ),  
        iconTheme: IconThemeData(color: Colors.white),  
      ),  
        
      // Card Theme  
      cardTheme: CardThemeData(  
        elevation: 2,  
        shape: RoundedRectangleBorder(  
          borderRadius: BorderRadius.circular(12),  
        ),  
        color: surfaceWhite,  
        shadowColor: Colors.black.withOpacity(0.1),  
      ),  
        
      // Elevated Button Theme  
      elevatedButtonTheme: ElevatedButtonThemeData(  
        style: ElevatedButton.styleFrom(  
          backgroundColor: primaryBlue,  
          foregroundColor: Colors.white,  
          elevation: 2,  
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),  
          shape: RoundedRectangleBorder(  
            borderRadius: BorderRadius.circular(8),  
          ),  
          textStyle: const TextStyle(  
            fontSize: 16,  
            fontWeight: FontWeight.w600,  
          ),  
        ),  
      ),  
        
      // Input Decoration Theme  
      inputDecorationTheme: InputDecorationTheme(  
        filled: true,  
        fillColor: surfaceWhite,  
        border: OutlineInputBorder(  
          borderRadius: BorderRadius.circular(8),  
          borderSide: const BorderSide(color: dividerGrey),  
        ),  
        enabledBorder: OutlineInputBorder(  
          borderRadius: BorderRadius.circular(8),  
          borderSide: const BorderSide(color: dividerGrey),  
        ),  
        focusedBorder: OutlineInputBorder(  
          borderRadius: BorderRadius.circular(8),  
          borderSide: const BorderSide(color: primaryBlue, width: 2),  
        ),  
        errorBorder: OutlineInputBorder(  
          borderRadius: BorderRadius.circular(8),  
          borderSide: const BorderSide(color: errorRed),  
        ),  
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),  
      ),  
        
      // Text Theme  
      textTheme: const TextTheme(  
        headlineLarge: TextStyle(  
          fontSize: 32,  
          fontWeight: FontWeight.bold,  
          color: textPrimary,  
        ),  
        headlineMedium: TextStyle(  
          fontSize: 28,  
          fontWeight: FontWeight.w600,  
          color: textPrimary,  
        ),  
        headlineSmall: TextStyle(  
          fontSize: 24,  
          fontWeight: FontWeight.w600,  
          color: textPrimary,  
        ),  
        titleLarge: TextStyle(  
          fontSize: 20,  
          fontWeight: FontWeight.w600,  
          color: textPrimary,  
        ),  
        titleMedium: TextStyle(  
          fontSize: 16,  
          fontWeight: FontWeight.w500,  
          color: textPrimary,  
        ),  
        bodyLarge: TextStyle(  
          fontSize: 16,  
          fontWeight: FontWeight.normal,  
          color: textPrimary,  
        ),  
        bodyMedium: TextStyle(  
          fontSize: 14,  
          fontWeight: FontWeight.normal,  
          color: textSecondary,  
        ),  
        labelLarge: TextStyle(  
          fontSize: 14,  
          fontWeight: FontWeight.w500,  
          color: textPrimary,  
        ),  
      ),  
        
      // Bottom Navigation Bar Theme  
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(  
        backgroundColor: surfaceWhite,  
        selectedItemColor: primaryBlue,  
        unselectedItemColor: textSecondary,  
        type: BottomNavigationBarType.fixed,  
        elevation: 8,  
      ),  
    );  
  }  
}