import 'dart:math';

/// UK Vehicle Excise Duty (VED / Road Tax) types and annual rates
enum VehicleType { petrolSmall, petrolLarge, electric, diesel, dieselSurcharge, hybrid, custom }

extension VehicleTypeExt on VehicleType {
  String get label {
    switch (this) {
      case VehicleType.petrolSmall:     return 'Petrol < 1000cc (£180/yr)';
      case VehicleType.petrolLarge:     return 'Petrol > 1000cc (£280/yr)';
      case VehicleType.electric:        return 'Electric (£0/yr)';
      case VehicleType.diesel:          return 'Diesel RDE2 (£190/yr)';
      case VehicleType.dieselSurcharge: return 'Diesel non-RDE2 (£590/yr)';
      case VehicleType.hybrid:          return 'Hybrid (£190/yr)';
      case VehicleType.custom:          return 'Custom VED rate';
    }
  }

  /// Annual VED rate in GBP (fixed rate; use [UKCalculation.calculate] customVedAnnual for custom)
  double get vedAnnual {
    switch (this) {
      case VehicleType.petrolSmall:     return 180.0;
      case VehicleType.petrolLarge:     return 280.0;
      case VehicleType.electric:        return 0.0;
      case VehicleType.diesel:          return 190.0; // Standard 2024 rate (RDE2-compliant)
      case VehicleType.dieselSurcharge: return 590.0; // Surcharge for non-RDE2 diesel
      case VehicleType.hybrid:          return 190.0;
      case VehicleType.custom:          return 0.0;   // Rate supplied via customVedAnnual param
    }
  }
}

class UKCalculation {
  final double vehiclePrice, downPayment, annualRate;
  final int termMonths;
  final bool includeRoadTax;
  final VehicleType vehicleType;

  /// Amount borrowed (VAT already included in UK vehicle price)
  final double loanAmount;

  /// Pure loan amortization payment (without VED)
  final double baseLoanPayment;

  /// Total monthly payment = baseLoanPayment + vedMonthly
  final double monthlyPayment;

  /// VED monthly instalment (vedAnnual / 12), 0 if not included
  final double vedMonthly;

  /// Total VED over loan term (vedAnnual × termMonths / 12)
  final double vedTotal;

  final double totalInterest, totalCost;

  const UKCalculation({
    required this.vehiclePrice, required this.downPayment, required this.annualRate,
    required this.termMonths, required this.includeRoadTax, required this.vehicleType,
    required this.loanAmount, required this.baseLoanPayment, required this.monthlyPayment,
    required this.vedMonthly, required this.vedTotal,
    required this.totalInterest, required this.totalCost,
  });

  static UKCalculation calculate({
    required double vehiclePrice,
    required double downPayment,
    required double annualRate,
    required int termMonths,
    bool includeRoadTax = false,
    VehicleType vehicleType = VehicleType.petrolLarge,
    double customVedAnnual = 0.0,
  }) {
    // UK: VAT already included in advertised price — no separate tax to add
    final loanAmount = (vehiclePrice - downPayment).clamp(0.0, double.infinity);

    double baseLoanPayment;
    if (annualRate <= 0) {
      baseLoanPayment = termMonths > 0 ? loanAmount / termMonths : 0;
    } else {
      final r    = annualRate / 12 / 100;
      final powN = pow(1 + r, termMonths).toDouble();
      baseLoanPayment = loanAmount * (r * powN) / (powN - 1);
    }

    final vedAnnual    = includeRoadTax
        ? (vehicleType == VehicleType.custom ? customVedAnnual : vehicleType.vedAnnual)
        : 0.0;
    final vedMonthly   = vedAnnual / 12;
    final vedTotal     = vedAnnual * termMonths / 12;
    final monthlyPayment = baseLoanPayment + vedMonthly;
    final totalInterest  = (baseLoanPayment * termMonths - loanAmount).clamp(0.0, double.infinity);

    // totalCost = vehiclePrice (includes downPayment) + interest + road tax over term
    // = loanAmount + totalInterest + vedTotal + downPayment
    final totalCost = vehiclePrice + totalInterest + vedTotal;

    return UKCalculation(
      vehiclePrice: vehiclePrice, downPayment: downPayment, annualRate: annualRate,
      termMonths: termMonths, includeRoadTax: includeRoadTax, vehicleType: vehicleType,
      loanAmount: loanAmount, baseLoanPayment: baseLoanPayment, monthlyPayment: monthlyPayment,
      vedMonthly: vedMonthly, vedTotal: vedTotal,
      totalInterest: totalInterest, totalCost: totalCost,
    );
  }
}
