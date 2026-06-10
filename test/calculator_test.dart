import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_loan/core/payment_frequency.dart';
import 'package:auto_loan/country/ca/ca_logic.dart';
import 'package:auto_loan/country/uk/uk_logic.dart';
import 'package:auto_loan/country/us/us_logic.dart';

void main() {
  // ── CA Tests ─────────────────────────────────────────────────────────────────
  group('CA Calculator', () {
    test('basic ON loan at 7.9% / 60 months', () {
      final r = CACalculation.calculate(
        vehiclePrice: 30000,
        downPayment: 5000,
        annualRate: 7.9,
        termMonths: 60,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
      );
      // Ontario HST = 13%
      expect(r.taxAmount, closeTo(30000 * 0.13, 0.01));
      // Loan = 30000 + 3900 - 5000 = 28900
      expect(r.loanAmount, closeTo(28900, 0.01));
      // Monthly payment should be roughly ~$585
      expect(r.monthlyPayment, greaterThan(550));
      expect(r.monthlyPayment, lessThan(620));
      expect(r.totalInterest, greaterThan(0));
      expect(r.totalCost, greaterThan(r.loanAmount));
    });

    test(
      'bi-weekly uses proper amortization formula (r=rate/26, n=years×26)',
      () {
        final r = CACalculation.calculate(
          vehiclePrice: 25000,
          downPayment: 3000,
          annualRate: 6.5,
          termMonths: 48,
          provinceCode: 'QC',
          frequency: PaymentFrequency.biWeekly,
        );
        // nBiPeriods = round(48/12 × 26) = 104
        expect(r.nBiPeriods, 104);
        // Bi-weekly loan payment uses independent formula
        final rBi = 6.5 / 26 / 100;
        final powN = pow(1 + rBi, 104).toDouble();
        final expected = r.loanAmount * (rBi * powN) / (powN - 1);
        expect(r.baseLoanBiWeekly, closeTo(expected, 0.0001));
        // Insurance bi-weekly = monthly × 12/26 (correct conversion)
        expect(
          r.insuranceBiWeekly,
          closeTo(r.insuranceMonthly * 12 / 26, 0.0001),
        );
      },
    );

    test('zero rate loan splits evenly', () {
      final r = CACalculation.calculate(
        vehiclePrice: 20000,
        downPayment: 2000,
        annualRate: 0,
        termMonths: 36,
        provinceCode: 'AB', // GST only = 5%
        frequency: PaymentFrequency.monthly,
      );
      // AB GST = 5%, loan = 20000*1.05 - 2000 = 19000
      expect(r.loanAmount, closeTo(19000, 0.01));
      expect(r.monthlyPayment, closeTo(19000 / 36, 0.01));
      expect(r.totalInterest, 0);
    });

    test('QC tax = 14.975%', () {
      final r = CACalculation.calculate(
        vehiclePrice: 40000,
        downPayment: 0,
        annualRate: 5.0,
        termMonths: 60,
        provinceCode: 'QC',
        frequency: PaymentFrequency.monthly,
      );
      expect(r.taxAmount, closeTo(40000 * 0.14975, 0.01));
    });

    test('insurance adds to monthly', () {
      final without = CACalculation.calculate(
        vehiclePrice: 25000,
        downPayment: 2500,
        annualRate: 7.0,
        termMonths: 60,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
      );
      final with_ = CACalculation.calculate(
        vehiclePrice: 25000,
        downPayment: 2500,
        annualRate: 7.0,
        termMonths: 60,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
        insuranceMonthly: 20,
      );
      expect(with_.monthlyPayment - without.monthlyPayment, closeTo(20, 0.001));
    });

    test('down payment cannot exceed vehicle price', () {
      final r = CACalculation.calculate(
        vehiclePrice: 10000,
        downPayment: 20000, // more than price
        annualRate: 5.0,
        termMonths: 36,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
      );
      expect(r.loanAmount, 0);
    });
  });

  // ── UK Tests ─────────────────────────────────────────────────────────────────
  group('UK Calculator', () {
    test('no GST — loanAmount = price - downPayment', () {
      final r = UKCalculation.calculate(
        vehiclePrice: 25000,
        downPayment: 5000,
        annualRate: 6.9,
        termMonths: 60,
      );
      // UK: VAT included in price, no separate tax
      expect(r.loanAmount, closeTo(20000, 0.01));
      expect(r.baseLoanPayment, greaterThan(350));
      expect(r.baseLoanPayment, lessThan(500));
      expect(r.vedMonthly, 0);
    });

    test('petrolLarge VED = £360/yr → £30.00/mo (DVLA 2025/26)', () {
      // source: VehicleType.petrolLarge.vedAnnual (uk_logic.dart)
      final r = UKCalculation.calculate(
        vehiclePrice: 25000,
        downPayment: 5000,
        annualRate: 6.9,
        termMonths: 60,
        includeRoadTax: true,
        vehicleType: VehicleType.petrolLarge,
      );
      final vedAnnual = VehicleType.petrolLarge.vedAnnual;
      expect(r.vedMonthly, closeTo(vedAnnual / 12, 0.01));
      expect(r.monthlyPayment, closeTo(r.baseLoanPayment + vedAnnual / 12, 0.01));
    });

    test('electric VED = £10/yr since April 2025 (DVLA 2025/26)', () {
      // UK EVs are no longer VED-exempt from April 2025 — £10/year standard rate.
      final r = UKCalculation.calculate(
        vehiclePrice: 30000,
        downPayment: 5000,
        annualRate: 6.5,
        termMonths: 48,
        includeRoadTax: true,
        vehicleType: VehicleType.electric,
      );
      expect(r.vedMonthly, closeTo(10.0 / 12, 0.01)); // £0.83/mo
      expect(r.vedTotal, closeTo(10.0 / 12 * 48, 0.01)); // £40 over 48 months
    });

    test('total cost = price + interest + vedTotal', () {
      final r = UKCalculation.calculate(
        vehiclePrice: 20000,
        downPayment: 3000,
        annualRate: 7.0,
        termMonths: 48,
        includeRoadTax: true,
        vehicleType: VehicleType.petrolSmall,
      );
      expect(
        r.totalCost,
        closeTo(r.vehiclePrice + r.totalInterest + r.vedTotal, 0.01),
      );
    });
  });

  // ── US Tests ─────────────────────────────────────────────────────────────────
  group('US Calculator', () {
    test('basic loan with sales tax and dealer fees', () {
      final r = USCalculation.calculate(
        vehiclePrice: 30000,
        tradeInValue: 0,
        downPayment: 3000,
        dealerFees: 500,
        salesTaxPercent: 8.0,
        annualRate: 6.9,
        termMonths: 60,
        creditScore: CreditScore.fair,
      );
      expect(r.taxAmount, closeTo(30000 * 0.08, 0.01));
      // financed = 30000 + 2400 + 500 - 0 - 3000 = 29900
      expect(r.financedAmount, closeTo(29900, 0.01));
      expect(r.effectiveRate, closeTo(6.9, 0.001)); // fair = no adjustment
      expect(r.monthlyPayment, greaterThan(550));
    });

    test('credit score excellent reduces rate by 1.5%', () {
      final excellent = USCalculation.calculate(
        vehiclePrice: 30000,
        tradeInValue: 0,
        downPayment: 3000,
        dealerFees: 0,
        salesTaxPercent: 0,
        annualRate: 6.9,
        termMonths: 60,
        creditScore: CreditScore.excellent,
      );
      expect(excellent.effectiveRate, closeTo(5.4, 0.001));
      expect(
        excellent.monthlyPayment,
        lessThan(
          USCalculation.calculate(
            vehiclePrice: 30000,
            tradeInValue: 0,
            downPayment: 3000,
            dealerFees: 0,
            salesTaxPercent: 0,
            annualRate: 6.9,
            termMonths: 60,
            creditScore: CreditScore.poor,
          ).monthlyPayment,
        ),
      );
    });

    test('trade-in reduces financed amount', () {
      final noTrade = USCalculation.calculate(
        vehiclePrice: 25000,
        tradeInValue: 0,
        downPayment: 2500,
        dealerFees: 300,
        salesTaxPercent: 7.0,
        annualRate: 5.9,
        termMonths: 48,
        creditScore: CreditScore.good,
      );
      final withTrade = USCalculation.calculate(
        vehiclePrice: 25000,
        tradeInValue: 5000,
        downPayment: 2500,
        dealerFees: 300,
        salesTaxPercent: 7.0,
        annualRate: 5.9,
        termMonths: 48,
        creditScore: CreditScore.good,
      );
      expect(
        withTrade.financedAmount,
        closeTo(noTrade.financedAmount - 5000, 0.01),
      );
      expect(withTrade.monthlyPayment, lessThan(noTrade.monthlyPayment));
    });

    test('poor credit adds 2% rate', () {
      final r = USCalculation.calculate(
        vehiclePrice: 20000,
        tradeInValue: 0,
        downPayment: 2000,
        dealerFees: 0,
        salesTaxPercent: 5.0,
        annualRate: 6.0,
        termMonths: 36,
        creditScore: CreditScore.poor,
      );
      expect(r.effectiveRate, closeTo(8.0, 0.001));
    });

    test('rate clamped at 30%', () {
      final r = USCalculation.calculate(
        vehiclePrice: 10000,
        tradeInValue: 0,
        downPayment: 0,
        dealerFees: 0,
        salesTaxPercent: 0,
        annualRate: 29.0,
        termMonths: 12,
        creditScore: CreditScore.poor, // +2%
      );
      expect(r.effectiveRate, 30.0);
    });

    test('total cost = vehicle + tax + fees + interest - tradeIn', () {
      final r = USCalculation.calculate(
        vehiclePrice: 35000,
        tradeInValue: 5000,
        downPayment: 5000,
        dealerFees: 500,
        salesTaxPercent: 6.0,
        annualRate: 6.5,
        termMonths: 60,
        creditScore: CreditScore.good,
      );
      expect(
        r.totalCost,
        closeTo(
          r.vehiclePrice +
              r.taxAmount +
              r.dealerFees +
              r.totalInterest -
              r.tradeInValue,
          0.01,
        ),
      );
    });
  });
}
