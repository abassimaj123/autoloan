/// Payment frequency shared across all flavors (CA / UK / US).
///
/// Drives the loan amortization period count and the displayed payment label.
/// - [monthly]   : 12 payments/year
/// - [biWeekly]  : 26 payments/year (accelerated)
/// - [weekly]    : 52 payments/year (more accelerated)
enum PaymentFrequency { monthly, biWeekly, weekly }

extension PaymentFrequencyExt on PaymentFrequency {
  /// Number of payment periods per year.
  int get periodsPerYear {
    switch (this) {
      case PaymentFrequency.monthly:
        return 12;
      case PaymentFrequency.biWeekly:
        return 26;
      case PaymentFrequency.weekly:
        return 52;
    }
  }

  bool get isMonthly => this == PaymentFrequency.monthly;
  bool get isBiWeekly => this == PaymentFrequency.biWeekly;
  bool get isWeekly => this == PaymentFrequency.weekly;
}
