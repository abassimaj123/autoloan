import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/shared_inputs.dart';
import '../../widgets/premium_gate.dart';
import '../../widgets/paywall_soft.dart';
import '../../core/freemium/freemium_service.dart';
import 'package:calcwise_core/calcwise_core.dart'
    show
        CalcwiseAdService,
        CalcwiseAdFooter,
        ComparisonView,
        ComparisonScenario;
import 'package:calcwise_core/calcwise_core.dart' hide SectionCard, ResultTile;

class CompareScreen extends StatefulWidget {
  final String flavor; // 'ca', 'uk', 'us'
  const CompareScreen({super.key, required this.flavor});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  // ── Shared inputs ──────────────────────────────────────────────────────────
  double vehiclePrice = 30000;
  double downPayment = 5000;
  double salesTaxPct = 8.0; // US only
  bool isBiWeekly = false;

  // ── Scenario A ─────────────────────────────────────────────────────────────
  double rateA = 5.9;
  int termA = 60;

  // ── Scenario B ─────────────────────────────────────────────────────────────
  double rateB = 7.9;
  int termB = 72;

  // ── Computed results ───────────────────────────────────────────────────────
  _LoanResult? _resA;
  _LoanResult? _resB;

  bool get _showBiWeekly => true; // all flavors support bi-weekly

  String get _currencySymbol => widget.flavor == 'uk' ? '£' : '\$';

  void _calculate() {
    final taxAmount = widget.flavor == 'us'
        ? vehiclePrice * salesTaxPct / 100
        : 0.0;
    final loanAmount = (vehiclePrice + taxAmount - downPayment).clamp(
      0.0,
      double.infinity,
    );
    setState(() {
      _resA = _LoanResult.compute(loanAmount, rateA, termA, isBiWeekly);
      _resB = _LoanResult.compute(loanAmount, rateB, termB, isBiWeekly);
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fmt = NumberFormat.currency(
      symbol: _currencySymbol,
      decimalDigits: 2,
    );

    final taxAmount = widget.flavor == 'us'
        ? vehiclePrice * salesTaxPct / 100
        : 0.0;
    final loanAmount = (vehiclePrice + taxAmount - downPayment).clamp(
      0.0,
      double.infinity,
    );

    // Determine better deal
    final aBetter =
        _resA != null && _resB != null && _resA!.totalCost <= _resB!.totalCost;
    final savings = (_resA != null && _resB != null)
        ? (_resA!.totalCost - _resB!.totalCost).abs()
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.compareLoans)),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              top: false,
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xxl,
                ),
                children: [
                  // ── Shared ──────────────────────────────────────────────────────
                  SectionCard(
                    title: l10n.vehicle,
                    children: [
                      CurrencySliderInput(
                        label: l10n.vehiclePrice,
                        value: vehiclePrice,
                        min: 3000,
                        max: 200000,
                        step: 500,
                        symbol: _currencySymbol,
                        onChanged: (v) {
                          setState(() {
                            vehiclePrice = v;
                            if (downPayment > v * 0.5) downPayment = v * 0.5;
                          });
                          _calculate();
                        },
                      ),
                      const SizedBox(height: 12),
                      CurrencySliderInput(
                        label: l10n.downPayment,
                        value: downPayment,
                        min: 0,
                        max: vehiclePrice * 0.5,
                        step: 500,
                        symbol: _currencySymbol,
                        onChanged: (v) {
                          setState(() => downPayment = v);
                          _calculate();
                        },
                      ),
                      const SizedBox(height: 8),
                      ResultTile(
                        label: l10n.loanAmount,
                        value: NumberFormat.currency(
                          symbol: _currencySymbol,
                          decimalDigits: 2,
                        ).format(loanAmount),
                      ),
                      if (widget.flavor == 'us') ...[
                        const SizedBox(height: 12),
                        PercentSliderInput(
                          label: l10n.salesTax,
                          value: salesTaxPct,
                          min: 0,
                          max: 15,
                          step: 0.1,
                          onChanged: (v) {
                            setState(() => salesTaxPct = v);
                            _calculate();
                          },
                        ),
                      ],
                      if (_showBiWeekly) ...[
                        const SizedBox(height: 8),
                        Semantics(
                          label: l10n.biWeeklyToggle,
                          toggled: isBiWeekly,
                          child: Row(
                          children: [
                            Switch(
                              value: isBiWeekly,
                              onChanged: (v) {
                                setState(() => isBiWeekly = v);
                                _calculate();
                              },
                            ),
                            Text(l10n.biWeeklyToggle),
                          ],
                        )),
                      ],
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ── Side-by-side scenarios ──────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ScenarioCard(
                          label: '${l10n.scenario} A',
                          rate: rateA,
                          term: termA,
                          isBetter: _resA != null && _resB != null && aBetter,
                          betterLabel: l10n.betterDeal,
                          onRateChanged: (v) {
                            setState(() => rateA = v);
                            _calculate();
                          },
                          onTermChanged: (v) {
                            setState(() => termA = v);
                            _calculate();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ScenarioCard(
                          label: '${l10n.scenario} B',
                          rate: rateB,
                          term: termB,
                          isBetter: _resA != null && _resB != null && !aBetter,
                          betterLabel: l10n.betterDeal,
                          onRateChanged: (v) {
                            setState(() => rateB = v);
                            _calculate();
                          },
                          onTermChanged: (v) {
                            setState(() => termB = v);
                            _calculate();
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ── Quick comparison summary (calcwise_core ComparisonView) ─────
                  if (_resA != null && _resB != null)
                    ComparisonView(
                      title: l10n.compareLoans,
                      winnerIndex: aBetter ? 0 : 1,
                      scenarios: [
                        ComparisonScenario(
                          label: '${l10n.scenario} A',
                          metrics: {
                            (isBiWeekly && _showBiWeekly
                                ? l10n.biWeeklyPayment
                                : l10n.monthlyPayment): fmt.format(
                              isBiWeekly && _showBiWeekly
                                  ? _resA!.biWeeklyPayment
                                  : _resA!.monthlyPayment,
                            ),
                            l10n.totalInterest: fmt.format(
                              _resA!.totalInterest,
                            ),
                            l10n.totalCost: fmt.format(_resA!.totalCost),
                          },
                        ),
                        ComparisonScenario(
                          label: '${l10n.scenario} B',
                          metrics: {
                            (isBiWeekly && _showBiWeekly
                                ? l10n.biWeeklyPayment
                                : l10n.monthlyPayment): fmt.format(
                              isBiWeekly && _showBiWeekly
                                  ? _resB!.biWeeklyPayment
                                  : _resB!.monthlyPayment,
                            ),
                            l10n.totalInterest: fmt.format(
                              _resB!.totalInterest,
                            ),
                            l10n.totalCost: fmt.format(_resB!.totalCost),
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 8),

                  // ── Results side-by-side ────────────────────────────────────────
                  if (_resA != null && _resB != null)
                    _GatedCompareResults(
                      resA: _resA!,
                      resB: _resB!,
                      savings: savings,
                      aBetter: aBetter,
                      fmt: fmt,
                      isBiWeekly: isBiWeekly && _showBiWeekly,
                      l10n: l10n,
                      flavor: widget.flavor,
                    ),
                ],
              ),
            ),
          ),
          const CalcwiseAdFooter(),
        ],
      ),
    );
  }
}

// ── Scenario input card ────────────────────────────────────────────────────
class _ScenarioCard extends StatelessWidget {
  final String label;
  final double rate;
  final int term;
  final bool isBetter;
  final String betterLabel;
  final ValueChanged<double> onRateChanged;
  final ValueChanged<int> onTermChanged;

  const _ScenarioCard({
    required this.label,
    required this.rate,
    required this.term,
    required this.isBetter,
    required this.betterLabel,
    required this.onRateChanged,
    required this.onTermChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isBetter ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: isBetter
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (isBetter) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text(
                  betterLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Rate input
            Semantics(
              label: 'Interest rate for $label',
              textField: true,
              child: TextFormField(
              key: ValueKey('rate_$label'),
              initialValue: rate.toStringAsFixed(1),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: '% Rate',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixText: '%',
              ),
              onChanged: (v) {
                final val = double.tryParse(v);
                if (val != null && val >= 0 && val <= 30) onRateChanged(val);
              },
            ),
            ),
            const SizedBox(height: 8),
            // Term chips (compact)
            Builder(
              builder: (context) {
                final yr = AppLocalizations.of(context)!.year;
                return Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [24, 36, 48, 60, 72, 84]
                      .map(
                        (t) => Semantics(
                          label: '${t ~/ 12} $yr loan term${term == t ? ", selected" : ""}',
                          child: ChoiceChip(
                          label: Text(
                            '${t ~/ 12}$yr',
                            style: const TextStyle(fontSize: AppTextSize.xs),
                          ),
                          selected: term == t,
                          onSelected: (_) => onTermChanged(t),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gated results wrapper ──────────────────────────────────────────────────
class _GatedCompareResults extends StatelessWidget {
  final _LoanResult resA, resB;
  final double savings;
  final bool aBetter, isBiWeekly;
  final NumberFormat fmt;
  final AppLocalizations l10n;
  final String flavor;

  const _GatedCompareResults({
    required this.resA,
    required this.resB,
    required this.savings,
    required this.aBetter,
    required this.isBiWeekly,
    required this.fmt,
    required this.l10n,
    required this.flavor,
  });

  @override
  Widget build(BuildContext context) {
    final adService = context.read<CalcwiseAdService>();
    final priceLabel = flavor == 'uk'
        ? '£2.99'
        : (flavor == 'us' ? r'$2.99' : r'$3.99 CAD');

    return ListenableBuilder(
      listenable: Listenable.merge([
        freemiumService.isPremiumNotifier,
        freemiumService.isRewardedNotifier,
      ]),
      builder: (context, _) {
        final hasFull =
            freemiumService.hasFullAccess || freemiumService.isRewarded;
        if (!hasFull) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Unlock to see full comparison',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PremiumGate(adService: adService, flavor: flavor),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        PaywallSoft.show(context, priceLabel: priceLabel),
                    child: Text('Get Premium — $priceLabel'),
                  ),
                ],
              ),
            ),
          );
        }
        return _CompareResults(
          resA: resA,
          resB: resB,
          savings: savings,
          aBetter: aBetter,
          isBiWeekly: isBiWeekly,
          fmt: fmt,
          l10n: l10n,
        );
      },
    );
  }
}

// ── Results comparison ─────────────────────────────────────────────────────
class _CompareResults extends StatelessWidget {
  final _LoanResult resA, resB;
  final double savings;
  final bool aBetter, isBiWeekly;
  final NumberFormat fmt;
  final AppLocalizations l10n;

  const _CompareResults({
    required this.resA,
    required this.resB,
    required this.savings,
    required this.aBetter,
    required this.isBiWeekly,
    required this.fmt,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final paymentLabel = isBiWeekly
        ? l10n.biWeeklyPayment
        : l10n.monthlyPayment;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _ResultRow(
              label: paymentLabel,
              valA: fmt.format(
                isBiWeekly ? resA.biWeeklyPayment : resA.monthlyPayment,
              ),
              valB: fmt.format(
                isBiWeekly ? resB.biWeeklyPayment : resB.monthlyPayment,
              ),
              aHighlight: aBetter,
              bHighlight: !aBetter,
            ),
            const Divider(height: 16),
            _ResultRow(
              label: l10n.totalInterest,
              valA: fmt.format(resA.totalInterest),
              valB: fmt.format(resB.totalInterest),
              aHighlight: aBetter,
              bHighlight: !aBetter,
            ),
            const SizedBox(height: 4),
            _ResultRow(
              label: l10n.totalCost,
              valA: fmt.format(resA.totalCost),
              valB: fmt.format(resB.totalCost),
              aHighlight: aBetter,
              bHighlight: !aBetter,
              bold: true,
            ),
            const Divider(height: 16),
            Semantics(
              label: '${l10n.totalSavings}: ${fmt.format(savings)} — ${aBetter ? "Scenario A" : "Scenario B"} is the better deal',
              child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.savings_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${l10n.totalSavings}: ${fmt.format(savings)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label, valA, valB;
  final bool aHighlight, bHighlight, bold;
  const _ResultRow({
    required this.label,
    required this.valA,
    required this.valB,
    this.aHighlight = false,
    this.bHighlight = false,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    final highlightStyle = style?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.bold,
    );

    return Semantics(
      label: '$label: Scenario A $valA${aHighlight ? " (better)" : ""}, Scenario B $valB${bHighlight ? " (better)" : ""}',
      child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Text(
            valA,
            textAlign: TextAlign.center,
            style: aHighlight ? highlightStyle : style,
          ),
        ),
        Expanded(
          child: Text(
            valB,
            textAlign: TextAlign.center,
            style: bHighlight ? highlightStyle : style,
          ),
        ),
      ],
    ),
    );
  }
}

// ── Pure loan math ─────────────────────────────────────────────────────────
class _LoanResult {
  final double monthlyPayment, biWeeklyPayment, totalInterest, totalCost;

  const _LoanResult({
    required this.monthlyPayment,
    required this.biWeeklyPayment,
    required this.totalInterest,
    required this.totalCost,
  });

  static _LoanResult compute(
    double loanAmount,
    double annualRate,
    int termMonths,
    bool biWeekly,
  ) {
    double monthly;
    if (annualRate <= 0) {
      monthly = termMonths > 0 ? loanAmount / termMonths : 0;
    } else {
      final r = annualRate / 12 / 100;
      final powN = pow(1 + r, termMonths).toDouble();
      monthly = loanAmount * (r * powN) / (powN - 1);
    }

    double biWeeklyPmt;
    final termYears = termMonths / 12;
    if (annualRate <= 0) {
      biWeeklyPmt = loanAmount / (termYears * 26);
    } else {
      final rBi = annualRate / 26 / 100;
      final nBi = (termYears * 26).round();
      final powBi = pow(1 + rBi, nBi).toDouble();
      biWeeklyPmt = loanAmount * (rBi * powBi) / (powBi - 1);
    }

    final totalInterest = (monthly * termMonths - loanAmount).clamp(
      0.0,
      double.infinity,
    );
    final totalCost = loanAmount + totalInterest;

    return _LoanResult(
      monthlyPayment: monthly,
      biWeeklyPayment: biWeeklyPmt,
      totalInterest: totalInterest,
      totalCost: totalCost,
    );
  }
}
