import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0C0C0D);
  static const panel = Color(0xFF141416);
  static const line = Color(0xFF232327);
  static const gold = Color(0xFFE6B84A);
  static const onGold = Color(0xFF1A1405);
  static const text = Color(0xFFF4F2EC);
  static const muted = Color(0xFF8E8C86);
  static const error = Color(0xFFE5675A);
}

const kFont = 'Plex';

/// Thick outline on the focused control, so it is obvious from across the room
/// which button the TV remote is on.
WidgetStateProperty<BorderSide?> focusRing(Color color) =>
    WidgetStateProperty.resolveWith<BorderSide?>((states) =>
        states.contains(WidgetState.focused) ? BorderSide(color: color, width: 3) : null);

ThemeData buildTheme() {
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.line, width: 1.5),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: kFont,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      onPrimary: AppColors.onGold,
      secondary: AppColors.gold,
      onSecondary: AppColors.onGold,
      surface: AppColors.panel,
      onSurface: AppColors.text,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    canvasColor: AppColors.bg,
    dividerColor: AppColors.line,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bg,
      labelStyle: const TextStyle(color: AppColors.muted),
      floatingLabelStyle: const TextStyle(color: AppColors.gold),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.gold, width: 2.5),
      ),
      errorBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.error, width: 2.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        side: focusRing(AppColors.text),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontFamily: kFont, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(AppColors.text),
        side: WidgetStateProperty.resolveWith<BorderSide?>((states) =>
            states.contains(WidgetState.focused)
                ? const BorderSide(color: AppColors.gold, width: 3)
                : const BorderSide(color: AppColors.line, width: 1.5)),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontFamily: kFont, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.panel,
      contentTextStyle: TextStyle(fontFamily: kFont, color: AppColors.text, fontSize: 16),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
