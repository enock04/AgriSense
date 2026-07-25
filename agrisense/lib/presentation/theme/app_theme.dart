import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green700,
      primary: AppColors.green700,
      onPrimary: Colors.white,
      secondary: AppColors.amber400,
      surface: AppColors.surface,
      error: AppColors.red600,
    ),
    scaffoldBackgroundColor: AppColors.surface,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.gray900,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: TextStyle(
        color: AppColors.gray900,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.green700,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.green700,
        minimumSize: const Size(double.infinity, 52),
        side: const BorderSide(color: AppColors.green700, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.gray100,
      selectedColor: AppColors.green50,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gray200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gray200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.green700, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.gray500),
      hintStyle: const TextStyle(color: AppColors.gray400),
    ),
    textTheme: const TextTheme(
      displayLarge:   TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.gray900),
      displayMedium:  TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.gray900),
      headlineLarge:  TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.gray900),
      headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.gray900),
      headlineSmall:  TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gray900),
      bodyLarge:      TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.gray700),
      bodyMedium:     TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.gray700),
      bodySmall:      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.gray500),
      labelLarge:     TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray700),
      labelSmall:     TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.gray400),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.green50,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.green700);
        }
        return const IconThemeData(color: AppColors.gray400);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.green700);
        }
        return const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.gray400);
      }),
    ),
  );
}
