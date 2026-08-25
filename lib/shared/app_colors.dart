import 'package:flutter/cupertino.dart';

extension ThemeColors on BuildContext {
  bool get isDarkTheme => CupertinoTheme.of(this).brightness == Brightness.dark;
  Color get primaryTextColor => isDarkTheme ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
  Color get secondaryTextColor => isDarkTheme ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get borderColor => isDarkTheme ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get surfaceColor => isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
  Color get backgroundColor => isDarkTheme ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
  Color get primaryColor => CupertinoTheme.of(this).primaryColor;
}
