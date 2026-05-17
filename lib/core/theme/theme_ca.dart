import 'package:flutter/material.dart';
import 'package:calcwise_core/calcwise_core.dart' hide SectionCard, ResultTile;

/// AutoLoan CA — Forest green brand, CalcwiseThemeFactory tokens.
class ThemeCA {
  static const Color primary = Color(0xFF1B5E20); // Forest green
  static const Color accent = Color(0xFFF9A825); // Amber
  // Semantic aliases kept for screens that reference them directly
  static const Color primaryLight = Color(0xFF2E7D32);
  static const Color accentPos = Color(0xFF2E7D32);
  static const Color accentNeg = Color(0xFFC62828);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF424242);
  static const Color divider = Color(0xFFBDBDBD);

  static ThemeData get theme =>
      CalcwiseThemeFactory.buildLight(primary: primary, accent: accent);
  static ThemeData get dark =>
      CalcwiseThemeFactory.buildDark(primary: primary, accent: accent);
}
