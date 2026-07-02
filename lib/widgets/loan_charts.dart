import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:calcwise_core/calcwise_core.dart'
    show AppSpacing, AppTextSize, AmountFormatter, CalcwiseChartTokens;

// ─────────────────────────────────────────────────────────────────────────────
// 1. LoanDonutChart — Principal vs Total Interest breakdown
// ─────────────────────────────────────────────────────────────────────────────

/// Donut pie chart showing principal vs total interest.
///
/// Touch-interactive: tapping a section highlights it.
class LoanDonutChart extends StatefulWidget {
  final double principal;
  final double totalInterest;
  final Color primaryColor;
  final Color accentColor;
  final String currencyCode;

  const LoanDonutChart({
    super.key,
    required this.principal,
    required this.totalInterest,
    required this.primaryColor,
    required this.accentColor,
    this.currencyCode = 'USD',
  });

  @override
  State<LoanDonutChart> createState() => _LoanDonutChartState();
}

class _LoanDonutChartState extends State<LoanDonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.principal + widget.totalInterest;
    if (total <= 0) {
      return const SizedBox.shrink();
    }

    final compactFmt = NumberFormat.compactCurrency(
      symbol: '\$',
      decimalDigits: 0,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 180,
          child: Semantics(
            label: 'Donut chart showing principal versus total interest. '
                'Principal: ${compactFmt.format(widget.principal)}, '
                'total interest: ${compactFmt.format(widget.totalInterest)}.',
            excludeSemantics: true,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                centerSpaceRadius: CalcwiseChartTokens.donutCenterR,
                sectionsSpace: 2,
                sections: [
                  PieChartSectionData(
                    value: widget.principal,
                    color: widget.primaryColor,
                    radius: _touchedIndex == 0
                        ? CalcwiseChartTokens.donutSectionR + 4
                        : CalcwiseChartTokens.donutSectionR,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: widget.totalInterest,
                    color: widget.accentColor,
                    radius: _touchedIndex == 1
                        ? CalcwiseChartTokens.donutSectionR + 4
                        : CalcwiseChartTokens.donutSectionR,
                    showTitle: false,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _DonutLegend(
          items: [
            _LegendItem(
              color: widget.primaryColor,
              label: 'Principal',
              amount: AmountFormatter.compact(
                  widget.principal, widget.currencyCode),
            ),
            _LegendItem(
              color: widget.accentColor,
              label: 'Interest',
              amount: AmountFormatter.compact(
                  widget.totalInterest, widget.currencyCode),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem {
  final Color color;
  final String label;
  final String amount;
  const _LegendItem({
    required this.color,
    required this.label,
    required this.amount,
  });
}

class _DonutLegend extends StatelessWidget {
  final List<_LegendItem> items;
  const _DonutLegend({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${item.label}: ${item.amount}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: AppTextSize.sm,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. LoanTermComparisonChart — Monthly payments for different terms
// ─────────────────────────────────────────────────────────────────────────────

/// Horizontal bar chart comparing monthly payments across loan term scenarios.
///
/// Scenarios are sorted ascending by term months.
class LoanTermComparisonChart extends StatelessWidget {
  final List<({int months, double payment})> scenarios;
  final Color barColor;

  const LoanTermComparisonChart({
    super.key,
    required this.scenarios,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    if (scenarios.isEmpty) return const SizedBox.shrink();

    final sorted = List<({int months, double payment})>.from(scenarios)
      ..sort((a, b) => a.months.compareTo(b.months));

    final maxPayment =
        sorted.fold(0.0, (m, s) => s.payment > m ? s.payment : m);
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return SizedBox(
      height: (sorted.length * 52.0).clamp(120, 400),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxPayment * 1.15,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 64,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= sorted.length) return const SizedBox();
                  final s = sorted[idx];
                  final years = s.months ~/ 12;
                  final rem = s.months % 12;
                  final label = rem == 0 ? '${years}yr' : '${s.months}mo';
                  return Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: CalcwiseChartTokens.axisFontSize,
                        ),
                  );
                },
              ),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 72,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= sorted.length) return const SizedBox();
                  return Text(
                    '${fmt.format(sorted[idx].payment)}/mo',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: CalcwiseChartTokens.axisFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: List.generate(sorted.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: sorted[i].payment,
                  width: CalcwiseChartTokens.barWidth,
                  color: barColor,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. LoanAmortizationChart — Remaining balance over time
// ─────────────────────────────────────────────────────────────────────────────

/// Line chart showing remaining loan balance over time with gradient fill
/// and touch tooltips.
///
/// When [termMonths] > 24 the x-axis labels switch to years.
class LoanAmortizationChart extends StatelessWidget {
  final List<double> balances;
  final int termMonths;
  final Color lineColor;

  const LoanAmortizationChart({
    super.key,
    required this.balances,
    required this.termMonths,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    if (balances.isEmpty) return const SizedBox.shrink();

    final maxBal = balances.fold(0.0, (m, b) => b > m ? b : m);
    final useYears = termMonths > 24;

    // Downsample to at most 100 points for performance
    final step = (balances.length / 100).ceil().clamp(1, balances.length);
    final spots = <FlSpot>[
      for (int i = 0; i < balances.length; i += step)
        FlSpot(i.toDouble(), balances[i]),
    ];
    // Ensure last point is always included
    if (spots.last.x != (balances.length - 1).toDouble()) {
      spots.add(FlSpot(
        (balances.length - 1).toDouble(),
        balances.last,
      ));
    }

    final compactFmt = NumberFormat.compactCurrency(
      symbol: '\$',
      decimalDigits: 0,
    );

    return SizedBox(
      height: 220,
      child: Semantics(
        label: 'Line chart showing remaining balance over '
            '$termMonths months. Starting: '
            '${compactFmt.format(balances.first)}, '
            'ending: ${compactFmt.format(balances.last)}.',
        excludeSemantics: true,
        child: LineChart(
          duration: CalcwiseChartTokens.swapDuration,
          LineChartData(
            minY: 0,
            maxY: maxBal * 1.05,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.25),
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
                    compactFmt.format(value),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: CalcwiseChartTokens.axisFontSize,
                        ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) {
                    final month = value.toInt();
                    if (useYears) {
                      if (month % 12 != 0) return const SizedBox();
                      return Text(
                        'Yr ${month ~/ 12}',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: CalcwiseChartTokens.axisFontSize,
                                ),
                      );
                    }
                    return Text(
                      'Mo $month',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: CalcwiseChartTokens.axisFontSize,
                          ),
                    );
                  },
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
                  final month = s.x.toInt();
                  final bal = NumberFormat.currency(
                    symbol: '\$',
                    decimalDigits: 0,
                  ).format(s.y);
                  return LineTooltipItem(
                    'Month $month\n$bal',
                    Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onInverseSurface,
                        ),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: lineColor,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      lineColor.withValues(alpha: 0.25),
                      lineColor.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
