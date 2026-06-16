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
import 'ca_provider.dart';
import 'ca_logic.dart';
import 'ca_taxes.dart';

class CAScreen extends StatefulWidget {
  const CAScreen({super.key});

  @override
  State<CAScreen> createState() => _CAScreenState();
}

class _CAScreenState extends State<CAScreen> {
  Timer? _debounce;

  bool _validated = false;
  int _selectedTab = 0;
  int _historyRefreshKey = 0;
  bool _wasPremium = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView('ca');
    _wasPremium = freemiumService.hasFullAccess;
    freemiumService.isPremiumNotifier.addListener(_onPremiumChange);
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
      try { AnalyticsService.instance.logPaywallConverted('iap'); } catch (_) {}
    }
    _wasPremium = now;
    unawaited(AnalyticsService.instance.setUserPremium(now));
  }

  Future<void> _onNavTap(int i) async {
    if (i == _selectedTab) return;
    if (i == 1) {
      AnalyticsService.instance.logTabChanged('compare');
      AnalyticsService.instance.logCompareUsed('ca');
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

  void _debouncedCalculate() {
    if (!_validated) setState(() => _validated = true);
    _debounce?.cancel();
    _debounce = Timer(AppDuration.page, () {
      if (!mounted) return;
      final p = context.read<CAProvider>();
      p.calculate();
      p.scheduleAutoSave();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adService = context.read<CalcwiseAdService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appNameCA),
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
                      const SettingsScreen(flavor: 'ca'),
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
          NavigationDestination(
            icon: const Icon(Icons.balance_outlined),
            selectedIcon: const Icon(Icons.balance_rounded),
            label: l10n.leaseVsBuy,
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
            child: Builder(
              builder: (context) {
                final pages = <Widget>[
                  // Tab 0: Calculator
                  _CACalculatorTab(
                    validated: _validated,
                    onCalculate: _debouncedCalculate,
                    adService: adService,
                  ),
                  // Tab 1: Compare
                  CompareScreen(flavor: 'ca', showAppBar: false),
                  // Tab 2: Lease vs Buy
                  const LeaseVsBuyScreen(flavor: 'ca', showAppBar: false),
                  // Tab 3: History
                  HistoryScreen(
                    key: ValueKey(_historyRefreshKey),
                    country: 'ca',
                    showAppBar: false,
                    onClear: () => setState(() => _historyRefreshKey++),
                  ),
                ];
                return Stack(
                  fit: StackFit.expand,
                  children: List.generate(
                    pages.length,
                    (i) => IgnorePointer(
                      ignoring: _selectedTab != i,
                      child: CalcwiseTabReveal(
                        active: _selectedTab == i,
                        child: pages[i],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const CalcwiseAdFooter(),
        ],
      ),
    );
  }
}

// ── CA Calculator Tab ──────────────────────────────────────────────────────────

class _CACalculatorTab extends StatelessWidget {
  final bool validated;
  final VoidCallback onCalculate;
  final CalcwiseAdService adService;

  const _CACalculatorTab({
    required this.validated,
    required this.onCalculate,
    required this.adService,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CAProvider>(
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
                                  child: _CAResults(p: p, adService: adService),
                                ),
                                CalcwiseStaggerItem(
                                  index: 1,
                                  child: SaveScenarioButton(
                                    onSave: (label) => context
                                        .read<CAProvider>()
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
                                    'fr'
                                ? 'Pas encore de résultats'
                                : 'No results yet',
                            body:
                                Localizations.localeOf(context).languageCode ==
                                    'fr'
                                ? 'Entrez le prix du véhicule pour voir votre analyse.'
                                : 'Enter the vehicle price to see your analysis.',
                          ),
                        // ── Input sections ────────────────────────────────
                        _CAVehicleSection(
                          p: p,
                          validated: validated,
                          onCalculate: onCalculate,
                        ),
                        _CAProvinceSection(p: p, onCalculate: onCalculate),
                        _CALoanTermsSection(
                          p: p,
                          validated: validated,
                          onCalculate: onCalculate,
                        ),
                        _CAInsuranceSection(p: p, onCalculate: onCalculate),
                        // ── Cost Breakdown Chart ─────────────────────────
                        if (p.result != null)
                          Builder(
                            builder: (context) {
                              final isFr = Localizations.localeOf(context).languageCode == 'fr';
                              final principal = p.result!.loanAmount;
                              final interest = p.result!.totalInterest;
                              final cs = Theme.of(context).colorScheme;
                              return SectionCard(
                                title: isFr ? 'Répartition des coûts' : 'Cost Breakdown',
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
                        _CAQuickToolsSection(p: p),
                        // ── Extra sections ────────────────────────────────
                        if (p.result != null) _CATcoSection(p: p),
                        _CALeaseSection(p: p),
                        _CATradeInSection(p: p),
                        _CAAffordabilitySection(p: p),
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

// ── CA Vehicle Section ─────────────────────────────────────────────────────────

class _CAVehicleSection extends StatelessWidget {
  final CAProvider p;
  final bool validated;
  final VoidCallback onCalculate;

  const _CAVehicleSection({
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
          symbol: 'C\$',
          helperText: 'e.g. 35 000',
          errorText: validated && p.vehiclePrice <= 0
              ? (Localizations.localeOf(context).languageCode == 'fr' ? 'Requis' : 'Required')
              : null,
          onChanged: (v) {
            p.setVehiclePrice(v);
            onCalculate();
          },
        ),
        const SizedBox(height: AppSpacing.md),
        CurrencySliderInput(
          label: l10n.downPayment,
          value: p.dpAmount,
          min: 0,
          max: p.vehiclePrice * 0.5,
          step: 500,
          symbol: 'C\$',
          onChanged: (v) {
            p.setDpIsPercent(false);
            p.setDownPayment(v);
            onCalculate();
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Switch(
              value: p.dpIsPercent,
              onChanged: (v) {
                p.setDpIsPercent(v);
                onCalculate();
              },
            ),
            Text(' ${l10n.usePercentage}'),
            if (p.dpIsPercent) ...[
              const SizedBox(width: 8),
              Text(
                '${p.downPayment.toStringAsFixed(1)}%',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ── CA Province Section ────────────────────────────────────────────────────────

class _CAProvinceSection extends StatelessWidget {
  final CAProvider p;
  final VoidCallback onCalculate;

  const _CAProvinceSection({required this.p, required this.onCalculate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SectionCard(
      title: l10n.province,
      children: [
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: p.provinceCode,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.province,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
          ),
          selectedItemBuilder: (ctx) => kCAProvinces
              .map(
                (prov) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${prov.code} · '
                    '${(prov.totalRate * 100).toStringAsFixed(prov.totalRate == 0.14975 ? 3 : 0)}%',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          items: kCAProvinces
              .map(
                (prov) => DropdownMenuItem(
                  value: prov.code,
                  child: Text(
                    '${prov.code}  ${prov.nameEn}  '
                    '${(prov.totalRate * 100).toStringAsFixed(prov.totalRate == 0.14975 ? 3 : 0)}%',
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) {
              p.setProvinceCode(v);
              onCalculate();
            }
          },
        ),
        if (p.result != null) ...[
          const SizedBox(height: AppSpacing.sm),
          ResultTile(
            label: l10n.taxAmount,
            value: AmountFormatter.ui(p.result!.taxAmount, 'CAD'),
          ),
        ],
      ],
    );
  }
}

// ── CA Loan Terms Section ──────────────────────────────────────────────────────

class _CALoanTermsSection extends StatelessWidget {
  final CAProvider p;
  final bool validated;
  final VoidCallback onCalculate;

  const _CALoanTermsSection({
    required this.p,
    required this.validated,
    required this.onCalculate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SectionCard(
      title: l10n.loanTerms,
      children: [
        RateInputField(
          label: l10n.annualRate,
          value: p.annualRate,
          helperText: 'Default rate as of 2026 — update to your actual rate',
          onChanged: (v) {
            p.setAnnualRate(v);
            onCalculate();
          },
          errorText: validated && p.annualRate <= 0
              ? (Localizations.localeOf(context).languageCode == 'fr' ? 'Requis' : 'Required')
              : null,
        ),
        const SizedBox(height: AppSpacing.lg),
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

// ── CA Insurance Section ───────────────────────────────────────────────────────

class _CAInsuranceSection extends StatelessWidget {
  final CAProvider p;
  final VoidCallback onCalculate;

  const _CAInsuranceSection({required this.p, required this.onCalculate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SectionCard(
      title: l10n.insurance,
      children: [
        _InsuranceRow(
          label:
              '${l10n.lifeDisability} (C\$${p.insurance.lifeDisabilityAmount.toStringAsFixed(0)}/${l10n.month})',
          value: p.insurance.lifeDisability,
          onChanged: (v) {
            p.setLifeDisability(v);
            onCalculate();
          },
        ),
        _InsuranceRow(
          label: l10n.extendedWarranty,
          value: p.insurance.extendedWarranty,
          onChanged: (v) {
            p.setExtendedWarranty(v);
            onCalculate();
          },
        ),
        if (p.insurance.extendedWarranty)
          CurrencySliderInput(
            label: '${l10n.extendedWarranty} Total',
            value: p.insurance.warrantyAmount,
            min: 0,
            max: 5000,
            step: 100,
            symbol: 'C\$',
            onChanged: (v) {
              p.setWarrantyAmount(v);
              onCalculate();
            },
          ),
        _InsuranceRow(
          label: l10n.gap,
          value: p.insurance.gap,
          onChanged: (v) {
            p.setGap(v);
            onCalculate();
          },
        ),
        if (p.insurance.gap)
          CurrencySliderInput(
            label: '${l10n.gap} Total',
            value: p.insurance.gapAmount,
            min: 0,
            max: 2000,
            step: 50,
            symbol: 'C\$',
            onChanged: (v) {
              p.setGapAmount(v);
              onCalculate();
            },
          ),
      ],
    );
  }
}

// ── CA Quick Tools Section (Reverse Solve + Cash-Back) ────────────────────────

class _CAQuickToolsSection extends StatelessWidget {
  final CAProvider p;

  const _CAQuickToolsSection({required this.p});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    return Column(
      children: [
        // ── Reverse Affordability ──────────────────────────────────────
        const SizedBox(height: AppSpacing.md),
        ReverseSolveCard(
          title: isFr
              ? 'Quel prix de véhicule puis-je me permettre?'
              : 'What vehicle price can I afford?',
          targetLabel: isFr ? 'Paiement mensuel cible' : 'Target monthly payment',
          resultLabel: isFr ? 'Prix max du véhicule' : 'Max vehicle price',
          prefix: 'C\$',
          minBound: 5000,
          maxBound: 200000,
          targetValue: 0,
          ascending: true,
          compute: (vehiclePrice) {
            final dpRatio = p.vehiclePrice > 0
                ? (p.dpAmount / p.vehiclePrice).clamp(0.0, 0.95)
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
        // ── Cash-Back vs Low-APR Comparator ───────────────────────────
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) =>
                    const CashbackVsLowAprScreen(flavor: 'ca'),
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
          label: l10n.trueCostOfOwnership,
          description: isFr
              ? 'Analysez le vrai coût total de votre véhicule'
              : 'Analyze the true total cost of your vehicle',
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => TotalCostScreen(
                flavor: 'ca',
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
          label: l10n.compare3Loans,
          description: isFr
              ? 'Comparez jusqu\'a 3 offres de pret cote a cote'
              : 'Compare up to 3 loan offers side by side',
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) =>
                  const LoanComparisonScreen(flavor: 'ca'),
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

class _InsuranceRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _InsuranceRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Switch(value: value, onChanged: onChanged),
      Expanded(
        child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ),
    ],
  );
}

class _CAResults extends StatelessWidget {
  final CAProvider p;
  final CalcwiseAdService adService;
  const _CAResults({required this.p, required this.adService});

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
    CACalculation r,
    bool hasFull,
  ) {
    return SectionCard(
      title: l10n.results,
      children: [
        // ── Hero monthly payment ──────────────────────────────────────────
        CalcwiseHeroCard(
          label: paymentLabelFor(l10n, p.frequency),
          value: AmountFormatter.ui(r.displayPayment, 'CAD'),
          rawValue: r.displayPayment,
          valueFormatter: (v) => AmountFormatter.ui(v, 'CAD'),
          secondary: 'Principal & Interest',
          stats: [
            (label: l10n.totalInterest, value: AmountFormatter.ui(r.totalInterest, 'CAD')),
            (label: l10n.totalCost, value: AmountFormatter.ui(r.totalCost, 'CAD')),
          ],
          rawStats: [
            (label: l10n.totalInterest, value: r.totalInterest, formatter: (v) => AmountFormatter.ui(v, 'CAD')),
            (label: l10n.totalCost, value: r.totalCost, formatter: (v) => AmountFormatter.ui(v, 'CAD')),
          ],
        ),
        if (!p.frequency.isMonthly)
          ResultTile(
            label: '${l10n.monthlyPayment} (equiv.)',
            value: AmountFormatter.ui(r.monthlyPayment, 'CAD'),
          ),
        ResultTile(label: l10n.loanAmount, value: AmountFormatter.ui(r.loanAmount, 'CAD')),
        ResultTile(
          label: '${l10n.taxAmount} (${r.provinceCode})',
          value: AmountFormatter.ui(r.taxAmount, 'CAD'),
        ),
        const Divider(),
        // Cost breakdown — always visible
        ResultTile(label: l10n.financedAmount, value: AmountFormatter.ui(r.loanAmount, 'CAD')),
        ResultTile(
          label: l10n.totalInterest,
          value: AmountFormatter.ui(r.totalInterest, 'CAD'),
        ),
        if (r.insuranceTotal > 0)
          ResultTile(
            label: l10n.totalInsurances,
            value: AmountFormatter.ui(r.insuranceTotal, 'CAD'),
          ),
        ResultTile(label: l10n.downPayment, value: AmountFormatter.ui(r.downPayment, 'CAD')),
        const Divider(height: 8),
        ResultTile(
          label: l10n.totalCost,
          value: AmountFormatter.ui(r.totalCost, 'CAD'),
          isHighlight: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        // ── Smart Insights ────────────────────────────────────────────
        InsightCard(
          insights: InsightEngine.generate(
            vehiclePrice: r.vehiclePrice,
            loanAmount: r.loanAmount,
            annualRatePct: r.annualRate,
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
                '${paymentLabelFor(l10n, p.frequency)}: ${AmountFormatter.ui(r.displayPayment, 'CAD')}';
            final isFrenchShare =
                Localizations.localeOf(context).languageCode == 'fr';
            try {
              await Share.share(
                isFrenchShare
                    ? 'Prêt Auto CA\n'
                        'Véhicule: ${AmountFormatter.ui(r.vehiclePrice, 'CAD')}  |  Mise de fonds: ${AmountFormatter.ui(r.downPayment, 'CAD')}\n'
                        'Prêt: ${AmountFormatter.ui(r.loanAmount, 'CAD')}  |  Taux: ${r.annualRate.toStringAsFixed(2)}%  |  ${r.termMonths ~/ 12} ans\n'
                        '$payment\n'
                        'Intérêts totaux: ${AmountFormatter.ui(r.totalInterest, 'CAD')}  |  Coût total: ${AmountFormatter.ui(r.totalCost, 'CAD')}\n'
                        'Taxe (${r.provinceCode}): ${AmountFormatter.ui(r.taxAmount, 'CAD')}\n\n'
                        '📄 Exportez le rapport PDF complet dans l\'app →'
                    : 'Auto Loan CA\n'
                        'Vehicle: ${AmountFormatter.ui(r.vehiclePrice, 'CAD')}  |  Down: ${AmountFormatter.ui(r.downPayment, 'CAD')}\n'
                        'Loan: ${AmountFormatter.ui(r.loanAmount, 'CAD')}  |  Rate: ${r.annualRate.toStringAsFixed(2)}%  |  ${r.termMonths ~/ 12} yr\n'
                        '$payment\n'
                        'Total Interest: ${AmountFormatter.ui(r.totalInterest, 'CAD')}  |  Total Cost: ${AmountFormatter.ui(r.totalCost, 'CAD')}\n'
                        'Tax (${r.provinceCode}): ${AmountFormatter.ui(r.taxAmount, 'CAD')}\n\n'
                        '📄 Export the full PDF report in the app →',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isFrenchShare
                        ? 'Partagé avec succès'
                        : 'Shared successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isFrenchShare
                        ? 'Échec du partage'
                        : 'Share failed'),
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
              AnalyticsService.instance.logAmortizationViewed('ca');
              adService.showInterstitialThen(() {
                if (context.mounted) {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => AmortizationScreen(
                        loanAmount: r.loanAmount,
                        annualRate: r.annualRate,
                        termMonths: r.termMonths,
                        downPayment: r.downPayment,
                        insuranceMonthly: p.insurance.monthlyTotal(
                          r.termMonths,
                        ),
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
              final isFrPdf =
                  Localizations.localeOf(context).languageCode == 'fr';
              try {
                await PdfExportService.exportLoanPdf(
                  title: l10n.appNameCA,
                  currencySymbol: 'C\$',
                  loanAmount: r.loanAmount,
                  annualRate: r.annualRate,
                  termMonths: r.termMonths,
                  downPayment: r.downPayment,
                  insuranceMonthly: p.insurance.monthlyTotal(r.termMonths),
                  isFrench: isFrPdf,
                  summary: [
                    MapEntry(
                      l10n.vehiclePrice,
                      AmountFormatter.ui(r.vehiclePrice, 'CAD'),
                    ),
                    MapEntry(
                      '${l10n.taxAmount} (${r.provinceCode})',
                      AmountFormatter.ui(r.taxAmount, 'CAD'),
                    ),
                    MapEntry(
                      l10n.downPayment,
                      AmountFormatter.ui(r.downPayment, 'CAD'),
                    ),
                    MapEntry(
                      l10n.loanAmount,
                      AmountFormatter.ui(r.loanAmount, 'CAD'),
                    ),
                    MapEntry(
                      l10n.annualRate,
                      '${r.annualRate.toStringAsFixed(2)}%',
                    ),
                    MapEntry(
                      l10n.termMonths,
                      '${r.termMonths} mo (${r.termMonths ~/ 12} yr)',
                    ),
                    MapEntry(
                      l10n.monthlyPayment,
                      AmountFormatter.ui(r.monthlyPayment, 'CAD'),
                    ),
                    if (p.frequency == PaymentFrequency.biWeekly)
                      MapEntry(
                        l10n.biWeeklyPayment,
                        AmountFormatter.ui(r.biWeeklyPayment, 'CAD'),
                      ),
                    if (p.frequency == PaymentFrequency.weekly)
                      MapEntry(
                        l10n.weeklyPayment,
                        AmountFormatter.ui(r.weeklyPayment, 'CAD'),
                      ),
                    if (r.insuranceTotal > 0)
                      MapEntry(
                        l10n.totalInsurances,
                        AmountFormatter.ui(r.insuranceTotal, 'CAD'),
                      ),
                  ],
                );
                AnalyticsService.instance.logPdfExported('ca');
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isFrPdf
                          ? 'PDF exporté avec succès'
                          : 'PDF exported successfully'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
              } catch (e) {
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isFrPdf
                          ? 'Échec de l\'export'
                          : 'Export failed'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
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
                    loanAmount: r.loanAmount,
                    annualRate: r.annualRate,
                    termMonths: r.termMonths,
                    currencySymbol: 'C\$',
                    flavor: 'ca',
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

// ── CA Lease vs Buy ────────────────────────────────────────────────────────────

class _CALeaseSection extends StatefulWidget {
  final CAProvider p;
  const _CALeaseSection({required this.p});

  @override
  State<_CALeaseSection> createState() => _CALeaseSectionState();
}

class _CALeaseSectionState extends State<_CALeaseSection> {
  bool _expanded = false;

  double _residualPercent = 50.0;
  double _moneyFactor = 0.00175; // ~4.2% ÷ 2400
  int _leaseTerm = 36;

  CALeaseCalculation? _lease;

  // ── Km Overage Calculator ──────────────────────────────────────────────
  bool _overageExpanded = false;
  double _annualKmAllowance = 20000;
  double _estimatedAnnualKm = 20000;
  double _overageFeeCentsPerKm = 15; // $0.15/km

  void _calculate() {
    setState(() {
      _lease = CALeaseCalculation.calculate(
        vehiclePrice: widget.p.vehiclePrice,
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
      title: AppLocalizations.of(context)!.leaseVsBuy,
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
          // Residual %
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text('Residual Value %', overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
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
          // Money factor
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
              if (rate != null && rate > 0) {
                setState(() => _moneyFactor = rate / 2400);
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),
          // Lease term chips
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
            // Compute buy equivalent monthly for the lease term
            _ComparisonCard(
              lease: _lease!,
              buyMonthly: r.monthlyPayment,
              buyTermMonths: widget.p.termMonths,
              leaseTermMonths: _leaseTerm,
            ),
          ],
          // ── Km Overage Calculator ──────────────────────────────────────
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          Row(
            children: [
              Switch(
                value: _overageExpanded,
                onChanged: (v) => setState(() => _overageExpanded = v),
              ),
              const Expanded(
                child: Text(
                  'Km Overage Calculator',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (_overageExpanded) ...[
            const SizedBox(height: AppSpacing.sm),
            _TcoSlider(
              label: 'Annual km allowance',
              value: _annualKmAllowance,
              min: 10000,
              max: 40000,
              step: 1000,
              display: '${_annualKmAllowance.toStringAsFixed(0)} km',
              onChanged: (v) => setState(() => _annualKmAllowance = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            _TcoSlider(
              label: 'Estimated annual km driven',
              value: _estimatedAnnualKm,
              min: 5000,
              max: 60000,
              step: 1000,
              display: '${_estimatedAnnualKm.toStringAsFixed(0)} km',
              onChanged: (v) => setState(() => _estimatedAnnualKm = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            _TcoSlider(
              label: 'Overage fee (¢/km)',
              value: _overageFeeCentsPerKm,
              min: 8,
              max: 25,
              step: 1,
              display:
                  'C\$${(_overageFeeCentsPerKm / 100).toStringAsFixed(2)}/km',
              onChanged: (v) => setState(() => _overageFeeCentsPerKm = v),
            ),
            const SizedBox(height: AppSpacing.md),
            Builder(
              builder: (ctx) {
                final leaseYears = _leaseTerm / 12;
                final overagePerYear = (_estimatedAnnualKm - _annualKmAllowance)
                    .clamp(0.0, double.infinity);
                final feePerKm = _overageFeeCentsPerKm / 100;
                final totalOverageKm = overagePerYear * leaseYears;
                final totalOverageCost = totalOverageKm * feePerKm;
                final monthlyOverageCost = totalOverageCost / _leaseTerm;

                if (overagePerYear <= 0) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'No overage — estimated km within allowance.',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimated overage: ${overagePerYear.toStringAsFixed(0)} km/year',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Projected overage cost over lease: ${AmountFormatter.ui(totalOverageCost, 'CAD')}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                ),
                          ),
                          Text(
                            'Monthly cost of overage: ${AmountFormatter.ui(monthlyOverageCost, 'CAD')}/mo',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Consider increasing your km allowance or choosing a different plan.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ],
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final CALeaseCalculation lease;
  final double buyMonthly;
  final int buyTermMonths;
  final int leaseTermMonths;

  const _ComparisonCard({
    required this.lease,
    required this.buyMonthly,
    required this.buyTermMonths,
    required this.leaseTermMonths,
  });

  @override
  Widget build(BuildContext context) {
    // Buy total cost over the same lease term (partial buy)
    final buyTotalOverLeaseTerm = buyMonthly * leaseTermMonths;
    final diff = lease.totalLeaseCost - buyTotalOverLeaseTerm;
    final leaseWins = diff < 0;
    final absDiff = diff.abs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ComparisonColumn(
                  label: 'Lease ($leaseTermMonths mo)',
                  monthly: AmountFormatter.ui(lease.monthlyLease, 'CAD'),
                  total: AmountFormatter.ui(lease.totalLeaseCost, 'CAD'),
                  highlight: leaseWins,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ComparisonColumn(
                  label: 'Buy ($buyTermMonths mo)',
                  monthly: AmountFormatter.ui(buyMonthly, 'CAD'),
                  total: AmountFormatter.ui(buyTotalOverLeaseTerm, 'CAD'),
                  highlight: !leaseWins,
                  footnote: 'over $leaseTermMonths mo',
                ),
              ),
            ],
          ),
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
                ? 'Lease saves ${AmountFormatter.ui(absDiff, 'CAD')} over $leaseTermMonths months'
                : 'Buy saves ${AmountFormatter.ui(absDiff, 'CAD')} over $leaseTermMonths months',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Residual: ${AmountFormatter.ui(lease.residualValue, 'CAD')} · '
          'Money factor: ${lease.moneyFactor.toStringAsFixed(5)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ComparisonColumn extends StatelessWidget {
  final String label;
  final String monthly;
  final String total;
  final bool highlight;
  final String? footnote;

  const _ComparisonColumn({
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

// ── CA Total Cost of Ownership ─────────────────────────────────────────────────

class _CATcoSection extends StatefulWidget {
  final CAProvider p;
  const _CATcoSection({required this.p});

  @override
  State<_CATcoSection> createState() => _CATcoSectionState();
}

class _CATcoSectionState extends State<_CATcoSection> {
  bool _expanded = false;

  double _annualKm = 20000;
  double _fuelPer100km = 10.0;
  double _fuelPrice = 1.65;
  double _annualInsurance = 1800;
  double _annualMaint = 800;

  CATcoCalculation? _tco;

  void _calculate() {
    final r = widget.p.result!;
    setState(() {
      _tco = CATcoCalculation.calculate(
        annualKm: _annualKm,
        fuelPer100km: _fuelPer100km,
        fuelPricePerL: _fuelPrice,
        annualInsurance: _annualInsurance,
        annualMaintenance: _annualMaint,
        termMonths: r.termMonths,
        totalInterest: r.totalInterest,
        vehiclePrice: r.vehiclePrice,
        downPayment: r.downPayment,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.p.result!;
    final termYears = r.termMonths ~/ 12;

    return SectionCard(
      title: AppLocalizations.of(context)!.totalCostOfOwnership,
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
          _TcoSlider(
            label: 'Annual km driven',
            value: _annualKm,
            min: 5000,
            max: 50000,
            step: 1000,
            display: '${_annualKm.toStringAsFixed(0)} km',
            onChanged: (v) => setState(() => _annualKm = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _TcoSlider(
            label: 'Fuel consumption (L/100km)',
            value: _fuelPer100km,
            min: 4,
            max: 20,
            step: 0.5,
            display: '${_fuelPer100km.toStringAsFixed(1)} L/100km',
            onChanged: (v) => setState(() => _fuelPer100km = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _TcoSlider(
            label: 'Fuel price (C\$/L)',
            value: _fuelPrice,
            min: 1.00,
            max: 2.50,
            step: 0.05,
            display: AmountFormatter.ui(_fuelPrice, 'CAD'),
            onChanged: (v) => setState(() => _fuelPrice = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _TcoSlider(
            label: 'Annual insurance (C\$)',
            value: _annualInsurance,
            min: 600,
            max: 5000,
            step: 100,
            display: AmountFormatter.formatInteger(_annualInsurance),
            onChanged: (v) => setState(() => _annualInsurance = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _TcoSlider(
            label: 'Annual maintenance (C\$)',
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
            ResultTile(label: 'Total fuel', value: AmountFormatter.formatInteger(_tco!.totalFuel)),
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
              label: 'True cost of ownership over $termYears years',
              value: AmountFormatter.formatInteger(_tco!.grandTotal),
              isHighlight: true,
            ),
          ],
        ],
      ],
    );
  }
}

class _TcoSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final String display;
  final ValueChanged<double> onChanged;

  const _TcoSlider({
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

// ── CA Trade-In Value Calculator ───────────────────────────────────────────────

class _CATradeInSection extends StatefulWidget {
  final CAProvider p;
  const _CATradeInSection({required this.p});

  @override
  State<_CATradeInSection> createState() => _CATradeInSectionState();
}

class _CATradeInSectionState extends State<_CATradeInSection> {
  bool _expanded = false;
  double _tradeInValue = 0;
  double _remaining = 0;

  CATradeInResult? _result;

  void _compute() {
    final p = widget.p;
    final province = caProvinceByCode(p.provinceCode);
    final taxAmount = p.vehiclePrice * province.totalRate;
    final priceWithTax = p.vehiclePrice + taxAmount;

    final netTradeIn = _tradeInValue - _remaining;
    final effectiveDownPayment = p.dpAmount + netTradeIn;
    final adjustedLoan = (priceWithTax - effectiveDownPayment).clamp(
      0.0,
      double.infinity,
    );

    setState(() {
      _result = CATradeInResult(
        netTradeIn: netTradeIn,
        effectiveDownPayment: effectiveDownPayment,
        adjustedLoanAmount: adjustedLoan,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: AppLocalizations.of(context)!.tradeInValue,
      children: [
        Row(
          children: [
            Switch(
              value: _expanded,
              onChanged: (v) => setState(() => _expanded = v),
            ),
            const Expanded(child: Text('Show Trade-In Calculator')),
          ],
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.md),
          CurrencySliderInput(
            label: 'Trade-in value',
            value: _tradeInValue,
            min: 0,
            max: 30000,
            step: 500,
            symbol: 'C\$',
            onChanged: (v) => setState(() => _tradeInValue = v),
          ),
          const SizedBox(height: AppSpacing.md),
          CurrencySliderInput(
            label: 'Remaining balance on current loan',
            value: _remaining,
            min: 0,
            max: 30000,
            step: 500,
            symbol: 'C\$',
            onChanged: (v) => setState(() => _remaining = v),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              _compute();
            },
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calculate Trade-In'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            // Equity / negative equity message
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _result!.netTradeIn >= 0
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                _result!.netTradeIn >= 0
                    ? 'Equity of ${AmountFormatter.formatInteger(_result!.netTradeIn)} applied to down payment'
                    : 'Negative equity of ${AmountFormatter.formatInteger(_result!.netTradeIn.abs())} added to loan',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _result!.netTradeIn >= 0
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ResultTile(
              label: 'Net trade-in',
              value: AmountFormatter.formatInteger(_result!.netTradeIn),
            ),
            ResultTile(
              label: 'Effective down payment',
              value: AmountFormatter.formatInteger(_result!.effectiveDownPayment),
            ),
            ResultTile(
              label: 'Adjusted loan amount',
              value: AmountFormatter.formatInteger(_result!.adjustedLoanAmount),
              isHighlight: true,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                final dp = _result!.effectiveDownPayment.clamp(
                  0.0,
                  double.infinity,
                );
                widget.p.setDpIsPercent(false);
                widget.p.setDownPayment(dp);
                setState(() => _expanded = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Down payment updated to ${AmountFormatter.formatInteger(dp)}'),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Apply to Calculator'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

// ── CA Affordability Guide ─────────────────────────────────────────────────────

class _CAAffordabilitySection extends StatefulWidget {
  final CAProvider p;
  const _CAAffordabilitySection({required this.p});

  @override
  State<_CAAffordabilitySection> createState() =>
      _CAAffordabilitySectionState();
}

class _CAAffordabilitySectionState extends State<_CAAffordabilitySection> {
  bool _expanded = false;
  double _monthlyIncome = 5000;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final maxRecommended = _monthlyIncome * 0.15;
    final maxVehicle = maxAffordablePrice(
      monthlyIncome: _monthlyIncome,
      annualRate: p.annualRate,
      termMonths: p.termMonths,
      downPayment: p.dpAmount,
    );

    // Traffic-light: compare actual monthly payment vs income
    final CACalculation? r = p.result;
    Color? _trafficColor;
    String _trafficLabel = '';
    if (r != null) {
      final ratio = r.monthlyPayment / _monthlyIncome;
      if (ratio < 0.12) {
        _trafficColor = CalcwiseTheme.of(context).successGreen;
        _trafficLabel = 'Comfortable (< 12% of income)';
      } else if (ratio <= 0.18) {
        _trafficColor = CalcwiseTheme.of(context).warningOrange;
        _trafficLabel = 'Moderate (12–18% of income)';
      } else {
        _trafficColor = CalcwiseTheme.of(context).errorRed;
        _trafficLabel = 'Over budget (> 18% of income)';
      }
    }

    return SectionCard(
      title: AppLocalizations.of(context)!.affordabilityGuide,
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
          // Income slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text('Gross monthly income', overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
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
                value: _monthlyIncome.clamp(2000, 20000),
                min: 2000,
                max: 20000,
                divisions: ((20000 - 2000) / 500).round(),
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
                    AmountFormatter.formatInteger(20000),
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
            value: '${AmountFormatter.ui(maxRecommended, 'CAD')}/mo',
          ),
          ResultTile(
            label: 'Max affordable vehicle (at current rate/term)',
            value: AmountFormatter.formatInteger(maxVehicle),
            isHighlight: true,
          ),
          if (r != null) ...[
            const SizedBox(height: AppSpacing.md),
            // Traffic-light indicator
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
                    'Your payment ${AmountFormatter.ui(r.monthlyPayment, 'CAD')}/mo — $_trafficLabel',
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

// ── Premium Tool Card ─────────────────────────────────────────────────────────
// Premium-gated tool card with gradient banner (locked) or clean card (unlocked).
// Locked: gradient bg, lock icon, tool name, description, chevron → PaywallSoft.
// Unlocked: tool icon, tool name, description, chevron → navigates to tool.

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
