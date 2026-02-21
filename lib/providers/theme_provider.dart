import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme provider for managing light/dark mode
/// 
/// Handles theme switching and persistence across app restarts
/// using SharedPreferences.
/// 
/// Example usage:
/// ```dart
/// final themeProvider = Provider.of<ThemeProvider>(context);
/// themeProvider.toggleTheme();
/// ```
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoading = false;

  /// Get the current theme mode
  ThemeMode get themeMode => _themeMode;
  
  /// Check if dark mode is currently active
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  /// Check if theme is being loaded/saved
  bool get isLoading => _isLoading;

  /// Initialize theme from SharedPreferences
  /// 
  /// Should be called during app startup to restore the user's
  /// preferred theme.
  /// 
  /// Example:
  /// ```dart
  /// await themeProvider.loadTheme();
  /// ```
  Future<void> loadTheme() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_themeKey);
      
      if (themeModeString != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeString,
          orElse: () => ThemeMode.light,
        );
      }
    } catch (e) {
      // If loading fails, keep default light theme
      _themeMode = ThemeMode.light;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Set theme mode
  /// 
  /// Changes the theme and persists the preference.
  /// 
  /// Parameters:
  /// - [mode]: The ThemeMode to set (light, dark, or system)
  /// 
  /// Example:
  /// ```dart
  /// await themeProvider.setThemeMode(ThemeMode.dark);
  /// ```
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.toString());
    } catch (e) {
      // Handle error silently - theme will still work for current session
      debugPrint('Failed to save theme preference: $e');
    }
  }

  /// Toggle between light and dark mode
  /// 
  /// Switches to dark mode if currently light, and vice versa.
  /// 
  /// Example:
  /// ```dart
  /// themeProvider.toggleTheme();
  /// ```
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    await setThemeMode(newMode);
  }

  /// Set light theme
  /// 
  /// Convenience method to explicitly set light mode.
  Future<void> setLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  /// Set dark theme
  /// 
  /// Convenience method to explicitly set dark mode.
  Future<void> setDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }

  /// Set system theme
  /// 
  /// Uses the device's system theme preference.
  Future<void> setSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }
}