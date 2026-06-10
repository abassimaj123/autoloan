import 'dart:async' show unawaited;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:calcwise_core/calcwise_core.dart'
    show
        CalcwiseAdService,
        CalcwiseAdFooter,
        AppSpacing,
        AppRadius,
        AppTextSize,
        CalcwiseChartTokens,
        ResultHasher;
import 'package:calcwise_core/calcwise_core.dart'
    hide SectionCard, ResultTile, PaywallHard;
import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';
import '../widgets/shared_inputs.dart';
import '../widgets/paywall_soft.dart';
import '../widgets/paywall_hard.dart';
import '../widgets/save_scenario_button.dart';
import '../main.dart' show smartHistoryService, paywallSession;
import '../core/freemium/freemium_service.dart';
import '../core/freemium/iap_service.dart';
import '../features/pdf/pdf_export_service.dart';
import '../features/history/history_screen.dart';

/// Total Cost of Ownership Calculator — premium-gated full screen.
/// Works for all 3 flavors: CA (CAD, km), UK (GBP, miles), US (USD, miles).
class TotalCostScreen extends StatefulWidget {
  /// Flavor: 'ca', 'uk', or 'us'
  final String flavor;

  /// Optional pre-filled monthly payment from the main calculator.
  final double? monthlyPayment;

  /// Optional loan term in months for pre-fill.
  final int? termMonths;

  /// Optional vehicle price for pre-fill.
  final double? vehiclePrice;

  const TotalCostScreen({
    super.key,
    required this.flavor,
    this.monthlyPayment,
    this.termMonths,
    this.vehiclePrice,
  });

  @override
  State<TotalCostScreen> createState() => _TotalCostScreenState();
}

class _TotalCostScreenState extends State<TotalCostScreen> {
  // ── Inputs ─────────────────────────────────────────────────────────────────
  late double _vehiclePrice;
  late double _monthlyPayment;
  late int _ownershipYears;
  double _insurance = 120; // default; overridden per flavor in initState
  double _fuel = 150;      // default; overridden per flavor in initState
  double _maintenance = 80; // default; overridden per flavor in initState
  double _depreciationRate = 15; // % per year

  // ── Derived ────────────────────────────────────────────────────────────────
  _TcoResult? _result;

  /// Currency symbol: C$ for CA, £ for UK, $ for US.
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

  String _fuelLabel(AppLocalizations l10n) {
    if (widget.flavor == 'uk') return 'Petrol (${l10n.month})';
    return l10n.gasPerMonth;
  }

  String get _distUnit => widget.flavor == 'ca' ? 'km' : 'miles';

  static double _roundTo(double v, double step) => (v / step).round() * step;

  void _scheduleAutoSave() {
    if (_result == null) return;
    final annualFuel = _fuel * 12;
    final hash = ResultHasher.hashMixed({
      'vehiclePrice': _roundTo(_vehiclePrice, 1000),
      'loanRate': _roundTo(_monthlyPayment, 25),
      'ownershipYears': _ownershipYears,
      'annualFuel': _roundTo(annualFuel, 500),
    });
    smartHistoryService.scheduleAutoSave(
      appKey: 'autoloan',
      screenId: 'total_cost',
      inputHash: hash,
      l1: {
        'vehiclePrice': _vehiclePrice,
        'monthlyPayment': _monthlyPayment,
        'annualCost': _result!.costPerMonth * 12,
        'total': _result!.grandTotal,
        'years': _ownershipYears,
      },
      l2: {
        'inputs': {
          'vehiclePrice': _vehiclePrice,
          'monthlyPayment': _monthlyPayment,
          'ownershipYears': _ownershipYears,
          'insurance': _insurance,
          'fuel': _fuel,
          'maintenance': _maintenance,
          'depreciationRate': _depreciationRate,
          'flavor': widget.flavor,
        },
        'results': {
          'totalLoan': _result!.totalLoan,
          'totalInsurance': _result!.totalInsurance,
          'totalFuel': _result!.totalFuel,
          'totalMaintenance': _result!.totalMaintenance,
          'depreciationLoss': _result!.depreciationLoss,
          'grandTotal': _result!.grandTotal,
          'costPerMonth': _result!.costPerMonth,
        },
      },
      onSaved: () { HistoryScreen.refreshNotifier.value++; },
    );
  }

  Future<void> _saveScenario(String? label) async {
    if (_result == null) return;
    final annualFuel = _fuel * 12;
    final hash = ResultHasher.hashMixed({
      'vehiclePrice': _roundTo(_vehiclePrice, 1000),
      'loanRate': _roundTo(_monthlyPayment, 25),
      'ownershipYears': _ownershipYears,
      'annualFuel': _roundTo(annualFuel, 500),
    });
    await smartHistoryService.saveScenario(
      appKey: 'autoloan',
      screenId: 'total_cost',
      inputHash: hash,
      l1: {
        'vehiclePrice': _vehiclePrice,
        'monthlyPayment': _monthlyPayment,
        'annualCost': _result!.costPerMonth * 12,
        'total': _result!.grandTotal,
        'years': _ownershipYears,
      },
      l2: {
        'inputs': {
          'vehiclePrice': _vehiclePrice,
          'monthlyPayment': _monthlyPayment,
          'ownershipYears': _ownershipYears,
          'insurance': _insurance,
          'fuel': _fuel,
          'maintenance': _maintenance,
          'depreciationRate': _depreciationRate,
          'flavor': widget.flavor,
        },
        'results': {
          'totalLoan': _result!.totalLoan,
          'totalInsurance': _result!.totalInsurance,
          'totalFuel': _result!.totalFuel,
          'totalMaintenance': _result!.totalMaintenance,
          'depreciationLoss': _result!.depreciationLoss,
          'grandTotal': _result!.grandTotal,
          'costPerMonth': _result!.costPerMonth,
        },
      },
      label: label,
    );
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
    if (_result == null) return;
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final l10n = AppLocalizations.of(context)!;
    try {
      await PdfExportService.exportTotalCost(
        title: l10n.trueCostOfOwnership,
        currency: _sym,
        vehiclePrice: _vehiclePrice,
        monthlyPayment: _monthlyPayment,
        ownershipYears: _ownershipYears,
        insurance: _insurance,
        fuel: _fuel,
        maintenance: _maintenance,
        depreciationRate: _depreciationRate,
        totalLoan: _result!.totalLoan,
        totalInsurance: _result!.totalInsurance,
        totalFuel: _result!.totalFuel,
        totalMaintenance: _result!.totalMaintenance,
        depreciationLoss: _result!.depreciationLoss,
        grandTotal: _result!.grandTotal,
        costPerMonth: _result!.costPerMonth,
        fuelLabel: _fuelLabel(l10n),
        distUnit: _distUnit,
        isFrench: isFr,
        isSpanish: isEs,
      );
      AnalyticsService.instance.logPdfExported('total_cost');
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
      final isFr = Localizations.localeOf(context).languageCode == 'fr';
      final isEs = Localizations.localeOf(context).languageCode == 'es';
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
  void dispose() {
    smartHistoryService.cancelPendingSave('autoloan', 'total_cost');
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView('total_cost');
    _vehiclePrice = widget.vehiclePrice ?? 25000;
    _monthlyPayment = widget.monthlyPayment ?? 450;
    _ownershipYears = widget.termMonths != null
        ? (widget.termMonths! / 12).round().clamp(1, 10)
        : 5;
    // Per-flavor defaults
    if (widget.flavor == 'uk') {
      _insurance = 120;
      _fuel = 180;
      _maintenance = 70;
    } else if (widget.flavor == 'ca') {
      // CA market: slightly higher insurance (~$120 CAD/mo is correct)
      _insurance = 120;
      _fuel = 150;
      _maintenance = 80;
    }
    _calculate();
  }

  void _calculate() {
    final termMonths = _ownershipYears * 12;
    final totalLoan = _monthlyPayment * termMonths;
    final totalInsurance = _insurance * termMonths;
    final totalFuel = _fuel * termMonths;
    final totalMaintenance = _maintenance * termMonths;
    final depLoss =
        _vehiclePrice * (1 - pow(1 - _depreciationRate / 100, _ownershipYears)).toDouble();
    final total =
        totalLoan + totalInsurance + totalFuel + totalMaintenance + depLoss;
    final costPerMonth = termMonths > 0 ? total / termMonths : 0.0;

    setState(() {
      _result = _TcoResult(
        totalLoan: totalLoan,
        totalInsurance: totalInsurance,
        totalFuel: totalFuel,
        totalMaintenance: totalMaintenance,
        depreciationLoss: depLoss,
        grandTotal: total,
        costPerMonth: costPerMonth,
      );
    });
    _scheduleAutoSave();
    unawaited(_checkPaywall());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adService = context.read<CalcwiseAdService>();
    final fmt = NumberFormat.currency(symbol: _sym, decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trueCostOfOwnership),
        actions: [
          if (_result != null &&
              (freemiumService.hasFullAccess || freemiumService.isRewarded))
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
      body: Column(
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
                // ── Vehicle & loan inputs ───────────────────────────────────
                SectionCard(
                  title: l10n.vehicle,
                  children: [
                    CurrencySliderInput(
                      label: l10n.vehiclePrice,
                      value: _vehiclePrice,
                      min: 3000,
                      max: 200000,
                      step: 1000,
                      symbol: _sym,
                      onChanged: (v) {
                        setState(() => _vehiclePrice = v);
                        _calculate();
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CurrencySliderInput(
                      label: l10n.monthlyPayment,
                      value: _monthlyPayment,
                      min: 100,
                      max: 3000,
                      step: 25,
                      symbol: _sym,
                      onChanged: (v) {
                        setState(() => _monthlyPayment = v);
                        _calculate();
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _YearChips(
                      label: l10n.ownershipPeriod,
                      selected: _ownershipYears,
                      onSelected: (y) {
                        setState(() => _ownershipYears = y);
                        _calculate();
                      },
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── Running costs ───────────────────────────────────────────
                SectionCard(
                  title: l10n.runningCosts,
                  children: [
                    CurrencySliderInput(
                      label: l10n.insurancePerMonth,
                      value: _insurance,
                      min: 0,
                      max: 1000,
                      step: 10,
                      symbol: _sym,
                      onChanged: (v) {
                        setState(() => _insurance = v);
                        _calculate();
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CurrencySliderInput(
                      label: _fuelLabel(l10n),
                      value: _fuel,
                      min: 0,
                      max: 1000,
                      step: 10,
                      symbol: _sym,
                      onChanged: (v) {
                        setState(() => _fuel = v);
                        _calculate();
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CurrencySliderInput(
                      label: l10n.maintenancePerMonth,
                      value: _maintenance,
                      min: 0,
                      max: 500,
                      step: 10,
                      symbol: _sym,
                      onChanged: (v) {
                        setState(() => _maintenance = v);
                        _calculate();
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DepreciationSlider(
                      label: l10n.depreciationRate,
                      value: _depreciationRate,
                      onChanged: (v) {
                        setState(() => _depreciationRate = v);
                        _calculate();
                      },
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── Results — premium gated ─────────────────────────────────
                if (_result != null)
                  _GatedTcoResults(
                    result: _result!,
                    fmt: fmt,
                    l10n: l10n,
                    adService: adService,
                    flavor: widget.flavor,
                    ownershipYears: _ownershipYears,
                  ),

                // ── Save Scenario ────────────────────────────────────────────
                if (_result != null)
                  SaveScenarioButton(onSave: _saveScenario),

                const SizedBox(height: AppSpacing.md),
                Builder(builder: (context) {
                  final isFr = Localizations.localeOf(context).languageCode == 'fr';
                  final isEs = Localizations.localeOf(context).languageCode == 'es';
                  final footerText = isFr
                      ? 'À titre informatif seulement. La dépréciation varie selon la marque, le modèle et les $_distUnit parcourus.'
                      : isEs
                          ? 'Solo con fines informativos. La depreciación varía según la marca, modelo y $_distUnit recorridos.'
                          : 'For informational purposes only. Depreciation estimates vary by vehicle make, model, and $_distUnit driven.';
                  return Text(
                    footerText,
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
    );
  }
}

// ── Year chips ─────────────────────────────────────────────────────────────────

class _YearChips extends StatelessWidget {
  final String label;
  final int selected;
  final ValueChanged<int> onSelected;

  const _YearChips({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          children: [1, 2, 3, 4, 5, 6, 7, 8]
              .map(
                (y) => ChoiceChip(
                  label: Text(
                    '$y ${AppLocalizations.of(context)!.year}',
                  ),
                  selected: selected == y,
                  onSelected: (_) => onSelected(y),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ── Depreciation slider ────────────────────────────────────────────────────────

class _DepreciationSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _DepreciationSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child:
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Text(
              '${value.toStringAsFixed(0)}% / yr',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 5,
          max: 30,
          divisions: 25,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ── Gated results ──────────────────────────────────────────────────────────────

class _GatedTcoResults extends StatelessWidget {
  final _TcoResult result;
  final NumberFormat fmt;
  final AppLocalizations l10n;
  final CalcwiseAdService adService;
  final String flavor;
  final int ownershipYears;

  const _GatedTcoResults({
    required this.result,
    required this.fmt,
    required this.l10n,
    required this.adService,
    required this.flavor,
    required this.ownershipYears,
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
          final l10n = AppLocalizations.of(context)!;
          return CalcwisePremiumGate(
            title: l10n.trueCostOfOwnership,
            description: l10n.unlockFull,
            price: IAPService.instance.localizedPrice,
            onUnlock: () => PaywallSoft.show(context, priceLabel: priceLabel),
          );
        }
        return _TcoResults(
          result: result,
          fmt: fmt,
          l10n: l10n,
          ownershipYears: ownershipYears,
        );
      },
    );
  }
}

// ── Results card ───────────────────────────────────────────────────────────────

class _TcoResults extends StatelessWidget {
  final _TcoResult result;
  final NumberFormat fmt;
  final AppLocalizations l10n;
  final int ownershipYears;

  const _TcoResults({
    required this.result,
    required this.fmt,
    required this.l10n,
    required this.ownershipYears,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final grand = result.grandTotal;

    // Percentage of each component for bar chart
    double pct(double v) => grand > 0 ? v / grand : 0;

    return Column(
      children: [
        // ── Summary ──────────────────────────────────────────────────────
        SectionCard(
          title: l10n.results,
          children: [
            ResultTile(
              label: l10n.totalLoanCost,
              value: fmt.format(result.totalLoan),
            ),
            ResultTile(
              label: l10n.totalInsurance,
              value: fmt.format(result.totalInsurance),
            ),
            ResultTile(
              label: l10n.totalFuel,
              value: fmt.format(result.totalFuel),
            ),
            ResultTile(
              label: l10n.totalMaintenance,
              value: fmt.format(result.totalMaintenance),
            ),
            ResultTile(
              label: l10n.depreciationLoss,
              value: fmt.format(result.depreciationLoss),
            ),
            const Divider(height: 16),
            ResultTile(
              label: '${l10n.totalCostOfOwnership} ($ownershipYears ${l10n.year})',
              value: fmt.format(grand),
              isHighlight: true,
            ),
            ResultTile(
              label: l10n.monthlyTrueCost,
              value: '${fmt.format(result.costPerMonth)}/${l10n.month}',
              isHighlight: true,
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // ── Visual breakdown ─────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.costBreakdown,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                _BarRow(
                  label: l10n.totalLoanCost,
                  pct: pct(result.totalLoan),
                  value: result.totalLoan,
                  fmt: fmt,
                  color: cs.primary,
                ),
                const SizedBox(height: AppSpacing.xs),
                _BarRow(
                  label: l10n.depreciationLoss,
                  pct: pct(result.depreciationLoss),
                  value: result.depreciationLoss,
                  fmt: fmt,
                  color: cs.error,
                ),
                const SizedBox(height: AppSpacing.xs),
                _BarRow(
                  label: l10n.totalInsurance,
                  pct: pct(result.totalInsurance),
                  value: result.totalInsurance,
                  fmt: fmt,
                  color: cs.tertiary,
                ),
                const SizedBox(height: AppSpacing.xs),
                _BarRow(
                  label: l10n.totalFuel,
                  pct: pct(result.totalFuel),
                  value: result.totalFuel,
                  fmt: fmt,
                  color: cs.secondary,
                ),
                const SizedBox(height: AppSpacing.xs),
                _BarRow(
                  label: l10n.totalMaintenance,
                  pct: pct(result.totalMaintenance),
                  value: result.totalMaintenance,
                  fmt: fmt,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final double pct;
  final double value;
  final NumberFormat fmt;
  final Color color;

  const _BarRow({
    required this.label,
    required this.pct,
    required this.value,
    required this.fmt,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Text(
              '$label: ${fmt.format(value)} '
              '(${(pct * 100).toStringAsFixed(0)}%)',
            ),
          ),
        );
      },
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                minHeight: CalcwiseChartTokens.barWidth,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(pct * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Pure data model ────────────────────────────────────────────────────────────

class _TcoResult {
  final double totalLoan;
  final double totalInsurance;
  final double totalFuel;
  final double totalMaintenance;
  final double depreciationLoss;
  final double grandTotal;
  final double costPerMonth;

  const _TcoResult({
    required this.totalLoan,
    required this.totalInsurance,
    required this.totalFuel,
    required this.totalMaintenance,
    required this.depreciationLoss,
    required this.grandTotal,
    required this.costPerMonth,
  });
}
