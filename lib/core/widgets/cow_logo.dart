import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CowLogoWidget extends StatelessWidget {
  final double size;
  final bool showBadge;

  const CowLogoWidget({
    super.key,
    this.size = 80,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.softLightGreen,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryGreen, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.agriculture_rounded,
          size: size * 0.55,
          color: AppColors.darkGreen,
        ),
      ),
    );
  }
}

