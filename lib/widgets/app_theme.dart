import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static const _key = 'theme_is_dark';

  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier(ThemeMode.dark);

  static bool get isDark => mode.value != ThemeMode.light;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dark = prefs.getBool(_key) ?? true;
      mode.value = dark ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
    }
  }

  static Future<void> setDark(bool dark) async {
    mode.value = dark ? ThemeMode.dark : ThemeMode.light;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, dark);
    } catch (_) {
      
    }
  }
}
