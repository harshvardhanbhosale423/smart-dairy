import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isOutlined;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isOutlined = false,
    this.width,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = backgroundColor ?? AppColors.darkGreen;
    final effectiveTextColor = textColor ?? (isOutlined ? effectiveBgColor : AppColors.pureWhite);

    Widget childContent;
    if (isLoading) {
      childContent = SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
        ),
      );
    } else if (icon != null) {
      childContent = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: effectiveTextColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: effectiveTextColor,
            ),
          ),
        ],
      );
    } else {
      childContent = Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: effectiveTextColor,
        ),
      );
    }

    if (isOutlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: effectiveBgColor, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: childContent,
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBgColor,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: childContent,
      ),
    );
  }
}

