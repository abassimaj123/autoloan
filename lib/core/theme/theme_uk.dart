import 'package:flutter/material.dart';

class ThemeUK {
  static const primary        = Color(0xFFC62828);  // Union Jack red
  static const primaryLight   = Color(0xFFEF5350);
  static const secondary      = Color(0xFF0D47A1);  // Union Jack blue
  static const background     = Color(0xFFFFFFFF);
  static const surface        = Color(0xFFFFEBEE);  // light red tint
  static const surfaceVariant = Color(0xFFFFCDD2);
  static const accentPos      = Color(0xFF2E7D32);
  static const accentNeg      = Color(0xFFC62828);
  static const textPrimary    = Color(0xFF1A1A1A);
  static const textSecondary  = Color(0xFF424242);
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
      bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      // TODO: iOS — add iOS flavor config (Info.plist, GoogleService-Info.plist, icons)
      // TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );

  static const _darkBackground     = Color(0xFF1A0A0A);
  static const _darkSurface        = Color(0xFF2A1010);
  static const _darkSurfaceVariant = Color(0xFF3A1818);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
        seedColor: primary, brightness: Brightness.dark,
        primary: primaryLight, secondary: secondary,
        surface: _darkSurface),
    scaffoldBackgroundColor: _darkBackground,
    appBarTheme: const AppBarTheme(
        backgroundColor: _darkBackground, foregroundColor: Colors.white, elevation: 0,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
    cardTheme: CardThemeData(
        color: _darkSurface, elevation: 2, shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    sliderTheme: SliderThemeData(
        activeTrackColor: primaryLight,
        inactiveTrackColor: primaryLight.withValues(alpha: 0.2),
        thumbColor: primaryLight),
    chipTheme: ChipThemeData(
        color: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? primaryLight : Colors.transparent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : Colors.grey.shade400),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : _darkSurfaceVariant),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: _darkSurface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryLight, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0)),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 52, fontWeight: FontWeight.w800, color: primaryLight),
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    }),
  );
}
