import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF0D9488);
  static const Color secondaryColor = Color(0xFF7C3AED);
  static const Color successColor = Color(0xFF059669);
  static const Color warningColor = Color(0xFFD97706);
  static const Color errorColor = Color(0xFFDC2626);
  static const Color infoColor = Color(0xFF0284C7);

  static const Color _lightBg = Color(0xFFF1F5F9);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightText = Color(0xFF1E293B);
  static const Color _lightSecondaryText = Color(0xFF64748B);

  static const Color _darkBg = Color(0xFF0F172A);
  static const Color _darkSurface = Color(0xFF1E293B);
  static const Color _darkText = Color(0xFFF1F5F9);
  static const Color _darkSecondaryText = Color(0xFF94A3B8);

  static TextStyle _poppins(double size, FontWeight weight, {double? letterSpacing, Color? color}) {
    return GoogleFonts.poppins(fontSize: size, fontWeight: weight, letterSpacing: letterSpacing, color: color);
  }

  static Color colorFromHex(String hex) {
    var h = hex.replaceFirst('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    final value = int.tryParse(h, radix: 16);
    return value == null ? primaryColor : Color(value);
  }

  static CupertinoThemeData themeFor({
    required Brightness brightness,
    required Color accent,
  }) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? _darkBg : _lightBg;
    final surface = isDark ? _darkSurface : _lightSurface;
    final text = isDark ? _darkText : _lightText;
    final secondaryText = isDark ? _darkSecondaryText : _lightSecondaryText;

    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: accent,
      primaryContrastingColor: CupertinoColors.white,
      scaffoldBackgroundColor: bg,
      barBackgroundColor: surface,
      textTheme: CupertinoTextThemeData(
        primaryColor: text,
        textStyle: _poppins(14, FontWeight.w400, color: text),
        actionTextStyle: _poppins(14, FontWeight.w600, color: accent),
        tabLabelTextStyle: _poppins(10, FontWeight.w500, color: secondaryText),
        navTitleTextStyle: _poppins(17, FontWeight.w600, color: text),
        navLargeTitleTextStyle: _poppins(34, FontWeight.w700, color: text),
        navActionTextStyle: _poppins(17, FontWeight.w500, color: accent),
        pickerTextStyle: _poppins(20, FontWeight.w400, color: text),
        dateTimePickerTextStyle: _poppins(20, FontWeight.w400, color: text),
        actionSmallTextStyle: _poppins(12, FontWeight.w400, color: secondaryText),
      ),
    );
  }

  static CupertinoThemeData get lightTheme =>
      themeFor(brightness: Brightness.light, accent: primaryColor);

  static CupertinoThemeData get darkTheme =>
      themeFor(brightness: Brightness.dark, accent: const Color(0xFF3B82F6));
}

class AppColors {
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryDark = Color(0xFF3B82F6);
  static const Color secondary = Color(0xFF7C3AED);
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0284C7);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF1F5F9);
  static const Color text = Color(0xFF1E293B);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color shadow = Color(0x1A000000);

  // Status colors
  static const Color statusActive = Color(0xFF059669);
  static const Color statusInactive = Color(0xFF9CA3AF);
  static const Color statusPending = Color(0xFFD97706);
  static const Color statusApproved = Color(0xFF2563EB);
  static const Color statusReceived = Color(0xFF059669);
  static const Color statusCompleted = Color(0xFF059669);
  static const Color statusCancelled = Color(0xFFDC2626);
  static const Color statusPaid = Color(0xFF059669);
  static const Color statusUnpaid = Color(0xFFDC2626);
  static const Color statusPartial = Color(0xFFD97706);

  // Stock levels
  static const Color stockNormal = Color(0xFF059669);
  static const Color stockLow = Color(0xFFD97706);
  static const Color stockOut = Color(0xFFDC2626);
}
