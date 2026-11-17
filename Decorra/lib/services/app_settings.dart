import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/strings.dart';

/// The phone's appearance and language choices, saved on the phone.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final instance = AppSettings._();

  ThemeMode _themeMode = ThemeMode.system;

  /// null means "follow the phone's language".
  Locale? _locale;

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _themeMode = switch (prefs.getString('themeMode')) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      final code = prefs.getString('language');
      _locale = supportedLanguages.any((l) => l.code == code) ? Locale(code!) : null;
    } catch (_) {
      // Keep the defaults.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('themeMode', mode.name);
    } catch (_) {}
  }

  /// Pass null to follow the phone's language.
  Future<void> setLanguage(String? code) async {
    _locale = code == null ? null : Locale(code);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (code == null) {
        await prefs.remove('language');
      } else {
        await prefs.setString('language', code);
      }
    } catch (_) {}
  }
}