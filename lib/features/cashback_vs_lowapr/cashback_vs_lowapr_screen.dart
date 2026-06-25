import 'dart:async' show unawaited;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:calcwise_core/calcwise_core.dart'
    show ResultHasher;
import 'package:calcwise_core/calcwise_core.dart'
    hide SectionCard, ResultTile, PaywallHard;
import '../../l10n/app_localizations.dart';
import '../../widgets/shared_inputs.dart';
import '../../widgets/paywall_soft.dart';
import '../../widgets/paywall_hard.dart';
import '../../widgets/save_scenario_button.dart';
import '../../main.dart' show smartHistoryService, paywallSession;
import '../../services/analytics_service.dart';
import '../pdf/pdf_export_service.dart';
import '../../core/freemium/freemium_service.dart';
import '../../country/ca/ca_provider.dart';
import '../../country/uk/uk_provider.dart';
import '../../country/us/us_provider.dart';
import '../history/history_screen.dart';

/// Cash-Back vs Low-APR comparator.
///
/// Classic dealer-decision moment:
///   "Take $2 000 cash back at 7 % APR, or 0 % APR financing?"
///
/// Computes both scenarios and renders a side-by-side [ComparisonView]
/// with a winner badge on the lower total cost.
class CashbackVsLowAprScreen extends StatefulWidget {
  final String flavor; // 'us' | 'ca' | 'uk'
  const CashbackVsLowAprScreen({super.key, this.flavor = 'us'});

  @override
  State<CashbackVsLowAprScreen> createState() => _CashbackVsLowAprScreenState();
}

class _CashbackVsLowAprScreenState extends State<CashbackVsLowAprScreen> {
  late CalcwiseAdService _adService;

  // Shared inputs
  double _vehiclePrice = 35000;
  double _downPayment = 5000;
  int _termMonths = 60;

  // Scenario A — Cash back + standard APR
  double _cashBack = 2000;
  double _rateA = 7.0;

  // Scenario B — Low APR (often 0 %) + no cash back
  double _rateB = 0.0;

  // Cached result for SmartHistory (updated on each build)
  _Result? _resA;
  _Result? _resB;

  String get _currencySymbol => widget.flavor == 'uk' ? '£' : widget.flavor == 'ca' ? 'C\$' : '\$';

  static double _roundTo(double v, double step) => (v / step).round() * step;

  void _scheduleAutoSave(_Result resA, _Result resB, bool aWins) {
    final hash = ResultHasher.hashMixed({
      'vehiclePrice': _roundTo(_vehiclePrice, 1000),
      'cashBack': _roundTo(_cashBack, 500),
      'rateA': _roundTo(_rateA, 0.25),
      'rateB': _roundTo(_rateB, 0.25),
      'termMonths': _termMonths,
    });
    smartHistoryService.scheduleAutoSave(
      appKey: 'autoloan',
      screenId: 'cashback_vs_lowapr_${widget.flavor}',
      inputHash: hash,
      l1: {
        'vehiclePrice': _vehiclePrice,
        'cashBack': _cashBack,
        'lowAprRate': _rateB,
        'winner': aWins ? 'cashback' : 'lowapr',
        'savings': (resA.totalCost - resB.totalCost).abs(),
      },
      l2: {
        'inputs': {
          'vehiclePrice': _vehiclePrice,
          'downPayment': _downPayment,
          'termMonths': _termMonths,
          'cashBack': _cashBack,
          'rateA': _rateA,
          'rateB': _rateB,
          'flavor': widget.flavor,
        },
        'results': {
          'monthlyA': resA.monthly,
          'totalInterestA': resA.totalInterest,
          'totalCostA': resA.totalCost,
          'monthlyB': resB.monthly,
          'totalInterestB': resB.totalInterest,
          'totalCostB': resB.totalCost,
          'winner': aWins ? 'cashback' : 'lowapr',
          'savings': (resA.totalCost - resB.totalCost).abs(),
        },
      },
      onSaved: () { HistoryScreen.refreshNotifier.value++; },
    );
  }

  Future<void> _saveScenario(String? label) async {
    final resA = _resA;
    final resB = _resB;
    if (resA == null || resB == null) return;
    final aWins = resA.totalCost <= resB.totalCost;
    final hash = ResultHasher.hashMixed({
      'vehiclePrice': _roundTo(_vehiclePrice, 1000),
      'cashBack': _roundTo(_cashBack, 500),
      'rateA': _roundTo(_rateA, 0.25),
      'rateB': _roundTo(_rateB, 0.25),
      'termMonths': _termMonths,
    });
    await smartHistoryService.saveScenario(
      appKey: 'autoloan',
      screenId: 'cashback_vs_lowapr_${widget.flavor}',
      inputHash: hash,
      l1: {
        'vehiclePrice': _vehiclePrice,
        'cashBack': _cashBack,
        'lowAprRate': _rateB,
        'winner': aWins ? 'cashback' : 'lowapr',
        'savings': (resA.totalCost - resB.totalCost).abs(),
      },
      l2: {
        'inputs': {
          'vehiclePrice': _vehiclePrice,
          'downPayment': _downPayment,
          'termMonths': _termMonths,
          'cashBack': _cashBack,
          'rateA': _rateA,
          'rateB': _rateB,
          'flavor': widget.flavor,
        },
        'results': {
          'monthlyA': resA.monthly,
          'totalInterestA': resA.totalInterest,
          'totalCostA': resA.totalCost,
          'monthlyB': resB.monthly,
          'totalInterestB': resB.totalInterest,
          'totalCostB': resB.totalCost,
          'winner': aWins ? 'cashback' : 'lowapr',
          'savings': (resA.totalCost - resB.totalCost).abs(),
        },
      },
      label: label,
    );
    try { AnalyticsService.instance.logSave(); } catch (_) {}
    try { AnalyticsService.instance.logHistorySaved(); } catch (_) {}
    _adService.onSave();
    final trigger = await paywallSession.recordAction();
    if (!mounted) return;
    if (trigger == PaywallTrigger.soft) PaywallSoft.show(context);
    if (trigger == PaywallTrigger.hard) PaywallHard.show(context);
  }

  Future<void> _exportPdf(
      BuildContext context, _Result resA, _Result resB, bool aWins) async {
    final langCode = Localizations.localeOf(context).languageCode;
    final isFrench = langCode == 'fr';
    final isSpanish = langCode == 'es';
    final title = isFrench
        ? 'Remise vs Taux Bas'
        : isSpanish
            ? 'Reembolso vs Tasa Baja'
            : 'Cash-Back vs Low-APR';
    try {
      await PdfExportService.exportCashbackVsLowApr(
        title: title,
        currency: _currencySymbol,
        vehiclePrice: _vehiclePrice,
        downPayment: _downPayment,
        termMonths: _termMonths,
        cashBack: _cashBack,
        rateA: _rateA,
        rateB: _rateB,
        monthlyA: resA.monthly,
        totalInterestA: resA.totalInterest,
        totalCostA: resA.totalCost,
        monthlyB: resB.monthly,
        totalInterestB: resB.totalInterest,
        totalCostB: resB.totalCost,
        aWins: aWins,
        savings: (resA.totalCost - resB.totalCost).abs(),
        isFrench: isFrench,
        isSpanish: isSpanish,
      );
      AnalyticsService.instance.logPdfExported(widget.flavor);
    } catch (_) {}
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

  @override
  void dispose() {
    smartHistoryService.cancelPendingSave('autoloan', 'cashback_vs_lowapr_${widget.flavor}');
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adService = context.read<CalcwiseAdService>();
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView('cashback_vs_lowapr');
    // Pre-fill from the main calculator provider so the user sees their own
    // values instead of hardcoded defaults when this screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (widget.flavor) {
        case 'ca':
          final p = context.read<CAProvider>();
          setState(() {
            _vehiclePrice = p.vehiclePrice;
            _downPayment = p.dpAmount;
            _termMonths = p.termMonths;
            _rateA = p.annualRate;
          });
        case 'uk':
          final p = context.read<UKProvider>();
          setState(() {
            _vehiclePrice = p.vehiclePrice;
            _downPayment = p.downPayment;
            _termMonths = p.termMonths;
            _rateA = p.annualRate;
          });
        case 'us':
          final p = context.read<USProvider>();
          setState(() {
            _vehiclePrice = p.vehiclePrice;
            _downPayment = p.downPayment;
            _termMonths = p.termMonths;
            _rateA = p.annualRate;
          });
      }
    });
  }

  _Result _compute(double loan, double aprPct, int n) {
    if (loan <= 0 || n <= 0) {
      return const _Result(monthly: 0, totalInterest: 0, totalCost: 0);
    }
    final r = aprPct / 100 / 12;
    double monthly;
    if (r == 0) {
      monthly = loan / n;
    } else {
      monthly = loan * r * pow(1 + r, n) / (pow(1 + r, n) - 1);
    }
    final totalPaid = monthly * n;
    final interest = totalPaid - loan;
    return _Result(
      monthly: monthly,
      totalInterest: interest,
      totalCost: totalPaid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;
    final isSpanish = langCode == 'es';
    final isFrench = langCode == 'fr';
    final fmt = NumberFormat.currency(
      symbol: _currencySymbol,
      decimalDigits: 2,
    );

    final loanA = (_vehiclePrice - _downPayment - _cashBack).clamp(
      0.0,
      double.infinity,
    );
    final loanB = (_vehiclePrice - _downPayment).clamp(0.0, double.infinity);

    final resA = _compute(loanA, _rateA, _termMonths);
    final resB = _compute(loanB, _rateB, _termMonths);

    // Cache results for SmartHistory auto-save (fired after frame to avoid setState-in-build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_resA?.monthly != resA.monthly || _resB?.monthly != resB.monthly) {
        setState(() {
          _resA = resA;
          _resB = resB;
        });
        _scheduleAutoSave(resA, resB, resA.totalCost <= resB.totalCost);
      }
    });

    final aWins = resA.totalCost <= resB.totalCost;
    final winnerIndex = aWins ? 0 : 1;
    final savings = (resA.totalCost - resB.totalCost).abs();

    final monthlyLabel = isFrench ? 'Paiement mensuel' : isSpanish ? 'Pago mensual' : 'Monthly Payment';
    final interestLabel = isFrench ? 'Intérêt total' : isSpanish ? 'Interés total' : 'Total Interest';
    final costLabel = isFrench ? 'Coût total' : isSpanish ? 'Costo total' : 'Total Cost';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cashBackVsLowApr),
        actions: [
          if (freemiumService.hasFullAccess || freemiumService.isRewarded)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: l10n.exportPdf,
              onPressed: () => _exportPdf(context, resA, resB, aWins),
            ),
        ],
      ),
      body: CalcwisePageEntrance(
        child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionCard(
                      title: isFrench ? 'Véhicule' : isSpanish ? 'Vehículo' : 'Vehicle',
                      children: [
                        CurrencyTextInput(
                          label: isFrench
                              ? 'Prix du véhicule'
                              : isSpanish
                              ? 'Precio del vehículo'
                              : 'Vehicle price',
                          value: _vehiclePrice,
                          symbol: _currencySymbol,
                          helperText: 'e.g. 35 000',
                          onChanged: (v) => setState(() => _vehiclePrice = v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CurrencyTextInput(
                          label: isFrench ? 'Mise de fonds' : isSpanish ? 'Pago inicial' : 'Down payment',
                          value: _downPayment,
                          symbol: _currencySymbol,
                          helperText: 'e.g. 5 000',
                          onChanged: (v) => setState(() => _downPayment = v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _termChips(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SectionCard(
                      title: isFrench
                          ? 'Scénario A — Remise'
                          : isSpanish
                          ? 'Escenario A — Reembolso'
                          : 'Scenario A — Cash-Back',
                      children: [
                        CurrencyTextInput(
                          label: isFrench
                              ? 'Montant remise'
                              : isSpanish
                              ? 'Reembolso en efectivo'
                              : 'Cash-back amount',
                          value: _cashBack,
                          symbol: _currencySymbol,
                          helperText: 'e.g. 2 000',
                          onChanged: (v) => setState(() => _cashBack = v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        RateInputField(
                          label: isFrench
                              ? 'Taux annuel standard'
                              : isSpanish
                              ? 'Tasa anual estándar'
                              : 'Standard APR',
                          value: _rateA,
                          onChanged: (v) => setState(() => _rateA = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SectionCard(
                      title: isFrench
                          ? 'Scénario B — Taux bas'
                          : isSpanish
                          ? 'Escenario B — Tasa Baja'
                          : 'Scenario B — Low APR',
                      children: [
                        RateInputField(
                          label: isFrench
                              ? 'Taux promotionnel'
                              : isSpanish
                              ? 'Tasa promocional'
                              : 'Promotional APR',
                          value: _rateB,
                          onChanged: (v) => setState(() => _rateB = v),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          isFrench
                              ? 'Pas de remise — prêt complet à ce taux.'
                              : isSpanish
                              ? 'Sin reembolso — préstamo completo a esta tasa.'
                              : 'No cash-back — full loan at this rate.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ComparisonView(
                      title: isFrench ? 'Résultats' : isSpanish ? 'Resultados' : 'Results',
                      winnerIndex: winnerIndex,
                      scenarios: [
                        ComparisonScenario(
                          label: isFrench ? 'A — Remise' : isSpanish ? 'A — Reembolso' : 'A — Cash-Back',
                          metrics: {
                            monthlyLabel: fmt.format(resA.monthly),
                            interestLabel: fmt.format(resA.totalInterest),
                            costLabel: fmt.format(resA.totalCost),
                          },
                        ),
                        ComparisonScenario(
                          label: isFrench ? 'B — Taux bas' : isSpanish ? 'B — Tasa Baja' : 'B — Low APR',
                          metrics: {
                            monthlyLabel: fmt.format(resB.monthly),
                            interestLabel: fmt.format(resB.totalInterest),
                            costLabel: fmt.format(resB.totalCost),
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              aWins
                                  ? (isFrench
                                        ? 'Remise gagne — économise ${fmt.format(savings)} au total'
                                        : isSpanish
                                        ? 'Reembolso gana — ahorra ${fmt.format(savings)} en total'
                                        : 'Cash-Back wins — saves ${fmt.format(savings)} overall')
                                  : (isFrench
                                        ? 'Taux bas gagne — économise ${fmt.format(savings)} au total'
                                        : isSpanish
                                        ? 'Tasa Baja gana — ahorra ${fmt.format(savings)} en total'
                                        : 'Low-APR wins — saves ${fmt.format(savings)} overall'),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isFrench
                          ? 'À titre informatif seulement. Ne constitue pas un conseil financier.'
                          : isSpanish
                          ? 'Para fines informativos. No es asesoramiento financiero.'
                          : 'For informational purposes only. Not financial advice.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppTextSize.xs,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SaveScenarioButton(onSave: _saveScenario),
                    const SizedBox(height: 4),
                    const CalcwiseAdFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _termChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: const [24, 36, 48, 60, 72, 84].map((mo) {
        final selected = mo == _termMonths;
        return ChoiceChip(
          label: Text('$mo mo'),
          selected: selected,
          onSelected: (_) {
            HapticFeedback.selectionClick();
            setState(() => _termMonths = mo);
          },
        );
      }).toList(),
    );
  }
}

class _Result {
  final double monthly;
  final double totalInterest;
  final double totalCost;
  const _Result({
    required this.monthly,
    required this.totalInterest,
    required this.totalCost,
  });
}
