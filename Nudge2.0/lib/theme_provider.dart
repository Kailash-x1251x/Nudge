import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }

  Color get background => _isDark ? Colors.black : Colors.white;
  Color get surface => _isDark ? const Color(0xFF111111) : const Color(0xFFF5F5F5);
  Color get primary => _isDark ? Colors.white : Colors.black;
  Color get secondary => _isDark ? const Color(0xFF999999) : const Color(0xFF666666);
  Color get border => _isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
  Color get cardBg => _isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);
  Color get toggleBg => _isDark ? const Color(0xFF222222) : const Color(0xFFF0F0F0);
}