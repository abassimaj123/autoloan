import 'dart:math';

enum CreditScore { excellent, good, fair, poor }

extension CreditScoreExt on CreditScore {
  String get label {
    switch (this) {
      case CreditScore.excellent: return 'Excellent (750+)';
      case CreditScore.good:      return 'Good (700–749)';
      case CreditScore.fair:      return 'Fair (650–699)';
      case CreditScore.poor:      return 'Poor (<650)';
    }
  }

  double get rateAdjustment {
    switch (this) {
      case CreditScore.excellent: return -1.5;
      case CreditScore.good:      return -0.5;
      case CreditScore.fair:      return  0.0;
      case CreditScore.poor:      return  2.0;
    }
  }
}

class USCalculation {
  final double vehiclePrice, tradeInValue, downPayment, dealerFees;
  final double salesTaxPercent, annualRate;
  final int termMonths;
  final CreditScore creditScore;
  final double taxAmount, financedAmount, effectiveRate;
  final double monthlyPayment, biWeeklyPayment, totalInterest, totalCost;
  final bool isBiWeekly;

  double get displayPayment => isBiWeekly ? biWeeklyPayment : monthlyPayment;

  const USCalculation({
    required this.vehiclePrice, required this.tradeInValue, required this.downPayment,
    required this.dealerFees, required this.salesTaxPercent, required this.annualRate,
    required this.termMonths, required this.creditScore, required this.taxAmount,
    required this.financedAmount, required this.effectiveRate,
    required this.monthlyPayment, required this.biWeeklyPayment,
    required this.totalInterest, required this.totalCost,
    this.isBiWeekly = false,
  });

  static USCalculation calculate({
    required double vehiclePrice,
    required double tradeInValue,
    required double downPayment,
    required double dealerFees,
    required double salesTaxPercent,
    required double annualRate,
    required int termMonths,
    required CreditScore creditScore,
    bool isBiWeekly = false,
  }) {
    final effectiveRate   = (annualRate + creditScore.rateAdjustment).clamp(0.0, 30.0);
    final taxAmount       = vehiclePrice * salesTaxPercent / 100;
    final financedAmount  = (vehiclePrice + taxAmount + dealerFees - tradeInValue - downPayment)
        .clamp(0.0, double.infinity);

    double monthlyPayment;
    if (effectiveRate <= 0) {
      monthlyPayment = termMonths > 0 ? financedAmount / termMonths : 0;
    } else {
      final r    = effectiveRate / 12 / 100;
      final powN = pow(1 + r, termMonths).toDouble();
      monthlyPayment = financedAmount * (r * powN) / (powN - 1);
    }

    // Bi-weekly: independent formula — r = effectiveRate/26/100, n = years×26
    final termYears = termMonths / 12;
    double biWeeklyPayment;
    if (effectiveRate <= 0) {
      biWeeklyPayment = financedAmount / (termYears * 26);
    } else {
      final rBi   = effectiveRate / 26 / 100;
      final nBi   = (termYears * 26).round();
      final powBi = pow(1 + rBi, nBi).toDouble();
      biWeeklyPayment = financedAmount * (rBi * powBi) / (powBi - 1);
    }

    final totalInterest = (monthlyPayment * termMonths - financedAmount).clamp(0.0, double.infinity);
    final totalCost     = vehiclePrice + taxAmount + dealerFees + totalInterest - tradeInValue;

    return USCalculation(
      vehiclePrice: vehiclePrice, tradeInValue: tradeInValue, downPayment: downPayment,
      dealerFees: dealerFees, salesTaxPercent: salesTaxPercent, annualRate: annualRate,
      termMonths: termMonths, creditScore: creditScore, taxAmount: taxAmount,
      financedAmount: financedAmount, effectiveRate: effectiveRate,
      monthlyPayment: monthlyPayment, biWeeklyPayment: biWeeklyPayment,
      totalInterest: totalInterest, totalCost: totalCost,
      isBiWeekly: isBiWeekly,
    );
  }
}
