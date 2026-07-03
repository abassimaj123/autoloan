import 'dart:math';
import 'ca_taxes.dart';
import '../../core/payment_frequency.dart';

// ── CA Trade-In Result ─────────────────────────────────────────────────────────

class CATradeInResult {
  final double netTradeIn; // tradeInValue - remainingBalance
  final double effectiveDownPayment; // dpAmount + netTradeIn
  final double adjustedLoanAmount; // vehiclePriceWithTax - effectiveDownPayment

  const CATradeInResult({
    required this.netTradeIn,
    required this.effectiveDownPayment,
    required this.adjustedLoanAmount,
  });
}

// ── CA Affordability helpers ───────────────────────────────────────────────────

/// Reverse PMT: compute the loan principal (PV) that produces [maxMonthlyPayment]
/// at [annualRate]% over [termMonths] months, then add [downPayment] to get
/// the total max vehicle price.
///
/// Formula: PV = PMT × (1 - (1+r)^-n) / r   (for r > 0)
///          PV = PMT × n                      (for r == 0)
double maxAffordablePrice({
  required double monthlyIncome,
  required double annualRate,
  required int termMonths,
  required double downPayment,
  double taxRate = 0,
}) {
  final maxPmt = monthlyIncome * 0.15;
  double loanPV;
  if (annualRate <= 0 || termMonths <= 0) {
    loanPV = termMonths > 0 ? maxPmt * termMonths : 0;
  } else {
    final r = annualRate / 12 / 100;
    loanPV = maxPmt * (1 - pow(1 + r, -termMonths)) / r;
  }
  // availableForLoan = loanPV; max vehicle price before tax = (loanPV + downPayment) / (1 + taxRate)
  final divisor = taxRate > 0 ? (1 + taxRate) : 1.0;
  return (loanPV + downPayment) / divisor;
}

// ── CA Lease Calculation ───────────────────────────────────────────────────────

class CALeaseCalculation {
  final double vehiclePrice;
  final double residualPercent; // e.g. 50.0 for 50%
  final double residualValue; // vehiclePrice × residualPercent / 100
  final double moneyFactor; // rate ÷ 2400
  final int leaseTerm; // months: 24, 36, 48
  final double fees; // add-on fees (insurance, etc.)

  final double monthlyLease; // lease payment
  final double totalLeaseCost; // monthlyLease × leaseTerm

  const CALeaseCalculation({
    required this.vehiclePrice,
    required this.residualPercent,
    required this.residualValue,
    required this.moneyFactor,
    required this.leaseTerm,
    required this.fees,
    required this.monthlyLease,
    required this.totalLeaseCost,
  });

  static CALeaseCalculation calculate({
    required double vehiclePrice,
    required double residualPercent,
    required double moneyFactor,
    required int leaseTerm,
    double fees = 0,
  }) {
    final residualValue = vehiclePrice * residualPercent / 100;
    // Standard lease formula
    final monthlyLease =
        (vehiclePrice - residualValue + fees) / leaseTerm +
        (vehiclePrice + residualValue) * moneyFactor;
    final totalLeaseCost = monthlyLease * leaseTerm;
    return CALeaseCalculation(
      vehiclePrice: vehiclePrice,
      residualPercent: residualPercent,
      residualValue: residualValue,
      moneyFactor: moneyFactor,
      leaseTerm: leaseTerm,
      fees: fees,
      monthlyLease: monthlyLease,
      totalLeaseCost: totalLeaseCost,
    );
  }
}

// ── CA TCO Calculation ─────────────────────────────────────────────────────────

class CATcoCalculation {
  final double annualKm;
  final double fuelPer100km;
  final double fuelPricePerL;
  final double annualInsurance;
  final double annualMaintenance;
  final int termMonths;

  final double totalFuel;
  final double totalInsurance;
  final double totalMaintenance;
  final double totalInterest;
  final double netVehicleCost; // vehiclePrice - tradeIn/downPayment component
  final double grandTotal;

  const CATcoCalculation({
    required this.annualKm,
    required this.fuelPer100km,
    required this.fuelPricePerL,
    required this.annualInsurance,
    required this.annualMaintenance,
    required this.termMonths,
    required this.totalFuel,
    required this.totalInsurance,
    required this.totalMaintenance,
    required this.totalInterest,
    required this.netVehicleCost,
    required this.grandTotal,
  });

  static CATcoCalculation calculate({
    required double annualKm,
    required double fuelPer100km,
    required double fuelPricePerL,
    required double annualInsurance,
    required double annualMaintenance,
    required int termMonths,
    required double totalInterest,
    required double vehiclePrice,
    required double downPayment,
    double taxRate = 0,
  }) {
    final termYears = termMonths / 12;
    final totalFuel = annualKm / 100 * fuelPer100km * fuelPricePerL * termYears;
    final totalInsurance = annualInsurance * termYears;
    final totalMaintenance = annualMaintenance * termYears;
    // TCO = all money the user spends to own the vehicle over the term.
    // downPayment is NOT subtracted here — the user already paid it, so it IS
    // part of total cost.  vehiclePrice here already represents the full cost
    // (trade-in is handled at the loan level in CA).
    // Include provincial/HST tax in the vehicle cost.
    final netVehicleCost = vehiclePrice * (1 + taxRate);
    final grandTotal =
        totalFuel +
        totalInsurance +
        totalMaintenance +
        totalInterest +
        netVehicleCost;
    return CATcoCalculation(
      annualKm: annualKm,
      fuelPer100km: fuelPer100km,
      fuelPricePerL: fuelPricePerL,
      annualInsurance: annualInsurance,
      annualMaintenance: annualMaintenance,
      termMonths: termMonths,
      totalFuel: totalFuel,
      totalInsurance: totalInsurance,
      totalMaintenance: totalMaintenance,
      totalInterest: totalInterest,
      netVehicleCost: netVehicleCost,
      grandTotal: grandTotal,
    );
  }
}

class CACalculation {
  final double vehiclePrice, downPayment, annualRate;
  final int termMonths;
  final String provinceCode;
  final PaymentFrequency frequency;
  final double insuranceMonthly;
  final double taxAmount, loanAmount;

  // ── Monthly (r = annualRate/12/100, n = termMonths) ──────────────────────
  final double baseLoanMonthly; // pure loan payment, no insurance
  final double monthlyPayment; // baseLoanMonthly + insuranceMonthly

  // ── Bi-weekly (r = annualRate/26/100, n = years×26) — BUG #1/#2 fix ─────
  // Computed with proper formula, NOT converted from monthly
  final int nBiPeriods; // = round(termMonths / 12 * 26), e.g. 130 for 5 yr
  final double baseLoanBiWeekly; // pure loan bi-weekly payment
  final double insuranceBiWeekly; // insuranceMonthly × 12/26
  final double biWeeklyPayment; // baseLoanBiWeekly + insuranceBiWeekly

  // ── Weekly (r = annualRate/52/100, n = years×52) ─────────────────────────
  final int nWeeklyPeriods; // = round(termMonths / 12 * 52), e.g. 260 for 5 yr
  final double baseLoanWeekly; // pure loan weekly payment
  final double insuranceWeekly; // insuranceMonthly × 12/52
  final double weeklyPayment; // baseLoanWeekly + insuranceWeekly

  final double totalInterest, insuranceTotal, totalCost;

  const CACalculation({
    required this.vehiclePrice,
    required this.downPayment,
    required this.annualRate,
    required this.termMonths,
    required this.provinceCode,
    required this.frequency,
    required this.insuranceMonthly,
    required this.taxAmount,
    required this.loanAmount,
    required this.baseLoanMonthly,
    required this.monthlyPayment,
    required this.nBiPeriods,
    required this.baseLoanBiWeekly,
    required this.insuranceBiWeekly,
    required this.biWeeklyPayment,
    required this.nWeeklyPeriods,
    required this.baseLoanWeekly,
    required this.insuranceWeekly,
    required this.weeklyPayment,
    required this.totalInterest,
    required this.insuranceTotal,
    required this.totalCost,
  });

  bool get isBiWeekly => frequency == PaymentFrequency.biWeekly;

  double get displayPayment {
    switch (frequency) {
      case PaymentFrequency.monthly:
        return monthlyPayment;
      case PaymentFrequency.biWeekly:
        return biWeeklyPayment;
      case PaymentFrequency.weekly:
        return weeklyPayment;
    }
  }

  double get priceWithTax => vehiclePrice + taxAmount;

  static CACalculation calculate({
    required double vehiclePrice,
    required double downPayment,
    required double annualRate,
    required int termMonths,
    required String provinceCode,
    required PaymentFrequency frequency,
    double insuranceMonthly = 0,
    double tradeInValue = 0.0,
  }) {
    final province = caProvinceByCode(provinceCode);
    // In CA: trade-in reduces the taxable purchase price (sale price for tax purposes)
    final taxablePrice = (vehiclePrice - tradeInValue).clamp(0.0, double.infinity);
    final taxAmount = taxablePrice * province.totalRate;
    final loanAmount = ((vehiclePrice - tradeInValue) + taxAmount - downPayment).clamp(
      0.0,
      double.infinity,
    );

    // ── Monthly formula ────────────────────────────────────────────────────
    double baseLoanMonthly;
    if (annualRate <= 0) {
      baseLoanMonthly = termMonths > 0 ? loanAmount / termMonths : 0;
    } else {
      final r = annualRate / 12 / 100;
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
      final rBi = annualRate / 26 / 100;
      final powN = pow(1 + rBi, nBiPeriods).toDouble();
      baseLoanBiWeekly = loanAmount * (rBi * powN) / (powN - 1);
    }
    // Insurance bi-weekly = insuranceMonthly × 12/26
    // Math note: (periodic/mo × 12/26) + (oneTime/termMo × 12/26)
    //           = periodic/bi-weekly + oneTime/nBiPeriods  ✓
    final insuranceBiWeekly = insuranceMonthly * 12 / 26;
    final biWeeklyPayment = baseLoanBiWeekly + insuranceBiWeekly;

    // ── Weekly formula ─────────────────────────────────────────────────────
    // Proper amortization with r = annualRate/52/100, n = years×52
    final nWeeklyPeriods = ((termMonths / 12) * 52).round(); // e.g. 260 for 5 yr
    double baseLoanWeekly;
    if (annualRate <= 0 || nWeeklyPeriods <= 0) {
      baseLoanWeekly = nWeeklyPeriods > 0 ? loanAmount / nWeeklyPeriods : 0;
    } else {
      final rWk = annualRate / 52 / 100;
      final powN = pow(1 + rWk, nWeeklyPeriods).toDouble();
      baseLoanWeekly = loanAmount * (rWk * powN) / (powN - 1);
    }
    final insuranceWeekly = insuranceMonthly * 12 / 52;
    final weeklyPayment = baseLoanWeekly + insuranceWeekly;

    // ── Totals ────────────────────────────────────────────────────────────
    final monthlyTotalInterest = (baseLoanMonthly * termMonths - loanAmount)
        .clamp(0.0, double.infinity);
    final biWeeklyTotalInterest = (baseLoanBiWeekly * nBiPeriods - loanAmount)
        .clamp(0.0, double.infinity);
    final weeklyTotalInterest = (baseLoanWeekly * nWeeklyPeriods - loanAmount)
        .clamp(0.0, double.infinity);
    final double totalInterest;
    switch (frequency) {
      case PaymentFrequency.biWeekly:
        totalInterest = biWeeklyTotalInterest;
        break;
      case PaymentFrequency.weekly:
        totalInterest = weeklyTotalInterest;
        break;
      case PaymentFrequency.monthly:
        totalInterest = monthlyTotalInterest;
        break;
    }
    final insuranceTotal = insuranceMonthly * termMonths;
    final totalCost = vehiclePrice + taxAmount + totalInterest + insuranceTotal;

    return CACalculation(
      vehiclePrice: vehiclePrice,
      downPayment: downPayment,
      annualRate: annualRate,
      termMonths: termMonths,
      provinceCode: provinceCode,
      frequency: frequency,
      insuranceMonthly: insuranceMonthly,
      taxAmount: taxAmount,
      loanAmount: loanAmount,
      baseLoanMonthly: baseLoanMonthly,
      monthlyPayment: monthlyPayment,
      nBiPeriods: nBiPeriods,
      baseLoanBiWeekly: baseLoanBiWeekly,
      insuranceBiWeekly: insuranceBiWeekly,
      biWeeklyPayment: biWeeklyPayment,
      nWeeklyPeriods: nWeeklyPeriods,
      baseLoanWeekly: baseLoanWeekly,
      insuranceWeekly: insuranceWeekly,
      weeklyPayment: weeklyPayment,
      totalInterest: totalInterest,
      insuranceTotal: insuranceTotal,
      totalCost: totalCost,
    );
  }
}
