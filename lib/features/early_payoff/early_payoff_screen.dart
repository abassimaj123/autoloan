import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/shared_inputs.dart';
import '../../widgets/save_scenario_button.dart';
import '../../services/analytics_service.dart';
import '../../main.dart' show smartHistoryService, paywallSession;
import '../history/history_screen.dart';
import 'package:calcwise_core/calcwise_core.dart'
    show CalcwiseAdFooter, ResultHasher, PaywallTrigger;
import 'package:calcwise_core/calcwise_core.dart' hide SectionCard, ResultTile, PaywallHard;
import '../../widgets/paywall_soft.dart';
import '../../widgets/paywall_hard.dart';
import '../../core/freemium/freemium_service.dart';
import '../pdf/pdf_export_service.dart';

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
  late CalcwiseAdService _adService;
  double _extraMonthly = 100;

  static double _roundTo(double v, double step) => (v / step).round() * step;

  Future<void> _saveScenario(String? label) async {
    HapticFeedback.mediumImpact();
    final result = _compute(_extraMonthly);
    final hash = ResultHasher.hashMixed({
      'loanAmount': _roundTo(widget.loanAmount, 1000),
      'annualRate': _roundTo(widget.annualRate, 0.25),
      'termMonths': widget.termMonths,
      'extraMonthly': _roundTo(_extraMonthly, 25),
    });
    await smartHistoryService.saveScenario(
      appKey: 'autoloan',
      screenId: 'early_payoff',
      inputHash: hash,
      l1: {
        'loanAmount': widget.loanAmount,
        'extraMonthly': _extraMonthly,
        'monthsSaved': result.monthsSaved,
        'interestSaved': result.interestSaved,
      },
      l2: {
        'inputs': {
          'loanAmount': widget.loanAmount,
          'annualRate': widget.annualRate,
          'termMonths': widget.termMonths,
          'extraPayment': _extraMonthly,
        },
        'results': {
          'monthsSaved': result.monthsSaved,
          'interestSaved': result.interestSaved,
          'earlyMonths': result.earlyMonths,
          'earlyTotalInterest': result.earlyTotalInterest,
          'stdMonthlyPayment': result.stdMonthlyPayment,
        },
      },
      label: label,
    );
    HistoryScreen.refreshNotifier.value++;
    try { AnalyticsService.instance.logSave(); } catch (_) {}
    try { AnalyticsService.instance.logHistorySaved(); } catch (_) {}
    _adService.onSave();
    final trigger = await paywallSession.recordAction();
    if (!mounted) return;
    if (trigger == PaywallTrigger.soft) PaywallSoft.show(context);
    if (trigger == PaywallTrigger.hard) PaywallHard.show(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adService = context.read<CalcwiseAdService>();
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView('early_payoff');
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
      appBar: AppBar(title: Text(l10n.earlyPayoff)),
      body: Column(
        children: [
          Expanded(
            child: CalcwiseScreenScaffold(
              resultKey: ValueKey(result.hashCode),
              children: [
                // ── Loan summary ────────────────────────────────────────────
                SectionCard(
                  title: l10n.loanSummary,
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
                  title: l10n.extraMonthlyPayment,
                  children: [
                    CurrencySliderInput(
                      label: l10n.extraAmountPerMonth,
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
                    title: l10n.withExtraPayment,
                    children: [
                      ResultTile(
                        label: l10n.newMonthlyPayment,
                        value: fmt.format(
                          result.stdMonthlyPayment + _extraMonthly,
                        ),
                        isHighlight: true,
                      ),
                      ResultTile(
                        label: l10n.paidOffIn,
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
                                l10n.youSave,
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
                                label: l10n.interestSaved,
                                value: fmt.format(result.interestSaved),
                                context: context,
                              ),
                              _SavingsChip(
                                label: l10n.monthsSaved,
                                value: '${result.monthsSaved} ${l10n.month}',
                                context: context,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Save Scenario ──────────────────────────────────────────
                  SaveScenarioButton(onSave: _saveScenario),

                  // ── PDF Export (premium) ───────────────────────────────────
                  if (freemiumService.hasFullAccess || freemiumService.isRewarded)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          final isFr =
                              Localizations.localeOf(context).languageCode == 'fr';
                          try {
                            await PdfExportService.exportLoanPdf(
                              title: l10n.earlyPayoff,
                              currencySymbol: widget.currencySymbol,
                              loanAmount: widget.loanAmount,
                              annualRate: widget.annualRate,
                              termMonths: widget.termMonths,
                              downPayment: 0,
                              isFrench: isFr,
                              summary: [
                                MapEntry(l10n.loanAmount,
                                    fmt.format(widget.loanAmount)),
                                MapEntry(l10n.annualRate,
                                    '${widget.annualRate.toStringAsFixed(2)}%'),
                                MapEntry(l10n.termMonths,
                                    '${widget.termMonths} mo (${widget.termMonths ~/ 12} yr)'),
                                MapEntry(l10n.monthlyPayment,
                                    fmt.format(result.stdMonthlyPayment)),
                                MapEntry(l10n.extraMonthlyPayment,
                                    fmt.format(_extraMonthly)),
                                MapEntry(l10n.newMonthlyPayment,
                                    fmt.format(result.stdMonthlyPayment + _extraMonthly)),
                                MapEntry(l10n.paidOffIn,
                                    '${result.earlyMonths} mo (${(result.earlyMonths / 12).toStringAsFixed(1)} yr)'),
                                MapEntry(l10n.interestSaved,
                                    fmt.format(result.interestSaved)),
                                MapEntry(l10n.monthsSaved,
                                    '${result.monthsSaved} ${l10n.month}'),
                              ],
                            );
                            AnalyticsService.instance.logPdfExported('early_payoff');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.pdfExportSuccess),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.pdfExportFailed),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: Text(l10n.exportPdf),
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
