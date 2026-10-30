import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    color: AppColors.textDark,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.3,
    color: AppColors.textDark,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textDark,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textDark,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textMuted,
  );

  static const TextStyle currencyBig = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.darkGreen,
  );

  static const TextStyle badgeText = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
}

