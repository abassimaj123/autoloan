// Comprehensive formula validation tests for AutoLoan
// Test data: CA — $30,000 vehicle, ON province (13%), $5,000 down, 7.90%, 60 months
// Ref: https://en.wikipedia.org/wiki/Mortgage_calculator#Monthly_payment_formula

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_loan/core/payment_frequency.dart';
import 'package:auto_loan/country/ca/ca_logic.dart';
import 'package:auto_loan/country/us/us_logic.dart';
import 'package:auto_loan/country/uk/uk_logic.dart';

void main() {
  // ── Shared test inputs (CA) ───────────────────────────────────────────────
  const caVehiclePrice = 30000.0;
  const caDownPayment = 5000.0;
  const caTaxRateON = 0.13;
  const caAnnualRate = 7.9;
  const caTermMonths = 60;
  // insurance: life=$20/mo, warranty=$500 one-time, GAP=$250 one-time (term=60)
  const caInsuranceMonthly = 20.0 + 500.0 / 60 + 250.0 / 60; // = 32.5

  // Pre-computed expected values
  const expectedTaxON = caVehiclePrice * caTaxRateON; // 3900
  const expectedLoanAmt =
      caVehiclePrice + expectedTaxON - caDownPayment; // 28900
  const expectedInsTotal = caInsuranceMonthly * caTermMonths; // 1950

  // ── TEST 1 — Financed amount ──────────────────────────────────────────────
  test('TEST 1 — Financed amount = price + tax - down', () {
    final r = CACalculation.calculate(
      vehiclePrice: caVehiclePrice,
      downPayment: caDownPayment,
      annualRate: caAnnualRate,
      termMonths: caTermMonths,
      provinceCode: 'ON',
      frequency: PaymentFrequency.monthly,
    );

    expect(r.taxAmount, closeTo(3900.0, 0.01), reason: 'ON tax = 13% × 30000');
    expect(r.loanAmount, closeTo(28900.0, 0.01), reason: '30000 + 3900 - 5000');
  });

  // ── TEST 2 — Monthly payment formula ─────────────────────────────────────
  test('TEST 2 — Monthly payment ≈ \$584.61 (no insurance)', () {
    final r = CACalculation.calculate(
      vehiclePrice: caVehiclePrice,
      downPayment: caDownPayment,
      annualRate: caAnnualRate,
      termMonths: caTermMonths,
      provinceCode: 'ON',
      frequency: PaymentFrequency.monthly,
    );

    // Formula: P × r(1+r)^n / ((1+r)^n - 1)
    final rate = caAnnualRate / 12 / 100;
    final powN = pow(1 + rate, caTermMonths);
    final expected = expectedLoanAmt * (rate * powN) / (powN - 1);

    expect(
      r.monthlyPayment,
      closeTo(expected, 0.01),
      reason: 'Formula: P × r(1+r)^n / ((1+r)^n - 1)',
    );
    expect(
      r.monthlyPayment,
      inInclusiveRange(583.0, 586.0),
      reason: 'Expected approx \$584.61',
    );
  });

  // ── TEST 3 — Total interest ───────────────────────────────────────────────
  test('TEST 3 — Total interest ≈ \$6,176 (no insurance)', () {
    final r = CACalculation.calculate(
      vehiclePrice: caVehiclePrice,
      downPayment: caDownPayment,
      annualRate: caAnnualRate,
      termMonths: caTermMonths,
      provinceCode: 'ON',
      frequency: PaymentFrequency.monthly,
    );

    // totalInterest = (baseMonthly × 60) - loanAmount
    final expectedInterest = r.monthlyPayment * caTermMonths - expectedLoanAmt;
    expect(r.totalInterest, closeTo(expectedInterest, 0.01));
    expect(
      r.totalInterest,
      inInclusiveRange(6000.0, 6400.0),
      reason: 'Expected approx \$6,176.60',
    );
  });

  // ── TEST 4 — Total insurance ──────────────────────────────────────────────
  test('TEST 4 — Total insurance = (\$20×60) + \$500 + \$250 = \$1,950', () {
    final r = CACalculation.calculate(
      vehiclePrice: caVehiclePrice,
      downPayment: caDownPayment,
      annualRate: caAnnualRate,
      termMonths: caTermMonths,
      provinceCode: 'ON',
      frequency: PaymentFrequency.monthly,
      insuranceMonthly: caInsuranceMonthly,
    );

    // insuranceTotal = insuranceMonthly × termMonths
    // = (20 + 500/60 + 250/60) × 60 = 1200 + 500 + 250 = 1950
    expect(r.insuranceTotal, closeTo(1950.0, 0.01));
    expect(expectedInsTotal, closeTo(1950.0, 0.01));
  });

  // ── TEST 5 — Total vehicle cost (NE PAS additionner downPayment) ──────────
  test(
    'TEST 5 — Total cost = price + tax + interest + insurance (no duplicate down)',
    () {
      final r = CACalculation.calculate(
        vehiclePrice: caVehiclePrice,
        downPayment: caDownPayment,
        annualRate: caAnnualRate,
        termMonths: caTermMonths,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
        insuranceMonthly: caInsuranceMonthly,
      );

      // Correct formula — downPayment NOT added separately
      final expected =
          caVehiclePrice + r.taxAmount + r.totalInterest + r.insuranceTotal;
      expect(r.totalCost, closeTo(expected, 0.01));
      expect(
        r.totalCost,
        inInclusiveRange(41000.0, 43000.0),
        reason: 'Expected approx \$42,026.60',
      );

      // Verify downPayment is NOT counted twice:
      // totalCost must NOT equal vehiclePrice + tax + downPayment + interest + insurance
      final doubleCountedDP =
          caVehiclePrice +
          r.taxAmount +
          caDownPayment +
          r.totalInterest +
          r.insuranceTotal;
      expect(r.totalCost, isNot(closeTo(doubleCountedDP, 0.01)));
    },
  );

  // ── TEST 6 — Real user cost (out-of-pocket) ───────────────────────────────
  test('TEST 6 — Real cost (via financing) = totalCost - downPayment', () {
    final r = CACalculation.calculate(
      vehiclePrice: caVehiclePrice,
      downPayment: caDownPayment,
      annualRate: caAnnualRate,
      termMonths: caTermMonths,
      provinceCode: 'ON',
      frequency: PaymentFrequency.monthly,
      insuranceMonthly: caInsuranceMonthly,
    );

    final realCost = r.totalCost - r.downPayment;
    // = loanAmount + totalInterest + insuranceTotal
    expect(
      realCost,
      closeTo(r.loanAmount + r.totalInterest + r.insuranceTotal, 0.01),
    );
    expect(
      realCost,
      inInclusiveRange(36000.0, 38000.0),
      reason: 'Expected approx \$37,026.60',
    );
  });

  // ── TEST 7 — Bi-weekly uses independent formula (BUG #1/#2 fix) ──────────
  test('TEST 7 — Bi-weekly uses own formula r=rate/26, n=years×26', () {
    final r = CACalculation.calculate(
      vehiclePrice: caVehiclePrice,
      downPayment: caDownPayment,
      annualRate: caAnnualRate,
      termMonths: caTermMonths,
      provinceCode: 'ON',
      frequency: PaymentFrequency.biWeekly,
    );

    // Verify nBiPeriods = round(60/12 × 26) = 130
    expect(r.nBiPeriods, 130);

    // Compute expected bi-weekly independently
    final rBi = caAnnualRate / 26 / 100;
    final powN = pow(1 + rBi, r.nBiPeriods).toDouble();
    final expectedBiWeekly = r.loanAmount * (rBi * powN) / (powN - 1);

    expect(
      r.baseLoanBiWeekly,
      closeTo(expectedBiWeekly, 0.0001),
      reason: 'Must match formula: P × rBi(1+rBi)^n / ((1+rBi)^n - 1)',
    );
    expect(
      r.baseLoanBiWeekly,
      inInclusiveRange(267.0, 272.0),
      reason: 'Expected approx \$269.43',
    );

    // BUG #2 fix: bi-weekly ≠ monthly × 12/26
    expect(
      r.baseLoanBiWeekly,
      isNot(closeTo(r.baseLoanMonthly * 12 / 26, 0.01)),
      reason: 'Bi-weekly and monthly are computed independently',
    );
  });

  // ── TEST 7b — Insurance bi-weekly = monthly × 12/26 ──────────────────────
  test('TEST 7b — Insurance bi-weekly = insuranceMonthly × 12/26', () {
    const insMonthly = 20.0 + 500.0 / 60; // life + warranty ≈ 28.33/mo
    final r = CACalculation.calculate(
      vehiclePrice: caVehiclePrice,
      downPayment: caDownPayment,
      annualRate: caAnnualRate,
      termMonths: caTermMonths,
      provinceCode: 'ON',
      frequency: PaymentFrequency.biWeekly,
      insuranceMonthly: insMonthly,
    );

    // Insurance bi-weekly = insMonthly × 12/26 ≈ $13.08
    expect(r.insuranceBiWeekly, closeTo(insMonthly * 12 / 26, 0.0001));
    expect(
      r.insuranceBiWeekly,
      closeTo(13.08, 0.05),
      reason: '28.33 × 12/26 ≈ \$13.08',
    );
    expect(
      r.biWeeklyPayment,
      closeTo(r.baseLoanBiWeekly + r.insuranceBiWeekly, 0.0001),
    );
  });

  // ── TEST 7c — Monthly with insurance ─────────────────────────────────────
  test('TEST 7c — Monthly with insurance ≈ \$612.94', () {
    const insMonthly = 20.0 + 500.0 / 60; // ≈ 28.33/mo
    final r = CACalculation.calculate(
      vehiclePrice: caVehiclePrice,
      downPayment: caDownPayment,
      annualRate: caAnnualRate,
      termMonths: caTermMonths,
      provinceCode: 'ON',
      frequency: PaymentFrequency.monthly,
      insuranceMonthly: insMonthly,
    );

    // monthly = baseLoan + insurance = 584.61 + 28.33 ≈ 612.94
    expect(r.monthlyPayment, closeTo(r.baseLoanMonthly + insMonthly, 0.0001));
    expect(
      r.monthlyPayment,
      inInclusiveRange(611.0, 615.0),
      reason: 'Expected approx \$612.94',
    );
  });

  // ── TEST 8 — Affordability ratio ─────────────────────────────────────────
  test('TEST 8 — Affordability: payment / income < 20% = Excellent', () {
    final r = CACalculation.calculate(
      vehiclePrice: caVehiclePrice,
      downPayment: caDownPayment,
      annualRate: caAnnualRate,
      termMonths: caTermMonths,
      provinceCode: 'ON',
      frequency: PaymentFrequency.monthly,
    );

    const monthlyIncome = 5000.0;
    final ratio = r.monthlyPayment / monthlyIncome * 100;
    expect(ratio, closeTo(11.69, 0.5), reason: 'Expected ~11.69%');
    expect(ratio, lessThan(20.0), reason: 'Below 20% = Excellent');
  });

  // ── TEST 9 — Screen consistency (no rounding discrepancy) ─────────────────
  test('TEST 9 — Formula gives same value regardless of rounding path', () {
    final r = CACalculation.calculate(
      vehiclePrice: caVehiclePrice,
      downPayment: caDownPayment,
      annualRate: caAnnualRate,
      termMonths: caTermMonths,
      provinceCode: 'ON',
      frequency: PaymentFrequency.monthly,
    );

    // Verify: monthlyPayment to 2 decimal places matches double-to-2dp
    final displayed = double.parse(r.monthlyPayment.toStringAsFixed(2));
    expect(displayed, closeTo(r.monthlyPayment, 0.005));

    // Verify the formula is stable: recompute independently and compare
    final rate = caAnnualRate / 12 / 100;
    final powN = pow(1 + rate, caTermMonths).toDouble();
    final recomputed = r.loanAmount * (rate * powN) / (powN - 1);
    expect(
      r.monthlyPayment,
      closeTo(recomputed, 0.0001),
      reason: 'Same formula must produce exact same double',
    );
  });

  // ── TEST 10 — Amortization month 1 ───────────────────────────────────────
  test('TEST 10 — Amortization month 1 (interest / principal / balance)', () {
    final r = CACalculation.calculate(
      vehiclePrice: caVehiclePrice,
      downPayment: caDownPayment,
      annualRate: caAnnualRate,
      termMonths: caTermMonths,
      provinceCode: 'ON',
      frequency: PaymentFrequency.monthly,
    );

    final rate = caAnnualRate / 12 / 100;
    final interest1 = r.loanAmount * rate; // ≈ 190.25
    final principal1 = r.monthlyPayment - interest1; // ≈ 394.36
    final balance1 = r.loanAmount - principal1; // ≈ 28,505.64

    expect(
      interest1,
      closeTo(190.25, 0.10),
      reason: '28900 × 0.0065833 ≈ \$190.25',
    );
    expect(
      principal1,
      closeTo(394.36, 0.10),
      reason: 'payment - interest ≈ \$394.36',
    );
    expect(
      balance1,
      closeTo(28505.64, 0.20),
      reason: '28900 - 394.36 ≈ \$28,505.64',
    );
  });

  // ── TEST 11 — Amortization last month balance = 0 ────────────────────────
  test('TEST 11 — Amortization: last month balance ≈ \$0.00', () {
    final r = CACalculation.calculate(
      vehiclePrice: caVehiclePrice,
      downPayment: caDownPayment,
      annualRate: caAnnualRate,
      termMonths: caTermMonths,
      provinceCode: 'ON',
      frequency: PaymentFrequency.monthly,
    );

    // Simulate amortization to last payment
    final rate = caAnnualRate / 12 / 100;
    double balance = r.loanAmount;
    for (int m = 1; m <= caTermMonths; m++) {
      final interest = balance * rate;
      final isLast = m == caTermMonths;
      final payment = isLast ? balance + interest : r.monthlyPayment;
      final principal = payment - interest;
      balance -= principal;
      balance = balance.clamp(0.0, double.infinity);
    }

    expect(
      balance,
      closeTo(0.0, 1.0),
      reason: 'Final balance must clear to \$0',
    );
  });

  // ── TEST 12 — Edge cases ──────────────────────────────────────────────────
  group('TEST 12 — Edge cases', () {
    test('downPayment = 0 → loanAmount = price + taxes', () {
      final r = CACalculation.calculate(
        vehiclePrice: caVehiclePrice,
        downPayment: 0,
        annualRate: caAnnualRate,
        termMonths: caTermMonths,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
      );
      expect(r.loanAmount, closeTo(caVehiclePrice * 1.13, 0.01));
    });

    test('rate = 0% → payment = loanAmount / months', () {
      final r = CACalculation.calculate(
        vehiclePrice: 24000,
        downPayment: 0,
        annualRate: 0,
        termMonths: 24,
        provinceCode: 'AB', // 5% GST only
        frequency: PaymentFrequency.monthly,
      );
      expect(r.totalInterest, 0);
      expect(r.monthlyPayment, closeTo(r.loanAmount / 24, 0.01));
    });

    test('term = 12 months → valid calculation', () {
      final r = CACalculation.calculate(
        vehiclePrice: 15000,
        downPayment: 3000,
        annualRate: 5.0,
        termMonths: 12,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
      );
      expect(r.monthlyPayment, greaterThan(0));
      expect(r.loanAmount, greaterThan(0));
    });

    test('vehiclePrice = 0 → loanAmount clamped to 0', () {
      final r = CACalculation.calculate(
        vehiclePrice: 0,
        downPayment: 0,
        annualRate: 7.9,
        termMonths: 60,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
      );
      expect(r.loanAmount, 0);
    });

    test('downPayment > vehicle+tax → loanAmount clamped to 0', () {
      final r = CACalculation.calculate(
        vehiclePrice: 10000,
        downPayment: 99999,
        annualRate: 7.9,
        termMonths: 60,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
      );
      expect(r.loanAmount, 0);
      expect(r.monthlyPayment, 0);
    });
  });

  // ── TEST 13 — US Trade-in ─────────────────────────────────────────────────
  test('TEST 13 — US financed = price - tradeIn + fees + tax', () {
    const usTax = 30000.0 * 0.08; // 2400
    final r = USCalculation.calculate(
      vehiclePrice: 30000,
      tradeInValue: 5000,
      downPayment: 0,
      dealerFees: 500,
      salesTaxPercent: 8.0,
      annualRate: 6.9,
      termMonths: 60,
      creditScore: CreditScore.fair,
    );

    // 30000 - 5000 + 500 + 2400 - 0 = 27900
    expect(r.taxAmount, closeTo(usTax, 0.01));
    expect(r.financedAmount, closeTo(27900.0, 0.01));
  });

  // ── TEST 14 — US Credit score rate adjustments ────────────────────────────
  test('TEST 14 — US credit score adjustments ±%', () {
    calc(CreditScore cs) => USCalculation.calculate(
      vehiclePrice: 30000,
      tradeInValue: 0,
      downPayment: 0,
      dealerFees: 0,
      salesTaxPercent: 0,
      annualRate: 7.9,
      termMonths: 60,
      creditScore: cs,
    );

    expect(
      calc(CreditScore.excellent).effectiveRate,
      closeTo(6.40, 0.001),
      reason: '7.90 - 1.5 = 6.40%',
    );
    expect(
      calc(CreditScore.good).effectiveRate,
      closeTo(7.40, 0.001),
      reason: '7.90 - 0.5 = 7.40%',
    );
    expect(
      calc(CreditScore.fair).effectiveRate,
      closeTo(7.90, 0.001),
      reason: '7.90 + 0 = 7.90%',
    );
    expect(
      calc(CreditScore.poor).effectiveRate,
      closeTo(9.90, 0.001),
      reason: '7.90 + 2.0 = 9.90%',
    );
  });

  // ── TEST 15 — UK Road tax ─────────────────────────────────────────────────
  test('TEST 15 — UK petrolLarge VED £360/yr → £30.00/mo in payment (DVLA 2025/26)', () {
    final r = UKCalculation.calculate(
      vehiclePrice: 20000,
      downPayment: 4000,
      annualRate: 6.9,
      termMonths: 60,
      includeRoadTax: true,
      vehicleType: VehicleType.petrolLarge,
    );

    // VED annual = £360, monthly = £360/12 = £30.00
    expect(
      r.vedMonthly,
      closeTo(360.0 / 12, 0.01),
      reason: '£360/yr ÷ 12 = £30.00/mo',
    );
    expect(
      r.monthlyPayment,
      closeTo(r.baseLoanPayment + 360.0 / 12, 0.01),
      reason: 'Monthly = loan payment + VED monthly (£360/12 = £30)',
    );

    // Total VED over 60 months = £360 × 5 = £1,800
    expect(
      r.vedTotal,
      closeTo(360.0 * 60 / 12, 0.01),
      reason: 'VED total = £360 × (60/12) = £1,800',
    );

    // totalCost includes road tax
    expect(
      r.totalCost,
      closeTo(r.vehiclePrice + r.totalInterest + r.vedTotal, 0.01),
    );
  });
}
