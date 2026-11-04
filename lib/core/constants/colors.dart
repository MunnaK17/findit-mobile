import 'package:flutter/material.dart';

class AppColors {
  // === DESIGN TOKENS (Skema Web "Find.It") ===

  // --bg: Background utama (navy gelap) #0F172A
  static const Color bg = Color(0xFF0F172A);
  // --bg-header: Background header / navbar #14213D
  static const Color bgHeader = Color(0xFF14213D);
  // --surface: Surface kartu (glass/slate) #1E2638, border tipis rgba(255,255,255,0.08)
  static const Color surface = Color(0xFF1E2638);
  static const Color surfaceBorder = Color(0x14FFFFFF);
  // --surface-2: Surface kartu sekunder / tombol netral #232C42, border #3A4358
  static const Color surface2 = Color(0xFF232C42);
  static const Color surface2Border = Color(0xFF3A4358);
  // --input-bg: Input / search bar #1B2338, border rgba(255,255,255,0.10)
  static const Color inputBg = Color(0xFF1B2338);
  static const Color inputBorder = Color(0x1AFFFFFF);
  // Efek glow latar (opsional, sangat halus)
  static const Color glowBlue = Color(0x262563EB); // rgba(37,99,235,0.15)
  static const Color glowAmber = Color(0x33F9A61A); // rgba(249,166,26,0.20)
  // --bg-light: Background section terang / mode light #F8F9FD
  static const Color bgLight = Color(0xFFF8F9FD);

  // --primary: Aksen utama Amber #F9A61A
  static const Color primary = Color(0xFFF9A61A);
  // --on-primary: Teks di atas amber #1A1A2E (gelap)
  static const Color onPrimary = Color(0xFF1A1A2E);
  // --primary-hover: Hover / pressed amber #E0930F
  static const Color primaryHover = Color(0xFFE0930F);

  // --status-lost: Hilang #F9A61A, badge bg rgba(249,166,26,0.15)
  static const Color statusLost = Color(0xFFF9A61A);
  static const Color statusLostBg = Color(0x26F9A61A);
  // --status-found: Temuan #4F8BF0 (biru), badge bg rgba(79,139,240,0.15)
  static const Color statusFound = Color(0xFF4F8BF0);
  static const Color statusFoundBg = Color(0x264F8BF0);
  // --status-returned: Kembali / Berhasil #34C58A (hijau), badge bg rgba(52,197,138,0.15)
  static const Color statusReturned = Color(0xFF34C58A);
  static const Color statusReturnedBg = Color(0x2634C58A);
  // --mint: Avatar / chip mint #86E3C8 dengan teks gelap #1A1A2E
  static const Color mint = Color(0xFF86E3C8);

  // --text-1 / 2 / 3 & placeholder
  static const Color text1 = Color(0xFFFFFFFF);
  static const Color text2 = Color(0xFFD1D5E0);
  static const Color text3 = Color(0xFF9AA3B8);
  static const Color placeholder = Color(0xFF7C86A0);

  // Tombol "Lapor Temuan" & tombol chat/bantuan (ikon headset): biru #2563EB
  static const Color actionBlue = Color(0xFF2563EB);

  // === ALIAS KOMPATIBILITAS KOMPONEN ===
  static const Color appDark = bg;
  static const Color appDarker = bgHeader;
  static const Color appFrame = bgHeader;
  static const Color background = bg;

  static const Color cardBg = surface;
  static const Color cardBgLight = surface2;
  static const Color cardBgNavy = surface2;
  static const Color cardBorder = surfaceBorder;
  static const Color cardBorderLight = surfaceBorder;
  static const Color border = surface2Border;

  static const Color accentAmber = primary;
  static const Color accentAmberLight = primary;
  static const Color accentAmberDark = primaryHover;
  static const Color bsiTeal = actionBlue;
  static const Color bsiTealLight = statusFound;
  static const Color accentBlue = actionBlue;
  static const Color accentBlueLight = statusFound;
  static const Color accentEmerald = statusReturned;
  static const Color accentEmeraldLight = statusReturned;

  static const Color primaryLight = primary;
  static const Color accent = actionBlue;

  static const Color statusPending = statusLost;
  static const Color statusApproved = statusReturned;
  static const Color statusRejected = Color(0xFFDC2626);
  static const Color statusCompleted = statusReturned;

  static const Color success = statusReturned;
  static const Color warning = statusLost;
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFF87171);

  static const Color badgeHilang = statusLost;
  static const Color badgeTemuan = statusFound;
  static const Color hilangColor = statusLost;
  static const Color temuanColor = statusFound;

  static const Color priorityCritical = Color(0xFFDC2626);
  static const Color priorityHigh = primaryHover;
  static const Color priorityNormal = statusReturned;

  static const Color textPrimary = text1;
  static const Color textSecondary = text2;
  static const Color textMuted = text3;
  static const Color slate300 = text2;
  static const Color slate400 = text3;
  static const Color slate900 = bg;
  static const Color slate950 = onPrimary;

  // Light Mode tokens: background #F8F9FD, kartu #FFFFFF, teks utama #0F172A, aksen #F9A61A
  static const Color lightBg = bgLight;
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardBg = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFCBD5E1);
  static const Color lightBorderSubtle = Color(0xFFE2E8F0);
  static const Color lightChipBg = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF334155);
  static const Color lightTextMuted = Color(0xFF475569);
}

/// Penyedia warna adaptif tema (Dark / Light) berbasis design tokens versi web Find.It.
class FinditColors {
  final bool isDark;

  const FinditColors._({required this.isDark});

  factory FinditColors.of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return FinditColors._(isDark: brightness == Brightness.dark);
  }

  // --bg & --surface
  Color get scaffoldBg => isDark ? AppColors.bg : AppColors.lightBg;
  Color get surface => isDark ? AppColors.surface : AppColors.lightSurface;

  Color get cardBg => isDark ? AppColors.surface : AppColors.lightCardBg;
  Color get cardBgLight => isDark ? AppColors.surface2 : AppColors.lightChipBg;
  Color get cardBgNavy => isDark ? AppColors.surface2 : AppColors.lightChipBg;
  Color get cardBorder => isDark ? AppColors.surfaceBorder : AppColors.lightBorder;
  Color get cardBorderLight => isDark ? AppColors.surfaceBorder : AppColors.lightBorderSubtle;

  // --text-1, --text-2, --text-3 (WCAG AA >= 4.5:1)
  Color get textPrimary => isDark ? AppColors.text1 : AppColors.lightTextPrimary;
  Color get textSecondary => isDark ? AppColors.text2 : AppColors.lightTextSecondary;
  Color get textMuted => isDark ? AppColors.text3 : AppColors.lightTextMuted;
  Color get slate300Adaptive => isDark ? AppColors.text2 : AppColors.lightTextSecondary;

  // --status-lost: Hilang (#F9A61A, badge bg rgba(249,166,26,0.15))
  Color get amberText => isDark ? AppColors.statusLost : const Color(0xFFB45309);
  Color get amberBg => isDark ? AppColors.statusLostBg : const Color(0x26F9A61A);

  // --status-found: Temuan (#4F8BF0, badge bg rgba(79,139,240,0.15))
  Color get tealText => isDark ? AppColors.statusFound : AppColors.actionBlue;
  Color get tealBg => isDark ? AppColors.statusFoundBg : const Color(0x264F8BF0);

  // --status-found / blue alias
  Color get blueText => isDark ? AppColors.statusFound : AppColors.actionBlue;
  Color get blueBg => isDark ? AppColors.statusFoundBg : const Color(0x264F8BF0);

  // --status-returned: Kembali / Berhasil (#34C58A, badge bg rgba(52,197,138,0.15))
  Color get successText => isDark ? AppColors.statusReturned : const Color(0xFF047857);
  Color get successBg => isDark ? AppColors.statusReturnedBg : const Color(0x2634C58A);

  // Avatar / chip mint: #86E3C8 dengan teks gelap #1A1A2E
  Color get mintBg => AppColors.mint;
  Color get mintText => AppColors.onPrimary;

  Color get dangerText => isDark ? AppColors.dangerLight : const Color(0xFF991B1B);
  Color get dangerBg => isDark
      ? AppColors.dangerLight.withValues(alpha: 0.15)
      : const Color(0xFFFEE2E2);

  Color get adminText => isDark ? const Color(0xFFC084FC) : const Color(0xFF6B21A8);
  Color get adminBg => isDark
      ? const Color(0xFFC084FC).withValues(alpha: 0.15)
      : const Color(0xFFF3E8FF);

  // Bottom nav & Header: bg #14213D
  Color get navBarBg => isDark ? AppColors.bgHeader : AppColors.lightCardBg;
  Color get navBarBorder => isDark ? AppColors.surfaceBorder : AppColors.lightBorder;
  Color get navBarFabBorder => isDark ? AppColors.bg : AppColors.lightCardBg;

  Color get heroSectionBg => isDark ? AppColors.bgHeader : AppColors.lightCardBg;
  Color get feedSectionBg => scaffoldBg;
  Color get communitySectionBg => scaffoldBg;
  Color get guideSectionBg => scaffoldBg;

  // Input / search bar: #1B2338, border rgba(255,255,255,0.10), placeholder #7C86A0
  Color get inputFill => isDark ? AppColors.inputBg : AppColors.lightCardBg;
  Color get inputBorder => isDark ? AppColors.inputBorder : AppColors.lightBorder;
  Color get inputHint => isDark ? AppColors.placeholder : AppColors.lightTextMuted;
  Color get inputText => isDark ? AppColors.text1 : AppColors.lightTextPrimary;

  // Chip kategori non-aktif: bg #1E2638, border #3A4358, teks #D1D5E0
  Color get chipBg => isDark ? AppColors.surface : AppColors.lightCardBg;
  Color get chipBorder => isDark ? AppColors.surface2Border : AppColors.lightBorder;

  // Kartu statistik non-aktif: border rgba(255,255,255,0.10)
  Color get statCardInactiveBorder => isDark ? AppColors.inputBorder : AppColors.lightBorder;

  Color get sheetBg => isDark ? AppColors.surface : AppColors.lightCardBg;
  Color get divider => isDark ? AppColors.surfaceBorder : AppColors.lightBorder;

  Color get snackbarBg => isDark ? AppColors.surface2 : AppColors.bg;

  Color get stepCardBg => isDark ? AppColors.surface : AppColors.lightCardBg;
  Color get stepCardBorder => isDark ? AppColors.surfaceBorder : AppColors.lightBorder;

  Color get faqBg => isDark ? AppColors.surface : AppColors.lightCardBg;
  Color get faqBorder => isDark ? AppColors.surfaceBorder : AppColors.lightBorder;

  Color statusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return blueText;
      case 'completed':
        return successText;
      case 'rejected':
        return dangerText;
      default:
        return amberText;
    }
  }

  Color statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return blueBg;
      case 'completed':
        return successBg;
      case 'rejected':
        return dangerBg;
      default:
        return amberBg;
    }
  }

  static String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Terverifikasi';
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu Verifikasi';
    }
  }
}
