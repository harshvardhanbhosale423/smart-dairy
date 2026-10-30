import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.darkGreen,
      scaffoldBackgroundColor: AppColors.creamBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.darkGreen,
        onPrimary: AppColors.pureWhite,
        primaryContainer: AppColors.softLightGreen,
        onPrimaryContainer: AppColors.darkGreen,
        secondary: AppColors.lightGreen,
        onSecondary: AppColors.pureWhite,
        tertiary: AppColors.goldenYellow,
        background: AppColors.creamBackground,
        surface: AppColors.pureWhite,
        error: AppColors.error,
        onError: AppColors.pureWhite,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.bold),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w600),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: AppColors.textDark),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: AppColors.textDark),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: AppColors.textMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkGreen,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.pureWhite,
        ),
        iconTheme: const IconThemeData(color: AppColors.pureWhite),
      ),
      cardTheme: CardTheme(
        color: AppColors.pureWhite,
        elevation: 1.5,
        shadowColor: AppColors.darkGreen.withOpacity(0.08),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.dividerColor.withOpacity(0.5), width: 0.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkGreen,
          foregroundColor: AppColors.pureWhite,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkGreen,
          side: const BorderSide(color: AppColors.darkGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.pureWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.pureWhite,
        selectedItemColor: AppColors.darkGreen,
        unselectedItemColor: AppColors.textMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerColor,
        thickness: 0.8,
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.lightGreen,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.lightGreen,
        onPrimary: AppColors.darkBg,
        primaryContainer: AppColors.darkSurface,
        onPrimaryContainer: AppColors.lightGreen,
        secondary: AppColors.goldenYellow,
        background: AppColors.darkBg,
        surface: AppColors.darkSurface,
        error: AppColors.error,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: AppColors.pureWhite, fontWeight: FontWeight.bold),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: AppColors.pureWhite, fontWeight: FontWeight.w700),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: AppColors.pureWhite, fontWeight: FontWeight.w600),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: AppColors.pureWhite),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: AppColors.pureWhite),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: AppColors.textLight),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.pureWhite,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.darkCard,
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 0.8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGreen, width: 2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.lightGreen,
        unselectedItemColor: AppColors.textLight,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}

