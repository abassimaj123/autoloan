import 'dart:async' show unawaited;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:calcwise_core/calcwise_core.dart'
    show
        CalcwiseAdService,
        CalcwiseAdFooter,
        AppSpacing,
        AppRadius,
        AppTextSize,
        ResultHasher;
import 'package:calcwise_core/calcwise_core.dart'
    hide SectionCard, ResultTile, PaywallHard;
import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';
import '../widgets/paywall_soft.dart';
import '../widgets/paywall_hard.dart';
import '../widgets/save_scenario_button.dart';
import '../main.dart' show smartHistoryService, paywallSession;
import '../core/freemium/freemium_service.dart';
import '../core/freemium/iap_service.dart';
import '../features/pdf/pdf_export_service.dart';
import '../features/history/history_screen.dart';

/// Multi-Loan Comparison — compare 3 loan offers side-by-side.
/// Premium-gated screen, works for all 3 flavors.
class LoanComparisonScreen extends StatefulWidget {
  final String flavor; // 'ca', 'uk', 'us'

  const LoanComparisonScreen({super.key, required this.flavor});

  @override
  State<LoanComparisonScreen> createState() => _LoanComparisonScreenState();
}

class _LoanComparisonScreenState extends State<LoanComparisonScreen> {
  late CalcwiseAdService _adService;

  // ── Loan 1 ─────────────────────────────────────────────────────────────────
  double _amount1 = 25000;
  double _rate1 = 5.9;
  int _term1 = 60;

  // ── Loan 2 ─────────────────────────────────────────────────────────────────
  double _amount2 = 25000;
  double _rate2 = 7.4;
  int _term2 = 72;

  // ── Loan 3 ─────────────────────────────────────────────────────────────────
  double _amount3 = 25000;
  double _rate3 = 4.9;
  int _term3 = 48;

  // ── Computed ───────────────────────────────────────────────────────────────
  late _LoanResult _r1;
  late _LoanResult _r2;
  late _LoanResult _r3;

  String get _sym {
    switch (widget.flavor) {
      case 'uk':
        return '£';
      case 'ca':
        return 'C\$';
      default:
        return '\$';
    }
  }

  static double _roundTo(double v, double step) => (v / step).round() * step;

  void _scheduleAutoSave() {
    final hash = ResultHasher.hashMixed({
      'amount1': _roundTo(_amount1, 1000),
      'rate1': _roundTo(_rate1, 0.25),
      'amount2': _roundTo(_amount2, 1000),
      'rate2': _roundTo(_rate2, 0.25),
      'term1': _term1,
      'term2': _term2,
    });
    final best = _winnerIndex;
    final costs = [_r1.totalCost, _r2.totalCost, _r3.totalCost];
    final worstCost = costs.reduce((a, b) => a > b ? a : b);
    final bestCost = costs[best];
    smartHistoryService.scheduleAutoSave(
      appKey: 'autoloan',
      screenId: 'loan_comparison',
      inputHash: hash,
      l1: {
        'loanCount': 3,
        'bestMonthly': [_r1, _r2, _r3][best].monthlyPayment,
        'intDiff': worstCost - bestCost,
        'bestLoan': best + 1,
      },
      l2: {
        'inputs': {
          'amount1': _amount1,
          'rate1': _rate1,
          'term1': _term1,
          'amount2': _amount2,
          'rate2': _rate2,
          'term2': _term2,
          'amount3': _amount3,
          'rate3': _rate3,
          'term3': _term3,
          'flavor': widget.flavor,
        },
        'results': {
          'monthly1': _r1.monthlyPayment,
          'interest1': _r1.totalInterest,
          'cost1': _r1.totalCost,
          'monthly2': _r2.monthlyPayment,
          'interest2': _r2.totalInterest,
          'cost2': _r2.totalCost,
          'monthly3': _r3.monthlyPayment,
          'interest3': _r3.totalInterest,
          'cost3': _r3.totalCost,
          'winner': best,
        },
      },
      onSaved: () { HistoryScreen.refreshNotifier.value++; },
    );
  }

  Future<void> _saveScenario(String? label) async {
    final hash = ResultHasher.hashMixed({
      'amount1': _roundTo(_amount1, 1000),
      'rate1': _roundTo(_rate1, 0.25),
      'amount2': _roundTo(_amount2, 1000),
      'rate2': _roundTo(_rate2, 0.25),
      'term1': _term1,
      'term2': _term2,
    });
    final best = _winnerIndex;
    final costs = [_r1.totalCost, _r2.totalCost, _r3.totalCost];
    final worstCost = costs.reduce((a, b) => a > b ? a : b);
    final bestCost = costs[best];
    await smartHistoryService.saveScenario(
      appKey: 'autoloan',
      screenId: 'loan_comparison',
      inputHash: hash,
      l1: {
        'loanCount': 3,
        'bestMonthly': [_r1, _r2, _r3][best].monthlyPayment,
        'intDiff': worstCost - bestCost,
        'bestLoan': best + 1,
      },
      l2: {
        'inputs': {
          'amount1': _amount1,
          'rate1': _rate1,
          'term1': _term1,
          'amount2': _amount2,
          'rate2': _rate2,
          'term2': _term2,
          'amount3': _amount3,
          'rate3': _rate3,
          'term3': _term3,
          'flavor': widget.flavor,
        },
        'results': {
          'monthly1': _r1.monthlyPayment,
          'interest1': _r1.totalInterest,
          'cost1': _r1.totalCost,
          'monthly2': _r2.monthlyPayment,
          'interest2': _r2.totalInterest,
          'cost2': _r2.totalCost,
          'monthly3': _r3.monthlyPayment,
          'interest3': _r3.totalInterest,
          'cost3': _r3.totalCost,
          'winner': best,
        },
      },
      label: label,
    );
    try { AnalyticsService.instance.logSave(); } catch (_) {}
    try { AnalyticsService.instance.logHistorySaved(); } catch (_) {}
    _adService.onSave();
    paywallSession.recordAction().ignore();
  }

  Future<void> _checkPaywall() async {
    final trigger = await paywallSession.recordAction();
    if (!mounted) return;
    if (trigger == PaywallTrigger.hard) {
      PaywallHard.show(context);
    } else if (trigger == PaywallTrigger.soft) {
      PaywallSoft.show(context);
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final l10n = AppLocalizations.of(context)!;
    final isUk = widget.flavor == 'uk';
    final screenTitle =
        isUk ? 'Compare 3 Finance Deals' : l10n.compare3Loans;
    try {
      await PdfExportService.exportLoanComparison(
        title: screenTitle,
        currency: _sym,
        amounts: [_amount1, _amount2, _amount3],
        rates: [_rate1, _rate2, _rate3],
        terms: [_term1, _term2, _term3],
        monthlyPayments: [
          _r1.monthlyPayment,
          _r2.monthlyPayment,
          _r3.monthlyPayment,
        ],
        totalInterests: [
          _r1.totalInterest,
          _r2.totalInterest,
          _r3.totalInterest,
        ],
        totalCosts: [_r1.totalCost, _r2.totalCost, _r3.totalCost],
        winnerIndex: _winnerIndex,
        isFrench: isFr,
        isSpanish: isEs,
      );
      AnalyticsService.instance.logPdfExported('loan_comparison');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFr
              ? 'PDF exporté avec succès'
              : isEs
                  ? 'PDF exportado exitosamente'
                  : 'PDF exported successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFr
              ? "Échec de l'export"
              : isEs
                  ? 'Error al exportar'
                  : 'Export failed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adService = context.read<CalcwiseAdService>();
  }

  @override
  void dispose() {
    smartHistoryService.cancelPendingSave('autoloan', 'loan_comparison');
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView('loan_comparison');
    _recalc();
  }

  void _recalc() {
    setState(() {
      _r1 = _LoanResult.compute(_amount1, _rate1, _term1);
      _r2 = _LoanResult.compute(_amount2, _rate2, _term2);
      _r3 = _LoanResult.compute(_amount3, _rate3, _term3);
    });
    _scheduleAutoSave();
  }

  /// Called from input change handlers (after frame, so context is valid).
  void _recalcAndPaywall() {
    _recalc();
    unawaited(_checkPaywall());
  }

  /// Index (0,1,2) of the loan with lowest totalCost.
  int get _winnerIndex {
    final costs = [_r1.totalCost, _r2.totalCost, _r3.totalCost];
    double best = costs[0];
    int idx = 0;
    for (int i = 1; i < costs.length; i++) {
      if (costs[i] < best) {
        best = costs[i];
        idx = i;
      }
    }
    return idx;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adService = context.read<CalcwiseAdService>();
    final fmt = NumberFormat.currency(symbol: _sym, decimalDigits: 2);

    final isUk = widget.flavor == 'uk';

    final winner = _winnerIndex;
    // UK car finance uses "Deal" terminology (HP/PCP deals), not "Loan"
    final labels = isUk
        ? ['Deal 1', 'Deal 2', 'Deal 3']
        : [l10n.loan1, l10n.loan2, l10n.loan3];
    final amounts = [_amount1, _amount2, _amount3];
    final rates = [_rate1, _rate2, _rate3];
    final terms = [_term1, _term2, _term3];
    final results = [_r1, _r2, _r3];

    // UK: "Compare 3 Finance Deals"; CA/US: "Compare 3 Loans"
    final screenTitle = isUk ? 'Compare 3 Finance Deals' : l10n.compare3Loans;

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
        actions: [
          if (freemiumService.hasFullAccess || freemiumService.isRewarded)
            Semantics(
              label: 'Export PDF',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: l10n.exportPdf,
                onPressed: () => _exportPdf(context),
              ),
            ),
        ],
      ),
      body: CalcwisePageEntrance(
        child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              children: [
                // ── 3 loan input cards (vertical, full-width each) ───────────
                for (int i = 0; i < 3; i++) ...[
                  _LoanInputCard(
                    label: labels[i],
                    amount: amounts[i],
                    rate: rates[i],
                    term: terms[i],
                    isWinner: winner == i,
                    winnerLabel: l10n.bestDeal,
                    sym: _sym,
                    isUk: isUk,
                    onAmountChanged: (v) {
                      setState(() {
                        if (i == 0) _amount1 = v;
                        if (i == 1) _amount2 = v;
                        if (i == 2) _amount3 = v;
                      });
                      _recalcAndPaywall();
                    },
                    onRateChanged: (v) {
                      setState(() {
                        if (i == 0) _rate1 = v;
                        if (i == 1) _rate2 = v;
                        if (i == 2) _rate3 = v;
                      });
                      _recalcAndPaywall();
                    },
                    onTermChanged: (v) {
                      setState(() {
                        if (i == 0) _term1 = v;
                        if (i == 1) _term2 = v;
                        if (i == 2) _term3 = v;
                      });
                      _recalcAndPaywall();
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                const SizedBox(height: AppSpacing.sm),

                // ── Results — premium gated ──────────────────────────────────
                _GatedComparisonResults(
                  results: results,
                  labels: labels,
                  winner: winner,
                  fmt: fmt,
                  l10n: l10n,
                  adService: adService,
                  flavor: widget.flavor,
                ),

                // ── Save Scenario ──────────────────────────────────────────
                SaveScenarioButton(onSave: _saveScenario),

                const SizedBox(height: AppSpacing.md),
                Builder(builder: (context) {
                  final langCode = Localizations.localeOf(context).languageCode;
                  final disclaimer = langCode == 'fr'
                      ? 'À titre informatif seulement. Les taux et frais varient selon le prêteur.'
                      : langCode == 'es'
                          ? 'Solo con fines informativos. Las tasas y cargos varían según el prestamista.'
                          : 'For informational purposes only. Rates and fees vary by lender.';
                  return Text(
                    disclaimer,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTextSize.xs,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
                  );
                }),
              ],
            ),
          ),
          const CalcwiseAdFooter(),
        ],
        ),
      ),
    );
  }
}

// ── Loan input card ────────────────────────────────────────────────────────────

class _LoanInputCard extends StatelessWidget {
  final String label;
  final double amount;
  final double rate;
  final int term;
  final bool isWinner;
  final String winnerLabel;
  final String sym;
  final bool isUk;
  final ValueChanged<double> onAmountChanged;
  final ValueChanged<double> onRateChanged;
  final ValueChanged<int> onTermChanged;

  const _LoanInputCard({
    required this.label,
    required this.amount,
    required this.rate,
    required this.term,
    required this.isWinner,
    required this.winnerLabel,
    required this.sym,
    required this.isUk,
    required this.onAmountChanged,
    required this.onRateChanged,
    required this.onTermChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: isWinner ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: isWinner
            ? BorderSide(color: cs.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label + winner badge row
            Row(
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (isWinner) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          size: 12,
                          color: cs.onPrimaryContainer,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          winnerLabel,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: cs.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Amount + Rate row (side by side on full-width card)
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: isUk ? 'Finance amount for $label' : 'Loan amount for $label',
                    textField: true,
                    child: TextFormField(
                      key: ValueKey('amount_$label'),
                      initialValue: amount.toStringAsFixed(0),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]')),
                      ],
                      decoration: InputDecoration(
                        labelText: isUk
                            ? 'Finance Amount'
                            : AppLocalizations.of(context)!.loanInputAmount,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        prefixText: sym,
                        isDense: true,
                      ),
                      onChanged: (v) {
                        final val = double.tryParse(v.replaceAll(',', ''));
                        if (val != null && val > 0) onAmountChanged(val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Semantics(
                    label: 'Interest rate for $label',
                    textField: true,
                    child: TextFormField(
                      key: ValueKey('rate_$label'),
                      initialValue: rate.toStringAsFixed(1),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]')),
                      ],
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.loanInputRate,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        suffixText: '%',
                        isDense: true,
                      ),
                      onChanged: (v) {
                        final val = double.tryParse(v);
                        if (val != null && val >= 0 && val <= 30)
                          onRateChanged(val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Term chips
            Text(
              AppLocalizations.of(context)!.loanInputTerm,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [24, 36, 48, 60, 72, 84]
                  .map(
                    (t) => Semantics(
                      label:
                          '${t ~/ 12} year term${term == t ? ", selected" : ""}',
                      child: ChoiceChip(
                        label: Text(
                          '${t ~/ 12} ${AppLocalizations.of(context)!.year}',
                          style: const TextStyle(fontSize: AppTextSize.xs),
                        ),
                        selected: term == t,
                        onSelected: (_) => onTermChanged(t),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gated results ──────────────────────────────────────────────────────────────

class _GatedComparisonResults extends StatelessWidget {
  final List<_LoanResult> results;
  final List<String> labels;
  final int winner;
  final NumberFormat fmt;
  final AppLocalizations l10n;
  final CalcwiseAdService adService;
  final String flavor;

  const _GatedComparisonResults({
    required this.results,
    required this.labels,
    required this.winner,
    required this.fmt,
    required this.l10n,
    required this.adService,
    required this.flavor,
  });

  @override
  Widget build(BuildContext context) {
    final priceLabel = IAPService.instance.localizedPrice.value ?? 'Premium';

    return ListenableBuilder(
      listenable: Listenable.merge([
        freemiumService.hasFullAccessNotifier,
        freemiumService.isRewardedNotifier,
      ]),
      builder: (context, _) {
        final hasFull =
            freemiumService.hasFullAccess || freemiumService.isRewarded;
        if (!hasFull) {
          return CalcwisePremiumGate(
            title: l10n.compare3Loans,
            description: l10n.unlockFull,
            price: IAPService.instance.localizedPrice,
            onUnlock: () => PaywallSoft.show(context, priceLabel: priceLabel),
          );
        }
        return _ComparisonResults(
          results: results,
          labels: labels,
          winner: winner,
          fmt: fmt,
          l10n: l10n,
        );
      },
    );
  }
}

// ── Results table ──────────────────────────────────────────────────────────────

class _ComparisonResults extends StatelessWidget {
  final List<_LoanResult> results;
  final List<String> labels;
  final int winner;
  final NumberFormat fmt;
  final AppLocalizations l10n;

  const _ComparisonResults({
    required this.results,
    required this.labels,
    required this.winner,
    required this.fmt,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Best deal banner
    return Column(
      children: [
        // ── Winner banner ─────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${l10n.bestDeal}: ${labels[winner]} — ${l10n.lowestTotalCost}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── Comparison table card ─────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                // Header row
                _TableRow(
                  label: '',
                  values: labels,
                  isHeader: true,
                  winner: winner,
                  context: context,
                ),
                const Divider(height: 12),
                _TableRow(
                  label: l10n.monthlyPayment,
                  values: results
                      .map((r) => fmt.format(r.monthlyPayment))
                      .toList(),
                  winner: winner,
                  context: context,
                ),
                const SizedBox(height: 6),
                _TableRow(
                  label: l10n.totalInterest,
                  values: results
                      .map((r) => fmt.format(r.totalInterest))
                      .toList(),
                  winner: winner,
                  context: context,
                ),
                const Divider(height: 12),
                _TableRow(
                  label: l10n.totalCost,
                  values:
                      results.map((r) => fmt.format(r.totalCost)).toList(),
                  winner: winner,
                  context: context,
                  bold: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TableRow extends StatelessWidget {
  final String label;
  final List<String> values;
  final bool isHeader;
  final bool bold;
  final int winner;
  final BuildContext context;

  const _TableRow({
    required this.label,
    required this.values,
    required this.winner,
    required this.context,
    this.isHeader = false,
    this.bold = false,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final baseStyle = isHeader
        ? Theme.of(ctx).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            )
        : Theme.of(ctx).textTheme.bodySmall?.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            );

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ),
        for (int i = 0; i < values.length; i++)
          Expanded(
            child: Text(
              values[i],
              textAlign: TextAlign.center,
              style: (i == winner && !isHeader)
                  ? baseStyle?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    )
                  : baseStyle,
            ),
          ),
      ],
    );
  }
}

// ── Pure loan math ─────────────────────────────────────────────────────────────

class _LoanResult {
  final double monthlyPayment;
  final double totalInterest;
  final double totalCost;

  const _LoanResult({
    required this.monthlyPayment,
    required this.totalInterest,
    required this.totalCost,
  });

  static _LoanResult compute(double principal, double annualRate, int termMonths) {
    double monthly;
    if (annualRate <= 0 || termMonths <= 0) {
      monthly = termMonths > 0 ? principal / termMonths : 0;
    } else {
      final r = annualRate / 100 / 12;
      final powN = pow(1 + r, termMonths).toDouble();
      monthly = principal * (r * powN) / (powN - 1);
    }
    final totalCost = monthly * termMonths;
    final totalInterest = (totalCost - principal).clamp(0.0, double.infinity);
    return _LoanResult(
      monthlyPayment: monthly,
      totalInterest: totalInterest,
      totalCost: totalCost,
    );
  }
}
