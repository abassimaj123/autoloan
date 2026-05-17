import 'dart:math';

/// UK Vehicle Excise Duty (VED / Road Tax) types and annual rates
enum VehicleType {
  petrolSmall,
  petrolLarge,
  electric,
  diesel,
  dieselSurcharge,
  hybrid,
  custom,
}

extension VehicleTypeExt on VehicleType {
  String get label {
    switch (this) {
      case VehicleType.petrolSmall:
        return 'Petrol < 1000cc (£180/yr)';
      case VehicleType.petrolLarge:
        return 'Petrol > 1000cc (£280/yr)';
      case VehicleType.electric:
        return 'Electric (£0/yr)';
      case VehicleType.diesel:
        return 'Diesel RDE2 (£190/yr)';
      case VehicleType.dieselSurcharge:
        return 'Diesel non-RDE2 (£590/yr)';
      case VehicleType.hybrid:
        return 'Hybrid (£190/yr)';
      case VehicleType.custom:
        return 'Custom VED rate';
    }
  }

  /// Annual VED rate in GBP (fixed rate; use [UKCalculation.calculate] customVedAnnual for custom)
  double get vedAnnual {
    switch (this) {
      case VehicleType.petrolSmall:
        return 180.0;
      case VehicleType.petrolLarge:
        return 280.0;
      case VehicleType.electric:
        return 0.0;
      case VehicleType.diesel:
        return 190.0; // Standard 2024 rate (RDE2-compliant)
      case VehicleType.dieselSurcharge:
        return 590.0; // Surcharge for non-RDE2 diesel
      case VehicleType.hybrid:
        return 190.0;
      case VehicleType.custom:
        return 0.0; // Rate supplied via customVedAnnual param
    }
  }
}

class UKCalculation {
  final double vehiclePrice, downPayment, annualRate;
  final int termMonths;
  final bool includeRoadTax, isBiWeekly;
  final VehicleType vehicleType;

  /// Amount borrowed (VAT already included in UK vehicle price)
  final double loanAmount;

  /// Pure loan amortization payment (without VED)
  final double baseLoanPayment;

  /// Bi-weekly loan payment (without VED)
  final double biWeeklyLoanPayment;

  /// Total monthly payment = baseLoanPayment + vedMonthly
  final double monthlyPayment;

  /// Total bi-weekly payment = biWeeklyLoanPayment + vedBiWeekly
  final double biWeeklyPayment;

  /// Display payment depending on isBiWeekly
  double get displayPayment => isBiWeekly ? biWeeklyPayment : monthlyPayment;

  /// VED monthly instalment (vedAnnual / 12), 0 if not included
  final double vedMonthly;

  /// VED bi-weekly instalment (vedAnnual / 26), 0 if not included
  double get vedBiWeekly => vedMonthly * 12 / 26;

  /// Total VED over loan term (vedAnnual × termMonths / 12)
  final double vedTotal;

  final double totalInterest, totalCost;

  // PCP fields
  final bool isPcp;
  final double gmfvAmount; // Guaranteed Minimum Future Value in £
  final double gmfvPercent; // GMFV as % of vehicle price
  /// Total cost if user pays GMFV at end of PCP contract
  final double pcpTotalIfBuy;

  const UKCalculation({
    required this.vehiclePrice,
    required this.downPayment,
    required this.annualRate,
    required this.termMonths,
    required this.includeRoadTax,
    required this.vehicleType,
    required this.loanAmount,
    required this.baseLoanPayment,
    required this.monthlyPayment,
    required this.biWeeklyLoanPayment,
    required this.biWeeklyPayment,
    required this.vedMonthly,
    required this.vedTotal,
    required this.totalInterest,
    required this.totalCost,
    this.isBiWeekly = false,
    this.isPcp = false,
    this.gmfvAmount = 0,
    this.gmfvPercent = 0,
    this.pcpTotalIfBuy = 0,
  });

  static UKCalculation calculate({
    required double vehiclePrice,
    required double downPayment,
    required double annualRate,
    required int termMonths,
    bool includeRoadTax = false,
    VehicleType vehicleType = VehicleType.petrolLarge,
    double customVedAnnual = 0.0,
    bool isPcp = false,
    double gmfvPercent = 30.0,
    bool isBiWeekly = false,
  }) {
    // UK: VAT already included in advertised price — no separate tax to add
    final loanAmount = (vehiclePrice - downPayment).clamp(0.0, double.infinity);
    final gmfvAmount = isPcp ? vehiclePrice * gmfvPercent / 100 : 0.0;

    double baseLoanPayment;
    if (!isPcp) {
      // Standard loan
      if (annualRate <= 0) {
        baseLoanPayment = termMonths > 0 ? loanAmount / termMonths : 0;
      } else {
        final r = annualRate / 12 / 100;
        final powN = pow(1 + r, termMonths).toDouble();
        baseLoanPayment = loanAmount * (r * powN) / (powN - 1);
      }
    } else {
      // PCP: balloon formula — monthly payment on (loanAmount - PV of GMFV)
      if (annualRate <= 0) {
        baseLoanPayment = termMonths > 0
            ? (loanAmount - gmfvAmount) / termMonths
            : 0;
      } else {
        final r = annualRate / 12 / 100;
        final powN = pow(1 + r, termMonths).toDouble();
        // Present value of GMFV
        final pvGmfv = gmfvAmount / powN;
        baseLoanPayment = (loanAmount - pvGmfv) * (r * powN) / (powN - 1);
      }
    }

    // Bi-weekly loan payment
    final nBi = (termMonths / 12 * 26).round();
    double biWeeklyLoanPayment;
    if (!isPcp) {
      if (annualRate <= 0) {
        biWeeklyLoanPayment = nBi > 0 ? loanAmount / nBi : 0;
      } else {
        final rBi = annualRate / 26 / 100;
        final powBi = pow(1 + rBi, nBi).toDouble();
        biWeeklyLoanPayment = loanAmount * (rBi * powBi) / (powBi - 1);
      }
    } else {
      if (annualRate <= 0) {
        biWeeklyLoanPayment = nBi > 0 ? (loanAmount - gmfvAmount) / nBi : 0;
      } else {
        final rBi = annualRate / 26 / 100;
        final powBi = pow(1 + rBi, nBi).toDouble();
        final pvGmfv =
            gmfvAmount / pow(1 + annualRate / 12 / 100, termMonths).toDouble();
        biWeeklyLoanPayment =
            (loanAmount - pvGmfv) * (rBi * powBi) / (powBi - 1);
      }
    }

    final vedAnnual = includeRoadTax
        ? (vehicleType == VehicleType.custom
              ? customVedAnnual
              : vehicleType.vedAnnual)
        : 0.0;
    final vedMonthly = vedAnnual / 12;
    final vedBiWeekly = vedAnnual / 26;
    final vedTotal = vedAnnual * termMonths / 12;
    final monthlyPayment = baseLoanPayment + vedMonthly;
    final biWeeklyPayment = biWeeklyLoanPayment + vedBiWeekly;
    final totalInterest = isPcp
        ? (baseLoanPayment * termMonths + gmfvAmount - loanAmount).clamp(
            0.0,
            double.infinity,
          )
        : (baseLoanPayment * termMonths - loanAmount).clamp(
            0.0,
            double.infinity,
          );

    // Standard: totalCost = vehiclePrice + interest + vedTotal
    // PCP: totalCost = payments during term + vedTotal (not including GMFV — user may return)
    final totalCost = vehiclePrice + totalInterest + vedTotal;
    // PCP: cost if buying at end = downPayment + all monthly payments + GMFV
    final pcpTotalIfBuy = isPcp
        ? downPayment + baseLoanPayment * termMonths + gmfvAmount + vedTotal
        : 0.0;

    return UKCalculation(
      vehiclePrice: vehiclePrice,
      downPayment: downPayment,
      annualRate: annualRate,
      termMonths: termMonths,
      includeRoadTax: includeRoadTax,
      vehicleType: vehicleType,
      loanAmount: loanAmount,
      baseLoanPayment: baseLoanPayment,
      monthlyPayment: monthlyPayment,
      biWeeklyLoanPayment: biWeeklyLoanPayment,
      biWeeklyPayment: biWeeklyPayment,
      vedMonthly: vedMonthly,
      vedTotal: vedTotal,
      totalInterest: totalInterest,
      totalCost: totalCost,
      isBiWeekly: isBiWeekly,
      isPcp: isPcp,
      gmfvAmount: gmfvAmount,
      gmfvPercent: gmfvPercent,
      pcpTotalIfBuy: pcpTotalIfBuy,
    );
  }
}

// ── UK TCO Calculation ─────────────────────────────────────────────────────────

class UKTcoCalculation {
  final double annualMiles;
  final double mpg;
  final double fuelPricePencePerLitre;
  final double annualInsurance;
  final double annualMot;
  final int termMonths;

  final double totalFuel;
  final double totalInsurance;
  final double totalMot;
  final double totalVed;
  final double totalInterest;
  final double grandTotal;

  const UKTcoCalculation({
    required this.annualMiles,
    required this.mpg,
    required this.fuelPricePencePerLitre,
    required this.annualInsurance,
    required this.annualMot,
    required this.termMonths,
    required this.totalFuel,
    required this.totalInsurance,
    required this.totalMot,
    required this.totalVed,
    required this.totalInterest,
    required this.grandTotal,
  });

  /// [fuelPricePencePerLitre] — pence per litre (e.g. 148.0 for 148p/L)
  /// [annualMiles] — miles driven per year
  /// [mpg] — miles per gallon (UK imperial: 1 gallon = 4.54609 L)
  static UKTcoCalculation calculate({
    required double annualMiles,
    required double mpg,
    required double fuelPricePencePerLitre,
    required double annualInsurance,
    required double annualMot,
    required int termMonths,
    required double totalInterest,
    required double totalVed,
  }) {
    const litresPerGallon = 4.54609;
    final termYears = termMonths / 12;
    // Annual fuel cost in £: (miles / mpg) gallons × litresPerGallon × (pence/L / 100)
    final annualFuelCost = mpg > 0
        ? (annualMiles / mpg) * litresPerGallon * (fuelPricePencePerLitre / 100)
        : 0.0;
    final totalFuel = annualFuelCost * termYears;
    final totalInsurance = annualInsurance * termYears;
    final totalMot = annualMot * termYears;
    final grandTotal =
        totalFuel + totalInsurance + totalMot + totalVed + totalInterest;

    return UKTcoCalculation(
      annualMiles: annualMiles,
      mpg: mpg,
      fuelPricePencePerLitre: fuelPricePencePerLitre,
      annualInsurance: annualInsurance,
      annualMot: annualMot,
      termMonths: termMonths,
      totalFuel: totalFuel,
      totalInsurance: totalInsurance,
      totalMot: totalMot,
      totalVed: totalVed,
      totalInterest: totalInterest,
      grandTotal: grandTotal,
    );
  }
}
