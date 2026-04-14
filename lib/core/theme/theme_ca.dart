import 'package:flutter/material.dart';

class ThemeCA {
  static const primary        = Color(0xFF1B5E20);
  static const primaryLight   = Color(0xFF2E7D32);
  static const secondary      = Color(0xFFF9A825);
  static const background     = Color(0xFFFFFFFF);
  static const surface        = Color(0xFFF5F5F5);
  static const surfaceVariant = Color(0xFFEEEEEE);
  static const accentPos      = Color(0xFF2E7D32);
  static const accentNeg      = Color(0xFFC62828);
  static const textPrimary    = Color(0xFF1A1A1A);
  static const textSecondary  = Color(0xFF424242); // was #757575 — too light
  static const divider        = Color(0xFFBDBDBD);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
        seedColor: primary, brightness: Brightness.light,
        primary: primary, secondary: secondary, surface: background),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
        backgroundColor: background, foregroundColor: textPrimary, elevation: 0,
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
    cardTheme: CardThemeData(
        color: surface, elevation: 2, shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: primary.withValues(alpha: 0.2),
        thumbColor: primary),
    chipTheme: ChipThemeData(
        color: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? primary : Colors.transparent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : textSecondary),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primaryLight : surfaceVariant),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0)),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 52, fontWeight: FontWeight.w800, color: primary),
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: textPrimary),   // labels must be dark
      bodySmall: TextStyle(fontSize: 12, color: textSecondary),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      // TODO: iOS — add iOS flavor config (Info.plist, GoogleService-Info.plist, icons)
      // TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
}
