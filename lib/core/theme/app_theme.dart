import 'package:flutter/material.dart';

/// Shared color constants used across all flavor widgets.
class AppTheme {
  AppTheme._();
  static const Color primary   = Color(0xFF0D47A1); // Blue 900
  static const Color labelGray = Color(0xFF757575); // Grey 600

  // Premium gold — AppBar icon & TextButton foreground
  static const Color premiumGold = Color(0xFFD4A017);

  // Warning / orange — PaywallHard icon
  static const Color warningOrangeBg   = Color(0xFFFFF3E0); // orange.shade50
  static const Color warningOrangeIcon = Color(0xFFFFA726); // orange.shade400

  // Rewarded session — UnlockSheet active chip
  static const Color rewardedGreenBg     = Color(0xFFF1F8E9); // green.shade50
  static const Color rewardedGreenBorder = Color(0xFF66BB6A); // green.shade400
  static const Color rewardedGreenText   = Color(0xFF388E3C); // green.shade700
  static const Color rewardedGreen       = Color(0xFF43A047); // green.shade600
}
