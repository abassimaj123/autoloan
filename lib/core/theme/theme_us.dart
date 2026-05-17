import 'package:flutter/material.dart';
import 'package:calcwise_core/calcwise_core.dart' hide SectionCard, ResultTile;

/// AutoLoan US — Navy blue brand, CalcwiseThemeFactory tokens.
class ThemeUS {
  static const Color primary = Color(0xFF0D47A1); // Navy blue
  static const Color accent = Color(0xFFB71C1C); // Deep red
  // Semantic aliases
  static const Color primaryLight = Color(0xFF1565C0);
  static const Color secondary = Color(0xFFB71C1C);
  static const Color accentPos = Color(0xFF2E7D32);
  static const Color accentNeg = Color(0xFFC62828);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFBDBDBD);

  static ThemeData get theme =>
      CalcwiseThemeFactory.buildLight(primary: primary, accent: accent);
  static ThemeData get dark =>
      CalcwiseThemeFactory.buildDark(primary: primary, accent: accent);
}
