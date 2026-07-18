import 'package:flutter/material.dart';

/// Central color palette for Vakil AI, matched to the approved Figma mockups:
/// deep navy surfaces, an emerald action color, and a gold accent reserved
/// for premium/brand moments (the logo mark, the onboarding CTA glow).
class AppColors {
  AppColors._();

  // Navy — primary brand surface
  static const Color navyDarkest = Color(0xFF0A1730);
  static const Color navyDark = Color(0xFF0F1F3D);
  static const Color navy = Color(0xFF16274A);
  static const Color navyLight = Color(0xFF1E3157);
  static const Color navyCard = Color(0xFF1B2C52);

  // Emerald — primary action color
  static const Color emerald = Color(0xFF22C58B);
  static const Color emeraldDark = Color(0xFF1AA476);
  static const Color emeraldSoft = Color(0xFFDFF6EC);

  // Gold — premium accent, used sparingly
  static const Color gold = Color(0xFFCBA35C);
  static const Color goldLight = Color(0xFFE4C98A);

  // Risk semantics
  static const Color riskHigh = Color(0xFFE15554);
  static const Color riskHighSoft = Color(0xFFFBE4E3);
  static const Color riskMedium = Color(0xFFF2A93B);
  static const Color riskMediumSoft = Color(0xFFFCEFD9);
  static const Color riskLow = Color(0xFF2ECC8F);
  static const Color riskLowSoft = Color(0xFFDFF6EC);

  // Neutrals
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF14213D);
  static const Color inkMuted = Color(0xFF5B6A8A);
  static const Color border = Color(0xFFE3E8F0);
  static const Color onNavyPrimary = Color(0xFFFFFFFF);
  static const Color onNavyMuted = Color(0xFFAEB9D6);

  static Color riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return riskHigh;
      case RiskLevel.medium:
        return riskMedium;
      case RiskLevel.low:
        return riskLow;
    }
  }

  static Color riskSoftColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return riskHighSoft;
      case RiskLevel.medium:
        return riskMediumSoft;
      case RiskLevel.low:
        return riskLowSoft;
    }
  }

  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [navyDarkest, navy],
  );

  static const LinearGradient goldEmeraldGlow = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [gold, emerald],
  );
}

enum RiskLevel { high, medium, low }

extension RiskLevelLabel on RiskLevel {
  String label(String Function(String key) t) {
    switch (this) {
      case RiskLevel.high:
        return t('risk_high');
      case RiskLevel.medium:
        return t('risk_medium');
      case RiskLevel.low:
        return t('risk_low');
    }
  }
}
