import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../../l10n/app_localizations.dart';
import 'package:calcwise_core/calcwise_core.dart'
    show CalcwiseAdFooter, AppSpacing, AppRadius;

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
      final interest = balance * r;
      final isLast = p == nPeriods;
      final payment = isLast ? balance + interest : pmt;
      final principal = payment - interest;
      balance = (balance - principal).clamp(0.0, double.infinity);
      rows.add(
        AmortizationRow(
          period: p,
          payment: payment,
          principal: principal,
          interest: interest,
          balance: balance,
        ),
      );
    }
  } else {
    double monthlyPayment;
    if (annualRate <= 0) {
      monthlyPayment = (loanAmount - balloonAmount) / termMonths;
    } else {
      final r = annualRate / 12 / 100;
      final powN = pow(1 + r, termMonths).toDouble();
      final ballPV = balloonAmount / powN;
      monthlyPayment = (loanAmount - ballPV) * (r * powN) / (powN - 1);
    }
    for (int m = 1; m <= termMonths; m++) {
      final r = annualRate / 12 / 100;
      final interest = balance * r;
      final isLast = m == termMonths;
      final payment = isLast
          ? balance + interest + balloonAmount
          : monthlyPayment;
      final principal = payment - interest - (isLast ? balloonAmount : 0);
      balance = (balance - principal).clamp(0.0, double.infinity);
      rows.add(
        AmortizationRow(
          period: m,
          payment: payment,
          principal: principal,
          interest: interest,
          balance: balance,
        ),
      );
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

  void _shareSchedule(
    List<AmortizationRow> rows,
    NumberFormat fmt,
    String symbol,
    AppLocalizations l10n,
  ) {
    if (rows.isEmpty) return;
    final totalInterest = rows.fold(0.0, (s, r) => s + r.interest);
    final totalPaid = rows.fold(0.0, (s, r) => s + r.payment);
    final header = isBiWeekly
        ? 'Bi-Wk | Payment     | Principal   | Interest    | Balance'
        : 'Month | Payment     | Principal   | Interest    | Balance';
    final sep = '-' * 64;
    // Show at most 60 rows in the share text to keep it readable
    final displayRows = rows.length > 60 ? rows.sublist(0, 60) : rows;
    final lines = displayRows
        .map((r) {
          final period = r.period.toString().padLeft(5);
          final pmt = fmt.format(r.payment).padLeft(12);
          final princ = fmt.format(r.principal).padLeft(12);
          final intStr = fmt.format(r.interest).padLeft(12);
          final bal = fmt.format(r.balance).padLeft(12);
          return '$period | $pmt | $princ | $intStr | $bal';
        })
        .join('\n');
    final truncNote = rows.length > 60
        ? '\n... (${rows.length - 60} more rows)'
        : '';
    final summary =
        '\nTotal Interest: ${fmt.format(totalInterest)}'
        '\nTotal Paid:     ${fmt.format(totalPaid)}'
        '\nLoan Amount:    ${fmt.format(loanAmount)}'
        '\nAnnual Rate:    ${annualRate.toStringAsFixed(2)}%'
        '\nTerm:           ${isBiWeekly ? '${rows.length} bi-weekly periods' : '$termMonths months'}';
    Share.share(
      '${title ?? l10n.amortization}\n$sep\n$header\n$sep\n$lines$truncNote\n$sep$summary',
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = buildSchedule(
      loanAmount: loanAmount,
      annualRate: annualRate,
      termMonths: termMonths,
      balloonAmount: balloonAmount,
      isBiWeekly: isBiWeekly,
    );
    final fmt = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 0);
    final fmt2 = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 2,
    );

    final totalLoanPayments = rows.fold(0.0, (s, r) => s + r.payment);
    final nPeriods = rows.length;
    final insuranceTotal =
        insuranceMonthly * (isBiWeekly ? nPeriods : termMonths);
    final totalCost = totalLoanPayments + downPayment + insuranceTotal;

    // Per-period add-on: insurance expressed per period
    final insPerPeriod = isBiWeekly
        ? insuranceMonthly *
              12 /
              26 // monthly → bi-weekly equivalent
        : insuranceMonthly;

    final l10n = AppLocalizations.of(context)!;
    final periodLabel = isBiWeekly ? 'Bi-wk' : l10n.month;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title ?? l10n.amortization),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share Schedule',
              onPressed: () => _shareSchedule(rows, fmt2, currencySymbol, l10n),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.table_chart), text: 'Schedule'),
              Tab(icon: Icon(Icons.show_chart), text: 'Payoff Chart'),
            ],
          ),
        ),
        bottomNavigationBar: const CalcwiseAdFooter(),
        body: TabBarView(
          children: [
            // ── Tab 1: Amortization Table ──────────────────────────────
            Column(
              children: [
                // Summary header
                Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _HeaderCell(
                              isBiWeekly ? 'Bi-wk Payment' : l10n.payment,
                              fmt2.format(
                                rows.isEmpty ? 0 : rows.first.payment,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _HeaderCell(
                              l10n.totalInterest,
                              fmt.format(
                                rows.fold(0.0, (s, r) => s + r.interest),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _HeaderCell(
                              l10n.totalCostShort,
                              fmt.format(totalCost),
                            ),
                          ),
                        ],
                      ),
                      if (insuranceMonthly > 0) ...[
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            '+ ${fmt2.format(insPerPeriod)}/period insurance · ${fmt.format(insuranceTotal)} total',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                      .withValues(alpha: 0.8),
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Column headers
                Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      _Col(periodLabel, flex: 1),
                      _Col(l10n.payment, flex: 2),
                      _Col(l10n.principal, flex: 2),
                      _Col(l10n.interest, flex: 2),
                      _Col(l10n.balance, flex: 2),
                    ],
                  ),
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
                            : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            _DataCell('${row.period}', flex: 1),
                            _DataCell(fmt2.format(row.payment), flex: 2),
                            _DataCell(fmt2.format(row.principal), flex: 2),
                            _DataCell(fmt2.format(row.interest), flex: 2),
                            _DataCell(
                              fmt2.format(row.balance),
                              flex: 2,
                              bold: row.balance == 0,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // ── Tab 2: Payoff Chart ────────────────────────────────────
            _PayoffChart(
              rows: rows,
              currencySymbol: currencySymbol,
              isBiWeekly: isBiWeekly,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderCell(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
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
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        textAlign: TextAlign.right,
      ),
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
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }
}

// ── Payoff Chart ───────────────────────────────────────────────────────────────

class _PayoffChart extends StatelessWidget {
  final List<AmortizationRow> rows;
  final String currencySymbol;
  final bool isBiWeekly;

  const _PayoffChart({
    required this.rows,
    required this.currencySymbol,
    required this.isBiWeekly,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(child: Text('No data to display.'));
    }

    final primary = Theme.of(context).colorScheme.primary;
    final maxBalance =
        rows.first.balance + rows.first.principal + rows.first.interest;
    // Downsample to at most 100 points for performance
    final step = (rows.length / 100).ceil().clamp(1, rows.length);
    final spots = <FlSpot>[
      FlSpot(0, maxBalance),
      for (int i = 0; i < rows.length; i += step)
        FlSpot(rows[i].period.toDouble(), rows[i].balance),
    ];

    final fmt = NumberFormat.compactCurrency(
      symbol: currencySymbol,
      decimalDigits: 0,
    );
    final periodLabel = isBiWeekly ? 'Bi-wk' : 'Mo';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Remaining Balance Over Time',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxBalance * 1.05,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 56,
                      getTitlesWidget: (value, meta) => Text(
                        fmt.format(value),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()} $periodLabel',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                      return LineTooltipItem(
                        '$periodLabel ${s.x.toInt()}\n${NumberFormat.currency(symbol: currencySymbol, decimalDigits: 0).format(s.y)}',
                        Theme.of(
                          context,
                        ).textTheme.bodySmall!.copyWith(color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: primary.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
