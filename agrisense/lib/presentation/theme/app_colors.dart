import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Green
  static const Color green900 = Color(0xFF186024);
  static const Color green700 = Color(0xFF2A8139);
  static const Color green500 = Color(0xFF3EAE55);
  static const Color green300 = Color(0xFF7FCD90);
  static const Color green200 = Color(0xFFB2DFBC);
  static const Color green100 = Color(0xFFD9F5E1);
  static const Color green50  = Color(0xFFEFF9F2);

  // Amber / Warning
  // amber600 darkened from #D89000 (2.66:1) → #8A5D00 (5.79:1) to pass WCAG AA
  static const Color amber600 = Color(0xFF8A5D00);
  static const Color amber400 = Color(0xFFF0B429);
  static const Color amber100 = Color(0xFFFFEFC3);
  static const Color amber50  = Color(0xFFFFFBEB);

  // Red / Danger
  static const Color red600 = Color(0xFFD22222);
  static const Color red100 = Color(0xFFFFE0E0);
  static const Color red50  = Color(0xFFFFF5F5);

  // Blue / Info
  static const Color blue500 = Color(0xFF1E94ED);
  static const Color blue100 = Color(0xFFDCEFFE);
  static const Color blue50  = Color(0xFFEFF7FF);

  // Neutrals
  static const Color gray900 = Color(0xFF1A1F1A);
  static const Color gray700 = Color(0xFF515D51);
  // gray600 darkened: #637163 (5.22:1 on white) — WCAG AA ✓
  static const Color gray600 = Color(0xFF637163);
  // gray500 darkened from #7A8C7A (3.58:1) → #677767 (4.80:1) — WCAG AA ✓
  static const Color gray500 = Color(0xFF677767);
  // gray400: #9EABA0 (2.39:1) — use ONLY for placeholder / hint / disabled text (WCAG-exempt)
  // For any readable body text use gray500 or gray600 instead.
  static const Color gray400 = Color(0xFF9EABA0);
  static const Color gray300 = Color(0xFFBDC9BD);
  static const Color gray200 = Color(0xFFD4DDD4);
  static const Color gray100 = Color(0xFFEFF3EF);
  static const Color white   = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF3FAF4);
}
