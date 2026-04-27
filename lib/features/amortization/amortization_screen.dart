import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';

class AmortizationRow {
  final int period;
  final double payment, principal, interest, balance;
  const AmortizationRow({
    required this.period,
    required this.payment,
    required this.principal,
    required this.interest,
    required this.balance,
  });
  // Backward-compat alias
  int get month => period;
}

List<AmortizationRow> buildSchedule({
  required double loanAmount,
  required double annualRate,
  required int termMonths,
  double balloonAmount = 0,
  bool isBiWeekly = false,
}) {
  if (loanAmount <= 0 || termMonths <= 0) return [];

  final rows = <AmortizationRow>[];
  double balance = loanAmount;

  if (isBiWeekly) {
    final nPeriods = (termMonths / 12 * 26).round();
    final r = annualRate / 26 / 100;
    double pmt;
    if (annualRate <= 0) {
      pmt = loanAmount / nPeriods;
    } else {
      final powN = pow(1 + r, nPeriods).toDouble();
      pmt = loanAmount * (r * powN) / (powN - 1);
    }
    for (int p = 1; p <= nPeriods; p++) {
      final interest  = balance * r;
      final isLast    = p == nPeriods;
      final payment   = isLast ? balance + interest : pmt;
      final principal = payment - interest;
      balance = (balance - principal).clamp(0.0, double.infinity);
      rows.add(AmortizationRow(
        period: p,
        payment: payment,
        principal: principal,
        interest: interest,
        balance: balance,
      ));
    }
  } else {
    double monthlyPayment;
    if (annualRate <= 0) {
      monthlyPayment = (loanAmount - balloonAmount) / termMonths;
    } else {
      final r    = annualRate / 12 / 100;
      final powN = pow(1 + r, termMonths).toDouble();
      final ballPV = balloonAmount / powN;
      monthlyPayment = (loanAmount - ballPV) * (r * powN) / (powN - 1);
    }
    for (int m = 1; m <= termMonths; m++) {
      final r        = annualRate / 12 / 100;
      final interest  = balance * r;
      final isLast    = m == termMonths;
      final payment   = isLast ? balance + interest + balloonAmount : monthlyPayment;
      final principal = payment - interest - (isLast ? balloonAmount : 0);
      balance = (balance - principal).clamp(0.0, double.infinity);
      rows.add(AmortizationRow(
        period: m,
        payment: payment,
        principal: principal,
        interest: interest,
        balance: balance,
      ));
    }
  }
  return rows;
}

class AmortizationScreen extends StatelessWidget {
  final double loanAmount;
  final double annualRate;
  final int termMonths;
  final double balloonAmount;
  final double downPayment;
  final double insuranceMonthly;
  final String currencySymbol;
  final bool isBiWeekly;
  /// Override AppBar title (e.g. UK uses 'Amortisation Schedule')
  final String? title;

  const AmortizationScreen({
    super.key,
    required this.loanAmount,
    required this.annualRate,
    required this.termMonths,
    this.balloonAmount = 0,
    this.downPayment = 0,
    this.insuranceMonthly = 0,
    this.currencySymbol = '\$',
    this.isBiWeekly = false,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final rows = buildSchedule(
      loanAmount: loanAmount,
      annualRate: annualRate,
      termMonths: termMonths,
      balloonAmount: balloonAmount,
      isBiWeekly: isBiWeekly,
    );
    final fmt   = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 0);
    final fmt2  = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);

    final totalLoanPayments = rows.fold(0.0, (s, r) => s + r.payment);
    final nPeriods          = rows.length;
    final insuranceTotal    = insuranceMonthly * (isBiWeekly ? nPeriods : termMonths);
    final totalCost         = totalLoanPayments + downPayment + insuranceTotal;

    // Per-period add-on: insurance expressed per period
    final insPerPeriod = isBiWeekly
        ? insuranceMonthly * 12 / 26   // monthly → bi-weekly equivalent
        : insuranceMonthly;

    final l10n      = AppLocalizations.of(context)!;
    final periodLabel = isBiWeekly ? 'Bi-wk' : l10n.month;

    return Scaffold(
      appBar: AppBar(title: Text(title ?? l10n.amortization)),
      body: Column(children: [
        // ── Summary header ─────────────────────────────────────────────
        Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(child: _HeaderCell(
                  isBiWeekly ? 'Bi-wk Payment' : l10n.payment,
                  fmt2.format(rows.isEmpty ? 0 : rows.first.payment),
                )),
                Expanded(child: _HeaderCell(
                  l10n.totalInterest,
                  fmt.format(rows.fold(0.0, (s, r) => s + r.interest)),
                )),
                Expanded(child: _HeaderCell(l10n.totalCostShort, fmt.format(totalCost))),
              ]),
              if (insuranceMonthly > 0) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    '+ ${fmt2.format(insPerPeriod)}/period insurance · ${fmt.format(insuranceTotal)} total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // ── Column headers ──────────────────────────────────────────────
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(children: [
            _Col(periodLabel, flex: 1),
            _Col(l10n.payment, flex: 2),
            _Col(l10n.principal, flex: 2),
            _Col(l10n.interest, flex: 2),
            _Col(l10n.balance, flex: 2),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final row = rows[i];
              final isOdd = i.isOdd;
              return Container(
                color: isOdd
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(children: [
                  _DataCell('${row.period}', flex: 1),
                  _DataCell(fmt2.format(row.payment), flex: 2),
                  _DataCell(fmt2.format(row.principal), flex: 2),
                  _DataCell(fmt2.format(row.interest), flex: 2),
                  _DataCell(fmt2.format(row.balance), flex: 2, bold: row.balance == 0),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderCell(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      Text(value,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold)),
    ]);
  }
}

class _Col extends StatelessWidget {
  final String text;
  final int flex;
  const _Col(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.right),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool bold;
  const _DataCell(this.text, {required this.flex, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
          textAlign: TextAlign.right),
    );
  }
}
