import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class RiskBadge extends StatelessWidget {
  final RiskLevel level;
  final String label;
  final bool solid;

  const RiskBadge({
    super.key,
    required this.level,
    required this.label,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.riskColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: solid ? color : AppColors.riskSoftColor(level),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.label(solid ? Colors.white : color, size: 12),
      ),
    );
  }
}
