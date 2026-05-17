// US Loan Calculator — Tests exhaustifs
// Référence : prix=$30,000 | down=$3,000 | fees=$500 | tax=8% | 6.90% | 60 mois | Fair
// NOTE US-1: spec dit monthly=$583.63 mais formule PMT(29900, 6.9%/12, 60) donne ~$590.57
// NOTE US-2: spec dit monthly=$569.61 mais PMT(29900, 5.4%/12, 60) donne ~$567.x
// Les valeurs programmées sont utilisées pour les tests (formule mathématique correcte).

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_loan/country/us/us_logic.dart';
import 'package:auto_loan/features/amortization/amortization_screen.dart';

/// PMT standard : P × r(1+r)^n / ((1+r)^n − 1)
double _pmt(double p, double r, int n) {
  if (r <= 0) return n > 0 ? p / n : 0;
  final powN = pow(1 + r, n).toDouble();
  return p * (r * powN) / (powN - 1);
}

void main() {
  // ═══════════════════════════════════════════════════════════════════
  // US — CALCUL DE BASE (CAS US-1 : Fair, pas de trade-in)
  // ═══════════════════════════════════════════════════════════════════
  group('US — Calcul de base', () {
    late USCalculation r;
    setUpAll(
      () => r = USCalculation.calculate(
        vehiclePrice: 30000,
        tradeInValue: 0,
        downPayment: 3000,
        dealerFees: 500,
        salesTaxPercent: 8.0,
        annualRate: 6.9,
        termMonths: 60,
        creditScore: CreditScore.fair,
      ),
    );

    test('[US-1a] Taxe = 8% × \$30,000 = \$2,400.00', () {
      expect(
        r.taxAmount,
        closeTo(2400.00, 0.01),
        reason: '[US-1a] 30000 × 8% = 2400',
      );
    });

    test(
      '[US-1b] Montant financé = prix + taxe + frais − down = \$29,900.00',
      () {
        expect(
          r.financedAmount,
          closeTo(29900.00, 0.01),
          reason: '[US-1b] 30000 + 2400 + 500 − 3000 = 29900',
        );
      },
    );

    test('[US-1c] Taux effectif Fair = 6.90% (pas d\'ajustement)', () {
      expect(
        r.effectiveRate,
        closeTo(6.90, 0.001),
        reason: '[US-1c] Fair = 0% d\'ajustement → effectiveRate = 6.90%',
      );
    });

    test('[US-1d] Paiement mensuel = PMT(29900, 6.9%/12, 60)', () {
      final expected = _pmt(29900.0, 6.9 / 12 / 100, 60);
      expect(
        r.monthlyPayment,
        closeTo(expected, 0.01),
        reason:
            '[US-1d] Formule PMT — spec dit \$583.63 mais formule donne ~\$590.57',
      );
    });

    test('[US-1e] Intérêts totaux = pmt×60 − financedAmount', () {
      final expected = r.monthlyPayment * 60 - r.financedAmount;
      expect(
        r.totalInterest,
        closeTo(expected, 0.01),
        reason: '[US-1e] totalInterest = pmt×60 − 29900',
      );
    });

    test('[US-1f] Coût total = prix + taxe + frais + intérêts − trade-in', () {
      final expected = 30000.0 + r.taxAmount + 500.0 + r.totalInterest - 0.0;
      expect(
        r.totalCost,
        closeTo(expected, 0.01),
        reason:
            '[US-1f] vehiclePrice + taxAmount + dealerFees + totalInterest − tradeIn',
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // US — CREDIT SCORE (CAS US-2, US-3, US-4)
  // ═══════════════════════════════════════════════════════════════════
  group('US — Credit Score', () {
    USCalculation calc(CreditScore cs) => USCalculation.calculate(
      vehiclePrice: 30000,
      tradeInValue: 0,
      downPayment: 3000,
      dealerFees: 500,
      salesTaxPercent: 8.0,
      annualRate: 6.9,
      termMonths: 60,
      creditScore: cs,
    );

    test('[US-2a] Excellent (750+) : taux − 1.5% → effectiveRate = 5.40%', () {
      expect(
        calc(CreditScore.excellent).effectiveRate,
        closeTo(5.40, 0.001),
        reason: '[US-2a] 6.90 − 1.50 = 5.40%',
      );
    });

    test('[US-2b] Excellent : paiement mensuel = PMT(29900, 5.4%/12, 60)', () {
      final r = calc(CreditScore.excellent);
      final expected = _pmt(29900.0, 5.4 / 12 / 100, 60);
      expect(
        r.monthlyPayment,
        closeTo(expected, 0.01),
        reason: '[US-2b] PMT(29900, 5.4%/12, 60)',
      );
    });

    test('[US-3a] Good (700-749) : taux − 0.5% → effectiveRate = 6.40%', () {
      expect(
        calc(CreditScore.good).effectiveRate,
        closeTo(6.40, 0.001),
        reason: '[US-3a] 6.90 − 0.50 = 6.40%',
      );
    });

    test('[US-3b] Good : paiement mensuel = PMT(29900, 6.4%/12, 60)', () {
      final r = calc(CreditScore.good);
      final expected = _pmt(29900.0, 6.4 / 12 / 100, 60);
      expect(
        r.monthlyPayment,
        closeTo(expected, 0.01),
        reason: '[US-3b] PMT(29900, 6.4%/12, 60)',
      );
    });

    test('[US-4a] Poor (<650) : taux + 2.0% → effectiveRate = 8.90%', () {
      expect(
        calc(CreditScore.poor).effectiveRate,
        closeTo(8.90, 0.001),
        reason: '[US-4a] 6.90 + 2.00 = 8.90%',
      );
    });

    test('[US-4b] Poor : paiement mensuel = PMT(29900, 8.9%/12, 60)', () {
      final r = calc(CreditScore.poor);
      final expected = _pmt(29900.0, 8.9 / 12 / 100, 60);
      expect(
        r.monthlyPayment,
        closeTo(expected, 0.01),
        reason: '[US-4b] PMT(29900, 8.9%/12, 60)',
      );
    });

    test(
      '[US-CS-ord] Excellent < Good < Fair < Poor (paiements croissants)',
      () {
        final excellent = calc(CreditScore.excellent).monthlyPayment;
        final good = calc(CreditScore.good).monthlyPayment;
        final fair = calc(CreditScore.fair).monthlyPayment;
        final poor = calc(CreditScore.poor).monthlyPayment;
        expect(excellent, lessThan(good), reason: 'Excellent < Good');
        expect(good, lessThan(fair), reason: 'Good < Fair');
        expect(fair, lessThan(poor), reason: 'Fair < Poor');
      },
    );

    test('[US-CS-clamp] Taux plafonné à 30% (poor + taux de base 29%)', () {
      final r = USCalculation.calculate(
        vehiclePrice: 10000,
        tradeInValue: 0,
        downPayment: 0,
        dealerFees: 0,
        salesTaxPercent: 0,
        annualRate: 29.0,
        termMonths: 12,
        creditScore: CreditScore.poor, // +2% → 31% → clampé à 30%
      );
      expect(
        r.effectiveRate,
        30.0,
        reason: '[US-CS-clamp] 29 + 2 = 31 → clampé à 30%',
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // US — TRADE-IN (CAS US-5)
  // ═══════════════════════════════════════════════════════════════════
  group('US — Trade-in', () {
    test('[US-5a] Taxe = 6% × \$35,000 = \$2,100.00', () {
      final r = USCalculation.calculate(
        vehiclePrice: 35000,
        tradeInValue: 8000,
        downPayment: 2000,
        dealerFees: 800,
        salesTaxPercent: 6.0,
        annualRate: 5.9,
        termMonths: 48,
        creditScore: CreditScore.fair,
      );
      expect(
        r.taxAmount,
        closeTo(2100.00, 0.01),
        reason: '[US-5a] 35000 × 6% = 2100',
      );
    });

    test('[US-5b] Montant financé avec trade-in = \$27,900.00', () {
      final r = USCalculation.calculate(
        vehiclePrice: 35000,
        tradeInValue: 8000,
        downPayment: 2000,
        dealerFees: 800,
        salesTaxPercent: 6.0,
        annualRate: 5.9,
        termMonths: 48,
        creditScore: CreditScore.fair,
      );
      expect(
        r.financedAmount,
        closeTo(27900.00, 0.01),
        reason: '[US-5b] 35000 + 2100 + 800 − 8000 − 2000 = 27900',
      );
    });

    test(
      '[US-5c] Paiement mensuel avec trade-in = PMT(27900, 5.9%/12, 48)',
      () {
        final r = USCalculation.calculate(
          vehiclePrice: 35000,
          tradeInValue: 8000,
          downPayment: 2000,
          dealerFees: 800,
          salesTaxPercent: 6.0,
          annualRate: 5.9,
          termMonths: 48,
          creditScore: CreditScore.fair,
        );
        final expected = _pmt(27900.0, 5.9 / 12 / 100, 48);
        expect(
          r.monthlyPayment,
          closeTo(expected, 0.01),
          reason: '[US-5c] PMT(27900, 5.9%/12, 48)',
        );
      },
    );

    test('[US-5d] Trade-in réduit le montant financé de \$8,000', () {
      final noTrade = USCalculation.calculate(
        vehiclePrice: 35000,
        tradeInValue: 0,
        downPayment: 2000,
        dealerFees: 800,
        salesTaxPercent: 6.0,
        annualRate: 5.9,
        termMonths: 48,
        creditScore: CreditScore.fair,
      );
      final withTrade = USCalculation.calculate(
        vehiclePrice: 35000,
        tradeInValue: 8000,
        downPayment: 2000,
        dealerFees: 800,
        salesTaxPercent: 6.0,
        annualRate: 5.9,
        termMonths: 48,
        creditScore: CreditScore.fair,
      );
      expect(
        withTrade.financedAmount,
        closeTo(noTrade.financedAmount - 8000, 0.01),
        reason: '[US-5d] Trade-in réduit financedAmount de 8000',
      );
      expect(
        withTrade.monthlyPayment,
        lessThan(noTrade.monthlyPayment),
        reason: '[US-5d] Paiement plus bas avec trade-in',
      );
    });

    test('[US-5e] Coût total = prix + taxe + frais + intérêts − trade-in', () {
      final r = USCalculation.calculate(
        vehiclePrice: 35000,
        tradeInValue: 8000,
        downPayment: 2000,
        dealerFees: 800,
        salesTaxPercent: 6.0,
        annualRate: 5.9,
        termMonths: 48,
        creditScore: CreditScore.fair,
      );
      final expected = 35000.0 + r.taxAmount + 800.0 + r.totalInterest - 8000.0;
      expect(
        r.totalCost,
        closeTo(expected, 0.01),
        reason:
            '[US-5e] totalCost = vehiclePrice + tax + fees + interest − tradeIn',
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // US — COHÉRENCE AMORTISSEMENT (CAS US-6)
  // ═══════════════════════════════════════════════════════════════════
  group('US — Amortissement', () {
    const financed = 29900.0, rate = 6.9, term = 60;
    late List<AmortizationRow> rows;
    late USCalculation calc;

    setUpAll(() {
      calc = USCalculation.calculate(
        vehiclePrice: 30000,
        tradeInValue: 0,
        downPayment: 3000,
        dealerFees: 500,
        salesTaxPercent: 8.0,
        annualRate: rate,
        termMonths: term,
        creditScore: CreditScore.fair,
      );
      rows = buildSchedule(
        loanAmount: financed,
        annualRate: rate,
        termMonths: term,
      );
    });

    test('[US-6a] Tableau a exactement 60 lignes', () {
      expect(rows.length, term, reason: '[US-6a] 60 lignes pour 60 mois');
    });

    test('[US-6b] Somme des principaux = \$29,900.00 ± \$1.00', () {
      final sum = rows.fold(0.0, (s, r) => s + r.principal);
      expect(
        sum,
        closeTo(financed, 1.00),
        reason: '[US-6b] Σ principaux ≈ montant financé',
      );
    });

    test('[US-6c] Somme des intérêts = totalInterest ± \$1.00', () {
      final sum = rows.fold(0.0, (s, r) => s + r.interest);
      expect(
        sum,
        closeTo(calc.totalInterest, 1.00),
        reason: '[US-6c] Σ intérêts = totalInterest du calculator',
      );
    });

    test('[US-6d] Balance mois 60 = \$0.00 ± \$1.00', () {
      expect(
        rows.last.balance,
        closeTo(0.0, 1.00),
        reason: '[US-6d] Balance finale = \$0',
      );
    });

    test(
      '[US-6e] Taux effectif affiché = taux après ajustement credit score',
      () {
        expect(
          calc.effectiveRate,
          closeTo(6.90, 0.001),
          reason: '[US-6e] Fair = effectiveRate = 6.90%',
        );
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════
  // US — TAXE 0% (CAS US-7)
  // ═══════════════════════════════════════════════════════════════════
  group('US — Sales Tax = 0%', () {
    test('[US-7a] Taxe 0% → taxAmount = \$0', () {
      final r = USCalculation.calculate(
        vehiclePrice: 20000,
        tradeInValue: 0,
        downPayment: 2000,
        dealerFees: 300,
        salesTaxPercent: 0.0,
        annualRate: 6.9,
        termMonths: 60,
        creditScore: CreditScore.fair,
      );
      expect(
        r.taxAmount,
        closeTo(0.0, 0.001),
        reason: '[US-7a] Pas de taxe à 0%',
      );
    });

    test('[US-7b] Taxe 0% → financedAmount = prix + frais − down − trade', () {
      final r = USCalculation.calculate(
        vehiclePrice: 20000,
        tradeInValue: 0,
        downPayment: 2000,
        dealerFees: 300,
        salesTaxPercent: 0.0,
        annualRate: 6.9,
        termMonths: 60,
        creditScore: CreditScore.fair,
      );
      expect(
        r.financedAmount,
        closeTo(20000 + 0 + 300 - 0 - 2000, 0.01),
        reason: '[US-7b] 20000 + 300 − 2000 = 18300',
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // CAS LIMITES US (CAS US-8)
  // ═══════════════════════════════════════════════════════════════════
  group('Cas limites US', () {
    test('[US-8a] Trade-in > Down Payment — financedAmount réduit', () {
      final noTrade = USCalculation.calculate(
        vehiclePrice: 25000,
        tradeInValue: 0,
        downPayment: 2000,
        dealerFees: 0,
        salesTaxPercent: 0,
        annualRate: 6.9,
        termMonths: 60,
        creditScore: CreditScore.fair,
      );
      final withTrade = USCalculation.calculate(
        vehiclePrice: 25000,
        tradeInValue: 10000,
        downPayment: 2000,
        dealerFees: 0,
        salesTaxPercent: 0,
        annualRate: 6.9,
        termMonths: 60,
        creditScore: CreditScore.fair,
      );
      expect(
        withTrade.financedAmount,
        closeTo(noTrade.financedAmount - 10000, 0.01),
        reason: '[US-8a] Trade-in \$10k réduit financedAmount de \$10k',
      );
    });

    test(
      '[US-8b] Down Payment = Prix → financedAmount minimal (juste taxe + frais)',
      () {
        const price = 20000.0;
        final r = USCalculation.calculate(
          vehiclePrice: price,
          tradeInValue: 0,
          downPayment: price,
          dealerFees: 300,
          salesTaxPercent: 8.0,
          annualRate: 6.9,
          termMonths: 60,
          creditScore: CreditScore.fair,
        );
        // financed = price + tax + fees - tradeIn - down = price×1.08 + 300 - price = price×0.08 + 300
        final expectedFinanced = price * 0.08 + 300.0;
        expect(
          r.financedAmount,
          closeTo(expectedFinanced, 0.01),
          reason: '[US-8b] financed = taxe + frais seulement',
        );
      },
    );

    test('[US-8c] Down Payment excessif → financedAmount clampé à 0', () {
      final r = USCalculation.calculate(
        vehiclePrice: 10000,
        tradeInValue: 0,
        downPayment: 99999,
        dealerFees: 0,
        salesTaxPercent: 0,
        annualRate: 6.9,
        termMonths: 60,
        creditScore: CreditScore.fair,
      );
      expect(
        r.financedAmount,
        0.0,
        reason: '[US-8c] financedAmount ne peut être négatif',
      );
    });

    test('[US-8d] Taux 0.99% — paiement proche remboursement simple', () {
      final r = USCalculation.calculate(
        vehiclePrice: 30000,
        tradeInValue: 0,
        downPayment: 3000,
        dealerFees: 0,
        salesTaxPercent: 0,
        annualRate: 0.99,
        termMonths: 60,
        creditScore: CreditScore.fair,
      );
      expect(
        r.totalInterest,
        greaterThan(0),
        reason: '[US-8d] Intérêts > 0 même à 0.99%',
      );
      expect(
        r.monthlyPayment,
        closeTo(_pmt(27000.0, 0.99 / 12 / 100, 60), 0.01),
        reason: '[US-8d] PMT(27000, 0.99%/12, 60)',
      );
    });

    test('[US-8e] Taux 24.99% — intérêts très élevés', () {
      final r = USCalculation.calculate(
        vehiclePrice: 30000,
        tradeInValue: 0,
        downPayment: 3000,
        dealerFees: 0,
        salesTaxPercent: 0,
        annualRate: 24.99,
        termMonths: 60,
        creditScore: CreditScore.fair,
      );
      expect(
        r.monthlyPayment,
        closeTo(_pmt(27000.0, 24.99 / 12 / 100, 60), 0.01),
        reason: '[US-8e] PMT(27000, 24.99%/12, 60)',
      );
      expect(
        r.totalInterest,
        greaterThan(r.financedAmount * 0.7),
        reason: '[US-8e] Intérêts > 70% du capital à 24.99%',
      );
    });

    test('[US-8f] Durée 24 mois — paiement mensuel', () {
      final r = USCalculation.calculate(
        vehiclePrice: 30000,
        tradeInValue: 0,
        downPayment: 3000,
        dealerFees: 500,
        salesTaxPercent: 8.0,
        annualRate: 6.9,
        termMonths: 24,
        creditScore: CreditScore.fair,
      );
      expect(
        r.monthlyPayment,
        closeTo(_pmt(29900.0, 6.9 / 12 / 100, 24), 0.01),
        reason: '[US-8f] PMT(29900, 6.9%/12, 24)',
      );
    });

    test('[US-8g] Durée 84 mois — paiement plus bas que 24 mois', () {
      final r24 = USCalculation.calculate(
        vehiclePrice: 30000,
        tradeInValue: 0,
        downPayment: 3000,
        dealerFees: 500,
        salesTaxPercent: 8.0,
        annualRate: 6.9,
        termMonths: 24,
        creditScore: CreditScore.fair,
      );
      final r84 = USCalculation.calculate(
        vehiclePrice: 30000,
        tradeInValue: 0,
        downPayment: 3000,
        dealerFees: 500,
        salesTaxPercent: 8.0,
        annualRate: 6.9,
        termMonths: 84,
        creditScore: CreditScore.fair,
      );
      expect(
        r84.monthlyPayment,
        lessThan(r24.monthlyPayment),
        reason: '[US-8g] 7 ans → pmt < 2 ans',
      );
    });

    test('[US-8h] Taux 0% — paiement = financedAmount / terme', () {
      final r = USCalculation.calculate(
        vehiclePrice: 30000,
        tradeInValue: 0,
        downPayment: 3000,
        dealerFees: 0,
        salesTaxPercent: 0,
        annualRate: 0,
        termMonths: 60,
        creditScore: CreditScore.fair,
      );
      expect(r.totalInterest, 0.0, reason: '[US-8h] Pas d\'intérêt à 0%');
      expect(
        r.monthlyPayment,
        closeTo(27000.0 / 60, 0.01),
        reason: '[US-8h] pmt = 27000 / 60 à 0%',
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // US — BI-WEEKLY (CAS US-9)
  // ═══════════════════════════════════════════════════════════════════
  group('US — Bi-weekly', () {
    // Référence : financed=$29,900 | effectiveRate=6.9% (Fair) | 60 mois = 5 ans
    // Bi-weekly: r=6.9%/26/100, n=5×26=130
    const financed = 29900.0;
    const effectiveRate = 6.9;
    const termMonths = 60;
    const termYears = termMonths / 12; // 5
    final rBi = effectiveRate / 26 / 100;
    final nBi = (termYears * 26).round(); // 130

    late USCalculation r;
    setUpAll(
      () => r = USCalculation.calculate(
        vehiclePrice: 30000,
        tradeInValue: 0,
        downPayment: 3000,
        dealerFees: 500,
        salesTaxPercent: 8.0,
        annualRate: 6.9,
        termMonths: termMonths,
        creditScore: CreditScore.fair,
        isBiWeekly: true,
      ),
    );

    test('[US-9a] isBiWeekly = true', () {
      expect(r.isBiWeekly, isTrue, reason: '[US-9a] flag isBiWeekly');
    });

    test('[US-9b] biWeeklyPayment = PMT(financed, 6.9%/26, 130)', () {
      final expected = _pmt(financed, rBi, nBi);
      expect(
        r.biWeeklyPayment,
        closeTo(expected, 0.01),
        reason: '[US-9b] PMT($financed, ${rBi.toStringAsFixed(6)}, $nBi)',
      );
    });

    test('[US-9c] displayPayment = biWeeklyPayment quand isBiWeekly=true', () {
      expect(
        r.displayPayment,
        closeTo(r.biWeeklyPayment, 0.001),
        reason: '[US-9c] displayPayment = biWeeklyPayment',
      );
    });

    test('[US-9d] Bi-weekly ≠ mensuel × 12/26 (formules indépendantes)', () {
      final approx = r.monthlyPayment * 12 / 26;
      expect(
        r.biWeeklyPayment,
        isNot(closeTo(approx, 0.01)),
        reason: '[US-9d] Formule indépendante, pas une conversion',
      );
    });

    test('[US-9e] displayPayment mensuel quand isBiWeekly=false', () {
      final monthly = USCalculation.calculate(
        vehiclePrice: 30000,
        tradeInValue: 0,
        downPayment: 3000,
        dealerFees: 500,
        salesTaxPercent: 8.0,
        annualRate: 6.9,
        termMonths: 60,
        creditScore: CreditScore.fair,
      );
      expect(
        monthly.displayPayment,
        closeTo(monthly.monthlyPayment, 0.001),
        reason: '[US-9e] displayPayment = monthlyPayment par défaut',
      );
    });

    test('[US-9f] Taux 0% bi-weekly = financed / (years×26)', () {
      final r0 = USCalculation.calculate(
        vehiclePrice: 30000,
        tradeInValue: 0,
        downPayment: 3000,
        dealerFees: 0,
        salesTaxPercent: 0,
        annualRate: 0,
        termMonths: 60,
        creditScore: CreditScore.fair,
        isBiWeekly: true,
      );
      expect(
        r0.biWeeklyPayment,
        closeTo(27000.0 / (5 * 26), 0.01),
        reason: '[US-9f] 0% → 27000 / 130',
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // US — TABLEAU AMORTISSEMENT BI-WEEKLY (CAS US-10)
  // ═══════════════════════════════════════════════════════════════════
  group('US — Amortissement bi-weekly', () {
    // financedAmount = 30000 + 30000×8% + 500 - 0 - 3000 = 29900
    const loanAmt = 29900.0;
    const rate = 6.9;
    const term = 60;
    late List<AmortizationRow> rows;

    setUpAll(() {
      rows = buildSchedule(
        loanAmount: loanAmt,
        annualRate: rate,
        termMonths: term,
        isBiWeekly: true,
      );
    });

    test('[US-10a] Tableau bi-weekly : 130 périodes pour 60 mois', () {
      expect(
        rows.length,
        (term / 12 * 26).round(),
        reason: '[US-10a] 5 ans × 26 = 130 périodes',
      );
    });

    test('[US-10b] Somme des principaux ≈ loanAmount ± \$1', () {
      final sum = rows.fold(0.0, (s, r) => s + r.principal);
      expect(
        sum,
        closeTo(loanAmt, 1.0),
        reason: '[US-10b] Σ principaux = capital financé',
      );
    });

    test('[US-10c] Balance finale = \$0 ± \$1', () {
      expect(
        rows.last.balance,
        closeTo(0.0, 1.0),
        reason: '[US-10c] Prêt entièrement remboursé',
      );
    });

    test('[US-10d] Paiement bi-weekly < paiement mensuel', () {
      final monthlyRows = buildSchedule(
        loanAmount: loanAmt,
        annualRate: rate,
        termMonths: term,
      );
      expect(
        rows.first.payment,
        lessThan(monthlyRows.first.payment),
        reason: '[US-10d] pmt bi-weekly < pmt mensuel',
      );
    });

    test('[US-10e] Intérêts totaux bi-weekly < intérêts mensuel', () {
      final monthlyRows = buildSchedule(
        loanAmount: loanAmt,
        annualRate: rate,
        termMonths: term,
      );
      final biSum = rows.fold(0.0, (s, r) => s + r.interest);
      final moSum = monthlyRows.fold(0.0, (s, r) => s + r.interest);
      expect(
        biSum,
        lessThan(moSum),
        reason: '[US-10e] Remboursement bi-weekly = moins d\'intérêts',
      );
    });
  });
}
