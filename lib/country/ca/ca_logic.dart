import 'dart:math';
import 'ca_taxes.dart';

class CACalculation {
  final double vehiclePrice, downPayment, annualRate;
  final int termMonths;
  final String provinceCode;
  final bool isBiWeekly;
  final double insuranceMonthly;
  final double taxAmount, loanAmount;

  // ── Monthly (r = annualRate/12/100, n = termMonths) ──────────────────────
  final double baseLoanMonthly;  // pure loan payment, no insurance
  final double monthlyPayment;   // baseLoanMonthly + insuranceMonthly

  // ── Bi-weekly (r = annualRate/26/100, n = years×26) — BUG #1/#2 fix ─────
  // Computed with proper formula, NOT converted from monthly
  final int    nBiPeriods;        // = round(termMonths / 12 * 26), e.g. 130 for 5 yr
  final double baseLoanBiWeekly; // pure loan bi-weekly payment
  final double insuranceBiWeekly; // insuranceMonthly × 12/26
  final double biWeeklyPayment;  // baseLoanBiWeekly + insuranceBiWeekly

  final double totalInterest, insuranceTotal, totalCost;

  const CACalculation({
    required this.vehiclePrice, required this.downPayment, required this.annualRate,
    required this.termMonths, required this.provinceCode, required this.isBiWeekly,
    required this.insuranceMonthly, required this.taxAmount, required this.loanAmount,
    required this.baseLoanMonthly, required this.monthlyPayment,
    required this.nBiPeriods, required this.baseLoanBiWeekly,
    required this.insuranceBiWeekly, required this.biWeeklyPayment,
    required this.totalInterest, required this.insuranceTotal, required this.totalCost,
  });

  double get displayPayment => isBiWeekly ? biWeeklyPayment : monthlyPayment;
  double get priceWithTax   => vehiclePrice + taxAmount;

  static CACalculation calculate({
    required double vehiclePrice,
    required double downPayment,
    required double annualRate,
    required int termMonths,
    required String provinceCode,
    required bool isBiWeekly,
    double insuranceMonthly = 0,
  }) {
    final province   = caProvinceByCode(provinceCode);
    final taxAmount  = vehiclePrice * province.totalRate;
    final loanAmount = (vehiclePrice + taxAmount - downPayment).clamp(0.0, double.infinity);

    // ── Monthly formula ────────────────────────────────────────────────────
    double baseLoanMonthly;
    if (annualRate <= 0) {
      baseLoanMonthly = termMonths > 0 ? loanAmount / termMonths : 0;
    } else {
      final r    = annualRate / 12 / 100;
      final powN = pow(1 + r, termMonths).toDouble();
      baseLoanMonthly = loanAmount * (r * powN) / (powN - 1);
    }
    final monthlyPayment = baseLoanMonthly + insuranceMonthly;

    // ── Bi-weekly formula (BUG #1 fix) ────────────────────────────────────
    // Use proper amortization formula with r = annualRate/26/100, n = years×26
    // Never convert from monthly — compute independently (BUG #2 fix)
    final nBiPeriods = ((termMonths / 12) * 26).round(); // e.g. 130 for 5 yr
    double baseLoanBiWeekly;
    if (annualRate <= 0 || nBiPeriods <= 0) {
      baseLoanBiWeekly = nBiPeriods > 0 ? loanAmount / nBiPeriods : 0;
    } else {
      final rBi  = annualRate / 26 / 100;
      final powN = pow(1 + rBi, nBiPeriods).toDouble();
      baseLoanBiWeekly = loanAmount * (rBi * powN) / (powN - 1);
    }
    // Insurance bi-weekly = insuranceMonthly × 12/26
    // Math note: (periodic/mo × 12/26) + (oneTime/termMo × 12/26)
    //           = periodic/bi-weekly + oneTime/nBiPeriods  ✓
    final insuranceBiWeekly = insuranceMonthly * 12 / 26;
    final biWeeklyPayment   = baseLoanBiWeekly + insuranceBiWeekly;

    // ── Totals (based on monthly schedule) ────────────────────────────────
    final totalInterest  = (baseLoanMonthly * termMonths - loanAmount).clamp(0.0, double.infinity);
    final insuranceTotal = insuranceMonthly * termMonths;
    final totalCost      = vehiclePrice + taxAmount + totalInterest + insuranceTotal;

    return CACalculation(
      vehiclePrice: vehiclePrice, downPayment: downPayment, annualRate: annualRate,
      termMonths: termMonths, provinceCode: provinceCode, isBiWeekly: isBiWeekly,
      insuranceMonthly: insuranceMonthly, taxAmount: taxAmount, loanAmount: loanAmount,
      baseLoanMonthly: baseLoanMonthly, monthlyPayment: monthlyPayment,
      nBiPeriods: nBiPeriods, baseLoanBiWeekly: baseLoanBiWeekly,
      insuranceBiWeekly: insuranceBiWeekly, biWeeklyPayment: biWeeklyPayment,
      totalInterest: totalInterest, insuranceTotal: insuranceTotal, totalCost: totalCost,
    );
  }
}
