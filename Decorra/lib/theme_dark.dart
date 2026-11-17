import 'package:flutter/material.dart';

import 'theme.dart';

const _page = Color(0xFF171410);
const _card = Color(0xFF26211C);

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: sand, brightness: Brightness.dark).copyWith(
    primary: sand,
    onPrimary: espresso,
    surface: _page,
    onSurface: const Color(0xFFF2EBE3),
  );

  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: _page,
    appBarTheme: const AppBarTheme(
      backgroundColor: _page,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _card,
      indicatorColor: taupe.withAlpha(90),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: border(taupe),
      enabledBorder: border(taupe),
      focusedBorder: border(sand),
    ),
    dividerColor: taupe.withAlpha(90),
  );
}

/// Card and panel background: white in light mode, warm dark grey in dark mode.
Color surfaceCard(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? _card : Colors.white;

/// Dark brown in light mode, sand in dark mode. For icons or text drawn straight on the page.
Color accentInk(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? sand : espresso;