import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:calcwise_core/calcwise_core.dart' hide SectionCard, ResultTile, PaywallHard;
import '../../l10n/app_localizations.dart';
import '../../widgets/shared_inputs.dart';
import '../../core/payment_frequency.dart';
import '../../core/freemium/freemium_service.dart';
import '../../core/freemium/iap_service.dart';
import '../../main.dart' show paywallSession;
import '../../widgets/paywall_hard.dart';
import '../../widgets/paywall_soft.dart';
import 'dart:math';
import '../../features/amortization/amortization_screen.dart';
import '../../features/cashback_vs_lowapr/cashback_vs_lowapr_screen.dart';
import '../../features/history/history_screen.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../../features/pdf/pdf_export_service.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/compare/compare_screen.dart';
import '../../features/early_payoff/early_payoff_screen.dart';
import '../../features/lease_vs_buy/lease_vs_buy_screen.dart';
import '../../screens/total_cost_screen.dart';
import '../../screens/loan_comparison_screen.dart';
import '../../services/analytics_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/insight_engine.dart';
import '../../widgets/insight_card.dart';
import '../../widgets/loan_charts.dart';
import '../../widgets/save_scenario_button.dart';
import 'us_provider.dart';
import 'us_logic.dart';

class USScreen extends StatefulWidget {
  const USScreen({super.key});

  @override
  State<USScreen> createState() => _USScreenState();
}

class _USScreenState extends State<USScreen> {
  Timer? _debounce;

  bool _validated = false;
  int _selectedTab = 0;
  int _historyRefreshKey = 0;
  bool _wasPremium = false;

  @override
  void initState() {
    super.initState();
    _wasPremium = freemiumService.hasFullAccess;
    freemiumService.isPremiumNotifier.addListener(_onPremiumChange);
    AnalyticsService.instance.logScreenView('calculator');
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async => await paywallSession.recordSession(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _debouncedCalculate());
  }

  @override
  void dispose() {
    freemiumService.isPremiumNotifier.removeListener(_onPremiumChange);
    _debounce?.cancel();
    super.dispose();
  }

  void _onPremiumChange() {
    final now = freemiumService.hasFullAccess;
    if (now && !_wasPremium && mounted) {
      showPremiumWelcomeSnackBar(context);
    }
    _wasPremium = now;
  }

  void _debouncedCalculate() {
    if (!_validated) setState(() => _validated = true);
    _debounce?.cancel();
    _debounce = Timer(AppDuration.page, () {
      if (!mounted) return;
      final p = context.read<USProvider>();
      p.calculate();
      p.scheduleAutoSave();
    });
  }

  Future<void> _onNavTap(int i) async {
    if (i == _selectedTab) return;
    if (i == 1) {
      AnalyticsService.instance.logTabChanged('compare');
      AnalyticsService.instance.logCompareUsed('us');
    } else if (i == 2) {
      AnalyticsService.instance.logTabChanged('lease_vs_buy');
    } else if (i == 3) {
      AnalyticsService.instance.logTabChanged('history');
    }
    if (i > 0) {
      final trigger = await paywallSession.recordAction();
      if (!mounted) return;
      if (trigger == PaywallTrigger.hard)
        PaywallHard.show(context);
      else if (trigger == PaywallTrigger.soft)
        PaywallSoft.show(context);
      if (!mounted) return;
    }
    setState(() {
      _selectedTab = i;
      if (i == 3) _historyRefreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adService = context.read<CalcwiseAdService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appNameUS),
        actions: [
          CalcwiseAppBarActions(
            freemium: freemiumService,
            session: paywallSession,
            onSettings: () {
              AnalyticsService.instance.logTabChanged('settings');
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) =>
                      const SettingsScreen(flavor: 'us'),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
                  transitionDuration: AppDuration.base,
                ),
              );
            },
            onRewardAd: () => CalcwiseRewardAdSheet.show(context),
            onPremium: () => PaywallHard.show(context),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (i) => _onNavTap(i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.calculate_outlined),
            selectedIcon: const Icon(Icons.calculate_rounded),
            label: l10n.calculate,
          ),
          NavigationDestination(
            icon: const Icon(Icons.compare_arrows_outlined),
            selectedIcon: const Icon(Icons.compare_arrows_rounded),
            label: l10n.compareLoans,
          ),
          const NavigationDestination(
            icon: Icon(Icons.balance_outlined),
            selectedIcon: Icon(Icons.balance_rounded),
            label: 'Lease vs Buy',
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history_rounded),
            label: l10n.history,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                // Tab 0: Calculator
                _USCalculatorTab(
                  validated: _validated,
                  onCalculate: _debouncedCalculate,
                  adService: adService,
                  rateAdjLabel: _rateAdjLabel,
                ),
                // Tab 1: Compare
                CompareScreen(flavor: 'us', showAppBar: false),
                // Tab 2: Lease vs Buy
                const LeaseVsBuyScreen(flavor: 'us', showAppBar: false),
                // Tab 3: History (always last)
                HistoryScreen(
                  key: ValueKey(_historyRefreshKey),
                  country: 'us',
                  showAppBar: false,
                  onClear: () => setState(() => _historyRefreshKey++),
                ),
              ],
            ),
          ),
          const CalcwiseAdFooter(),
        ],
      ),
    );
  }

  String _rateAdjLabel(CreditScore cs, AppLocalizations l10n) {
    final adj = cs.rateAdjustment;
    if (adj == 0) return l10n.noAdjustment;
    return adj < 0
        ? l10n.rateDiscount(adj.abs().toStringAsFixed(1))
        : l10n.ratePremium(adj.toStringAsFixed(1));
  }
}

// ── US Calculator Tab ──────────────────────────────────────────────────────────

class _USCalculatorTab extends StatelessWidget {
  final bool validated;
  final VoidCallback onCalculate;
  final CalcwiseAdService adService;
  final String Function(CreditScore, AppLocalizations) rateAdjLabel;

  const _USCalculatorTab({
    required this.validated,
    required this.onCalculate,
    required this.adService,
    required this.rateAdjLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<USProvider>(
      builder: (context, p, _) => SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: CalcwisePageEntrance(
                    child: Column(
                      children: [
                        // ── Hero result ───────────────────────────────────
                        if (p.result != null)
                          CalcwisePageEntrance(
                            child: Column(
                              children: [
                                CalcwiseStaggerItem(
                                  index: 0,
                                  child: _USResults(p: p, adService: adService),
                                ),
                                CalcwiseStaggerItem(
                                  index: 1,
                                  child: SaveScenarioButton(
                                    onSave: (label) => context
                                        .read<USProvider>()
                                        .saveScenario(label: label),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          CalcwiseEmptyState(
                            icon: Icons.directions_car_outlined,
                            title:
                                Localizations.localeOf(context).languageCode ==
                                    'es'
                                ? 'Sin resultados'
                                : 'No results yet',
                            body:
                                Localizations.localeOf(context).languageCode ==
                                    'es'
                                ? 'Ingresa el precio del vehículo para ver el análisis.'
                                : 'Enter the vehicle price to see your analysis.',
                          ),
                        // ── Input sections ────────────────────────────────
                        _USVehicleSection(
                          p: p,
                          validated: validated,
                          onCalculate: onCalculate,
                        ),
                        _USTaxRateSection(
                          p: p,
                          validated: validated,
                          onCalculate: onCalculate,
                        ),
                        _USCreditScoreSection(
                          p: p,
                          onCalculate: onCalculate,
                          rateAdjLabel: rateAdjLabel,
                        ),
                        _USLoanTermsSection(p: p, onCalculate: onCalculate),
                        // ── Cost Breakdown Chart ─────────────────────────
                        if (p.result != null)
                          Builder(
                            builder: (context) {
                              final isSpanish =
                                  Localizations.localeOf(context).languageCode == 'es';
                              final principal = p.result!.financedAmount;
                              final interest = p.result!.totalInterest;
                              final cs = Theme.of(context).colorScheme;
                              return SectionCard(
                                title: isSpanish
                                    ? 'Desglose del costo'
                                    : 'Cost Breakdown',
                                children: [
                                  LoanDonutChart(
                                    principal: principal,
                                    totalInterest: interest,
                                    primaryColor: cs.primary,
                                    accentColor: cs.secondary,
                                  ),
                                ],
                              );
                            },
                          ),
                        // ── Quick Tools (visible immediately after inputs) ──
                        _USQuickToolsSection(p: p),
                        // ── Extra sections ────────────────────────────────
                        _USLeaseSection(p: p),
                        if (p.result != null) _USRefiSection(p: p),
                        if (p.result != null) _USTcoSection(p: p),
                        _USAffordabilityReverseSolverSection(p: p),
                        _USAffordabilitySection(p: p),
                        const SizedBox(height: AppSpacing.listBottomInset),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── US Vehicle Section ─────────────────────────────────────────────────────────

class _USVehicleSection extends StatelessWidget {
  final USProvider p;
  final bool validated;
  final VoidCallback onCalculate;

  const _USVehicleSection({
    required this.p,
    required this.validated,
    required this.onCalculate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SectionCard(
      title: l10n.vehicle,
      children: [
        CurrencyTextInput(
          label: l10n.vehiclePrice,
          value: p.vehiclePrice,
          onChanged: (v) {
            p.setVehiclePrice(v);
            onCalculate();
          },
          helperText: 'e.g. 35 000',
          errorText: validated && p.vehiclePrice <= 0 ? 'Required' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        CurrencySliderInput(
          label: l10n.tradeInValue,
          value: p.tradeInValue,
          min: 0,
          max: p.vehiclePrice,
          step: 500,
          onChanged: (v) {
            p.setTradeInValue(v);
            onCalculate();
          },
        ),
        const SizedBox(height: AppSpacing.md),
        CurrencySliderInput(
          label: l10n.downPayment,
          value: p.downPayment,
          min: 0,
          max: p.vehiclePrice,
          step: 500,
          onChanged: (v) {
            p.setDownPayment(v);
            onCalculate();
          },
        ),
        const SizedBox(height: AppSpacing.md),
        CurrencySliderInput(
          label: l10n.dealerFees,
          value: p.dealerFees,
          min: 0,
          max: 5000,
          step: 50,
          onChanged: (v) {
            p.setDealerFees(v);
            onCalculate();
          },
        ),
      ],
    );
  }
}

// ── US Tax & Rate Section ──────────────────────────────────────────────────────

class _USTaxRateSection extends StatelessWidget {
  final USProvider p;
  final bool validated;
  final VoidCallback onCalculate;

  const _USTaxRateSection({
    required this.p,
    required this.validated,
    required this.onCalculate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SectionCard(
      title: '${l10n.salesTax} & ${l10n.annualRate}',
      children: [
        PercentSliderInput(
          label: l10n.salesTax,
          value: p.salesTaxPercent,
          min: 0,
          max: 15,
          step: 0.1,
          onChanged: (v) {
            p.setSalesTax(v);
            onCalculate();
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        RateInputField(
          label: l10n.annualRate,
          value: p.annualRate,
          helperText: 'Default rate as of 2026 — update to your actual rate',
          onChanged: (v) {
            p.setAnnualRate(v);
            onCalculate();
          },
          errorText: validated && p.annualRate <= 0 ? 'Required' : null,
        ),
      ],
    );
  }
}

// ── US Credit Score Section ────────────────────────────────────────────────────

class _USCreditScoreSection extends StatelessWidget {
  final USProvider p;
  final VoidCallback onCalculate;
  final String Function(CreditScore, AppLocalizations) rateAdjLabel;

  const _USCreditScoreSection({
    required this.p,
    required this.onCalculate,
    required this.rateAdjLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SectionCard(
      title: l10n.creditScore,
      children: [
        // ignore: deprecated_member_use
        ...CreditScore.values.map(
          (cs) => RadioListTile<CreditScore>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(cs.label),
            subtitle: Text(rateAdjLabel(cs, l10n)),
            value: cs,
            // ignore: deprecated_member_use
            groupValue: p.creditScore,
            // ignore: deprecated_member_use
            onChanged: (v) {
              if (v != null) {
                p.setCreditScore(v);
                onCalculate();
              }
            },
          ),
        ),
        if (p.result != null)
          ResultTile(
            label: l10n.effectiveRate,
            value: '${p.result!.effectiveRate.toStringAsFixed(2)}%',
          ),
      ],
    );
  }
}

// ── US Loan Terms Section ──────────────────────────────────────────────────────

class _USLoanTermsSection extends StatelessWidget {
  final USProvider p;
  final VoidCallback onCalculate;

  const _USLoanTermsSection({required this.p, required this.onCalculate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SectionCard(
      title: l10n.loanTerms,
      children: [
        DurationChips(
          label: l10n.termMonths,
          options: const [24, 36, 48, 60, 72, 84],
          selected: p.termMonths,
          onSelected: (v) {
            p.setTermMonths(v);
            onCalculate();
          },
        ),
        const SizedBox(height: AppSpacing.md),
        PaymentFrequencySelector(
          value: p.frequency,
          onChanged: (v) {
            p.setFrequency(v);
            onCalculate();
          },
        ),
      ],
    );
  }
}

// ── US Quick Tools Section (Reverse Solve + Cash-Back) ────────────────────────

class _USQuickToolsSection extends StatelessWidget {
  final USProvider p;

  const _USQuickToolsSection({required this.p});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        ReverseSolveCard(
          title: isSpanish
              ? '¿Qué vehículo puedo pagar?'
              : 'What vehicle price can I afford?',
          targetLabel: isSpanish
              ? 'Pago mensual objetivo'
              : 'Target monthly payment',
          resultLabel: isSpanish
              ? 'Precio máximo del vehículo'
              : 'Max vehicle price',
          prefix: '\$',
          minBound: 5000,
          maxBound: 200000,
          targetValue: 0,
          ascending: true,
          compute: (vehiclePrice) {
            final dpRatio = p.vehiclePrice > 0
                ? (p.downPayment / p.vehiclePrice).clamp(0.0, 0.95)
                : 0.15;
            final down = vehiclePrice * dpRatio;
            final loan = vehiclePrice - down;
            final r = p.annualRate / 100 / 12;
            final n = p.termMonths;
            if (loan <= 0 || n <= 0) return 0;
            if (r == 0) return loan / n;
            return loan * r * pow(1 + r, n) / (pow(1 + r, n) - 1);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) =>
                    const CashbackVsLowAprScreen(flavor: 'us'),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
                transitionDuration: AppDuration.base,
              ),
            );
          },
          icon: const Icon(Icons.local_offer_rounded),
          label: Text(l10n.cashBackVsLowApr),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        // ── True Cost of Ownership ─────────────────────────────────────
        const SizedBox(height: AppSpacing.md),
        _PremiumToolCard(
          icon: Icons.directions_car_filled_rounded,
          label: isSpanish ? 'Costo Real de Propiedad' : 'True Cost of Ownership',
          description: isSpanish
              ? 'Analiza el verdadero costo total de tu vehículo'
              : 'Analyze the true total cost of your vehicle',
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => TotalCostScreen(
                flavor: 'us',
                monthlyPayment: p.result?.monthlyPayment,
                termMonths: p.result?.termMonths,
                vehiclePrice: p.result?.vehiclePrice,
              ),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: AppDuration.base,
            ),
          ),
        ),
        // ── Compare 3 Loans ────────────────────────────────────────────
        const SizedBox(height: AppSpacing.md),
        _PremiumToolCard(
          icon: Icons.compare_arrows_rounded,
          label: isSpanish ? 'Comparar 3 Préstamos' : 'Compare 3 Loans',
          description: isSpanish
              ? 'Compara hasta 3 ofertas de préstamo lado a lado'
              : 'Compare up to 3 loan offers side by side',
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) =>
                  const LoanComparisonScreen(flavor: 'us'),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: AppDuration.base,
            ),
          ),
        ),
      ],
    );
  }
}

class _USResults extends StatelessWidget {
  final USProvider p;
  final CalcwiseAdService adService;
  const _USResults({required this.p, required this.adService});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final r = p.result!;

    return ListenableBuilder(
      listenable: Listenable.merge([
        freemiumService.hasFullAccessNotifier,
        freemiumService.isRewardedNotifier,
      ]),
      builder: (context, _) {
        final hasFull =
            freemiumService.hasFullAccess || freemiumService.isRewarded;
        return _buildCard(context, l10n, r, hasFull);
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    AppLocalizations l10n,
    USCalculation r,
    bool hasFull,
  ) {
    return SectionCard(
      children: [
        // ── Hero payment ──────────────────────────────────────────────────
        CalcwiseHeroCard(
          label: paymentLabelFor(l10n, p.frequency),
          value: AmountFormatter.ui(r.displayPayment, 'USD'),
          secondary: 'Principal & Interest',
          stats: [
            (label: l10n.totalInterest, value: AmountFormatter.ui(r.totalInterest, 'USD')),
            (label: l10n.totalCost, value: AmountFormatter.ui(r.totalCost, 'USD')),
          ],
        ),
        if (!p.frequency.isMonthly)
          ResultTile(
            label: '${l10n.monthlyPayment} (equiv.)',
            value: AmountFormatter.ui(r.monthlyPayment, 'USD'),
          ),
        ResultTile(label: l10n.loanAmount, value: AmountFormatter.ui(r.financedAmount, 'USD')),
        ResultTile(label: l10n.taxAmount, value: AmountFormatter.ui(r.taxAmount, 'USD')),
        if (r.tradeInValue > 0)
          ResultTile(
            label: l10n.tradeInValue,
            value: AmountFormatter.ui(r.tradeInValue, 'USD'),
          ),
        const Divider(),
        ResultTile(
          label: l10n.financedAmount,
          value: AmountFormatter.ui(r.financedAmount, 'USD'),
        ),
        ResultTile(
          label: l10n.totalInterest,
          value: AmountFormatter.ui(r.totalInterest, 'USD'),
        ),
        ResultTile(label: l10n.downPayment, value: AmountFormatter.ui(r.downPayment, 'USD')),
        const Divider(height: 8),
        ResultTile(
          label: l10n.totalCost,
          value: AmountFormatter.ui(r.totalCost, 'USD'),
          isHighlight: true,
        ),
        ResultTile(
          label: l10n.effectiveRate,
          value: '${r.effectiveRate.toStringAsFixed(2)}%',
        ),
        const SizedBox(height: AppSpacing.sm),
        // ── Smart Insights ────────────────────────────────────────────
        InsightCard(
          insights: InsightEngine.generate(
            vehiclePrice: r.vehiclePrice,
            loanAmount: r.financedAmount,
            annualRatePct: r.effectiveRate,
            termMonths: r.termMonths,
            monthlyPayment: r.monthlyPayment,
            totalInterest: r.totalInterest,
            downPayment: r.downPayment,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () async {
            HapticFeedback.lightImpact();
            final payment =
                '${paymentLabelFor(l10n, p.frequency)}: ${AmountFormatter.ui(r.displayPayment, 'USD')}';
            final isSpanishShare =
                Localizations.localeOf(context).languageCode == 'es';
            try {
              await Share.share(
                isSpanishShare
                    ? 'Préstamo Auto EE.UU.\n'
                        'Vehículo: ${AmountFormatter.ui(r.vehiclePrice, 'USD')}  |  Inicial: ${AmountFormatter.ui(r.downPayment, 'USD')}\n'
                        'Financiado: ${AmountFormatter.ui(r.financedAmount, 'USD')}  |  Tasa: ${r.annualRate.toStringAsFixed(2)}% (ef. ${r.effectiveRate.toStringAsFixed(2)}%)  |  ${r.termMonths ~/ 12} años\n'
                        '$payment\n'
                        'Interés total: ${AmountFormatter.ui(r.totalInterest, 'USD')}  |  Costo total: ${AmountFormatter.ui(r.totalCost, 'USD')}'
                        '${r.taxAmount > 0 ? "\nImpuesto: ${AmountFormatter.ui(r.taxAmount, 'USD')}" : ""}\n\n'
                        '📄 Exporta el reporte completo en PDF →'
                    : 'Auto Loan USA\n'
                        'Vehicle: ${AmountFormatter.ui(r.vehiclePrice, 'USD')}  |  Down: ${AmountFormatter.ui(r.downPayment, 'USD')}\n'
                        'Financed: ${AmountFormatter.ui(r.financedAmount, 'USD')}  |  Rate: ${r.annualRate.toStringAsFixed(2)}% (eff. ${r.effectiveRate.toStringAsFixed(2)}%)  |  ${r.termMonths ~/ 12} yr\n'
                        '$payment\n'
                        'Total Interest: ${AmountFormatter.ui(r.totalInterest, 'USD')}  |  Total Cost: ${AmountFormatter.ui(r.totalCost, 'USD')}'
                        '${r.taxAmount > 0 ? "\nTax: ${AmountFormatter.ui(r.taxAmount, 'USD')}" : ""}\n\n'
                        '📄 Export the full PDF report in the app →',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Shared successfully'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share failed'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.share_rounded),
          label: Text(l10n.share),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (hasFull) ...[
          OutlinedButton.icon(
            onPressed: () {
              AnalyticsService.instance.logAmortizationViewed('us');
              adService.showInterstitialThen(() {
                if (context.mounted) {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => AmortizationScreen(
                        loanAmount: r.financedAmount,
                        annualRate: r.effectiveRate,
                        termMonths: r.termMonths,
                        downPayment: r.downPayment,
                        isBiWeekly: p.isBiWeekly,
                      ),
                      transitionsBuilder: (_, anim, __, child) =>
                          FadeTransition(opacity: anim, child: child),
                      transitionDuration: AppDuration.base,
                    ),
                  );
                }
              });
            },
            icon: const Icon(Icons.table_chart),
            label: Text(l10n.amortization),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await PdfExportService.exportLoanPdf(
                  title: l10n.appNameUS,
                  currencySymbol: '\$',
                  loanAmount: r.financedAmount,
                  annualRate: r.effectiveRate,
                  termMonths: r.termMonths,
                  downPayment: r.downPayment,
                  isSpanish: Localizations.localeOf(context).languageCode == 'es',
                  summary: [
                    MapEntry(
                      l10n.vehiclePrice,
                      AmountFormatter.ui(r.vehiclePrice, 'USD'),
                    ),
                    if (r.tradeInValue > 0)
                      MapEntry(
                        l10n.tradeInValue,
                        '-${AmountFormatter.ui(r.tradeInValue, 'USD')}',
                      ),
                    MapEntry(
                      l10n.downPayment,
                      AmountFormatter.ui(r.downPayment, 'USD'),
                    ),
                    if (r.dealerFees > 0)
                      MapEntry(
                        l10n.dealerFees,
                        AmountFormatter.ui(r.dealerFees, 'USD'),
                      ),
                    MapEntry(
                      l10n.taxAmount,
                      AmountFormatter.ui(r.taxAmount, 'USD'),
                    ),
                    MapEntry(
                      l10n.financedAmount,
                      AmountFormatter.ui(r.financedAmount, 'USD'),
                    ),
                    MapEntry(
                      l10n.annualRate,
                      '${r.annualRate.toStringAsFixed(2)}%',
                    ),
                    MapEntry(
                      l10n.effectiveRate,
                      '${r.effectiveRate.toStringAsFixed(2)}%',
                    ),
                    MapEntry(l10n.termMonths, '${r.termMonths} mo'),
                    MapEntry(
                      paymentLabelFor(l10n, p.frequency),
                      AmountFormatter.ui(r.displayPayment, 'USD'),
                    ),
                    if (!p.frequency.isMonthly)
                      MapEntry(
                        '${l10n.monthlyPayment} (equiv.)',
                        AmountFormatter.ui(r.monthlyPayment, 'USD'),
                      ),
                  ],
                );
                AnalyticsService.instance.logPdfExported('us');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PDF exported successfully'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export failed'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(l10n.exportPdf),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => EarlyPayoffScreen(
                    loanAmount: r.financedAmount,
                    annualRate: r.effectiveRate,
                    termMonths: r.termMonths,
                    flavor: 'us',
                  ),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
                  transitionDuration: AppDuration.base,
                ),
              );
            },
            icon: const Icon(Icons.rocket_launch_rounded),
            label: Text(l10n.earlyPayoff),
          ),
        ] else ...[
          CalcwisePremiumGate(
            title: l10n.results,
            description: l10n.unlockFull,
            price: IAPService.instance.localizedPrice,
            onUnlock: () => PaywallSoft.show(context),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          'For informational purposes only. Not financial advice.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppTextSize.xs,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

// ── US Lease vs Buy ────────────────────────────────────────────────────────────

class _USLeaseSection extends StatefulWidget {
  final USProvider p;
  const _USLeaseSection({required this.p});

  @override
  State<_USLeaseSection> createState() => _USLeaseSectionState();
}

class _USLeaseSectionState extends State<_USLeaseSection> {
  bool _expanded = false;

  double _residualPercent = 50.0;
  double _moneyFactor = 0.00175; // ~4.2% ÷ 2400
  double _capCostReduction = 0;
  double _acquisitionFee = 795;
  int _leaseTerm = 36;

  USLeaseCalculation? _lease;

  void _calculate() {
    setState(() {
      _lease = USLeaseCalculation.calculate(
        vehiclePrice: widget.p.vehiclePrice,
        downPayment: widget.p.downPayment,
        capCostReduction: _capCostReduction,
        acquisitionFee: _acquisitionFee,
        residualPercent: _residualPercent,
        moneyFactor: _moneyFactor,
        leaseTerm: _leaseTerm,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.p.result;

    return SectionCard(
      title: 'Lease vs Buy Comparison',
      children: [
        Row(
          children: [
            Switch(
              value: _expanded,
              onChanged: (v) => setState(() => _expanded = v),
            ),
            const Expanded(child: Text('Show Lease vs Buy')),
          ],
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Residual Value %'),
                  Text(
                    '${_residualPercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _residualPercent,
                min: 30,
                max: 70,
                divisions: 40,
                onChanged: (v) => setState(() => _residualPercent = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: (_moneyFactor * 2400).toStringAsFixed(2),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Equivalent Annual Rate % (÷2400 = money factor)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              suffixText: '%',
            ),
            onChanged: (v) {
              final rate = double.tryParse(v);
              if (rate != null && rate > 0)
                setState(() => _moneyFactor = rate / 2400);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: _capCostReduction.toStringAsFixed(0),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cap Cost Reduction (\$)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              prefixText: '\$ ',
            ),
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null && val >= 0)
                setState(() => _capCostReduction = val);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: _acquisitionFee.toStringAsFixed(0),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Acquisition Fee (\$)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              prefixText: '\$ ',
            ),
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null && val >= 0)
                setState(() => _acquisitionFee = val);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            children: [24, 36, 48].map((mo) {
              final selected = mo == _leaseTerm;
              return ChoiceChip(
                label: Text('${mo ~/ 12} yr'),
                selected: selected,
                backgroundColor: Colors.transparent,
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: selected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.primary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                side: selected
                    ? BorderSide.none
                    : BorderSide(color: Theme.of(context).colorScheme.primary),
                onSelected: (_) => setState(() => _leaseTerm = mo),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              _calculate();
            },
            icon: const Icon(Icons.compare),
            label: const Text('Compare'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
          ),
          if (_lease != null && r != null) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            _USComparisonCard(
              lease: _lease!,
              buyMonthly: r.monthlyPayment,
              buyTermMonths: widget.p.termMonths,
              leaseTermMonths: _leaseTerm,
            ),
          ],
        ],
      ],
    );
  }
}

class _USComparisonCard extends StatelessWidget {
  final USLeaseCalculation lease;
  final double buyMonthly;
  final int buyTermMonths;
  final int leaseTermMonths;

  const _USComparisonCard({
    required this.lease,
    required this.buyMonthly,
    required this.buyTermMonths,
    required this.leaseTermMonths,
  });

  @override
  Widget build(BuildContext context) {
    final buyTotalOverLeaseTerm = buyMonthly * leaseTermMonths;
    final diff = lease.totalLeaseCost - buyTotalOverLeaseTerm;
    final leaseWins = diff < 0;
    final absDiff = diff.abs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _USColumn(
                label: 'Lease ($leaseTermMonths mo)',
                monthly: AmountFormatter.ui(lease.monthlyLease, 'USD'),
                total: AmountFormatter.ui(lease.totalLeaseCost, 'USD'),
                highlight: leaseWins,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _USColumn(
                label: 'Buy ($buyTermMonths mo)',
                monthly: AmountFormatter.ui(buyMonthly, 'USD'),
                total: AmountFormatter.ui(buyTotalOverLeaseTerm, 'USD'),
                highlight: !leaseWins,
                footnote: 'over $leaseTermMonths mo',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            leaseWins
                ? 'Lease saves ${AmountFormatter.ui(absDiff, 'USD')} over $leaseTermMonths months'
                : 'Buy saves ${AmountFormatter.ui(absDiff, 'USD')} over $leaseTermMonths months',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Adj cap cost: ${AmountFormatter.ui(lease.adjCapCost, 'USD')}  ·  '
          'Residual: ${AmountFormatter.ui(lease.residualValue, 'USD')}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _USColumn extends StatelessWidget {
  final String label;
  final String monthly;
  final String total;
  final bool highlight;
  final String? footnote;

  const _USColumn({
    required this.label,
    required this.monthly,
    required this.total,
    required this.highlight,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.smPlus),
      decoration: BoxDecoration(
        border: Border.all(
          color: highlight
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
          width: highlight ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            monthly,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '/month',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Total: $total',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
          if (footnote != null)
            Text(
              footnote!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

// ── US Refi Calculator ─────────────────────────────────────────────────────────

class _USRefiSection extends StatefulWidget {
  final USProvider p;
  const _USRefiSection({required this.p});

  @override
  State<_USRefiSection> createState() => _USRefiSectionState();
}

class _USRefiSectionState extends State<_USRefiSection> {
  bool _expanded = false;

  late final TextEditingController _balanceCtrl;
  late final TextEditingController _currentRateCtrl;
  late final TextEditingController _moRemainingCtrl;
  late final TextEditingController _newRateCtrl;
  late final TextEditingController _newTermCtrl;

  USRefiCalculation? _refi;

  @override
  void initState() {
    super.initState();
    final r = widget.p.result!;
    _balanceCtrl = TextEditingController(
      text: r.financedAmount.toStringAsFixed(0),
    );
    _currentRateCtrl = TextEditingController(
      text: r.effectiveRate.toStringAsFixed(2),
    );
    _moRemainingCtrl = TextEditingController(text: r.termMonths.toString());
    _newRateCtrl = TextEditingController(
      text: (r.effectiveRate - 1).clamp(0, 30).toStringAsFixed(2),
    );
    _newTermCtrl = TextEditingController(text: r.termMonths.toString());
  }

  @override
  void dispose() {
    _balanceCtrl.dispose();
    _currentRateCtrl.dispose();
    _moRemainingCtrl.dispose();
    _newRateCtrl.dispose();
    _newTermCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final balance = double.tryParse(_balanceCtrl.text) ?? 0;
    final currentRate = double.tryParse(_currentRateCtrl.text) ?? 0;
    final moRemaining = int.tryParse(_moRemainingCtrl.text) ?? 0;
    final newRate = double.tryParse(_newRateCtrl.text) ?? 0;
    final newTerm = int.tryParse(_newTermCtrl.text) ?? 0;

    if (balance <= 0 || moRemaining <= 0 || newTerm <= 0) return;

    setState(() {
      _refi = USRefiCalculation.calculate(
        currentBalance: balance,
        currentRate: currentRate,
        currentMonthsRemaining: moRemaining,
        newRate: newRate,
        newTermMonths: newTerm,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Refi Calculator',
      children: [
        Row(
          children: [
            Switch(
              value: _expanded,
              onChanged: (v) => setState(() => _expanded = v),
            ),
            const Expanded(child: Text('Show Refinancing Calculator')),
          ],
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.md),
          _RefiField(
            controller: _balanceCtrl,
            label: 'Current remaining balance (\$)',
          ),
          const SizedBox(height: AppSpacing.sm),
          _RefiField(
            controller: _currentRateCtrl,
            label: 'Current rate (%)',
            suffix: '%',
          ),
          const SizedBox(height: AppSpacing.sm),
          _RefiField(
            controller: _moRemainingCtrl,
            label: 'Months remaining',
            suffix: 'mo',
          ),
          const SizedBox(height: AppSpacing.sm),
          _RefiField(
            controller: _newRateCtrl,
            label: 'New rate (%)',
            suffix: '%',
          ),
          const SizedBox(height: AppSpacing.sm),
          _RefiField(
            controller: _newTermCtrl,
            label: 'New term (months)',
            suffix: 'mo',
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              _calculate();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Calculate Refi'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
          ),
          if (_refi != null) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            ResultTile(
              label: 'Current monthly payment',
              value: AmountFormatter.ui(_refi!.currentMonthly, 'USD'),
            ),
            ResultTile(
              label: 'New monthly payment',
              value: AmountFormatter.ui(_refi!.newMonthly, 'USD'),
            ),
            ResultTile(
              label: 'Monthly savings',
              value: AmountFormatter.ui(_refi!.monthlySavings, 'USD'),
              isHighlight: _refi!.monthlySavings > 0,
            ),
            ResultTile(
              label: 'Total interest saved',
              value: AmountFormatter.ui(_refi!.totalInterestSavings, 'USD'),
            ),
            if (_refi!.breakevenMonths > 0)
              ResultTile(
                label: 'Breakeven',
                value: '${_refi!.breakevenMonths} months',
              ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _refi!.isWorthIt
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _refi!.isWorthIt
                        ? Icons.thumb_up_rounded
                        : Icons.thumb_down_rounded,
                    color: _refi!.isWorthIt
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _refi!.isWorthIt
                        ? 'Worth it — saves money overall'
                        : 'Not worth it — costs more overall',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _RefiField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? suffix;

  const _RefiField({
    required this.controller,
    required this.label,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }
}

// ── US Total Cost of Ownership ─────────────────────────────────────────────────

class _USTcoSection extends StatefulWidget {
  final USProvider p;
  const _USTcoSection({required this.p});

  @override
  State<_USTcoSection> createState() => _USTcoSectionState();
}

class _USTcoSectionState extends State<_USTcoSection> {
  bool _expanded = false;

  double _annualMiles = 15000;
  double _mpg = 28;
  double _gasPrice = 3.50;
  double _annualIns = 1400;
  double _annualMaint = 800;

  USTcoCalculation? _tco;

  void _calculate() {
    final r = widget.p.result!;
    setState(() {
      _tco = USTcoCalculation.calculate(
        annualMiles: _annualMiles,
        mpg: _mpg,
        gasPricePerGallon: _gasPrice,
        annualInsurance: _annualIns,
        annualMaintenance: _annualMaint,
        termMonths: r.termMonths,
        totalInterest: r.totalInterest,
        vehiclePrice: r.vehiclePrice,
        tradeInValue: r.tradeInValue,
        downPayment: r.downPayment,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.p.result!;
    final termYears = r.termMonths ~/ 12;

    return SectionCard(
      title: 'Total Cost of Ownership',
      children: [
        Row(
          children: [
            Switch(
              value: _expanded,
              onChanged: (v) => setState(() => _expanded = v),
            ),
            const Expanded(child: Text('Calculate true ownership cost')),
          ],
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.md),
          _USTcoRow(
            label: 'Annual miles driven',
            value: _annualMiles,
            min: 3000,
            max: 40000,
            step: 1000,
            display: '${_annualMiles.toStringAsFixed(0)} mi',
            onChanged: (v) => setState(() => _annualMiles = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _USTcoRow(
            label: 'MPG',
            value: _mpg,
            min: 10,
            max: 60,
            step: 1,
            display: '${_mpg.toStringAsFixed(0)} mpg',
            onChanged: (v) => setState(() => _mpg = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _USTcoRow(
            label: 'Gas price (\$/gal)',
            value: _gasPrice,
            min: 1.50,
            max: 6.00,
            step: 0.10,
            display: AmountFormatter.ui(_gasPrice, 'USD'),
            onChanged: (v) => setState(() => _gasPrice = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _USTcoRow(
            label: 'Annual insurance (\$)',
            value: _annualIns,
            min: 400,
            max: 5000,
            step: 100,
            display: AmountFormatter.formatInteger(_annualIns),
            onChanged: (v) => setState(() => _annualIns = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _USTcoRow(
            label: 'Annual maintenance (\$)',
            value: _annualMaint,
            min: 200,
            max: 3000,
            step: 100,
            display: AmountFormatter.formatInteger(_annualMaint),
            onChanged: (v) => setState(() => _annualMaint = v),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              _calculate();
            },
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calculate TCO'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
          ),
          if (_tco != null) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            ResultTile(
              label: 'Net vehicle cost',
              value: AmountFormatter.formatInteger(_tco!.netVehicleCost),
            ),
            ResultTile(
              label: 'Total interest',
              value: AmountFormatter.formatInteger(_tco!.totalInterest),
            ),
            ResultTile(label: 'Total gas', value: AmountFormatter.formatInteger(_tco!.totalGas)),
            ResultTile(
              label: 'Total insurance',
              value: AmountFormatter.formatInteger(_tco!.totalInsurance),
            ),
            ResultTile(
              label: 'Total maintenance',
              value: AmountFormatter.formatInteger(_tco!.totalMaintenance),
            ),
            const Divider(height: 8),
            ResultTile(
              label: 'True cost of owning over $termYears years',
              value: AmountFormatter.formatInteger(_tco!.grandTotal),
              isHighlight: true,
            ),
          ],
        ],
      ],
    );
  }
}

class _USTcoRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final String display;
  final ValueChanged<double> onChanged;

  const _USTcoRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.display,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          display,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Flexible(
          child: SizedBox(
            width: 120,
            child: SliderTheme(
              data: SliderTheme.of(
                context,
              ).copyWith(overlayShape: SliderComponentShape.noOverlay),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: ((max - min) / step).round().clamp(1, 500),
                onChanged: (v) => onChanged((v / step).round() * step),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── US Affordability Reverse-Solver ───────────────────────────────────────────

class _USAffordabilityReverseSolverSection extends StatefulWidget {
  final USProvider p;
  const _USAffordabilityReverseSolverSection({required this.p});

  @override
  State<_USAffordabilityReverseSolverSection> createState() =>
      _USAffordabilityReverseSolverSectionState();
}

class _USAffordabilityReverseSolverSectionState
    extends State<_USAffordabilityReverseSolverSection> {
  bool _expanded = false;

  double _monthlyBudget = 500;
  double _downPayment = 3000;
  double _tradeIn = 0;
  double _salesTaxPct = 8.0;
  double _dealerFees = 500;

  // Desired term (months) — used for main calculation
  int _term = 60;

  // Results
  double? _maxPrice;

  // Credit-score tiers for auto-fill rate
  static const _creditTiers = [
    (label: 'Excellent (750+)', rate: 5.5),
    (label: 'Good (700–749)', rate: 6.5),
    (label: 'Fair (650–699)', rate: 9.0),
    (label: 'Poor (<650)', rate: 14.0),
  ];
  int _creditTierIndex = 0;
  double get _rate => _creditTiers[_creditTierIndex].rate;

  /// Reverse-PMT: given monthly payment, return max loan principal
  double _reversePmt(double pmt, double annualRate, int n) {
    if (pmt <= 0 || n <= 0) return 0;
    if (annualRate <= 0) return pmt * n;
    final r = annualRate / 12 / 100;
    return pmt * (1 - pow(1 + r, -n)) / r;
  }

  /// Max affordable vehicle price given budget, tax, fees, down, trade-in
  double _maxVehiclePrice({
    required double monthlyBudget,
    required double annualRate,
    required int termMonths,
    required double downPayment,
    required double tradeIn,
    required double salesTaxPct,
    required double dealerFees,
  }) {
    // financedAmount = vehiclePrice * (1 + tax%) + dealerFees - downPayment - tradeIn
    // Solve: reversePmt(monthlyBudget, rate, term) = vehiclePrice*(1+taxPct/100) + dealerFees - down - tradeIn
    final loanPV = _reversePmt(monthlyBudget, annualRate, termMonths);
    // vehiclePrice*(1+taxPct/100) = loanPV - dealerFees + downPayment + tradeIn
    final taxFactor = 1.0 + salesTaxPct / 100;
    final vehiclePrice =
        (loanPV - dealerFees + downPayment + tradeIn) / taxFactor;
    return vehiclePrice.clamp(0, double.infinity);
  }

  void _calculate() {
    setState(() {
      _maxPrice = _maxVehiclePrice(
        monthlyBudget: _monthlyBudget,
        annualRate: _rate,
        termMonths: _term,
        downPayment: _downPayment,
        tradeIn: _tradeIn,
        salesTaxPct: _salesTaxPct,
        dealerFees: _dealerFees,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'How Much Can I Afford?',
      children: [
        Row(
          children: [
            Switch(
              value: _expanded,
              onChanged: (v) => setState(() => _expanded = v),
            ),
            const Expanded(child: Text('Affordability Reverse-Solver')),
          ],
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.md),
          // Monthly budget
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monthly budget for car payment'),
                  Text(
                    AmountFormatter.ui(_monthlyBudget, 'USD'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _monthlyBudget.clamp(100, 2000),
                min: 100,
                max: 2000,
                divisions: 38,
                onChanged: (v) =>
                    setState(() => _monthlyBudget = (v / 50).round() * 50.0),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Down payment
          CurrencySliderInput(
            label: 'Available down payment',
            value: _downPayment,
            min: 0,
            max: 20000,
            step: 500,
            onChanged: (v) => setState(() => _downPayment = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Trade-in
          CurrencySliderInput(
            label: 'Trade-in value (optional)',
            value: _tradeIn,
            min: 0,
            max: 20000,
            step: 500,
            onChanged: (v) => setState(() => _tradeIn = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Sales tax
          PercentSliderInput(
            label: 'Sales tax (%)',
            value: _salesTaxPct,
            min: 0,
            max: 15,
            step: 0.5,
            onChanged: (v) => setState(() => _salesTaxPct = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Dealer fees
          CurrencySliderInput(
            label: 'Dealer fees',
            value: _dealerFees,
            min: 0,
            max: 3000,
            step: 50,
            onChanged: (v) => setState(() => _dealerFees = v),
          ),
          const SizedBox(height: AppSpacing.md),
          // Credit score tier
          const Text(
            'Credit score tier',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...List.generate(_creditTiers.length, (i) {
            final tier = _creditTiers[i];
            final selected = i == _creditTierIndex;
            return RadioListTile<int>(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(tier.label),
              subtitle: Text(
                'Auto rate: ${tier.rate.toStringAsFixed(1)}% APR',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: i,
              groupValue: _creditTierIndex,
              onChanged: (v) {
                if (v != null) setState(() => _creditTierIndex = v);
              },
            );
          }),
          const SizedBox(height: AppSpacing.sm),
          // Desired term
          DurationChips(
            label: 'Desired loan term',
            options: const [36, 48, 60, 72],
            selected: _term,
            onSelected: (v) => setState(() => _term = v),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              _calculate();
            },
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calculate Affordability'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
          ),
          if (_maxPrice != null) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            // Hero result
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                children: [
                  Text(
                    'With ${_creditTiers[_creditTierIndex].label} credit at ${_rate.toStringAsFixed(1)}%, you can afford up to',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AmountFormatter.formatInteger(_maxPrice!),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'vehicle price  ·  ${AmountFormatter.ui(_monthlyBudget, 'USD')}/mo payment  ·  $_term mo',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Multi-term table
            Text(
              'Same budget at different terms:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...const [36, 48, 60, 72].map((mo) {
              final price = _maxVehiclePrice(
                monthlyBudget: _monthlyBudget,
                annualRate: _rate,
                termMonths: mo,
                downPayment: _downPayment,
                tradeIn: _tradeIn,
                salesTaxPct: _salesTaxPct,
                dealerFees: _dealerFees,
              );
              final isSelected = mo == _term;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${mo ~/ 12} yr ($mo mo)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        AmountFormatter.formatInteger(price),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 24,
                      child: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Includes ${_salesTaxPct.toStringAsFixed(1)}% sales tax, '
              '${AmountFormatter.formatInteger(_dealerFees)} dealer fees.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

// ── US Affordability Guide ─────────────────────────────────────────────────────

class _USAffordabilitySection extends StatefulWidget {
  final USProvider p;
  const _USAffordabilitySection({required this.p});

  @override
  State<_USAffordabilitySection> createState() =>
      _USAffordabilitySectionState();
}

class _USAffordabilitySectionState extends State<_USAffordabilitySection> {
  bool _expanded = false;
  double _monthlyIncome = 5000;

  @override
  Widget build(BuildContext context) {
    final r = widget.p.result;

    // Traffic-light: US thresholds — 15% / 20%
    Color? _trafficColor;
    String _trafficLabel = '';
    if (r != null) {
      final ratio = r.monthlyPayment / _monthlyIncome;
      if (ratio < 0.15) {
        _trafficColor = CalcwiseTheme.of(context).successGreen;
        _trafficLabel = 'Comfortable (< 15% of income)';
      } else if (ratio <= 0.20) {
        _trafficColor = CalcwiseTheme.of(context).warningOrange;
        _trafficLabel = 'Moderate (15–20% of income)';
      } else {
        _trafficColor = CalcwiseTheme.of(context).errorRed;
        _trafficLabel = 'Over budget (> 20% of income)';
      }
    }

    return SectionCard(
      title: 'Affordability Guide',
      children: [
        Row(
          children: [
            Switch(
              value: _expanded,
              onChanged: (v) => setState(() => _expanded = v),
            ),
            const Expanded(child: Text('Show Affordability Guide')),
          ],
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Gross monthly income'),
                  Text(
                    AmountFormatter.formatInteger(_monthlyIncome),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _monthlyIncome.clamp(2000, 25000),
                min: 2000,
                max: 25000,
                divisions: ((25000 - 2000) / 500).round(),
                onChanged: (v) =>
                    setState(() => _monthlyIncome = (v / 500).round() * 500),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AmountFormatter.formatInteger(2000),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    AmountFormatter.formatInteger(25000),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          ResultTile(
            label: 'Recommended max payment (15% of income)',
            value: '${AmountFormatter.ui(_monthlyIncome * 0.15, 'USD')}/mo',
          ),
          if (r != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _trafficColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your payment ${AmountFormatter.ui(r.monthlyPayment, 'USD')}/mo — $_trafficLabel',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _trafficColor,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Calculate a loan above to see your payment rating.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

// ── Premium tool card (US) ─────────────────────────────────────────────────────

class _PremiumToolCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _PremiumToolCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: Listenable.merge([
        freemiumService.hasFullAccessNotifier,
        freemiumService.isRewardedNotifier,
      ]),
      builder: (context, _) {
        final hasFull =
            freemiumService.hasFullAccess || freemiumService.isRewarded;
        return hasFull
            ? _buildUnlockedCard(context, cs)
            : CalcwisePremiumGate(
                title: label,
                description: description,
                price: IAPService.instance.localizedPrice,
                onUnlock: () => PaywallSoft.show(context),
              );
      },
    );
  }

  Widget _buildUnlockedCard(BuildContext context, ColorScheme cs) {
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.mdPlus,
          ),
          child: Row(
            children: [
              // Tool icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: cs.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.smPlus),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
