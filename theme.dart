import 'package:flutter/material.dart';

class AppTheme {
  static const purple = Color(0xFF7C4DFF);
  static const blue = Color(0xFF2979FF);
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, blue],
  );
  static const connected = Color(0xFF00E5A0);
  static const danger = Color(0xFFFF5370);

  static ThemeData dark() => _base(Brightness.dark).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E0F1A),
      );
  static ThemeData light() => _base(Brightness.light);

  static ThemeData _base(Brightness b) {
    final scheme = ColorScheme.fromSeed(seedColor: purple, brightness: b);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Vazirmatn',
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
