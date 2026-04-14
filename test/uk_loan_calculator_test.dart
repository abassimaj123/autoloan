// UK Loan Calculator — Tests exhaustifs
// Référence : prix=£25,000 | down=£5,000 | 6.90% | 60 mois | VAT inclus dans prix
// BUG #2 CORRIGÉ: diesel £180 → £190 (taux 2024 standard), +dieselSurcharge/hybrid/custom

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_loan/country/uk/uk_logic.dart';
import 'package:auto_loan/features/amortization/amortization_screen.dart';

/// PMT standard : P × r(1+r)^n / ((1+r)^n − 1)
double _pmt(double p, double r, int n) {
  if (r <= 0) return n > 0 ? p / n : 0;
  final powN = pow(1 + r, n).toDouble();
  return p * (r * powN) / (powN - 1);
}

void main() {
  // ═══════════════════════════════════════════════════════════════════
  // UK — CALCUL DE BASE (CAS UK-1 : sans VED)
  // ═══════════════════════════════════════════════════════════════════
  group('UK — Calcul de base', () {
    late UKCalculation r;
    setUpAll(() => r = UKCalculation.calculate(
      vehiclePrice: 25000, downPayment: 5000,
      annualRate: 6.9, termMonths: 60,
      includeRoadTax: false,
    ));

    test('[UK-1a] Pas de taxe séparée — VAT incluse dans le prix UK', () {
      // UK: loanAmount = price - down (pas de taxe ajoutée)
      expect(r.loanAmount, closeTo(20000.00, 0.01),
          reason: '[UK-1a] 25000 − 5000 = 20000 (VAT déjà incluse)');
    });

    test('[UK-1b] VED = £0 quand includeRoadTax = false', () {
      expect(r.vedMonthly, 0.0, reason: '[UK-1b] VED désactivé → £0/mo');
      expect(r.vedTotal,   0.0, reason: '[UK-1b] VED désactivé → £0 total');
    });

    test('[UK-1c] Paiement mensuel (prêt seulement) ≈ £395.08', () {
      final expected = _pmt(20000.0, 6.9 / 12 / 100, 60);
      expect(r.baseLoanPayment, closeTo(expected, 0.01),
          reason: '[UK-1c] PMT(20000, 6.9%/12, 60) ≈ £395.08');
      expect(r.baseLoanPayment, closeTo(395.08, 0.10),
          reason: '[UK-1c] Spec attendu ≈ £395.08');
    });

    test('[UK-1d] monthlyPayment = baseLoanPayment (sans VED)', () {
      expect(r.monthlyPayment, closeTo(r.baseLoanPayment, 0.001),
          reason: '[UK-1d] Sans VED, monthlyPayment = baseLoanPayment');
    });

    test('[UK-1e] Intérêts totaux ≈ £3,704.86', () {
      final expected = r.baseLoanPayment * 60 - 20000.0;
      expect(r.totalInterest, closeTo(expected, 0.01),
          reason: '[UK-1e] totalInterest = pmt×60 − loanAmount');
      expect(r.totalInterest, closeTo(3704.86, 1.00),
          reason: '[UK-1e] Spec attendu ≈ £3,704.86');
    });

    test('[UK-1f] Coût total = prix + intérêts = £28,704.86', () {
      // totalCost = vehiclePrice + totalInterest + vedTotal (ved=0)
      final expected = 25000.0 + r.totalInterest + 0.0;
      expect(r.totalCost, closeTo(expected, 0.01),
          reason: '[UK-1f] prix + intérêts = 25000 + ~3705');
      expect(r.totalCost, closeTo(28704.86, 1.00),
          reason: '[UK-1f] Spec attendu ≈ £28,704.86');
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // UK — VED ROAD TAX (CAS UK-2 : avec VED Petrol >1000cc)
  // ═══════════════════════════════════════════════════════════════════
  group('UK — VED Road Tax', () {
    late UKCalculation rNoVed;
    late UKCalculation rWithVed;

    setUpAll(() {
      rNoVed = UKCalculation.calculate(
        vehiclePrice: 25000, downPayment: 5000,
        annualRate: 6.9, termMonths: 60,
        includeRoadTax: false,
        vehicleType: VehicleType.petrolLarge,
      );
      rWithVed = UKCalculation.calculate(
        vehiclePrice: 25000, downPayment: 5000,
        annualRate: 6.9, termMonths: 60,
        includeRoadTax: true,
        vehicleType: VehicleType.petrolLarge,
      );
    });

    test('[UK-2a] VED Petrol >1000cc = £280/yr', () {
      expect(VehicleType.petrolLarge.vedAnnual, closeTo(280.0, 0.01),
          reason: '[UK-2a] vedAnnual petrolLarge = £280');
    });

    test('[UK-2b] VED mensuel = £280 / 12 = £23.33', () {
      expect(rWithVed.vedMonthly, closeTo(280.0 / 12, 0.01),
          reason: '[UK-2b] 280/12 = £23.33/mo');
    });

    test('[UK-2c] Paiement mensuel total = prêt + VED', () {
      expect(rWithVed.monthlyPayment,
          closeTo(rWithVed.baseLoanPayment + 280.0 / 12, 0.01),
          reason: '[UK-2c] baseLoanPayment + vedMonthly');
    });

    test('[UK-2d] Total VED 60 mois = £1,400.00', () {
      expect(rWithVed.vedTotal, closeTo(1400.00, 0.01),
          reason: '[UK-2d] £280 × 5 ans = £1,400');
    });

    test('[UK-2e] Coût total avec VED = £30,104.86', () {
      final expected = 25000.0 + rWithVed.totalInterest + rWithVed.vedTotal;
      expect(rWithVed.totalCost, closeTo(expected, 0.01),
          reason: '[UK-2e] prix + intérêts + VED');
      expect(rWithVed.totalCost, closeTo(30104.86, 1.00),
          reason: '[UK-2e] Spec attendu ≈ £30,104.86');
    });

    test('[UK-2f] VED ne change pas le prêt de base', () {
      expect(rWithVed.baseLoanPayment,
          closeTo(rNoVed.baseLoanPayment, 0.001),
          reason: '[UK-2f] VED ne modifie pas baseLoanPayment');
      expect(rWithVed.loanAmount,
          closeTo(rNoVed.loanAmount, 0.001),
          reason: '[UK-2f] VED ne modifie pas loanAmount');
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // UK — TOUS LES TYPES VED (CAS UK-3)
  // Taux 2024 corrigés : diesel £190, +dieselSurcharge £590, hybrid £190, custom
  // ═══════════════════════════════════════════════════════════════════
  group('UK — Types VED', () {

    void testVed(VehicleType type, double expectedAnnual, {double? customVed}) {
      final monthly = expectedAnnual / 12;
      test('[UK-3] ${type.name} : £${expectedAnnual.toStringAsFixed(0)}/yr → £${monthly.toStringAsFixed(2)}/mo', () {
        if (type != VehicleType.custom) {
          expect(type.vedAnnual, closeTo(expectedAnnual, 0.01),
              reason: '${type.name} vedAnnual = £$expectedAnnual');
        }
        final r = UKCalculation.calculate(
          vehiclePrice: 25000, downPayment: 5000, annualRate: 6.9,
          termMonths: 60, includeRoadTax: true, vehicleType: type,
          customVedAnnual: customVed ?? 0.0,
        );
        expect(r.vedMonthly, closeTo(monthly, 0.01),
            reason: '${type.name} vedMonthly = £${monthly.toStringAsFixed(2)}');
        expect(r.vedTotal, closeTo(expectedAnnual * 5, 0.01),
            reason: '${type.name} vedTotal = £${expectedAnnual * 5} (5 ans)');
      });
    }

    testVed(VehicleType.petrolSmall,     180.0); // £180/yr → £15.00/mo
    testVed(VehicleType.petrolLarge,     280.0); // £280/yr → £23.33/mo
    testVed(VehicleType.electric,          0.0); // £0/yr   → £0.00/mo
    testVed(VehicleType.diesel,          190.0); // Standard 2024 RDE2 diesel (BUG #2 corrigé)
    testVed(VehicleType.dieselSurcharge, 590.0); // Non-RDE2 diesel surcharge
    testVed(VehicleType.hybrid,          190.0); // Hybrid = same as standard diesel 2024

    test('[UK-3-custom] Custom VED : rate fourni via customVedAnnual', () {
      const customRate = 350.0;
      final r = UKCalculation.calculate(
        vehiclePrice: 25000, downPayment: 5000, annualRate: 6.9,
        termMonths: 60, includeRoadTax: true, vehicleType: VehicleType.custom,
        customVedAnnual: customRate,
      );
      expect(r.vedMonthly, closeTo(customRate / 12, 0.01),
          reason: '[UK-3-custom] vedMonthly = £${customRate / 12}');
      expect(r.vedTotal, closeTo(customRate * 5, 0.01),
          reason: '[UK-3-custom] vedTotal = £${customRate * 5} (5 ans)');
    });

    test('[UK-3-custom-zero] Custom VED £0 sans paramètre → vedMonthly = £0', () {
      final r = UKCalculation.calculate(
        vehiclePrice: 25000, downPayment: 5000, annualRate: 6.9,
        termMonths: 60, includeRoadTax: true, vehicleType: VehicleType.custom,
      );
      expect(r.vedMonthly, 0.0, reason: '[UK-3-custom-zero] customVedAnnual défaut = 0');
    });

    test('[UK-3-elect] Électrique : VED = £0, totalCost = prix + intérêts', () {
      final r = UKCalculation.calculate(
        vehiclePrice: 25000, downPayment: 5000, annualRate: 6.9,
        termMonths: 60, includeRoadTax: true, vehicleType: VehicleType.electric,
      );
      expect(r.vedMonthly, 0.0, reason: '[UK-3-elect] £0/mo');
      expect(r.vedTotal,   0.0, reason: '[UK-3-elect] £0 total');
      expect(r.monthlyPayment, closeTo(r.baseLoanPayment, 0.001),
          reason: '[UK-3-elect] monthlyPayment = baseLoanPayment (VED=0)');
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // UK — COHÉRENCE AMORTISSEMENT (CAS UK-4)
  // ═══════════════════════════════════════════════════════════════════
  group('UK — Amortissement', () {
    const loanAmt = 20000.0, rate = 6.9, term = 60;
    late List<AmortizationRow> rows;
    late UKCalculation calc;

    setUpAll(() {
      calc = UKCalculation.calculate(
        vehiclePrice: 25000, downPayment: 5000,
        annualRate: rate, termMonths: term,
        includeRoadTax: false,
      );
      rows = buildSchedule(loanAmount: loanAmt, annualRate: rate, termMonths: term);
    });

    test('[UK-4a] Tableau a exactement 60 lignes', () {
      expect(rows.length, term, reason: '[UK-4a] 60 lignes pour 60 mois');
    });

    test('[UK-4b] Somme des principaux = £20,000.00 ± £1.00', () {
      final sum = rows.fold(0.0, (s, r) => s + r.principal);
      expect(sum, closeTo(loanAmt, 1.00),
          reason: '[UK-4b] Σ principaux ≈ £20,000');
    });

    test('[UK-4c] Somme des intérêts ≈ £3,704.86 ± £1.00', () {
      final sum = rows.fold(0.0, (s, r) => s + r.interest);
      expect(sum, closeTo(calc.totalInterest, 1.00),
          reason: '[UK-4c] Σ intérêts = totalInterest');
      expect(sum, closeTo(3704.86, 1.00),
          reason: '[UK-4c] Spec ≈ £3,704.86');
    });

    test('[UK-4d] Balance mois 60 = £0.00 ± £1.00', () {
      expect(rows.last.balance, closeTo(0.0, 1.00),
          reason: '[UK-4d] Balance finale = £0');
    });

    test('[UK-4e] Header Payment = prêt seulement (sans VED)', () {
      // Le tableau amortissement montre le paiement prêt pur
      expect(rows.first.payment, closeTo(calc.baseLoanPayment, 0.01),
          reason: '[UK-4e] row.payment = baseLoanPayment (VED séparé)');
    });

    test('[UK-4f] Mois 1 : intérêt = 20000 × 6.9%/12 ≈ £115.00', () {
      final interest1 = 20000.0 * (6.9 / 12 / 100);
      expect(rows.first.interest, closeTo(interest1, 0.10),
          reason: '[UK-4f] 20000 × 0.575% ≈ £115.00');
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // CAS LIMITES UK (CAS UK-5)
  // ═══════════════════════════════════════════════════════════════════
  group('Cas limites UK', () {

    test('[UK-5a] Down Payment = £0 → loanAmount = vehiclePrice', () {
      final r = UKCalculation.calculate(
        vehiclePrice: 25000, downPayment: 0, annualRate: 6.9,
        termMonths: 60, includeRoadTax: false,
      );
      expect(r.loanAmount, closeTo(25000.0, 0.01),
          reason: '[UK-5a] Pas de mise de fonds → loan = prix entier');
    });

    test('[UK-5b] Down Payment = Prix → loanAmount = £0', () {
      final r = UKCalculation.calculate(
        vehiclePrice: 25000, downPayment: 25000, annualRate: 6.9,
        termMonths: 60, includeRoadTax: false,
      );
      expect(r.loanAmount, closeTo(0.0, 0.01),
          reason: '[UK-5b] down = prix → loan = £0');
      expect(r.totalInterest, 0.0,
          reason: '[UK-5b] Pas d\'intérêts si loan = £0');
    });

    test('[UK-5c] Taux 0.99% — paiement correct', () {
      final r = UKCalculation.calculate(
        vehiclePrice: 25000, downPayment: 5000, annualRate: 0.99,
        termMonths: 60, includeRoadTax: false,
      );
      expect(r.baseLoanPayment,
          closeTo(_pmt(20000.0, 0.99 / 12 / 100, 60), 0.01),
          reason: '[UK-5c] PMT(20000, 0.99%/12, 60)');
      expect(r.totalInterest, greaterThan(0),
          reason: '[UK-5c] Intérêts > 0 même à 0.99%');
    });

    test('[UK-5d] Taux 19.99% — intérêts élevés', () {
      final r = UKCalculation.calculate(
        vehiclePrice: 25000, downPayment: 5000, annualRate: 19.99,
        termMonths: 60, includeRoadTax: false,
      );
      expect(r.baseLoanPayment,
          closeTo(_pmt(20000.0, 19.99 / 12 / 100, 60), 0.01),
          reason: '[UK-5d] PMT(20000, 19.99%/12, 60)');
      expect(r.totalInterest, greaterThan(r.loanAmount * 0.5),
          reason: '[UK-5d] Intérêts > 50% du capital à 19.99%');
    });

    test('[UK-5e] Durée 24 mois — paiement mensuel', () {
      final r = UKCalculation.calculate(
        vehiclePrice: 25000, downPayment: 5000, annualRate: 6.9,
        termMonths: 24, includeRoadTax: false,
      );
      expect(r.baseLoanPayment,
          closeTo(_pmt(20000.0, 6.9 / 12 / 100, 24), 0.01),
          reason: '[UK-5e] PMT(20000, 6.9%/12, 24)');
    });

    test('[UK-5f] Durée 84 mois — paiement plus bas que 24 mois', () {
      final r24 = UKCalculation.calculate(
        vehiclePrice: 25000, downPayment: 5000, annualRate: 6.9,
        termMonths: 24, includeRoadTax: false,
      );
      final r84 = UKCalculation.calculate(
        vehiclePrice: 25000, downPayment: 5000, annualRate: 6.9,
        termMonths: 84, includeRoadTax: false,
      );
      expect(r84.baseLoanPayment, lessThan(r24.baseLoanPayment),
          reason: '[UK-5f] 7 ans → pmt < 2 ans');
    });

    test('[UK-5g] VED Total = vedAnnual × (termMonths/12)', () {
      const annualVed = 280.0;
      const term = 48;
      final r = UKCalculation.calculate(
        vehiclePrice: 25000, downPayment: 5000, annualRate: 6.9,
        termMonths: term, includeRoadTax: true,
        vehicleType: VehicleType.petrolLarge,
      );
      expect(r.vedTotal, closeTo(annualVed * term / 12, 0.01),
          reason: '[UK-5g] VED total = £280 × 4 ans = £1,120 (48 mois)');
    });

    test('[UK-5h] Taux 0% — paiement = loanAmount / terme', () {
      final r = UKCalculation.calculate(
        vehiclePrice: 25000, downPayment: 5000, annualRate: 0,
        termMonths: 60, includeRoadTax: false,
      );
      expect(r.totalInterest, 0.0, reason: '[UK-5h] Pas d\'intérêt à 0%');
      expect(r.baseLoanPayment, closeTo(20000.0 / 60, 0.01),
          reason: '[UK-5h] pmt = 20000/60 à 0%');
    });

    test('[UK-5i] Down Payment excessif → loanAmount clampé à £0', () {
      final r = UKCalculation.calculate(
        vehiclePrice: 10000, downPayment: 99999, annualRate: 6.9,
        termMonths: 60, includeRoadTax: false,
      );
      expect(r.loanAmount, 0.0,
          reason: '[UK-5i] loanAmount ne peut être négatif');
    });
  });
}
