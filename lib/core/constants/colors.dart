import 'package:flutter/material.dart';

class AppColors {
  // === REDESIGN TOKENS (Figma "FindIT Mobile — Redesign", halaman Foundations) ===
  // Tema terang minimalis. Aksen amber #F9A61A dipertahankan dari brand lama.

  // Background & border
  static const Color bgBase = Color(0xFFFFFFFF);
  static const Color bgSubtle = Color(0xFFF7F8FA);
  static const Color bgMuted = Color(0xFFEEF0F4);
  static const Color borderDefault = Color(0xFFE8EAEE);

  // Teks
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  // text/tertiary #8A94A8 hanya 3.05:1 di putih: pakai untuk ikon, garis,
  // dan teks besar (>= 18px). Teks kecil memakai [textTertiaryAA].
  static const Color textTertiary = Color(0xFF8A94A8);
  static const Color textTertiaryAA = Color(0xFF64708A); // 4.68:1 di bg/subtle

  // Brand
  static const Color brandPrimary = Color(0xFFF9A61A);
  static const Color brandOnPrimary = Color(0xFF1A1A2E); // 8.53:1 di amber
  static const Color brandSoft = Color(0xFFFEF3DC);

  // Status (fg di atas bg pasangannya)
  // status/lost-fg #B7791F hanya 3.31:1 di lost-bg: dipakai untuk ikon/titik,
  // teks badge memakai [statusLostText].
  static const Color statusLostFg = Color(0xFFB7791F);
  static const Color statusLostText = Color(0xFF8D5B0F); // 5.24:1
  static const Color statusLostBgLight = Color(0xFFFEF3DC);
  static const Color statusFoundFg = Color(0xFF2563EB); // 4.56:1
  static const Color statusFoundBgLight = Color(0xFFEAF1FF);
  static const Color statusReturnedFg = Color(0xFF15803D); // 4.53:1
  static const Color statusReturnedBgLight = Color(0xFFE8F7EE);
  // feedback/danger #DC2626 hanya 4.23:1 di danger-bg: teks memakai [dangerText].
  static const Color feedbackDanger = Color(0xFFDC2626);
  static const Color dangerTextLight = Color(0xFFB91C1C); // 5.66:1
  static const Color feedbackDangerBg = Color(0xFFFDECEC);

  // Spacing: 4 · 8 · 12 · 16 · 20 · 24 · 32
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  // Radius: 8 · 12 · 16 · 24 · full
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  // === TOKEN MODE GELAP (skema web lama, tetap dipakai saat toggle gelap) ===

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

  // Light mode = redesign Figma
  static const Color lightBg = bgBase;
  static const Color lightSurface = bgBase;
  static const Color lightCardBg = bgBase;
  static const Color lightBorder = borderDefault;
  static const Color lightBorderSubtle = borderDefault;
  static const Color lightChipBg = bgMuted;
  static const Color lightTextPrimary = textPrimaryLight;
  static const Color lightTextSecondary = textSecondaryLight;
  static const Color lightTextMuted = textTertiaryAA;
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
  Color get amberText => isDark ? AppColors.statusLost : AppColors.statusLostText;
  Color get amberBg => isDark ? AppColors.statusLostBg : AppColors.statusLostBgLight;

  // --status-found: Temuan (#4F8BF0, badge bg rgba(79,139,240,0.15))
  Color get tealText => isDark ? AppColors.statusFound : AppColors.statusFoundFg;
  Color get tealBg => isDark ? AppColors.statusFoundBg : AppColors.statusFoundBgLight;

  // --status-found / blue alias
  Color get blueText => isDark ? AppColors.statusFound : AppColors.statusFoundFg;
  Color get blueBg => isDark ? AppColors.statusFoundBg : AppColors.statusFoundBgLight;

  // --status-returned: Kembali / Berhasil (#34C58A, badge bg rgba(52,197,138,0.15))
  Color get successText => isDark ? AppColors.statusReturned : AppColors.statusReturnedFg;
  Color get successBg => isDark ? AppColors.statusReturnedBg : AppColors.statusReturnedBgLight;

  // Avatar / chip mint: #86E3C8 dengan teks gelap #1A1A2E
  Color get mintBg => AppColors.mint;
  Color get mintText => AppColors.onPrimary;

  Color get dangerText => isDark ? AppColors.dangerLight : AppColors.dangerTextLight;
  Color get dangerBg => isDark
      ? AppColors.dangerLight.withValues(alpha: 0.15)
      : AppColors.feedbackDangerBg;

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
  Color get inputFill => isDark ? AppColors.inputBg : AppColors.bgSubtle;
  Color get inputBorder => isDark ? AppColors.inputBorder : AppColors.lightBorder;
  Color get inputHint => isDark ? AppColors.placeholder : AppColors.lightTextMuted;
  Color get inputText => isDark ? AppColors.text1 : AppColors.lightTextPrimary;

  // Chip kategori non-aktif: bg #1E2638, border #3A4358, teks #D1D5E0
  Color get chipBg => isDark ? AppColors.surface : AppColors.lightCardBg;
  Color get chipBorder => isDark ? AppColors.surface2Border : AppColors.lightBorder;

  // Kartu statistik non-aktif: border rgba(255,255,255,0.10)
  Color get statCardInactiveBorder => isDark ? AppColors.inputBorder : AppColors.lightBorder;

  // Permukaan redesign: bg/muted untuk chip & field sekunder, brand/soft untuk sorotan
  Color get mutedBg => isDark ? AppColors.surface2 : AppColors.bgMuted;
  Color get brandSoftBg => isDark ? AppColors.statusLostBg : AppColors.brandSoft;
  Color get iconMuted => isDark ? AppColors.text3 : AppColors.textTertiary;

  Color get sheetBg => isDark ? AppColors.surface : AppColors.lightCardBg;
  Color get divider => isDark ? AppColors.surfaceBorder : AppColors.lightBorder;

  Color get snackbarBg => isDark ? AppColors.surface2 : AppColors.textPrimaryLight;

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
