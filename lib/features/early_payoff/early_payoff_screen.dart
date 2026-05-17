import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/shared_inputs.dart';
import '../../services/analytics_service.dart';
import 'package:calcwise_core/calcwise_core.dart' show CalcwiseAdFooter;
import 'package:calcwise_core/calcwise_core.dart' hide SectionCard, ResultTile;

/// Early Payoff Calculator — shows how extra monthly payments reduce
/// loan term and total interest paid.
class EarlyPayoffScreen extends StatefulWidget {
  final double loanAmount;
  final double annualRate;
  final int termMonths;
  final String currencySymbol;
  final String flavor;

  const EarlyPayoffScreen({
    super.key,
    required this.loanAmount,
    required this.annualRate,
    required this.termMonths,
    this.currencySymbol = '\$',
    required this.flavor,
  });

  @override
  State<EarlyPayoffScreen> createState() => _EarlyPayoffScreenState();
}

class _EarlyPayoffScreenState extends State<EarlyPayoffScreen> {
  double _extraMonthly = 100;

  @override
  void initState() {
    super.initState();
    // log immediately on open
    AnalyticsService.instance.logTabChanged('early_payoff');
  }

  _PayoffResult _compute(double extraPayment) {
    final rate = widget.annualRate / 12 / 100;
    // Standard monthly payment
    final double stdPayment;
    if (rate <= 0) {
      stdPayment = widget.termMonths > 0
          ? widget.loanAmount / widget.termMonths
          : 0;
    } else {
      final powN = pow(1 + rate, widget.termMonths).toDouble();
      stdPayment = widget.loanAmount * (rate * powN) / (powN - 1);
    }

    // Standard total interest
    final double stdInterest =
        (stdPayment * widget.termMonths - widget.loanAmount).clamp(
          0.0,
          double.infinity,
        );

    // Early payoff with extra payment
    double balance = widget.loanAmount;
    int periods = 0;
    double earlyInterest = 0;
    final totalPayment = stdPayment + extraPayment;

    while (balance > 0 && periods < widget.termMonths * 2) {
      final interest = balance * rate;
      earlyInterest += interest;
      final principal = totalPayment - interest;
      if (principal <= 0)
        break; // rate so high extra payment doesn't cover interest
      balance -= principal;
      periods++;
      if (balance <= 0) {
        balance = 0;
        break;
      }
    }

    final monthsSaved = widget.termMonths - periods;
    final interestSaved =
        stdInterest - earlyInterest.clamp(0.0, double.infinity);
    final earlyInterestClamped = earlyInterest.clamp(0.0, double.infinity);

    return _PayoffResult(
      stdMonthlyPayment: stdPayment,
      stdTotalInterest: stdInterest,
      earlyMonths: periods,
      earlyTotalInterest: earlyInterestClamped,
      monthsSaved: monthsSaved.clamp(0, widget.termMonths),
      interestSaved: interestSaved.clamp(0.0, double.infinity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fmt = NumberFormat.currency(
      symbol: widget.currencySymbol,
      decimalDigits: 2,
    );
    final result = _compute(_extraMonthly);

    return Scaffold(
      appBar: AppBar(title: const Text('Early Payoff')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
              children: [
                // ── Loan summary ────────────────────────────────────────────
                SectionCard(
                  title: 'Loan Summary',
                  children: [
                    ResultTile(
                      label: l10n.loanAmount,
                      value: fmt.format(widget.loanAmount),
                    ),
                    ResultTile(
                      label: l10n.annualRate,
                      value: '${widget.annualRate.toStringAsFixed(2)}%',
                    ),
                    ResultTile(
                      label: l10n.termMonths,
                      value:
                          '${widget.termMonths} mo (${widget.termMonths ~/ 12} yr)',
                    ),
                    ResultTile(
                      label: l10n.monthlyPayment,
                      value: fmt.format(result.stdMonthlyPayment),
                    ),
                  ],
                ),

                // ── Extra payment slider ─────────────────────────────────────
                SectionCard(
                  title: 'Extra Monthly Payment',
                  children: [
                    CurrencySliderInput(
                      label: 'Extra amount / month',
                      value: _extraMonthly,
                      min: 0,
                      max: result.stdMonthlyPayment.clamp(50, 2000),
                      step: 25,
                      symbol: widget.currencySymbol,
                      onChanged: (v) {
                        setState(() => _extraMonthly = v);
                        if (v > 0) {
                          AnalyticsService.instance.logEarlyPayoffCalculated(
                            flavor: widget.flavor,
                            monthsSaved: _compute(v).monthsSaved,
                          );
                        }
                      },
                    ),
                  ],
                ),

                // ── Results ──────────────────────────────────────────────────
                if (_extraMonthly > 0) ...[
                  SectionCard(
                    title: 'With Extra Payment',
                    children: [
                      ResultTile(
                        label: 'New Monthly Payment',
                        value: fmt.format(
                          result.stdMonthlyPayment + _extraMonthly,
                        ),
                        isHighlight: true,
                      ),
                      ResultTile(
                        label: 'Paid Off In',
                        value:
                            '${result.earlyMonths} mo (${(result.earlyMonths / 12).toStringAsFixed(1)} yr)',
                      ),
                      ResultTile(
                        label: l10n.totalInterest,
                        value: fmt.format(result.earlyTotalInterest),
                      ),
                    ],
                  ),

                  // ── Savings highlight ──────────────────────────────────────
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.savings_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'You Save',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _SavingsChip(
                                label: 'Interest Saved',
                                value: fmt.format(result.interestSaved),
                                context: context,
                              ),
                              _SavingsChip(
                                label: 'Months Saved',
                                value: '${result.monthsSaved} mo',
                                context: context,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const CalcwiseAdFooter(),
        ],
      ),
    );
  }
}

class _PayoffResult {
  final double stdMonthlyPayment;
  final double stdTotalInterest;
  final int earlyMonths;
  final double earlyTotalInterest;
  final int monthsSaved;
  final double interestSaved;

  const _PayoffResult({
    required this.stdMonthlyPayment,
    required this.stdTotalInterest,
    required this.earlyMonths,
    required this.earlyTotalInterest,
    required this.monthsSaved,
    required this.interestSaved,
  });
}

class _SavingsChip extends StatelessWidget {
  final String label;
  final String value;
  final BuildContext context;

  const _SavingsChip({
    required this.label,
    required this.value,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(ctx).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
            color: Theme.of(ctx).colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}
