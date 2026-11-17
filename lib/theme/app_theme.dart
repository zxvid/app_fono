import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF065274),
        primary: const Color(0xFF065274),
        primaryContainer: const Color(0xFF2D6A8D),
        secondary: const Color(0xFF00677E),
        surface: const Color(0xFFF4FAFF),
        onSurfaceVariant: const Color(0xFF41484D),
      ),
      fontFamily: 'Inter',
      useMaterial3: true,
    );
  }
}
