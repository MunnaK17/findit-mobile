import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.statusFound,
        surface: AppColors.surface,
        error: AppColors.dangerLight,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgHeader,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.text1),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.text1,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return AppColors.primaryHover;
            }
            return AppColors.primary;
          }),
          foregroundColor: const WidgetStatePropertyAll(AppColors.onPrimary),
          elevation: const WidgetStatePropertyAll(0),
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        hintStyle: const TextStyle(color: AppColors.placeholder, fontSize: 13),
        labelStyle: const TextStyle(color: AppColors.text2, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dangerLight, width: 1.5),
        ),
      ),
    );
  }

  /// Tema terang minimalis dari redesign Figma (halaman Foundations).
  static ThemeData get lightTheme {
    const radiusMd = BorderRadius.all(Radius.circular(AppColors.radiusMd));
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgBase,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brandPrimary,
        onPrimary: AppColors.brandOnPrimary,
        secondary: AppColors.actionBlue,
        onSecondary: Colors.white,
        surface: AppColors.bgBase,
        onSurface: AppColors.textPrimaryLight,
        onSurfaceVariant: AppColors.textSecondaryLight,
        surfaceContainerHighest: AppColors.bgMuted,
        outline: AppColors.borderDefault,
        outlineVariant: AppColors.borderDefault,
        error: AppColors.dangerTextLight,
      ),
      textTheme: AppTypography.textTheme(
        AppColors.textPrimaryLight,
        AppColors.textSecondaryLight,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDefault,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgBase,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
        titleTextStyle: AppTypography.titleMedium(AppColors.textPrimaryLight),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.bgBase,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppColors.radiusLg)),
          side: BorderSide(color: AppColors.borderDefault),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppColors.bgMuted;
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return AppColors.primaryHover;
            }
            return AppColors.brandPrimary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textTertiaryAA;
            }
            return AppColors.brandOnPrimary;
          }),
          elevation: const WidgetStatePropertyAll(0),
          minimumSize: const WidgetStatePropertyAll(Size(48, 52)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppColors.space5, vertical: 14),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: radiusMd),
          ),
          textStyle: WidgetStatePropertyAll(
            AppTypography.label(AppColors.brandOnPrimary).copyWith(fontSize: 15),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryLight,
          minimumSize: const Size(48, 52),
          side: const BorderSide(color: AppColors.borderDefault),
          shape: const RoundedRectangleBorder(borderRadius: radiusMd),
          textStyle: AppTypography.label(AppColors.textPrimaryLight)
              .copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.actionBlue,
          minimumSize: const Size(44, 44),
          textStyle: AppTypography.label(AppColors.actionBlue),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgBase,
        selectedColor: AppColors.textPrimaryLight,
        side: const BorderSide(color: AppColors.borderDefault),
        shape: const StadiumBorder(),
        labelStyle: AppTypography.label(AppColors.textSecondaryLight),
        secondaryLabelStyle: AppTypography.label(Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: AppColors.space3),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgBase,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppColors.radiusXl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimaryLight,
        contentTextStyle: AppTypography.bodyMedium(Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: radiusMd),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSubtle,
        hintStyle: AppTypography.body(AppColors.textTertiaryAA),
        labelStyle: AppTypography.label(AppColors.textSecondaryLight),
        floatingLabelStyle: AppTypography.label(AppColors.textPrimaryLight),
        prefixIconColor: AppColors.textTertiary,
        suffixIconColor: AppColors.textTertiary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppColors.space4,
          vertical: 14,
        ),
        border: const OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: AppColors.borderDefault),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: AppColors.borderDefault),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: AppColors.brandPrimary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: AppColors.feedbackDanger, width: 1.5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: AppColors.feedbackDanger, width: 2),
        ),
        errorStyle: AppTypography.caption(AppColors.dangerTextLight),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bgBase,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.brandSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.caption(
            selected ? AppColors.textPrimaryLight : AppColors.textTertiaryAA,
          ).copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w500);
        }),
      ),
    );
  }
}

/// Skala tipografi redesign, semuanya Plus Jakarta Sans.
/// Ukuran diturunkan dari tinggi baris di frame Typography Figma.
class AppTypography {
  AppTypography._();

  static TextStyle _s(double size, double lineHeight, FontWeight weight,
          Color color, {double spacing = 0}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        height: lineHeight / size,
        fontWeight: weight,
        color: color,
        letterSpacing: spacing,
      );

  /// Title/Large 26/34: judul layar ("Masuk ke Akun").
  static TextStyle titleLarge(Color c) =>
      _s(26, 34, FontWeight.w800, c, spacing: -0.4);

  /// Title/Medium 20/26: judul section ("Laporan Terbaru").
  static TextStyle titleMedium(Color c) =>
      _s(20, 26, FontWeight.w700, c, spacing: -0.2);

  /// Title/Small 16/22: judul kartu ("Kunci Motor Honda").
  static TextStyle titleSmall(Color c) => _s(16, 22, FontWeight.w700, c);

  /// Body/Regular 14/21.
  static TextStyle body(Color c) => _s(14, 21, FontWeight.w400, c);

  /// Body/Medium 14/21.
  static TextStyle bodyMedium(Color c) => _s(14, 21, FontWeight.w500, c);

  /// Label 13/18: chip, tombol kecil ("Semua Cabang").
  static TextStyle label(Color c) => _s(13, 18, FontWeight.w600, c);

  /// Caption 12/16: waktu, metadata ("5 jam lalu").
  static TextStyle caption(Color c) => _s(12, 16, FontWeight.w500, c);

  /// Overline 11/14: label section huruf kapital ("LAPORAN TERBARU").
  static TextStyle overline(Color c) =>
      _s(11, 14, FontWeight.w700, c, spacing: 0.8);

  static TextTheme textTheme(Color primary, Color secondary) => TextTheme(
        headlineSmall: titleLarge(primary),
        titleLarge: titleMedium(primary),
        titleMedium: titleSmall(primary),
        titleSmall: label(primary),
        bodyLarge: bodyMedium(primary),
        bodyMedium: body(primary),
        bodySmall: caption(secondary),
        labelLarge: label(primary),
        labelMedium: caption(primary),
        labelSmall: overline(secondary),
      );
}
