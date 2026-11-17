import 'package:flutter/material.dart';

// Same palette as the Android app.
const sand = Color(0xFFD6BE9A);
const cream = Color(0xFFF8F5EF);
const espresso = Color(0xFF332923);
const sage = Color(0xFFA5AE98);
const taupe = Color(0xFFB8A99A);

ThemeData buildTheme() {
  const scheme = ColorScheme.light(
    primary: espresso,
    onPrimary: cream,
    secondary: sand,
    onSecondary: espresso,
    tertiary: sage,
    surface: cream,
    onSurface: espresso,
    outline: taupe,
    error: Color(0xFFB3261E),
  );

  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: cream,
      foregroundColor: espresso,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cream,
      indicatorColor: sand.withValues(alpha: 0.5),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: espresso,
      indicatorColor: espresso,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: shape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: shape,
        side: const BorderSide(color: taupe),
        foregroundColor: espresso,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: taupe),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: espresso, width: 1.5),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: sand,
      foregroundColor: espresso,
    ),
  );
}
