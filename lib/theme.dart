import 'package:flutter/material.dart';

/// Palet dari DESIGN.md: hijau tua berwibawa + aksen emas, latar kertas hangat.
abstract class AppColors {
  static const primary = Color(0xFF0F4C3A);
  static const primaryDark = Color(0xFF0A382B);
  static const secondary = Color(0xFF1E7A5A);
  static const gold = Color(0xFFC6A15B);
  static const goldInk = Color(0xFF8A6A2F);
  static const surface = Color(0xFFFAF7F0);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF222B26);
  static const muted = Color(0xFF5C6A62);
  static const outline = Color(0xFFE6E2D6);
  static const outlineStrong = Color(0xFFC7CFCA);

  // Warna status operasional (tabel di DESIGN.md).
  static const hadirBg = Color(0xFFE8F5EF);
  static const hadirLine = Color(0xFF1E7A5A);
  static const hadirInk = Color(0xFF0B4A36);
  static const dupBg = Color(0xFFEAF2FB);
  static const dupLine = Color(0xFF2E6FB7);
  static const dupInk = Color(0xFF1D4E89);
  static const errBg = Color(0xFFFCEDEE);
  static const errLine = Color(0xFFC0392B);
  static const errInk = Color(0xFF8E2318);
  static const nmBg = Color(0xFFF1EEFB);
  static const nmLine = Color(0xFF6D5BD0);
  static const nmInk = Color(0xFF463A8E);
  static const offBg = Color(0xFFFBF3E4);
  static const offLine = Color(0xFFB7791F);
  static const offInk = Color(0xFF7A5310);
  static const closedBg = Color(0xFFF1F3F2);
  static const closedLine = Color(0xFFC7CFCA);
  static const closedInk = Color(0xFF45514A);
}

const kManrope = 'Manrope';
const kInter = 'Inter';

TextStyle manrope(
  double size,
  FontWeight weight, {
  double? height,
  Color? color,
  double? spacing,
}) => TextStyle(
  fontFamily: kManrope,
  fontSize: size,
  fontWeight: weight,
  height: height,
  color: color,
  letterSpacing: spacing,
);

TextStyle inter(
  double size,
  FontWeight weight, {
  double? height,
  Color? color,
  double? spacing,
}) => TextStyle(
  fontFamily: kInter,
  fontSize: size,
  fontWeight: weight,
  height: height,
  color: color,
  letterSpacing: spacing,
);

/// Angka lebar tetap supaya NISN, waktu, dan hitungan tidak goyang.
const tabular = [FontFeature.tabularFigures()];

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDCEAE3),
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      tertiary: AppColors.gold,
      onTertiary: Colors.white,
      error: AppColors.errLine,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      outline: AppColors.outlineStrong,
      outlineVariant: AppColors.outline,
    ),
    scaffoldBackgroundColor: AppColors.surface,
  );

  final text = base.textTheme.copyWith(
    displaySmall: manrope(32, FontWeight.w800, height: 1.12),
    headlineMedium: manrope(27, FontWeight.w800, height: 1.16),
    headlineSmall: manrope(23, FontWeight.w700, height: 1.2),
    titleLarge: manrope(20, FontWeight.w700),
    titleMedium: manrope(17, FontWeight.w700),
    titleSmall: manrope(15, FontWeight.w600),
    bodyLarge: inter(16, FontWeight.w400, height: 1.45),
    bodyMedium: inter(14.5, FontWeight.w400, height: 1.45),
    bodySmall: inter(13, FontWeight.w400, height: 1.4),
    labelLarge: inter(15, FontWeight.w600),
    labelMedium: inter(13, FontWeight.w600),
    labelSmall: inter(11.5, FontWeight.w600, spacing: 0.2),
  );

  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: manrope(20, FontWeight.w700, color: AppColors.ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: inter(16, FontWeight.w600),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: inter(15, FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: inter(14.5, FontWeight.w400, color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.outlineStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.outlineStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.outline,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: inter(14, FontWeight.w400, color: Colors.white),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titleTextStyle: manrope(19, FontWeight.w700, color: AppColors.ink),
      contentTextStyle: inter(14.5, FontWeight.w400, color: AppColors.ink),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.outline),
      ),
    ),
  );
}
