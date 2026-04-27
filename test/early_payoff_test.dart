// Early Payoff Calculator — Tests
// Reference: loan=$28,900 | rate=7.9% | term=60 months | extra=$100/mo

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

/// Standard PMT formula
double _pmt(double p, double r, int n) {
  if (r <= 0) return n > 0 ? p / n : 0;
  final powN = pow(1 + r, n).toDouble();
  return p * (r * powN) / (powN - 1);
}

/// Simulate early payoff — returns (periods, totalInterest)
(int periods, double totalInterest) _simulate(
    double loanAmount, double annualRate, int termMonths, double extraMonthly) {
  final rate = annualRate / 12 / 100;
  final stdPayment = _pmt(loanAmount, rate, termMonths);
  final totalPayment = stdPayment + extraMonthly;
  double balance = loanAmount;
  int periods = 0;
  double interestPaid = 0;
  while (balance > 0 && periods < termMonths * 2) {
    final interest = balance * rate;
    interestPaid += interest;
    final principal = totalPayment - interest;
    if (principal <= 0) break;
    balance -= principal;
    periods++;
    if (balance <= 0) break;
  }
  return (periods, interestPaid.clamp(0.0, double.infinity));
}

void main() {
  const loan       = 28900.0;
  const rate       = 7.9;
  const term       = 60;
  const extraMonth = 100.0;

  test('[EP-1] Standard payment ≈ \$584.61', () {
    final pmt = _pmt(loan, rate / 12 / 100, term);
    expect(pmt, closeTo(584.61, 0.10),
        reason: '[EP-1] PMT(28900, 7.9%/12, 60)');
  });

  test('[EP-2] Extra \$100/mo reduces loan term', () {
    final (earlyPeriods, _) = _simulate(loan, rate, term, extraMonth);
    expect(earlyPeriods, lessThan(term),
        reason: '[EP-2] Extra payment shortens term');
    expect(earlyPeriods, greaterThan(0),
        reason: '[EP-2] Term must be positive');
  });

  test('[EP-3] Extra \$100/mo saves interest vs no extra', () {
    final (_, interestWithExtra) = _simulate(loan, rate, term, extraMonth);
    final (_, interestNoExtra)   = _simulate(loan, rate, term, 0);
    expect(interestWithExtra, lessThan(interestNoExtra),
        reason: '[EP-3] Extra payment reduces total interest');
    expect(interestNoExtra - interestWithExtra, greaterThan(100.0),
        reason: '[EP-3] Interest savings > \$100 on a 5-yr \$28,900 loan');
  });

  test('[EP-4] Extra = 0 → same term and interest as standard', () {
    final (periods0, interest0)   = _simulate(loan, rate, term, 0);
    final stdPmt  = _pmt(loan, rate / 12 / 100, term);
    final stdInt  = stdPmt * term - loan;
    // Floating-point amortization may require at most 1 extra period to clear balance
    expect(periods0, inInclusiveRange(term, term + 1),
        reason: '[EP-4] Zero extra → full term (±1 for floating-point precision)');
    expect(interest0, closeTo(stdInt, 2.0),
        reason: '[EP-4] Zero extra → same total interest');
  });

  test('[EP-5] Extra = full monthly payment → term roughly halved', () {
    final stdPmt = _pmt(loan, rate / 12 / 100, term);
    final (halvePeriods, _) = _simulate(loan, rate, term, stdPmt);
    expect(halvePeriods, lessThan(term ~/ 2 + 5),
        reason: '[EP-5] Doubling payment roughly halves term');
  });

  test('[EP-6] monthsSaved = term - earlyPeriods > 0 for extra > 0', () {
    final (earlyPeriods, _) = _simulate(loan, rate, term, extraMonth);
    final monthsSaved = term - earlyPeriods;
    expect(monthsSaved, greaterThan(0),
        reason: '[EP-6] Positive months saved');
    expect(monthsSaved, lessThan(term),
        reason: '[EP-6] Cannot save more months than term');
  });

  test('[EP-7] Rate 0% — extra payment shortens term proportionally', () {
    final (earlyPeriods, _) = _simulate(loan, 0, term, 100);
    expect(earlyPeriods, lessThan(term),
        reason: '[EP-7] 0% rate: extra payment still shortens term');
  });

  group('[EP-8] Edge cases', () {
    test('[EP-8a] Very large extra → loan paid off in very few periods', () {
      final (periods, _) = _simulate(loan, rate, term, 5000.0);
      expect(periods, lessThan(10),
          reason: '[EP-8a] \$5000 extra on \$28,900 loan → paid off quickly');
    });

    test('[EP-8b] Minimal extra \$25 → modestly shorter term', () {
      final (periods, _) = _simulate(loan, rate, term, 25.0);
      expect(periods, lessThan(term),
          reason: '[EP-8b] Even \$25 extra reduces term');
    });
  });
}
