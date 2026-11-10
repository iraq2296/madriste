import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The official MADRASI logo widget.
///
/// Combines an open book (knowledge), an ascending architectural arch (future/growth),
/// and modern geometric badge styling. Renderable in any size, monochrome or full color.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 56,
    this.monochrome = false,
    this.withWordmark = false,
    this.withTagline = false,
    this.lightWordmark = false,
  });

  final double size;
  final bool monochrome;
  final bool withWordmark;
  final bool withTagline;
  final bool lightWordmark;

  @override
  Widget build(BuildContext context) {
    final emblem = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: monochrome
            ? null
            : const LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [AppColors.navy, AppColors.primary],
              ),
        color: monochrome ? Colors.white : null,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: monochrome
            ? null
            : [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.22),
                  blurRadius: size * 0.25,
                  offset: Offset(0, size * 0.1),
                ),
              ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.58, size * 0.58),
          painter: _LogoPainter(
            color: monochrome ? AppColors.navy : Colors.white,
            accentColor: monochrome ? AppColors.primary : const Color(0xFF64B5F6),
          ),
        ),
      ),
    );

    if (!withWordmark) return emblem;

    final titleColor = lightWordmark
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;
    final taglineColor = lightWordmark
        ? Colors.white70
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        emblem,
        SizedBox(width: size * 0.24),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مَدرَستي',
              style: TextStyle(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w900,
                color: titleColor,
                letterSpacing: 0.2,
                height: 1.1,
              ),
            ),
            if (withTagline) ...[
              const SizedBox(height: 2),
              Text(
                'مدرستك أقرب، ومستقبلك أكبر',
                style: TextStyle(
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.w500,
                  color: taglineColor,
                  height: 1.2,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter({required this.color, required this.accentColor});
  final Color color;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw stylized open book pages
    final bookPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Left page curve
    final leftPath = Path()
      ..moveTo(w * 0.08, h * 0.65)
      ..quadraticBezierTo(w * 0.28, h * 0.48, w * 0.5, h * 0.60)
      ..lineTo(w * 0.5, h * 0.88)
      ..quadraticBezierTo(w * 0.28, h * 0.76, w * 0.08, h * 0.90)
      ..close();

    // Right page curve
    final rightPath = Path()
      ..moveTo(w * 0.92, h * 0.65)
      ..quadraticBezierTo(w * 0.72, h * 0.48, w * 0.5, h * 0.60)
      ..lineTo(w * 0.5, h * 0.88)
      ..quadraticBezierTo(w * 0.72, h * 0.76, w * 0.92, h * 0.90)
      ..close();

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    canvas.drawPath(leftPath, fillPaint);
    canvas.drawPath(rightPath, fillPaint);
    canvas.drawPath(leftPath, bookPaint);
    canvas.drawPath(rightPath, bookPaint);

    // Rising sun / knowledge star above the book
    final starPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.5, h * 0.28), w * 0.14, starPaint);

    // Subtle graduation cap / arch facet
    final archPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;

    final archPath = Path()
      ..moveTo(w * 0.25, h * 0.32)
      ..quadraticBezierTo(w * 0.5, h * 0.08, w * 0.75, h * 0.32);

    canvas.drawPath(archPath, archPaint);
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.accentColor != accentColor;
}

