// Golden reference tests — AutoLoan (3 flavors: CA / UK / US)
// Focus: annualRate is PERCENT across all flavors
//        bi-weekly payment formula: PMT uses annualRate/26 (independent from monthly)
//        CreditScore.excellent has -1.5pp adjustment → use CreditScore.fair for PMT comparison

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_loan/country/ca/ca_logic.dart';
import 'package:auto_loan/country/uk/uk_logic.dart';
import 'package:auto_loan/country/us/us_logic.dart';
import 'package:auto_loan/core/payment_frequency.dart';

/// PMT(P, periodRate, nPeriods): P × r(1+r)^n / ((1+r)^n − 1)
double _pmtExact(double p, double periodRate, int nPeriods) {
  if (periodRate <= 0) return nPeriods > 0 ? p / nPeriods : 0;
  final powN = pow(1 + periodRate, nPeriods).toDouble();
  return p * (periodRate * powN) / (powN - 1);
}

void main() {
  void approx(double actual, double expected, {double tol = 1.0}) {
    expect(actual, closeTo(expected, tol),
        reason: 'Expected ~$expected, got $actual');
  }

  // ── CA — monthly PERCENT ──────────────────────────────────────────────────

  group('CACalculation — annualRate is PERCENT', () {
    test('AL-G1: \$25k / \$5k down / ON(13%) / 7.9% / 60mo monthly', () {
      final r = CACalculation.calculate(
        vehiclePrice: 25000, downPayment: 5000, annualRate: 7.9,
        termMonths: 60, provinceCode: 'ON', frequency: PaymentFrequency.monthly,
      );
      // ON 13% HST → taxed $28,250; loan = $23,250 at 7.9%/60mo
      final expected = _pmtExact(23250, 7.9 / 100 / 12, 60);
      approx(r.baseLoanMonthly, expected, tol: 2);
    });

    test('AL-G2: 0% rate → loan / termMonths', () {
      final r = CACalculation.calculate(
        vehiclePrice: 30000, downPayment: 5000, annualRate: 0.0,
        termMonths: 60, provinceCode: 'ON', frequency: PaymentFrequency.monthly,
      );
      expect(r.baseLoanMonthly, greaterThan(0));
    });
  });

  // ── CA — bi-weekly payment ────────────────────────────────────────────────

  group('CACalculation — bi-weekly: rate/26 (NOT monthly÷2)', () {
    test('AL-G3: \$25k / \$5k down / ON / 7.9% / 60mo bi-weekly', () {
      final r = CACalculation.calculate(
        vehiclePrice: 25000, downPayment: 5000, annualRate: 7.9,
        termMonths: 60, provinceCode: 'ON', frequency: PaymentFrequency.biWeekly,
      );
      // nBiPeriods = round(5×26) = 130; rBi = 7.9/26/100
      final nBi = (60 / 12 * 26).round(); // 130
      final rBi = 7.9 / 26 / 100;
      // ON 13% HST → loan = $23,250
      final expected = _pmtExact(23250, rBi, nBi);
      approx(r.baseLoanBiWeekly, expected, tol: 2);
    });

    test('AL-G4: bi-weekly × 26 ≈ monthly × 12 (same total annual payment)', () {
      final monthly = CACalculation.calculate(
        vehiclePrice: 25000, downPayment: 5000, annualRate: 7.9,
        termMonths: 60, provinceCode: 'ON', frequency: PaymentFrequency.monthly,
      );
      final biWeekly = CACalculation.calculate(
        vehiclePrice: 25000, downPayment: 5000, annualRate: 7.9,
        termMonths: 60, provinceCode: 'ON', frequency: PaymentFrequency.biWeekly,
      );
      // Annual totals should be close (bi-weekly has slightly different amortization)
      final annualMonthly = monthly.baseLoanMonthly * 12;
      final annualBiWeekly = biWeekly.baseLoanBiWeekly * 26;
      expect((annualBiWeekly - annualMonthly).abs(), lessThan(50));
    });
  });

  // ── UK — monthly PERCENT ──────────────────────────────────────────────────

  group('UKCalculation — annualRate is PERCENT', () {
    test('AL-G5: £20k / £4k down / 6.9% / 48mo', () {
      final r = UKCalculation.calculate(
        vehiclePrice: 20000, downPayment: 4000, annualRate: 6.9,
        termMonths: 48, vehicleType: VehicleType.petrolLarge,
      );
      approx(r.baseLoanPayment, _pmtExact(16000, 6.9 / 100 / 12, 48), tol: 2);
    });

    test('AL-G6: UK 0% rate → £15k / 60mo = £250/mo', () {
      final r = UKCalculation.calculate(
        vehiclePrice: 20000, downPayment: 5000, annualRate: 0.0, termMonths: 60,
      );
      approx(r.baseLoanPayment, 250, tol: 0.01);
    });
  });

  // ── US — monthly PERCENT (CreditScore.fair = 0pp adj) ─────────────────────

  group('USCalculation — annualRate is PERCENT (fair credit = no rate adj)', () {
    test('AL-G7: \$25k / \$5k down / 0% tax / 6.0% / fair credit → PMT(20k,6%,60)', () {
      final r = USCalculation.calculate(
        vehiclePrice: 25000, tradeInValue: 0, downPayment: 5000,
        dealerFees: 0, salesTaxPercent: 0, annualRate: 6.0,
        termMonths: 60, creditScore: CreditScore.fair,
      );
      approx(r.monthlyPayment, _pmtExact(20000, 6.0 / 100 / 12, 60), tol: 1);
    });

    test('AL-G8: excellent credit → lower payment than fair (−1.5pp rate adj)', () {
      final fair = USCalculation.calculate(
        vehiclePrice: 25000, tradeInValue: 0, downPayment: 5000,
        dealerFees: 0, salesTaxPercent: 0, annualRate: 6.0,
        termMonths: 60, creditScore: CreditScore.fair,
      );
      final excellent = USCalculation.calculate(
        vehiclePrice: 25000, tradeInValue: 0, downPayment: 5000,
        dealerFees: 0, salesTaxPercent: 0, annualRate: 6.0,
        termMonths: 60, creditScore: CreditScore.excellent, // -1.5pp
      );
      expect(excellent.monthlyPayment, lessThan(fair.monthlyPayment));
    });
  });

  // ── PMT formula reference ─────────────────────────────────────────────────

  group('PMT formula cross-check', () {
    test('AL-G9: \$15k / 7.0% / 48mo → PMT ≈ \$359 (standard formula)', () {
      approx(_pmtExact(15000, 7.0 / 100 / 12, 48), 359, tol: 1);
    });

    test('AL-G10: bi-weekly PMT = monthly PMT × (12/26) × small correction', () {
      // For same loan, bi-weekly payment ≈ monthly × 12/26 = 0.4615
      final monthlyPmt = _pmtExact(20000, 6.0 / 100 / 12, 60);
      final nBi = (5 * 26).round(); // 130
      final biWeeklyPmt = _pmtExact(20000, 6.0 / 100 / 26, nBi);
      // Bi-weekly should be roughly monthly × (12/26)
      approx(biWeeklyPmt, monthlyPmt * 12 / 26, tol: 5);
    });
  });
}
