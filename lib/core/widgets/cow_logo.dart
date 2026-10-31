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
        color: AppColors.darkGreen,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryGreen, width: size * 0.04),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.72, size * 0.72),
          painter: _CowPainter(),
        ),
      ),
    );
  }
}

class _CowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100.0;
    canvas.scale(scale, scale);

    // Horns (Golden Yellow)
    final hornPaint = Paint()..color = const Color(0xFFFDD835);
    final leftHorn = Path()
      ..moveTo(38, 38)
      ..cubicTo(36, 32, 32, 24, 27, 23)
      ..cubicTo(25, 23, 26, 26, 29, 30)
      ..cubicTo(32, 34, 34, 38, 35, 41)
      ..close();
    final rightHorn = Path()
      ..moveTo(62, 38)
      ..cubicTo(64, 32, 68, 24, 73, 23)
      ..cubicTo(75, 23, 74, 26, 71, 30)
      ..cubicTo(68, 34, 66, 38, 65, 41)
      ..close();
    canvas.drawPath(leftHorn, hornPaint);
    canvas.drawPath(rightHorn, hornPaint);

    // Ears (White outer, Pink inner)
    final whitePaint = Paint()..color = Colors.white;
    final pinkPaint = Paint()..color = const Color(0xFFFFCDD2);

    final leftEar = Path()
      ..moveTo(36, 42)
      ..cubicTo(28, 40, 16, 44, 18, 52)
      ..cubicTo(20, 56, 30, 53, 37, 48)
      ..close();
    canvas.drawPath(leftEar, whitePaint);

    final leftEarInner = Path()
      ..moveTo(34, 43)
      ..cubicTo(29, 42, 20, 45, 21, 50)
      ..cubicTo(23, 53, 30, 51, 35, 47)
      ..close();
    canvas.drawPath(leftEarInner, pinkPaint);

    final rightEar = Path()
      ..moveTo(64, 42)
      ..cubicTo(72, 40, 84, 44, 82, 52)
      ..cubicTo(80, 56, 70, 53, 63, 48)
      ..close();
    canvas.drawPath(rightEar, whitePaint);

    final rightEarInner = Path()
      ..moveTo(66, 43)
      ..cubicTo(71, 42, 80, 45, 79, 50)
      ..cubicTo(77, 53, 70, 51, 65, 47)
      ..close();
    canvas.drawPath(rightEarInner, pinkPaint);

    // Cow Head / Face (Crisp White)
    final face = Path()
      ..moveTo(35, 37)
      ..cubicTo(40, 36, 60, 36, 65, 37)
      ..cubicTo(68, 41, 69, 48, 68, 57)
      ..cubicTo(67, 63, 66, 69, 65, 73)
      ..cubicTo(60, 77, 40, 77, 35, 73)
      ..cubicTo(34, 69, 33, 63, 32, 57)
      ..cubicTo(31, 48, 32, 41, 35, 37)
      ..close();
    canvas.drawPath(face, whitePaint);

    // Green Spot on Cow's forehead
    final spotPaint = Paint()..color = const Color(0xFF1B5E20);
    final spot = Path()
      ..moveTo(60, 38)
      ..cubicTo(63, 40, 66, 45, 65, 50)
      ..cubicTo(63, 54, 59, 52, 58, 47)
      ..cubicTo(57, 43, 58, 39, 60, 38)
      ..close();
    canvas.drawPath(spot, spotPaint);

    // Eyes
    final blackPaint = Paint()..color = const Color(0xFF212121);
    canvas.drawCircle(const Offset(42, 49), 3, blackPaint);
    canvas.drawCircle(const Offset(58, 49), 3, blackPaint);
    canvas.drawCircle(const Offset(43, 48), 1, whitePaint);
    canvas.drawCircle(const Offset(59, 48), 1, whitePaint);

    // Muzzle / Snout (Peach Cream)
    final muzzlePaint = Paint()..color = const Color(0xFFFFE0B2);
    final muzzle = Path()
      ..moveTo(31, 63)
      ..cubicTo(31, 58, 69, 58, 69, 63)
      ..cubicTo(70, 70, 69, 78, 64, 81)
      ..cubicTo(57, 83, 43, 83, 36, 81)
      ..cubicTo(31, 78, 30, 70, 31, 63)
      ..close();
    canvas.drawPath(muzzle, muzzlePaint);

    // Nostrils
    final nostrilPaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawCircle(const Offset(43, 69), 2.2, nostrilPaint);
    canvas.drawCircle(const Offset(57, 69), 2.2, nostrilPaint);

    // Smile
    final smilePaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final smile = Path()
      ..moveTo(46, 75)
      ..cubicTo(48, 77, 52, 77, 54, 75);
    canvas.drawPath(smile, smilePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
