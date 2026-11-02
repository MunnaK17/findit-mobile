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

  // Light Mode Palette
  static const Color lightBg = Color(0xFFF8FAFC); // Clean crisp off-white (Slate 50)
  static const Color lightSurface = Colors.white;
  static const Color lightCardBg = Colors.white;
  static const Color lightBorder = Color(0xFFE2E8F0); // Slate 200
  static const Color lightBorderSubtle = Color(0xFFF1F5F9); // Slate 100
  static const Color lightChipBg = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A); // Dark Slate 900
  static const Color lightTextSecondary = Color(0xFF475569); // Slate 600
  static const Color lightTextMuted = Color(0xFF64748B); // Slate 500
}

/// Theme-aware color helper. Use `FinditColors.of(context)` to get the right
/// colors based on the current brightness (dark / light).
class FinditColors {
  final bool isDark;

  const FinditColors._({required this.isDark});

  factory FinditColors.of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return FinditColors._(isDark: brightness == Brightness.dark);
  }

  // Backgrounds — uniform across sections to prevent "belang warna"
  Color get scaffoldBg => isDark ? AppColors.appDark : AppColors.lightBg;
  Color get surface => isDark ? AppColors.surface : Colors.white;

  // Cards
  Color get cardBg => isDark ? AppColors.cardBg : Colors.white;
  Color get cardBgLight => isDark ? AppColors.cardBgLight : const Color(0xFFF1F5F9);
  Color get cardBgNavy => isDark ? AppColors.cardBgNavy : Colors.white;
  Color get cardBorder => isDark ? AppColors.cardBorder : AppColors.lightBorder;
  Color get cardBorderLight => isDark ? AppColors.cardBorderLight : const Color(0xFFE2E8F0);

  // Text
  Color get textPrimary => isDark ? Colors.white : AppColors.lightTextPrimary;
  Color get textSecondary => isDark ? AppColors.slate400 : AppColors.lightTextSecondary;
  Color get textMuted => isDark ? AppColors.textMuted : AppColors.lightTextMuted;
  Color get slate300Adaptive => isDark ? AppColors.slate300 : AppColors.lightTextSecondary;

  // Nav bar
  Color get navBarBg => isDark ? const Color(0xFF142036) : Colors.white;
  Color get navBarBorder => isDark ? const Color(0xFF263753) : AppColors.lightBorder;
  Color get navBarFabBorder => isDark ? AppColors.appDark : Colors.white;

  // Unified section backgrounds for home (no mismatched stripes / belang)
  Color get heroSectionBg => scaffoldBg;
  Color get feedSectionBg => scaffoldBg;
  Color get communitySectionBg => scaffoldBg;
  Color get guideSectionBg => scaffoldBg;

  // Input fields
  Color get inputFill => isDark ? AppColors.cardBgLight : Colors.white;
  Color get inputBorder => isDark ? AppColors.cardBorder : AppColors.lightBorder;
  Color get inputHint => isDark ? AppColors.slate400 : AppColors.lightTextMuted;
  Color get inputText => isDark ? Colors.white : AppColors.lightTextPrimary;

  // Chip / Filter
  Color get chipBg => isDark ? AppColors.cardBgLight : Colors.white;
  Color get chipBorder => isDark ? AppColors.cardBorder : AppColors.lightBorder;

  // Dialog / Bottom Sheet
  Color get sheetBg => isDark ? AppColors.cardBg : Colors.white;
  Color get divider => isDark ? AppColors.cardBorder : AppColors.lightBorder;

  // Snackbar
  Color get snackbarBg => isDark ? AppColors.cardBgLight : AppColors.appDark;

  // Step / guide cards
  Color get stepCardBg => isDark ? AppColors.cardBg : Colors.white;
  Color get stepCardBorder => isDark ? AppColors.cardBorder : AppColors.lightBorder;

  // FAQ
  Color get faqBg => isDark ? AppColors.cardBg : Colors.white;
  Color get faqBorder => isDark ? AppColors.cardBorder : AppColors.lightBorder;
}
