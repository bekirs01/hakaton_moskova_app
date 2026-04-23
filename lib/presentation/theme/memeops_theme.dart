import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';

/// iOS benzeri koyu mavi palet + premium yüzeyler.
abstract final class MemeopsColors {
  static const iosBlue = Color(0xFF0A84FF);
  static const iosBlueBright = Color(0xFF409CFF);
  static const bgTop = Color(0xFF0A0E1A);
  static const bgMid = Color(0xFF12182A);
  static const bgBottom = Color(0xFF0C1528);
  static const surfaceCharcoal = Color(0xFF1E2438);
  static const glowBlue = Color(0x330A84FF);
}

ThemeData memeopsDarkTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: MemeopsColors.bgBottom,
    colorScheme: ColorScheme.dark(
      primary: MemeopsColors.iosBlue,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF1A3A5C),
      onPrimaryContainer: Colors.white,
      secondary: MemeopsColors.iosBlueBright,
      onSecondary: Colors.white,
      surface: MemeopsColors.surfaceCharcoal,
      onSurface: Colors.white,
      onSurfaceVariant: const Color(0xFFADB1C0),
      error: const Color(0xFFFF453A),
      errorContainer: const Color(0xFF5C2B2B),
      onErrorContainer: const Color(0xFFFFE4E1),
      outline: const Color(0x3AFFFFFF),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: -0.3,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MemeopsRadii.md),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MemeopsRadii.md),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MemeopsRadii.md),
        borderSide: const BorderSide(color: MemeopsColors.iosBlue, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor: MemeopsColors.iosBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MemeopsRadii.md),
        ),
        elevation: 0,
        shadowColor: MemeopsColors.glowBlue,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: MemeopsColors.iosBlueBright),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MemeopsRadii.md),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.06),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MemeopsRadii.md),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      selectedTileColor: MemeopsColors.iosBlue.withValues(alpha: 0.16),
      selectedColor: MemeopsColors.iosBlueBright,
      iconColor: Colors.white.withValues(alpha: 0.55),
      textColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MemeopsRadii.sm),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: MemeopsColors.iosBlueBright,
      linearTrackColor: Color(0x33FFFFFF),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorColor: MemeopsColors.iosBlue.withValues(alpha: 0.38),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          );
        }
        return TextStyle(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.55),
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: MemeopsColors.iosBlueBright, size: 26);
        }
        return IconThemeData(color: Colors.white.withValues(alpha: 0.5), size: 24);
      }),
    ),
  );
}
