import 'package:flutter/material.dart';

class AppColors {
  // Theme Backgrounds (Brightened Navy ~30% from pitch black)
  static const Color appDark = Color(0xFF10192B); // Rich Deep Navy
  static const Color appDarker = Color(0xFF0D1424);
  static const Color appFrame = Color(0xFF121B2F);
  static const Color background = Color(0xFF10192B);
  static const Color surface = Color(0xFF1B2842);
  
  // Card & Container Colors (Brightened Navy)
  static const Color cardBg = Color(0xFF18243C);
  static const Color cardBgLight = Color(0xFF1E2C48);
  static const Color cardBgNavy = Color(0xFF1A2744);
  static const Color cardBorder = Color(0xFF2A3B5C);
  static const Color cardBorderLight = Color(0x44475569);
  static const Color border = Color(0xFF2A3B5C);

  // Accents
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentAmberLight = Color(0xFFFBBF24);
  static const Color accentAmberDark = Color(0xFFD97706);
  static const Color bsiTeal = Color(0xFF009B8D);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentEmerald = Color(0xFF10B981);

  // Existing aliases mapped to new dark theme
  static const Color primary = Color(0xFFF59E0B); // Amber as primary brand
  static const Color primaryLight = Color(0xFFFBBF24);
  static const Color accent = Color(0xFF009B8D);

  // Status Colors
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusApproved = Color(0xFF10B981);
  static const Color statusRejected = Color(0xFFEF4444);
  static const Color statusCompleted = Color(0xFF3B82F6);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Badges
  static const Color badgeHilang = Color(0xFFF59E0B); // Amber for hilang
  static const Color badgeTemuan = Color(0xFF3B82F6); // Blue for temuan
  static const Color hilangColor = Color(0xFFF59E0B);
  static const Color temuanColor = Color(0xFF3B82F6);

  // Priority
  static const Color priorityCritical = Color(0xFFDC2626);
  static const Color priorityHigh = Color(0xFFD97706);
  static const Color priorityNormal = Color(0xFF059669);

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);
}
