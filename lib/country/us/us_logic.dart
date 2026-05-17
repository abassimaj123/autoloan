import 'dart:math';

enum CreditScore { excellent, good, fair, poor }

extension CreditScoreExt on CreditScore {
  String get label {
    switch (this) {
      case CreditScore.excellent:
        return 'Excellent (750+)';
      case CreditScore.good:
        return 'Good (700–749)';
      case CreditScore.fair:
        return 'Fair (650–699)';
      case CreditScore.poor:
        return 'Poor (<650)';
    }
  }

  double get rateAdjustment {
    switch (this) {
      case CreditScore.excellent:
        return -1.5;
      case CreditScore.good:
        return -0.5;
      case CreditScore.fair:
        return 0.0;
      case CreditScore.poor:
        return 2.0;
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
    required this.vehiclePrice,
    required this.tradeInValue,
    required this.downPayment,
    required this.dealerFees,
    required this.salesTaxPercent,
    required this.annualRate,
    required this.termMonths,
    required this.creditScore,
    required this.taxAmount,
    required this.financedAmount,
    required this.effectiveRate,
    required this.monthlyPayment,
    required this.biWeeklyPayment,
    required this.totalInterest,
    required this.totalCost,
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
    final effectiveRate = (annualRate + creditScore.rateAdjustment).clamp(
      0.0,
      30.0,
    );
    final taxAmount = vehiclePrice * salesTaxPercent / 100;
    final financedAmount =
        (vehiclePrice + taxAmount + dealerFees - tradeInValue - downPayment)
            .clamp(0.0, double.infinity);

    double monthlyPayment;
    if (effectiveRate <= 0) {
      monthlyPayment = termMonths > 0 ? financedAmount / termMonths : 0;
    } else {
      final r = effectiveRate / 12 / 100;
      final powN = pow(1 + r, termMonths).toDouble();
      monthlyPayment = financedAmount * (r * powN) / (powN - 1);
    }

    // Bi-weekly: independent formula — r = effectiveRate/26/100, n = years×26
    final termYears = termMonths / 12;
    double biWeeklyPayment;
    if (effectiveRate <= 0) {
      biWeeklyPayment = financedAmount / (termYears * 26);
    } else {
      final rBi = effectiveRate / 26 / 100;
      final nBi = (termYears * 26).round();
      final powBi = pow(1 + rBi, nBi).toDouble();
      biWeeklyPayment = financedAmount * (rBi * powBi) / (powBi - 1);
    }

    final totalInterest = isBiWeekly
        ? (biWeeklyPayment * (termYears * 26).round() - financedAmount).clamp(
            0.0,
            double.infinity,
          )
        : (monthlyPayment * termMonths - financedAmount).clamp(
            0.0,
            double.infinity,
          );
    final totalCost =
        vehiclePrice + taxAmount + dealerFees + totalInterest - tradeInValue;

    return USCalculation(
      vehiclePrice: vehiclePrice,
      tradeInValue: tradeInValue,
      downPayment: downPayment,
      dealerFees: dealerFees,
      salesTaxPercent: salesTaxPercent,
      annualRate: annualRate,
      termMonths: termMonths,
      creditScore: creditScore,
      taxAmount: taxAmount,
      financedAmount: financedAmount,
      effectiveRate: effectiveRate,
      monthlyPayment: monthlyPayment,
      biWeeklyPayment: biWeeklyPayment,
      totalInterest: totalInterest,
      totalCost: totalCost,
      isBiWeekly: isBiWeekly,
    );
  }
}

// ── US Lease Calculation ───────────────────────────────────────────────────────

class USLeaseCalculation {
  final double vehiclePrice;
  final double capCostReduction; // cash down on lease
  final double acquisitionFee;
  final double residualPercent;
  final double residualValue;
  final double moneyFactor;
  final int leaseTerm;
  final double adjCapCost; // vehicle_price - capCostReduction - downPayment
  final double monthlyLease;
  final double totalLeaseCost;

  const USLeaseCalculation({
    required this.vehiclePrice,
    required this.capCostReduction,
    required this.acquisitionFee,
    required this.residualPercent,
    required this.residualValue,
    required this.moneyFactor,
    required this.leaseTerm,
    required this.adjCapCost,
    required this.monthlyLease,
    required this.totalLeaseCost,
  });

  static USLeaseCalculation calculate({
    required double vehiclePrice,
    required double downPayment,
    required double capCostReduction,
    required double acquisitionFee,
    required double residualPercent,
    required double moneyFactor,
    required int leaseTerm,
  }) {
    final residualValue = vehiclePrice * residualPercent / 100;
    final adjCapCost = vehiclePrice - capCostReduction - downPayment;
    // Lease payment formula
    final monthlyLease =
        (adjCapCost - residualValue + acquisitionFee) / leaseTerm +
        (adjCapCost + residualValue) * moneyFactor;
    final totalLeaseCost = monthlyLease * leaseTerm;
    return USLeaseCalculation(
      vehiclePrice: vehiclePrice,
      capCostReduction: capCostReduction,
      acquisitionFee: acquisitionFee,
      residualPercent: residualPercent,
      residualValue: residualValue,
      moneyFactor: moneyFactor,
      leaseTerm: leaseTerm,
      adjCapCost: adjCapCost,
      monthlyLease: monthlyLease,
      totalLeaseCost: totalLeaseCost,
    );
  }
}

// ── US Refi Calculation ────────────────────────────────────────────────────────

class USRefiCalculation {
  final double currentBalance;
  final double currentRate;
  final int currentMonthsRemaining;
  final double newRate;
  final int newTermMonths;

  final double currentMonthly;
  final double newMonthly;
  final double monthlySavings;
  final double currentTotalInterest;
  final double newTotalInterest;
  final double totalInterestSavings;
  final int breakevenMonths; // months to recoup any refinancing costs
  final bool isWorthIt; // simple heuristic: saves money before new term ends

  const USRefiCalculation({
    required this.currentBalance,
    required this.currentRate,
    required this.currentMonthsRemaining,
    required this.newRate,
    required this.newTermMonths,
    required this.currentMonthly,
    required this.newMonthly,
    required this.monthlySavings,
    required this.currentTotalInterest,
    required this.newTotalInterest,
    required this.totalInterestSavings,
    required this.breakevenMonths,
    required this.isWorthIt,
  });

  static USRefiCalculation calculate({
    required double currentBalance,
    required double currentRate,
    required int currentMonthsRemaining,
    required double newRate,
    required int newTermMonths,
    double refiCosts = 0,
  }) {
    double calcPmt(double balance, double annualRate, int n) {
      if (annualRate <= 0) return n > 0 ? balance / n : 0;
      final r = annualRate / 12 / 100;
      final powN = pow(1 + r, n).toDouble();
      return balance * (r * powN) / (powN - 1);
    }

    final currentMonthly = calcPmt(
      currentBalance,
      currentRate,
      currentMonthsRemaining,
    );
    final newMonthly = calcPmt(currentBalance, newRate, newTermMonths);
    final monthlySavings = currentMonthly - newMonthly;

    final currentTotalInterest =
        (currentMonthly * currentMonthsRemaining - currentBalance).clamp(
          0.0,
          double.infinity,
        );
    final newTotalInterest = (newMonthly * newTermMonths - currentBalance)
        .clamp(0.0, double.infinity);
    final totalInterestSavings = currentTotalInterest - newTotalInterest;

    final breakevenMonths = monthlySavings > 0 && refiCosts > 0
        ? (refiCosts / monthlySavings).ceil()
        : 0;
    final isWorthIt = totalInterestSavings > 0 && monthlySavings >= 0;

    return USRefiCalculation(
      currentBalance: currentBalance,
      currentRate: currentRate,
      currentMonthsRemaining: currentMonthsRemaining,
      newRate: newRate,
      newTermMonths: newTermMonths,
      currentMonthly: currentMonthly,
      newMonthly: newMonthly,
      monthlySavings: monthlySavings,
      currentTotalInterest: currentTotalInterest,
      newTotalInterest: newTotalInterest,
      totalInterestSavings: totalInterestSavings,
      breakevenMonths: breakevenMonths,
      isWorthIt: isWorthIt,
    );
  }
}

// ── US TCO Calculation ─────────────────────────────────────────────────────────

class USTcoCalculation {
  final double annualMiles;
  final double mpg;
  final double gasPricePerGallon;
  final double annualInsurance;
  final double annualMaintenance;
  final int termMonths;

  final double totalGas;
  final double totalInsurance;
  final double totalMaintenance;
  final double totalInterest;
  final double netVehicleCost;
  final double grandTotal;

  const USTcoCalculation({
    required this.annualMiles,
    required this.mpg,
    required this.gasPricePerGallon,
    required this.annualInsurance,
    required this.annualMaintenance,
    required this.termMonths,
    required this.totalGas,
    required this.totalInsurance,
    required this.totalMaintenance,
    required this.totalInterest,
    required this.netVehicleCost,
    required this.grandTotal,
  });

  static USTcoCalculation calculate({
    required double annualMiles,
    required double mpg,
    required double gasPricePerGallon,
    required double annualInsurance,
    required double annualMaintenance,
    required int termMonths,
    required double totalInterest,
    required double vehiclePrice,
    required double tradeInValue,
    required double downPayment,
  }) {
    final termYears = termMonths / 12;
    final double totalGas = mpg > 0
        ? (annualMiles / mpg) * gasPricePerGallon * termYears
        : 0.0;
    final totalInsurance = annualInsurance * termYears;
    final totalMaintenance = annualMaintenance * termYears;
    // TCO = all money the user spends to own the vehicle over the term.
    // downPayment is NOT subtracted here — the user already paid it, so it IS
    // part of total cost.  Only tradeInValue reduces cost (it offsets the price).
    final netVehicleCost = vehiclePrice - tradeInValue;
    final grandTotal =
        totalGas +
        totalInsurance +
        totalMaintenance +
        totalInterest +
        netVehicleCost;
    return USTcoCalculation(
      annualMiles: annualMiles,
      mpg: mpg,
      gasPricePerGallon: gasPricePerGallon,
      annualInsurance: annualInsurance,
      annualMaintenance: annualMaintenance,
      termMonths: termMonths,
      totalGas: totalGas,
      totalInsurance: totalInsurance,
      totalMaintenance: totalMaintenance,
      totalInterest: totalInterest,
      netVehicleCost: netVehicleCost,
      grandTotal: grandTotal,
    );
  }
}
