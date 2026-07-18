import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// The Vakil AI mark: a double-chevron "V" (echoing a checkmark — trust,
/// verified, vakil) rendered with the brand's gold-to-emerald gradient.
class GradientLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final Color wordmarkColor;
  final List<Color> gradientColors;

  const GradientLogo({
    super.key,
    this.size = 64,
    this.showWordmark = true,
    this.wordmarkColor = AppColors.onNavyPrimary,
    this.gradientColors = const [AppColors.gold, AppColors.emerald],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _VMarkPainter(colors: gradientColors),
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(height: 12),
          Text('Vakil AI', style: AppTextStyles.heading(wordmarkColor, size: 24)),
        ],
      ],
    );
  }
}

class _VMarkPainter extends CustomPainter {
  final List<Color> colors;
  _VMarkPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    ).createShader(Offset.zero & size);

    final strokeW = w * 0.16;

    Paint paint(double opacity) => Paint()
      ..shader = shader
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Back chevron (slightly offset, lower opacity) for a layered "wing" feel.
    final back = Path()
      ..moveTo(w * 0.10, h * 0.12)
      ..lineTo(w * 0.5, h * 0.68)
      ..lineTo(w * 0.90, h * 0.12);
    canvas.drawPath(back, paint(0.45));

    // Front chevron — the primary V stroke.
    final front = Path()
      ..moveTo(w * 0.06, h * 0.34)
      ..lineTo(w * 0.5, h * 0.92)
      ..lineTo(w * 0.94, h * 0.34);
    canvas.drawPath(front, paint(1));
  }

  @override
  bool shouldRepaint(covariant _VMarkPainter oldDelegate) => false;
}
