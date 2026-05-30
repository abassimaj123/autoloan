// CA Loan Calculator — Tests exhaustifs
// Référence : prix=$30,000 | mise=$5,000 | ON(13%) | 7.90% | 60 mois
// Statut SK : code = GST(5%)+PST(6%)=11% (spec dit 6% — non conforme au code)
// Statut CA-2 : spec dit $28.33/mo (erreur arithmetic — devrait être $32.50 avec GAP)
// Statut CA-3 : code calcule bi-weekly INDÉPENDAMMENT (BUG #1/#2 corrigé), ≠ monthly×12/26

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_loan/core/payment_frequency.dart';
import 'package:auto_loan/country/ca/ca_logic.dart';
import 'package:auto_loan/country/ca/ca_taxes.dart';
import 'package:auto_loan/features/amortization/amortization_screen.dart';

/// PMT standard : P × r(1+r)^n / ((1+r)^n − 1)
double _pmt(double p, double r, int n) {
  if (r <= 0) return n > 0 ? p / n : 0;
  final powN = pow(1 + r, n).toDouble();
  return p * (r * powN) / (powN - 1);
}

void main() {
  // ═══════════════════════════════════════════════════════════════════
  // CA — CALCUL DE BASE (CAS CA-1)
  // ═══════════════════════════════════════════════════════════════════
  group('CA — Calcul de base', () {
    const price = 30000.0, down = 5000.0, rate = 7.9, term = 60;

    late CACalculation r;
    setUpAll(
      () => r = CACalculation.calculate(
        vehiclePrice: price,
        downPayment: down,
        annualRate: rate,
        termMonths: term,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
      ),
    );

    test('[CA-1a] Taxe ON = 13% × \$30,000 = \$3,900.00', () {
      expect(
        r.taxAmount,
        closeTo(3900.00, 0.01),
        reason: '[CA-1a] ON HST 13% × 30000 = 3900.00',
      );
    });

    test(
      '[CA-1b] Montant financé = \$30,000 + \$3,900 − \$5,000 = \$28,900.00',
      () {
        expect(
          r.loanAmount,
          closeTo(28900.00, 0.01),
          reason: '[CA-1b] prix + taxe − mise = 28900',
        );
      },
    );

    test('[CA-1c] Paiement mensuel ≈ \$584.61', () {
      final expected = _pmt(28900.0, rate / 12 / 100, term);
      expect(
        r.monthlyPayment,
        closeTo(expected, 0.01),
        reason: '[CA-1c] PMT(28900, 7.9%/12, 60) ≈ 584.61',
      );
      expect(
        r.monthlyPayment,
        closeTo(584.61, 0.01),
        reason: '[CA-1c] Spec attendu = \$584.61',
      );
    });

    test('[CA-1d] Intérêts totaux ≈ \$6,176.34', () {
      expect(
        r.totalInterest,
        closeTo(r.monthlyPayment * term - 28900.0, 0.01),
        reason: '[CA-1d] totalInterest = pmt×60 − loanAmount',
      );
      expect(
        r.totalInterest,
        closeTo(6176.34, 1.00),
        reason: '[CA-1d] Spec attendu ≈ \$6,176.34',
      );
    });

    test('[CA-1e] Coût total = prix + taxe + intérêts = \$40,076.34', () {
      expect(
        r.totalCost,
        closeTo(price + r.taxAmount + r.totalInterest, 0.01),
        reason: '[CA-1e] formule : prix + taxe + intérêts',
      );
      expect(
        r.totalCost,
        closeTo(40076.34, 1.00),
        reason: '[CA-1e] Spec attendu ≈ \$40,076.34',
      );
    });

    test('[CA-1f] Mois 1 : intérêt ≈ \$190.25', () {
      final interest1 = 28900.0 * (rate / 12 / 100);
      expect(
        interest1,
        closeTo(190.25, 0.10),
        reason: '[CA-1f] 28900 × (7.9%/12) ≈ \$190.25',
      );
    });

    test('[CA-1g] Mois 1 : principal ≈ \$394.36', () {
      final interest1 = 28900.0 * (rate / 12 / 100);
      final principal1 = r.monthlyPayment - interest1;
      expect(
        principal1,
        closeTo(394.36, 0.10),
        reason: '[CA-1g] pmt − intérêt mois 1 ≈ \$394.36',
      );
    });

    test('[CA-1h] Mois 1 : balance ≈ \$28,505.64', () {
      final interest1 = 28900.0 * (rate / 12 / 100);
      final balance1 = 28900.0 - (r.monthlyPayment - interest1);
      expect(
        balance1,
        closeTo(28505.64, 0.50),
        reason: '[CA-1h] 28900 − principal1 ≈ \$28,505.64',
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // CA — ASSURANCES (CAS CA-2)
  // NOTE: spec dit $28.33/mo (oubli du GAP/60). Valeur correcte = $32.50/mo.
  // Total = 20×60 + 500 + 250 = $1,950 → insMonthly = 1950/60 = $32.50 ✓
  // ═══════════════════════════════════════════════════════════════════
  group('CA — Assurances', () {
    // Vie=$20/mo  Garantie=$500 total  GAP=$250 total
    const insMonthly = 20.0 + 500.0 / 60 + 250.0 / 60; // = 32.50/mo

    test(
      '[CA-2a] Assurance mensuelle = vie + garantie/60 + GAP/60 = \$32.50',
      () {
        expect(
          insMonthly,
          closeTo(32.50, 0.01),
          reason:
              '[CA-2a] 20 + 8.33 + 4.17 = 32.50/mo (spec dit 28.33 — erreur arithmétique)',
        );
      },
    );

    test('[CA-2b] Paiement mensuel total = prêt + assurances', () {
      final r = CACalculation.calculate(
        vehiclePrice: 30000,
        downPayment: 5000,
        annualRate: 7.9,
        termMonths: 60,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
        insuranceMonthly: insMonthly,
      );
      expect(
        r.monthlyPayment,
        closeTo(r.baseLoanMonthly + insMonthly, 0.01),
        reason: '[CA-2b] total = baseLoan + insurance',
      );
    });

    test('[CA-2c] Total assurances = 20×60 + 500 + 250 = \$1,950.00', () {
      final r = CACalculation.calculate(
        vehiclePrice: 30000,
        downPayment: 5000,
        annualRate: 7.9,
        termMonths: 60,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
        insuranceMonthly: insMonthly,
      );
      expect(
        r.insuranceTotal,
        closeTo(1950.00, 0.01),
        reason: '[CA-2c] insMonthly × 60 = 1950',
      );
    });

    test('[CA-2d] Coût total avec assurances ≈ \$42,026.34', () {
      final r = CACalculation.calculate(
        vehiclePrice: 30000,
        downPayment: 5000,
        annualRate: 7.9,
        termMonths: 60,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
        insuranceMonthly: insMonthly,
      );
      final expected =
          30000.0 + r.taxAmount + r.totalInterest + r.insuranceTotal;
      expect(
        r.totalCost,
        closeTo(expected, 0.01),
        reason: '[CA-2d] prix + taxe + intérêts + assurances',
      );
      expect(
        r.totalCost,
        closeTo(42026.34, 1.00),
        reason: '[CA-2d] Spec attendu ≈ \$42,026.34',
      );
    });

    test('[CA-2e] Montant financé inchangé avec assurances = \$28,900.00', () {
      final r = CACalculation.calculate(
        vehiclePrice: 30000,
        downPayment: 5000,
        annualRate: 7.9,
        termMonths: 60,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
        insuranceMonthly: insMonthly,
      );
      expect(
        r.loanAmount,
        closeTo(28900.00, 0.01),
        reason: '[CA-2e] Les assurances ne modifient pas le montant financé',
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // CA — BI-WEEKLY (CAS CA-3)
  // NOTE : le code calcule bi-weekly INDÉPENDAMMENT avec r=7.9%/26, n=130.
  // Spec dit $269.82 (= monthly×12/26 — ancienne méthode, bug corrigé).
  // Valeur correcte du code ≈ $269.32.
  // totalInterest est toujours basé sur le schedule mensuel.
  // ═══════════════════════════════════════════════════════════════════
  group('CA — Bi-weekly', () {
    test('[CA-3a] Périodes bi-weekly = round(60/12 × 26) = 130', () {
      final r = CACalculation.calculate(
        vehiclePrice: 30000,
        downPayment: 5000,
        annualRate: 7.9,
        termMonths: 60,
        provinceCode: 'ON',
        frequency: PaymentFrequency.biWeekly,
      );
      expect(
        r.nBiPeriods,
        130,
        reason: '[CA-3a] 5 ans × 26 = 130 périodes bi-weekly',
      );
    });

    test('[CA-3b] Taux bi-weekly = 7.90% / 26 = 0.30385%', () {
      const rBi = 7.9 / 26 / 100;
      expect(
        rBi,
        closeTo(0.003038, 0.000001),
        reason: '[CA-3b] rBi = 7.9/26/100',
      );
    });

    test('[CA-3c] Paiement bi-weekly calculé avec formule indépendante', () {
      final r = CACalculation.calculate(
        vehiclePrice: 30000,
        downPayment: 5000,
        annualRate: 7.9,
        termMonths: 60,
        provinceCode: 'ON',
        frequency: PaymentFrequency.biWeekly,
      );
      final rBi = 7.9 / 26 / 100;
      final powN = pow(1 + rBi, 130).toDouble();
      final expected = 28900.0 * (rBi * powN) / (powN - 1);
      expect(
        r.baseLoanBiWeekly,
        closeTo(expected, 0.01),
        reason: '[CA-3c] PMT(28900, 7.9%/26, 130) — formule indépendante',
      );
      // NOTE: spec dit $269.82 (= mensuel×12/26, ancienne méthode bug#1)
      // Code donne ~$269.32 avec la formule indépendante correcte
      expect(
        r.baseLoanBiWeekly,
        inInclusiveRange(267.0, 272.0),
        reason: '[CA-3c] Valeur attendue entre \$267 et \$272',
      );
    });

    test(
      '[CA-3d] Bi-weekly ≠ mensuel × 12/26 (formules indépendantes — bug #2 corrigé)',
      () {
        final r = CACalculation.calculate(
          vehiclePrice: 30000,
          downPayment: 5000,
          annualRate: 7.9,
          termMonths: 60,
          provinceCode: 'ON',
          frequency: PaymentFrequency.biWeekly,
        );
        final converted = r.baseLoanMonthly * 12 / 26;
        expect(
          r.baseLoanBiWeekly,
          isNot(closeTo(converted, 0.01)),
          reason: '[CA-3d] Formules indépendantes — bi-weekly ≠ monthly×12/26',
        );
      },
    );

    test(
      '[CA-3e] Équivalence annuelle : bi-weekly×26 vs mensuel×12 (légère diff attendue)',
      () {
        final r = CACalculation.calculate(
          vehiclePrice: 30000,
          downPayment: 5000,
          annualRate: 7.9,
          termMonths: 60,
          provinceCode: 'ON',
          frequency: PaymentFrequency.biWeekly,
        );
        // Avec formules indépendantes, les annualisations diffèrent légèrement
        final annualBi = r.baseLoanBiWeekly * 26;
        final annualMo = r.baseLoanMonthly * 12;
        expect(
          (annualBi - annualMo).abs(),
          lessThan(15.0),
          reason:
              '[CA-3e] Différence annuelle < \$15 (formules proches mais indépendantes)',
        );
      },
    );

    test('[CA-3f] Assurance bi-weekly = mensuel × 12/26', () {
      const ins = 20.0;
      final r = CACalculation.calculate(
        vehiclePrice: 30000,
        downPayment: 5000,
        annualRate: 7.9,
        termMonths: 60,
        provinceCode: 'ON',
        frequency: PaymentFrequency.biWeekly,
        insuranceMonthly: ins,
      );
      expect(
        r.insuranceBiWeekly,
        closeTo(ins * 12 / 26, 0.0001),
        reason: '[CA-3f] insuranceBiWeekly = monthly × 12/26',
      );
    });

    test(
      '[CA-3g] totalInterest bi-weekly < totalInterest mensuel (intérêts réels plus bas)',
      () {
        final rMo = CACalculation.calculate(
          vehiclePrice: 30000,
          downPayment: 5000,
          annualRate: 7.9,
          termMonths: 60,
          provinceCode: 'ON',
          frequency: PaymentFrequency.monthly,
        );
        final rBi = CACalculation.calculate(
          vehiclePrice: 30000,
          downPayment: 5000,
          annualRate: 7.9,
          termMonths: 60,
          provinceCode: 'ON',
          frequency: PaymentFrequency.biWeekly,
        );
        expect(
          rBi.totalInterest,
          lessThan(rMo.totalInterest),
          reason:
              '[CA-3g] bi-weekly rembourse plus vite → moins d\'intérêts totaux',
        );
        expect(
          rMo.totalInterest - rBi.totalInterest,
          greaterThan(40.0),
          reason: '[CA-3g] Économie bi-weekly > \$40 sur 60 mois',
        );
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════
  // CA — PROVINCE QC (CAS CA-4)
  // ═══════════════════════════════════════════════════════════════════
  group('CA — Province QC', () {
    late CACalculation r;
    setUpAll(
      () => r = CACalculation.calculate(
        vehiclePrice: 30000,
        downPayment: 5000,
        annualRate: 7.9,
        termMonths: 60,
        provinceCode: 'QC',
        frequency: PaymentFrequency.monthly,
      ),
    );

    test('[CA-4a] Taxe QC = 14.975% × \$30,000 = \$4,492.50', () {
      expect(
        r.taxAmount,
        closeTo(4492.50, 0.01),
        reason: '[CA-4a] QC GST(5%) + PST(9.975%) = 14.975%',
      );
    });

    test('[CA-4b] Montant financé QC = \$29,492.50', () {
      expect(
        r.loanAmount,
        closeTo(29492.50, 0.01),
        reason: '[CA-4b] 30000 + 4492.50 − 5000 = 29492.50',
      );
    });

    test('[CA-4c] Paiement mensuel QC = PMT(29492.50, 7.9%/12, 60)', () {
      final expected = _pmt(29492.50, 7.9 / 12 / 100, 60);
      expect(
        r.monthlyPayment,
        closeTo(expected, 0.01),
        reason: '[CA-4c] Valeur programmée (spec dit 594.92 — à vérifier)',
      );
      expect(
        r.monthlyPayment,
        greaterThan(590.0),
        reason: '[CA-4c] Plus grand que CA-1 car capital QC plus élevé',
      );
    });

    test('[CA-4d] Intérêts totaux QC = pmt×60 − 29492.50', () {
      expect(
        r.totalInterest,
        closeTo(r.monthlyPayment * 60 - 29492.50, 0.01),
        reason: '[CA-4d] Intérêts totaux cohérents avec PMT',
      );
    });

    test('[CA-4e] Coût total QC = prix + taxe + intérêts', () {
      final expected = 30000.0 + r.taxAmount + r.totalInterest;
      expect(
        r.totalCost,
        closeTo(expected, 0.01),
        reason: '[CA-4e] totalCost = vehiclePrice + taxAmount + totalInterest',
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // CA — TOUTES LES PROVINCES (CAS CA-6)
  // NOTE: SK = GST(5%) + PST(6%) = 11% dans le code.
  // Spec dit 6% ($1,800) — non conforme au code (code correct pour SK véhicules).
  // ═══════════════════════════════════════════════════════════════════
  group('CA — Provinces', () {
    const price = 30000.0;

    void testProv(String code, double rate, double expectedTax) {
      test(
        '[$code] taux=${(rate * 100).toStringAsFixed(3)}% → taxe=\$${expectedTax.toStringAsFixed(2)}',
        () {
          final prov = caProvinceByCode(code);
          expect(
            prov.totalRate,
            closeTo(rate, 0.00001),
            reason: '[$code] totalRate = $rate',
          );
          final r = CACalculation.calculate(
            vehiclePrice: price,
            downPayment: 0,
            annualRate: 0,
            termMonths: 12,
            provinceCode: code,
            frequency: PaymentFrequency.monthly,
          );
          expect(
            r.taxAmount,
            closeTo(expectedTax, 0.01),
            reason:
                '[$code] taxe = $price × ${(rate * 100).toStringAsFixed(3)}%',
          );
        },
      );
    }

    testProv('ON', 0.13000, 3900.00);
    testProv('QC', 0.14975, 4492.50);
    testProv('BC', 0.12000, 3600.00);
    testProv('AB', 0.05000, 1500.00);
    testProv('MB', 0.12000, 3600.00);
    // SK : GST(5%) + PST(6%) = 11% dans le code (spec indique 6%)
    testProv('SK', 0.11000, 3300.00);
    testProv('NS', 0.15000, 4500.00);
    testProv('NB', 0.15000, 4500.00);
    testProv('NL', 0.15000, 4500.00);
    testProv('PE', 0.15000, 4500.00);
    testProv('NT', 0.05000, 1500.00);
    testProv('YT', 0.05000, 1500.00);
    testProv('NU', 0.05000, 1500.00);
  });

  // ═══════════════════════════════════════════════════════════════════
  // CA — COHÉRENCE AMORTISSEMENT (CAS CA-5)
  // ═══════════════════════════════════════════════════════════════════
  group('CA — Amortissement', () {
    const P = 28900.0, rate = 7.9, term = 60;
    late List<AmortizationRow> rows;
    late CACalculation calc;

    setUpAll(() {
      calc = CACalculation.calculate(
        vehiclePrice: 30000,
        downPayment: 5000,
        annualRate: rate,
        termMonths: term,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
      );
      rows = buildSchedule(loanAmount: P, annualRate: rate, termMonths: term);
    });

    test('[CA-5a] Tableau a exactement 60 lignes', () {
      expect(rows.length, term, reason: '[CA-5a] 60 lignes pour 60 mois');
    });

    test('[CA-5b] Somme des principaux = \$28,900.00 ± \$1.00', () {
      final sum = rows.fold(0.0, (s, r) => s + r.principal);
      expect(
        sum,
        closeTo(P, 1.00),
        reason: '[CA-5b] Σ principaux ≈ montant financé',
      );
    });

    test('[CA-5c] Somme des intérêts ≈ \$6,176.34 ± \$1.00', () {
      final sum = rows.fold(0.0, (s, r) => s + r.interest);
      expect(
        sum,
        closeTo(calc.totalInterest, 1.00),
        reason: '[CA-5c] Σ intérêts = totalInterest du calculator',
      );
      expect(sum, closeTo(6176.34, 1.00), reason: '[CA-5c] Spec ≈ \$6,176.34');
    });

    test('[CA-5d] Balance mois 60 = \$0.00 ± \$1.00', () {
      expect(
        rows.last.balance,
        closeTo(0.0, 1.00),
        reason: '[CA-5d] Balance finale = \$0',
      );
    });

    test(
      '[CA-5e] Header Total Cost = Σ paiements + mise de fonds (\$5,000)',
      () {
        final sumPayments = rows.fold(0.0, (s, r) => s + r.payment);
        final headerTotal = sumPayments + 5000.0;
        expect(
          headerTotal,
          closeTo(calc.totalCost, 1.00),
          reason: '[CA-5e] Σ paiements + down ≈ totalCost',
        );
      },
    );

    test(
      '[CA-5f] Chaque ligne : balance = balance_prev − principal (± \$0.02)',
      () {
        double balance = P;
        for (final row in rows) {
          final newBalance = (balance - row.principal).clamp(
            0.0,
            double.infinity,
          );
          expect(
            row.balance,
            closeTo(newBalance, 0.02),
            reason: '[CA-5f] Mois ${row.month}: balance correcte',
          );
          balance = newBalance;
        }
      },
    );

    test('[CA-5g] Mois 1 : intérêt = 28900 × 7.9%/12 ≈ \$190.25', () {
      expect(
        rows.first.interest,
        closeTo(190.25, 0.10),
        reason: '[CA-5g] Premier intérêt = capital × taux mensuel',
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // CAS LIMITES CA (CA-7, CA-8)
  // ═══════════════════════════════════════════════════════════════════
  group('Cas limites CA', () {
    test('[CA-7] Mise de fonds % : 20% de \$40,000 = \$8,000', () {
      // Logique du provider : dpAmount = vehiclePrice × dpPercent / 100
      const vehiclePrice = 40000.0;
      const dpPercent = 20.0;
      final dpAmount = vehiclePrice * dpPercent / 100;
      expect(
        dpAmount,
        closeTo(8000.00, 0.01),
        reason: '[CA-7] 40000 × 20% = 8000',
      );
      final r = CACalculation.calculate(
        vehiclePrice: vehiclePrice,
        downPayment: dpAmount,
        annualRate: 7.9,
        termMonths: 60,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
      );
      expect(
        r.downPayment,
        closeTo(8000.00, 0.01),
        reason: '[CA-7] downPayment stocké = 8000',
      );
    });

    test('[CA-8a] Mise de fonds = \$0 → financé = prix + taxe', () {
      final r = CACalculation.calculate(
        vehiclePrice: 30000,
        downPayment: 0,
        annualRate: 7.9,
        termMonths: 60,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
      );
      expect(
        r.loanAmount,
        closeTo(30000 * 1.13, 0.01),
        reason: '[CA-8a] 30000 + 13% = 33900',
      );
    });

    test('[CA-8b] Mise de fonds = prix → loan = taxe seulement', () {
      final r = CACalculation.calculate(
        vehiclePrice: 30000,
        downPayment: 30000,
        annualRate: 7.9,
        termMonths: 60,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
      );
      expect(
        r.loanAmount,
        closeTo(30000 * 0.13, 0.01),
        reason: '[CA-8b] down=prix → loan = taxe = 3900',
      );
    });

    test('[CA-8c] Durée 24 mois — paiement mensuel correct', () {
      final r = CACalculation.calculate(
        vehiclePrice: 30000,
        downPayment: 5000,
        annualRate: 7.9,
        termMonths: 24,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
      );
      final expected = _pmt(28900.0, 7.9 / 12 / 100, 24);
      expect(
        r.monthlyPayment,
        closeTo(expected, 0.01),
        reason: '[CA-8c] PMT(28900, 7.9%/12, 24)',
      );
    });

    test('[CA-8d] Durée 84 mois — paiement plus petit que 24 mois', () {
      final r84 = CACalculation.calculate(
        vehiclePrice: 30000,
        downPayment: 5000,
        annualRate: 7.9,
        termMonths: 84,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
      );
      final r24 = CACalculation.calculate(
        vehiclePrice: 30000,
        downPayment: 5000,
        annualRate: 7.9,
        termMonths: 24,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
      );
      expect(
        r84.monthlyPayment,
        closeTo(_pmt(28900.0, 7.9 / 12 / 100, 84), 0.01),
        reason: '[CA-8d] PMT(28900, 7.9%/12, 84)',
      );
      expect(
        r84.monthlyPayment,
        lessThan(r24.monthlyPayment),
        reason: '[CA-8d] 7 ans → pmt < 2 ans',
      );
    });

    test('[CA-8e] Taux 0.99% — intérêts positifs faibles', () {
      final r = CACalculation.calculate(
        vehiclePrice: 30000,
        downPayment: 5000,
        annualRate: 0.99,
        termMonths: 60,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
      );
      expect(
        r.totalInterest,
        greaterThan(0),
        reason: '[CA-8e] Intérêts > 0 même à 0.99%',
      );
      expect(
        r.monthlyPayment,
        closeTo(_pmt(28900.0, 0.99 / 12 / 100, 60), 0.01),
        reason: '[CA-8e] PMT(28900, 0.99%/12, 60)',
      );
    });

    test('[CA-8f] Taux 19.99% — intérêts élevés', () {
      final r = CACalculation.calculate(
        vehiclePrice: 30000,
        downPayment: 5000,
        annualRate: 19.99,
        termMonths: 60,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
      );
      expect(
        r.monthlyPayment,
        closeTo(_pmt(28900.0, 19.99 / 12 / 100, 60), 0.01),
        reason: '[CA-8f] PMT(28900, 19.99%/12, 60)',
      );
      expect(
        r.totalInterest,
        greaterThan(r.loanAmount * 0.5),
        reason: '[CA-8f] Intérêts > 50% du capital à 19.99%',
      );
    });

    test('[CA-8g] Mise de fonds excessive → loanAmount = 0', () {
      final r = CACalculation.calculate(
        vehiclePrice: 10000,
        downPayment: 99999,
        annualRate: 7.9,
        termMonths: 60,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
      );
      expect(r.loanAmount, 0.0, reason: '[CA-8g] loanAmount clampé à 0');
      expect(r.monthlyPayment, 0.0, reason: '[CA-8g] pmt = 0 si loan = 0');
    });

    test('[CA-8h] Taux 0% — paiement = loanAmount / terme', () {
      final r = CACalculation.calculate(
        vehiclePrice: 30000,
        downPayment: 5000,
        annualRate: 0,
        termMonths: 60,
        provinceCode: 'ON',
        frequency: PaymentFrequency.monthly,
      );
      expect(r.totalInterest, 0.0, reason: '[CA-8h] Pas d\'intérêt à 0%');
      expect(
        r.monthlyPayment,
        closeTo(28900.0 / 60, 0.01),
        reason: '[CA-8h] pmt = loanAmount / 60 à 0%',
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // CA — TABLEAU AMORTISSEMENT BI-WEEKLY (CAS CA-6)
  // ═══════════════════════════════════════════════════════════════════
  group('CA — Amortissement bi-weekly', () {
    const loanAmt = 28900.0;
    const rate = 7.9;
    const term = 60; // mois → 130 périodes bi-weekly
    late List<AmortizationRow> rows;

    setUpAll(() {
      rows = buildSchedule(
        loanAmount: loanAmt,
        annualRate: rate,
        termMonths: term,
        isBiWeekly: true,
      );
    });

    test('[CA-6a] Tableau bi-weekly : 130 périodes pour 60 mois', () {
      expect(
        rows.length,
        (term / 12 * 26).round(),
        reason: '[CA-6a] 5 ans × 26 = 130 périodes',
      );
    });

    test('[CA-6b] Somme des principaux ≈ loanAmount ± \$1', () {
      final sum = rows.fold(0.0, (s, r) => s + r.principal);
      expect(
        sum,
        closeTo(loanAmt, 1.0),
        reason: '[CA-6b] Σ principaux = capital emprunté',
      );
    });

    test('[CA-6c] Balance finale = \$0 ± \$1', () {
      expect(
        rows.last.balance,
        closeTo(0.0, 1.0),
        reason: '[CA-6c] Prêt entièrement remboursé',
      );
    });

    test('[CA-6d] Paiement bi-weekly < paiement mensuel (26 pmt/an vs 12)', () {
      final monthlyRows = buildSchedule(
        loanAmount: loanAmt,
        annualRate: rate,
        termMonths: term,
      );
      expect(
        rows.first.payment,
        lessThan(monthlyRows.first.payment),
        reason: '[CA-6d] pmt bi-weekly < pmt mensuel',
      );
    });

    test('[CA-6e] Période 1 : intérêt = loanAmt × rate/26/100', () {
      final expected = loanAmt * (rate / 26 / 100);
      expect(
        rows.first.interest,
        closeTo(expected, 0.01),
        reason: '[CA-6e] Premier intérêt bi-weekly correct',
      );
    });

    test('[CA-6f] Somme intérêts bi-weekly < somme intérêts mensuel', () {
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
        reason:
            '[CA-6f] Bi-weekly génère moins d\'intérêts (remboursement plus fréquent)',
      );
    });
  });
}
