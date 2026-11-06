import 'package:flutter/material.dart';

class AppColors {
  // Brand Default Colors (Elyxia DNA)
  static const Color primaryDefault = Color(0xFF22577A);
  static const Color primaryDarkDefault = Color(0xFF16384F);
  static const Color primaryLightDefault = Color(0xFF38A3A5);
  static const Color accentDefault = Color(0xFF3BCC97);
  static const Color accentLightDefault = Color(0xFF57CC99);

  // Valeurs par défaut directes
  static const Color primary = primaryDefault;
  static const Color primaryDark = primaryDarkDefault;
  static const Color primaryLight = primaryLightDefault;
  static const Color accent = accentDefault;
  static const Color accentLight = accentLightDefault;

  // Backgrounds & Surface
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF1F5F9);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status & Badges
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFFDBEAFE);

  // Borders
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);

  /// Helper pour convertir une chaîne hexadécimale (ex: "#22577A") en Color
  static Color fromHex(String? hexString, {Color defaultColor = primaryDefault}) {
    if (hexString == null || hexString.isEmpty) return defaultColor;
    final clean = hexString.replaceAll('#', '').trim();
    if (clean.length == 6) {
      final val = int.tryParse('FF$clean', radix: 16);
      if (val != null) return Color(val);
    } else if (clean.length == 8) {
      final val = int.tryParse(clean, radix: 16);
      if (val != null) return Color(val);
    }
    return defaultColor;
  }
}
