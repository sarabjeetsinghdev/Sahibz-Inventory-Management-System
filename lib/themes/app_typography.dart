import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle poppins({
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  // Display
  static TextStyle get displayLarge => poppins(fontSize: 57, fontWeight: FontWeight.w700, letterSpacing: -0.25);
  static TextStyle get displayMedium => poppins(fontSize: 45, fontWeight: FontWeight.w600, letterSpacing: 0);
  static TextStyle get displaySmall => poppins(fontSize: 36, fontWeight: FontWeight.w600, letterSpacing: 0);

  // Headline
  static TextStyle get headlineLarge => poppins(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5);
  static TextStyle get headlineMedium => poppins(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.3);
  static TextStyle get headlineSmall => poppins(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.3);

  // Title
  static TextStyle get titleLarge => poppins(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0);
  static TextStyle get titleMedium => poppins(fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: 0);
  static TextStyle get titleSmall => poppins(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15);

  // Body
  static TextStyle get bodyLarge => poppins(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5);
  static TextStyle get bodyMedium => poppins(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25);
  static TextStyle get bodySmall => poppins(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4);

  // Label
  static TextStyle get labelLarge => poppins(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1);
  static TextStyle get labelMedium => poppins(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5);
  static TextStyle get labelSmall => poppins(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5);

  // Button
  static TextStyle get button => poppins(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5);

  // Caption
  static TextStyle get caption => poppins(fontSize: 11, fontWeight: FontWeight.w400, letterSpacing: 0.4);

  // Overline
  static TextStyle get overline => poppins(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 1.5);
}
