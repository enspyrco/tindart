import 'package:flutter/material.dart';

class WebColors {
  static const background = Color(0xFFFAFAFA);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B6B6B);
  static const border = Color(0xFFE5E5E5);
  static const accent = Color(0xFF2563EB);
  static const liked = Color(0xFFDC2626);
  static const disliked = Color(0xFF9CA3AF);
}

class WebTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: WebColors.background,
        colorScheme: const ColorScheme.light(
          primary: WebColors.accent,
          surface: WebColors.surface,
          onSurface: WebColors.textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: WebColors.surface,
          foregroundColor: WebColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w300,
            letterSpacing: -1,
            color: WebColors.textPrimary,
          ),
          displayMedium: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: WebColors.textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: WebColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.6,
            color: WebColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: WebColors.textSecondary,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: WebColors.border,
          thickness: 1,
        ),
        cardTheme: CardThemeData(
          color: WebColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: WebColors.border),
          ),
        ),
      );
}
