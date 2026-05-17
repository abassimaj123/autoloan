import 'package:calcwise_core/calcwise_core.dart'
    show Insight, InsightSeverity;

// ── Engine ────────────────────────────────────────────────────────────────────

class InsightEngine {
  InsightEngine._();

  /// Returns up to [maxCount] insights (alerts first) for an auto loan.
  static List<Insight> generate({
    required double vehiclePrice,
    required double loanAmount,
    required double annualRatePct,
    required int termMonths,
    required double monthlyPayment,
    required double totalInterest,
    double? downPayment,
    String currencySymbol = '\$',
    bool isFr = false,
    int maxCount = 3,
  }) {
    final insights = <Insight>[];

    // Local formatter using the provided currency symbol
    String fmtC(double amount) {
      final abs = amount.abs();
      String str;
      if (abs >= 1000000) {
        str = '$currencySymbol${(abs / 1000000).toStringAsFixed(2)}M';
      } else if (abs >= 1000) {
        str = '$currencySymbol${(abs / 1000).toStringAsFixed(1)}K';
      } else {
        str = '$currencySymbol${abs.toStringAsFixed(0)}';
      }
      return amount < 0 ? '-$str' : str;
    }

    // ── 1. Total interest as % of vehicle price ───────────────────────────
    if (vehiclePrice > 0 && totalInterest >= 0) {
      final pct = totalInterest / vehiclePrice * 100;
      if (pct > 25) {
        insights.add(
          Insight(
            severity: InsightSeverity.alert,
            title: isFr ? 'Coût des intérêts élevé' : 'High Interest Cost',
            body: isFr
                ? 'Vous paierez ${fmtC(totalInterest)} en intérêts — ${pct.toStringAsFixed(0)}% du prix du véhicule.'
                : "You'll pay ${fmtC(totalInterest)} in interest — ${pct.toStringAsFixed(0)}% of the vehicle price.",
          ),
        );
      } else if (pct >= 15) {
        insights.add(
          Insight(
            severity: InsightSeverity.warning,
            title: isFr ? 'Coût des intérêts modéré' : 'Moderate Interest Cost',
            body: isFr
                ? 'Vous paierez ${fmtC(totalInterest)} en intérêts — ${pct.toStringAsFixed(0)}% du prix du véhicule.'
                : "You'll pay ${fmtC(totalInterest)} in interest — ${pct.toStringAsFixed(0)}% of the vehicle price.",
          ),
        );
      } else {
        insights.add(
          Insight(
            severity: InsightSeverity.good,
            title: isFr
                ? 'Financement raisonnable'
                : 'Reasonable Financing Cost',
            body: isFr
                ? 'Coût des intérêts raisonnable : ${fmtC(totalInterest)} (${pct.toStringAsFixed(0)}% du prix).'
                : 'Reasonable financing cost: ${fmtC(totalInterest)} in interest (${pct.toStringAsFixed(0)}% of price).',
          ),
        );
      }
    }

    // ── 2. Loan term warning ──────────────────────────────────────────────
    if (termMonths > 60) {
      insights.add(
        Insight(
          severity: InsightSeverity.warning,
          title: isFr ? 'Prêt long terme' : 'Long Loan Term',
          body: isFr
              ? 'Les prêts de 72 mois peuvent vous mettre « sous l\'eau » (valeur < solde dû).'
              : 'Loans over 60 months risk being underwater — you may owe more than the car is worth.',
        ),
      );
    } else if (termMonths <= 48) {
      insights.add(
        Insight(
          severity: InsightSeverity.good,
          title: isFr ? 'Durée courte' : 'Short Loan Term',
          body: isFr
              ? 'Durée courte (${termMonths ~/ 12} ans) — moins de risque d\'être sous l\'eau.'
              : 'Short loan term (${termMonths ~/ 12} yr) reduces interest cost and underwater risk.',
        ),
      );
    }

    // ── 3. Down payment impact ────────────────────────────────────────────
    if (downPayment != null && vehiclePrice > 0) {
      final dpPct = downPayment / vehiclePrice * 100;
      if (dpPct < 20) {
        insights.add(
          Insight(
            severity: InsightSeverity.warning,
            title: isFr ? 'Mise de fonds faible' : 'Low Down Payment',
            body: isFr
                ? 'Moins de 20% de mise de fonds (${dpPct.toStringAsFixed(0)}%) — risque d\'être sous l\'eau.'
                : 'Consider 20%+ down (currently ${dpPct.toStringAsFixed(0)}%) to avoid being underwater on the loan.',
          ),
        );
      }
    }

    // ── 4. Rate risk: cost of each 1% rate rise ───────────────────────────
    if (loanAmount > 0 && termMonths > 0 && annualRatePct > 0) {
      final rateInc = (annualRatePct + 1.0) / 100 / 12;
      final rateCurr = annualRatePct / 100 / 12;
      final piCurr =
          loanAmount *
          rateCurr /
          (1 - _pow(1 + rateCurr, -termMonths.toDouble()));
      final piNew =
          loanAmount *
          rateInc /
          (1 - _pow(1 + rateInc, -termMonths.toDouble()));
      final delta = (piNew - piCurr).abs().roundToDouble();
      if (delta >= 10) {
        insights.add(
          Insight(
            severity: InsightSeverity.warning,
            title: isFr ? 'Risque de taux' : 'Rate Risk',
            body: isFr
                ? 'Chaque augmentation de 1% du taux ajoute ~${fmtC(delta)}/mois à votre paiement.'
                : 'Each 1% rate increase adds ~${fmtC(delta)}/mo to your payment.',
          ),
        );
      }
    }

    // ── 5. Total cost of ownership tip ────────────────────────────────────
    if (vehiclePrice > 0 && termMonths > 0) {
      final termYears = termMonths ~/ 12;
      // Estimate running costs: insurance ~$1,200/yr + maintenance ~$800/yr
      final estRunning = (1200.0 + 800.0) * termYears;
      final tco = vehiclePrice + totalInterest + estRunning;
      insights.add(
        Insight(
          severity: InsightSeverity.good,
          title: isFr ? 'Coût total estimé' : 'Estimated Total Cost',
          body: isFr
              ? 'Prix + intérêts + coûts estimés ≈ ${fmtC(tco)} sur $termYears ans.'
              : 'Price + interest + est. running costs ≈ ${fmtC(tco)} over $termYears yrs.',
        ),
      );
    }

    // Prioritise: alerts > warnings > good; cap at maxCount
    final alerts = insights
        .where((i) => i.severity == InsightSeverity.alert)
        .toList();
    final warnings = insights
        .where((i) => i.severity == InsightSeverity.warning)
        .toList();
    final goods = insights
        .where((i) => i.severity == InsightSeverity.good)
        .toList();

    final ordered = [...alerts, ...warnings, ...goods];
    if (ordered.isEmpty) {
      ordered.add(
        Insight(
          severity: InsightSeverity.good,
          title: 'Calculation Complete',
          body: 'Scroll down to see the full breakdown.',
        ),
      );
    }
    return ordered.take(maxCount).toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static double _pow(double base, double exp) {
    if (exp == 0) return 1;
    double result = 1;
    final n = exp.abs().round();
    for (int i = 0; i < n; i++) {
      result *= base;
    }
    return exp < 0 ? 1 / result : result;
  }
}
