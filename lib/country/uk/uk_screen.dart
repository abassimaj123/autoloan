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
import 'uk_provider.dart';
import 'uk_logic.dart';

class UKScreen extends StatefulWidget {
  const UKScreen({super.key});

  @override
  State<UKScreen> createState() => _UKScreenState();
}

class _UKScreenState extends State<UKScreen> {
  Timer? _debounce;

  bool _validated = false;
  int _selectedTab = 0;
  int _historyRefreshKey = 0;
  bool _wasPremium = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView('uk');
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
    }
    _wasPremium = now;
  }

  Future<void> _onNavTap(int i) async {
    if (i == _selectedTab) return;
    if (i == 1) {
      AnalyticsService.instance.logTabChanged('compare');
      AnalyticsService.instance.logCompareUsed('uk');
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
      final p = context.read<UKProvider>();
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
        title: Text(l10n.appNameUK),
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
                      const SettingsScreen(flavor: 'uk'),
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
                  _UKCalculatorTab(
                    validated: _validated,
                    onCalculate: _debouncedCalculate,
                    adService: adService,
                  ),
                  // Tab 1: Compare
                  CompareScreen(flavor: 'uk', showAppBar: false),
                  // Tab 2: Lease vs Buy
                  const LeaseVsBuyScreen(flavor: 'uk', showAppBar: false),
                  // Tab 3: History (always last)
                  HistoryScreen(
                    key: ValueKey(_historyRefreshKey),
                    country: 'uk',
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

// ── UK Calculator Tab ──────────────────────────────────────────────────────────

class _UKCalculatorTab extends StatelessWidget {
  final bool validated;
  final VoidCallback onCalculate;
  final CalcwiseAdService adService;

  const _UKCalculatorTab({
    required this.validated,
    required this.onCalculate,
    required this.adService,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UKProvider>(
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
                                  child: _UKResults(p: p, adService: adService),
                                ),
                                CalcwiseStaggerItem(
                                  index: 1,
                                  child: SaveScenarioButton(
                                    onSave: (label) => context
                                        .read<UKProvider>()
                                        .saveScenario(label: label),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const CalcwiseEmptyState(
                            icon: Icons.directions_car_outlined,
                            title: 'No results yet',
                            body:
                                'Enter the vehicle price to see your analysis.',
                          ),
                        // ── Cost Breakdown Chart ─────────────────────────
                        if (p.result != null)
                          Builder(
                            builder: (context) {
                              final principal = p.result!.loanAmount;
                              final interest = p.result!.totalInterest;
                              final cs = Theme.of(context).colorScheme;
                              return SectionCard(
                                title: 'Cost Breakdown',
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
                        // ── Input sections ────────────────────────────────
                        _UKVehicleSection(
                          p: p,
                          validated: validated,
                          onCalculate: onCalculate,
                        ),
                        _UKLoanTermsSection(
                          p: p,
                          validated: validated,
                          onCalculate: onCalculate,
                        ),
                        _UKFinancingTypeSection(p: p, onCalculate: onCalculate),
                        _UKRoadTaxSection(p: p, onCalculate: onCalculate),
                        // ── Quick Tools (visible immediately after inputs) ──
                        _UKQuickToolsSection(p: p),
                        // ── Extra sections ────────────────────────────────
                        if (p.result != null &&
                            p.financingType == UKFinancingType.pcp)
                          _UKPcpHpSection(p: p),
                        if (p.result != null) _UKCostOfCreditSection(p: p),
                        if (p.result != null) _UKEarlySettlementSection(p: p),
                        if (p.result != null) _UKTcoSection(p: p),
                        if (p.result != null) _UKHpVsPcpSection(p: p),
                        _UKAffordabilitySection(p: p),
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

// ── UK Vehicle Section ─────────────────────────────────────────────────────────

class _UKVehicleSection extends StatelessWidget {
  final UKProvider p;
  final bool validated;
  final VoidCallback onCalculate;

  const _UKVehicleSection({
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
          label: '${l10n.vehiclePrice} (VAT incl.)',
          value: p.vehiclePrice,
          symbol: '£',
          onChanged: (v) {
            p.setVehiclePrice(v);
            onCalculate();
          },
          helperText: 'e.g. 25 000',
          errorText: validated && p.vehiclePrice <= 0 ? 'Required' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        CurrencySliderInput(
          label: l10n.downPayment,
          value: p.downPayment,
          min: 0,
          max: p.vehiclePrice * 0.9,
          step: 500,
          symbol: '£',
          onChanged: (v) {
            p.setDownPayment(v);
            onCalculate();
          },
        ),
        if (p.result != null) ...[
          const SizedBox(height: AppSpacing.sm),
          ResultTile(
            label: l10n.loanAmount,
            value: AmountFormatter.ui(p.result!.loanAmount, 'GBP'),
          ),
        ],
      ],
    );
  }
}

// ── UK Loan Terms Section ──────────────────────────────────────────────────────

class _UKLoanTermsSection extends StatelessWidget {
  final UKProvider p;
  final bool validated;
  final VoidCallback onCalculate;

  const _UKLoanTermsSection({
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
          label: '${l10n.annualRate} (APR)',
          value: p.annualRate,
          helperText: 'Default rate as of 2026 — update to your actual rate',
          onChanged: (v) {
            p.setAnnualRate(v);
            onCalculate();
          },
          errorText: validated && p.annualRate <= 0 ? 'Required' : null,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Representative APR. Actual rate depends on your credit status (FCA CONC).',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
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

// ── UK Financing Type Section ──────────────────────────────────────────────────

class _UKFinancingTypeSection extends StatelessWidget {
  final UKProvider p;
  final VoidCallback onCalculate;

  const _UKFinancingTypeSection({required this.p, required this.onCalculate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ft = p.financingType;
    return SectionCard(
      title: l10n.financingType,
      children: [
        // Three-way toggle: Standard Loan | HP | PCP
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: ft == UKFinancingType.standardLoan
                      ? Theme.of(context).colorScheme.secondary
                      : null,
                  foregroundColor: ft == UKFinancingType.standardLoan
                      ? Theme.of(context).colorScheme.onSecondary
                      : null,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                onPressed: () {
                  p.setFinancingType(UKFinancingType.standardLoan);
                  onCalculate();
                },
                child: Text(l10n.standardLoan, textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: ft == UKFinancingType.hp
                      ? Theme.of(context).colorScheme.secondary
                      : null,
                  foregroundColor: ft == UKFinancingType.hp
                      ? Theme.of(context).colorScheme.onSecondary
                      : null,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                onPressed: () {
                  p.setFinancingType(UKFinancingType.hp);
                  onCalculate();
                },
                child: const Text('HP', textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: ft == UKFinancingType.pcp
                      ? Theme.of(context).colorScheme.secondary
                      : null,
                  foregroundColor: ft == UKFinancingType.pcp
                      ? Theme.of(context).colorScheme.onSecondary
                      : null,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                onPressed: () {
                  p.setFinancingType(UKFinancingType.pcp);
                  onCalculate();
                },
                child: Text(l10n.pcp, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
        // HP description
        if (ft == UKFinancingType.hp) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              'HP (Hire Purchase): Fixed monthly payments — you own the car outright at the end. '
              'No balloon payment, no mileage restrictions.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
        // PCP — GMFV inputs
        if (ft == UKFinancingType.pcp) ...[
          const SizedBox(height: AppSpacing.md),
          PercentSliderInput(
            label: l10n.gmfvPercent,
            value: p.gmfvPercent,
            min: 10,
            max: 60,
            step: 1,
            onChanged: (v) {
              p.setGmfvPercent(v);
              onCalculate();
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${l10n.gmfv}: £${(p.vehiclePrice * p.gmfvPercent / 100).toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.pcpNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

// ── UK Road Tax (VED) Section ──────────────────────────────────────────────────

class _UKRoadTaxSection extends StatelessWidget {
  final UKProvider p;
  final VoidCallback onCalculate;

  const _UKRoadTaxSection({required this.p, required this.onCalculate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SectionCard(
      title: l10n.roadTax,
      children: [
        Row(
          children: [
            Switch(
              value: p.includeRoadTax,
              onChanged: (v) {
                p.setIncludeRoadTax(v);
                onCalculate();
              },
            ),
            Expanded(
              child: Text(
                l10n.includeRoadTax,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        if (p.includeRoadTax) ...[
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<VehicleType>(
            // ignore: deprecated_member_use
            value: p.vehicleType,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.vehicleType,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
            ),
            items: VehicleType.values
                .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                p.setVehicleType(v);
                onCalculate();
              }
            },
          ),
          if (p.vehicleType == VehicleType.custom) ...[
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              initialValue: p.customVedAnnual.toStringAsFixed(0),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Custom annual VED (£)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                prefixText: '£ ',
              ),
              onChanged: (v) {
                final val = double.tryParse(v);
                if (val != null && val >= 0) {
                  p.setCustomVedAnnual(val);
                  onCalculate();
                }
              },
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            () {
              final annual = p.vehicleType == VehicleType.custom
                  ? p.customVedAnnual
                  : p.vehicleType.vedAnnual;
              return 'Annual VED: £${annual.toStringAsFixed(0)}  ·  Monthly: £${(annual / 12).toStringAsFixed(2)}';
            }(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          // ── CO2 Advanced Mode ──────────────────────────────────────
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Advanced: CO2-Based VED (post-2017 cars)',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: p.co2GPerKm > 0 ? p.co2GPerKm.toStringAsFixed(0) : '',
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'CO2 emissions (g/km) — optional',
              hintText: 'Leave blank to use category rate',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              suffixText: 'g/km',
            ),
            onChanged: (v) {
              final val = double.tryParse(v) ?? 0.0;
              p.setCo2GPerKm(val);
              onCalculate();
            },
          ),
          if (p.co2GPerKm > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Year 1 VED (CO2-based): £${p.co2FirstYearVed!.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    'Year 2+ VED (standard): £${p.co2StandardVed!.toStringAsFixed(0)}/yr  ·  £${(p.co2StandardVed! / 12).toStringAsFixed(2)}/mo',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    'First year differs from ongoing rate — check with DVLA.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
        if (!p.includeRoadTax)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Tooltip(
              triggerMode: TooltipTriggerMode.tap,
              showDuration: const Duration(seconds: 6),
              preferBelow: true,
              message:
                  'VED Annual Rates\n'
                  'Electric:            £10\n'
                  'Petrol <1000cc:  £180\n'
                  'Diesel / Hybrid:  £190\n'
                  'Petrol >1000cc:  £280\n'
                  'Diesel surcharge: £590',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'VED annual rates',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── UK Quick Tools Section (Reverse Solve + Cash-Back) ────────────────────────

class _UKQuickToolsSection extends StatelessWidget {
  final UKProvider p;

  const _UKQuickToolsSection({required this.p});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        ReverseSolveCard(
          title: 'What vehicle price can I afford?',
          targetLabel: 'Target monthly payment',
          resultLabel: 'Max vehicle price',
          prefix: '£',
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
                    const CashbackVsLowAprScreen(flavor: 'uk'),
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
          label: 'True Cost of Ownership',
          description: 'Analyse the true total cost of your vehicle',
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => TotalCostScreen(
                flavor: 'uk',
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
          label: 'Compare 3 Finance Deals',
          description: 'Compare up to 3 finance offers side by side',
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) =>
                  const LoanComparisonScreen(flavor: 'uk'),
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

class _UKResults extends StatelessWidget {
  final UKProvider p;
  final CalcwiseAdService adService;
  const _UKResults({required this.p, required this.adService});

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
    UKCalculation r,
    bool hasFull,
  ) {
    return SectionCard(
      title: l10n.results,
      children: [
        // ── Hero monthly payment ──────────────────────────────────────────
        CalcwiseHeroCard(
          label: r.isPcp
              ? l10n.pcpPayment
              : p.financingType == UKFinancingType.hp
              ? 'HP ${paymentLabelFor(l10n, p.frequency)}'
              : paymentLabelFor(l10n, p.frequency),
          value: AmountFormatter.ui(r.displayPayment, 'GBP'),
          secondary: p.financingType == UKFinancingType.hp
              ? 'Hire Purchase — you own the car at end'
              : 'Principal & Interest',
          stats: [
            (label: l10n.totalInterest, value: AmountFormatter.ui(r.totalInterest, 'GBP')),
            (label: l10n.totalCost, value: AmountFormatter.ui(r.totalCost, 'GBP')),
          ],
        ),
        if (!p.frequency.isMonthly)
          ResultTile(
            label: '${l10n.monthlyPayment} (equiv.)',
            value: AmountFormatter.ui(r.monthlyPayment, 'GBP'),
          ),
        if (r.vedMonthly > 0) ...[
          ResultTile(
            label:
                '  ${l10n.roadTax} /${p.frequency.isWeekly ? "wk" : p.frequency.isBiWeekly ? "2wk" : "mo"}',
            value: AmountFormatter.ui(
              p.frequency.isWeekly
                  ? r.vedWeekly
                  : p.frequency.isBiWeekly
                  ? r.vedBiWeekly
                  : r.vedMonthly,
              'GBP',
            ),
          ),
          ResultTile(
            label: '  ${l10n.loanOnly}',
            value: AmountFormatter.ui(
              p.frequency.isWeekly
                  ? r.weeklyLoanPayment
                  : p.frequency.isBiWeekly
                  ? r.biWeeklyLoanPayment
                  : r.baseLoanPayment,
              'GBP',
            ),
          ),
        ],
        if (r.isPcp)
          ResultTile(
            label: l10n.pcpFinalPayment,
            value: AmountFormatter.ui(r.gmfvAmount, 'GBP'),
          ),
        ResultTile(label: l10n.loanAmount, value: AmountFormatter.ui(r.loanAmount, 'GBP')),
        const Divider(),
        // Cost breakdown — always visible
        ResultTile(label: l10n.financedAmount, value: AmountFormatter.ui(r.loanAmount, 'GBP')),
        ResultTile(
          label: l10n.totalInterest,
          value: AmountFormatter.ui(r.totalInterest, 'GBP'),
        ),
        if (r.vedTotal > 0)
          ResultTile(label: l10n.totalVed, value: AmountFormatter.ui(r.vedTotal, 'GBP')),
        ResultTile(label: l10n.downPayment, value: AmountFormatter.ui(r.downPayment, 'GBP')),
        const Divider(height: 8),
        ResultTile(
          label: l10n.totalCost,
          value: AmountFormatter.ui(r.totalCost, 'GBP'),
          isHighlight: true,
        ),
        if (r.isPcp)
          ResultTile(
            label: 'Total if buying at end',
            value: AmountFormatter.ui(r.pcpTotalIfBuy, 'GBP'),
          ),
        const SizedBox(height: AppSpacing.sm),
        // ── Smart Insights ────────────────────────────────────────────
        InsightCard(
          insights: InsightEngine.generate(
            vehiclePrice: r.vehiclePrice,
            loanAmount: r.loanAmount,
            annualRatePct: r.annualRate,
            termMonths: r.termMonths,
            monthlyPayment: r.baseLoanPayment,
            totalInterest: r.totalInterest,
            downPayment: r.downPayment,
            currencySymbol: '£',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () async {
            HapticFeedback.lightImpact();
            final payment = r.isPcp && p.frequency.isMonthly
                ? 'PCP payment: ${AmountFormatter.ui(r.monthlyPayment, 'GBP')}'
                : '${paymentLabelFor(l10n, p.frequency)}: ${AmountFormatter.ui(r.displayPayment, 'GBP')}';
            try {
              await Share.share(
                'Auto Loan UK\n'
                'Vehicle: ${AmountFormatter.ui(r.vehiclePrice, 'GBP')}  |  Down: ${AmountFormatter.ui(r.downPayment, 'GBP')}\n'
                'Loan: ${AmountFormatter.ui(r.loanAmount, 'GBP')}  |  Rate: ${r.annualRate.toStringAsFixed(2)}%  |  ${r.termMonths ~/ 12} yr\n'
                '$payment\n'
                'Total Interest: ${AmountFormatter.ui(r.totalInterest, 'GBP')}  |  Total Cost: ${AmountFormatter.ui(r.totalCost, 'GBP')}'
                '${r.vedTotal > 0 ? "\nRoad Tax (VED): ${AmountFormatter.ui(r.vedTotal, 'GBP')}" : ""}\n\n'
                '📄 Export the full PDF report in the app →',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Shared successfully'),
                    behavior: SnackBarBehavior.floating,
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
              AnalyticsService.instance.logAmortizationViewed('uk');
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
                        balloonAmount: r.isPcp ? r.gmfvAmount : 0,
                        insuranceMonthly: r.vedMonthly,
                        currencySymbol: '£',
                        title: 'Amortisation Schedule',
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
            label: const Text('Amortisation Schedule'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await PdfExportService.exportLoanPdf(
                  title: l10n.appNameUK,
                  currencySymbol: '£',
                  loanAmount: r.loanAmount,
                  annualRate: r.annualRate,
                  termMonths: r.termMonths,
                  downPayment: r.downPayment,
                  balloonAmount: r.isPcp ? r.gmfvAmount : 0,
                  insuranceMonthly: r.vedMonthly,
                  summary: [
                    MapEntry(
                      l10n.vehiclePrice,
                      AmountFormatter.ui(r.vehiclePrice, 'GBP'),
                    ),
                    MapEntry(
                      l10n.downPayment,
                      AmountFormatter.ui(r.downPayment, 'GBP'),
                    ),
                    MapEntry(
                      l10n.loanAmount,
                      AmountFormatter.ui(r.loanAmount, 'GBP'),
                    ),
                    MapEntry(
                      l10n.annualRate,
                      '${r.annualRate.toStringAsFixed(2)}%',
                    ),
                    MapEntry(l10n.termMonths, '${r.termMonths} mo'),
                    if (r.isPcp) ...[
                      MapEntry(l10n.financingType, l10n.pcp),
                      MapEntry(
                        l10n.gmfv,
                        AmountFormatter.ui(r.gmfvAmount, 'GBP'),
                      ),
                    ],
                    MapEntry(
                      r.isPcp ? l10n.pcpPayment : l10n.monthlyPayment,
                      AmountFormatter.ui(r.monthlyPayment, 'GBP'),
                    ),
                    if (p.frequency == PaymentFrequency.biWeekly)
                      MapEntry(
                        l10n.biWeeklyPayment,
                        AmountFormatter.ui(r.biWeeklyPayment, 'GBP'),
                      ),
                    if (p.frequency == PaymentFrequency.weekly)
                      MapEntry(
                        l10n.weeklyPayment,
                        AmountFormatter.ui(r.weeklyPayment, 'GBP'),
                      ),
                    if (r.vedMonthly > 0) ...[
                      MapEntry(
                        '${l10n.roadTax} /mo',
                        AmountFormatter.ui(r.vedMonthly, 'GBP'),
                      ),
                      MapEntry(
                        l10n.totalVed,
                        AmountFormatter.ui(r.vedTotal, 'GBP'),
                      ),
                    ],
                    if (r.isPcp) ...[
                      MapEntry(
                        l10n.pcpFinalPayment,
                        AmountFormatter.ui(r.gmfvAmount, 'GBP'),
                      ),
                      MapEntry(
                        'Total if buying at end',
                        AmountFormatter.ui(r.pcpTotalIfBuy, 'GBP'),
                      ),
                    ],
                  ],
                );
                AnalyticsService.instance.logPdfExported('uk');
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
                    loanAmount: r.loanAmount,
                    annualRate: r.annualRate,
                    termMonths: r.termMonths,
                    currencySymbol: '£',
                    flavor: 'uk',
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

// ── UK PCP vs HP Comparison ────────────────────────────────────────────────────

class _UKPcpHpSection extends StatelessWidget {
  final UKProvider p;
  const _UKPcpHpSection({required this.p});

  @override
  Widget build(BuildContext context) {
    final r = p.result!;

    // Compute HP equivalent with same vehicle price, down payment, rate, term
    final hp = UKCalculation.calculate(
      vehiclePrice: p.vehiclePrice,
      downPayment: p.downPayment,
      annualRate: p.annualRate,
      termMonths: p.termMonths,
      includeRoadTax: p.includeRoadTax,
      vehicleType: p.vehicleType,
      customVedAnnual: p.customVedAnnual,
      isPcp: false,
      frequency: p.frequency,
    );

    final pcpMonthly = r.displayPayment;
    final hpMonthly = hp.displayPayment;
    final pcpTotal = r.pcpTotalIfBuy; // total if buying at end
    final hpTotal = hp.totalCost;

    final pcpSavesPerMo = hpMonthly - pcpMonthly;
    final hpSavesTotal = pcpTotal - hpTotal;

    return SectionCard(
      title: 'PCP vs HP Comparison',
      children: [
        Row(
          children: [
            Expanded(
              child: _UKCompareCol(
                label: 'PCP',
                monthly: AmountFormatter.ui(pcpMonthly, 'GBP'),
                total: AmountFormatter.ui(pcpTotal, 'GBP'),
                footnote: 'incl. ${AmountFormatter.formatInteger(r.gmfvAmount)} balloon',
                highlight: pcpSavesPerMo > 0,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _UKCompareCol(
                label: 'HP',
                monthly: AmountFormatter.ui(hpMonthly, 'GBP'),
                total: AmountFormatter.ui(hpTotal, 'GBP'),
                footnote: 'full ownership',
                highlight: pcpSavesPerMo <= 0,
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
          child: Column(
            children: [
              if (pcpSavesPerMo > 0)
                Text(
                  'PCP saves ${AmountFormatter.ui(pcpSavesPerMo, 'GBP')}/mo during contract',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              if (hpSavesTotal > 0)
                Text(
                  'HP saves ${AmountFormatter.ui(hpSavesTotal, 'GBP')} total (if buying at end of PCP)',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              if (hpSavesTotal <= 0 && pcpSavesPerMo <= 0)
                Text(
                  'PCP total cost similar to HP for these inputs',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UKCompareCol extends StatelessWidget {
  final String label;
  final String monthly;
  final String total;
  final String footnote;
  final bool highlight;

  const _UKCompareCol({
    required this.label,
    required this.monthly,
    required this.total,
    required this.footnote,
    required this.highlight,
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
          Text(
            footnote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── UK Total Cost of Credit ────────────────────────────────────────────────────

class _UKCostOfCreditSection extends StatelessWidget {
  final UKProvider p;
  const _UKCostOfCreditSection({required this.p});

  @override
  Widget build(BuildContext context) {
    final r = p.result!;

    // Total amount payable = all monthly payments + balloon if PCP
    // Note: totalPayable uses monthly-equivalent base payments for display consistency.
    // Weekly/bi-weekly users' actual total may differ slightly.
    final totalPayable = r.isPcp
        ? r.baseLoanPayment * r.termMonths +
              r.gmfvAmount +
              r.downPayment +
              r.vedTotal
        : r.baseLoanPayment * r.termMonths + r.downPayment + r.vedTotal;
    final costOfCredit = totalPayable - p.vehiclePrice;

    // APR flat-rate warning: if rate looks like a flat rate (typically < 5%)
    final flatRateAprApprox = p.annualRate * 1.8;
    final looksLikeFlat = p.annualRate < 6.0;

    return SectionCard(
      title: 'Total Cost of Credit',
      children: [
        ResultTile(label: 'Vehicle price', value: AmountFormatter.ui(p.vehiclePrice, 'GBP')),
        ResultTile(
          label: r.isPcp
              ? 'Total amount payable (if buying)'
              : 'Total amount payable',
          value: AmountFormatter.ui(totalPayable, 'GBP'),
          isHighlight: true,
        ),
        ResultTile(label: 'Cost of credit', value: AmountFormatter.ui(costOfCredit, 'GBP')),
        if (r.vedTotal > 0)
          ResultTile(
            label: 'Includes VED (road tax)',
            value: AmountFormatter.ui(r.vedTotal, 'GBP'),
          ),
        if (r.isPcp) ...[
          ResultTile(
            label: 'Optional final balloon',
            value: AmountFormatter.ui(r.gmfvAmount, 'GBP'),
          ),
        ],
        if (looksLikeFlat) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.tertiary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'If this is a flat rate, your APR is approx '
                    '${flatRateAprApprox.toStringAsFixed(1)}% '
                    '(flat rate × 1.8). Confirm with your lender.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border(
              left: BorderSide(
                color: Theme.of(context).colorScheme.secondary
                    .withValues(alpha: 0.7),
                width: 3,
              ),
            ),
          ),
          child: Text(
            'FCA CONC 3.5.4 — Representative APR must be disclosed. '
            'For informational purposes only — not financial advice.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ── UK TCO Slider helper ───────────────────────────────────────────────────────

class _UKTcoSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final String display;
  final ValueChanged<double> onChanged;

  const _UKTcoSlider({
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

// ── UK Total Cost of Ownership ─────────────────────────────────────────────────

class _UKTcoSection extends StatefulWidget {
  final UKProvider p;
  const _UKTcoSection({required this.p});

  @override
  State<_UKTcoSection> createState() => _UKTcoSectionState();
}

class _UKTcoSectionState extends State<_UKTcoSection> {
  bool _expanded = false;

  double _annualMiles = 10000;
  double _mpg = 40.0;
  double _fuelPricePence = 148.0;
  double _annualInsurance = 800;
  double _annualMot = 80;

  UKTcoCalculation? _tco;

  void _calculate() {
    final r = widget.p.result!;
    setState(() {
      _tco = UKTcoCalculation.calculate(
        annualMiles: _annualMiles,
        mpg: _mpg,
        fuelPricePencePerLitre: _fuelPricePence,
        annualInsurance: _annualInsurance,
        annualMot: _annualMot,
        termMonths: r.termMonths,
        totalInterest: r.totalInterest,
        totalVed: r.vedTotal,
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
          _UKTcoSlider(
            label: 'Annual miles driven',
            value: _annualMiles,
            min: 2000,
            max: 30000,
            step: 1000,
            display: '${_annualMiles.toStringAsFixed(0)} mi',
            onChanged: (v) => setState(() => _annualMiles = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _UKTcoSlider(
            label: 'Fuel efficiency (MPG)',
            value: _mpg,
            min: 20,
            max: 80,
            step: 1,
            display: '${_mpg.toStringAsFixed(0)} mpg',
            onChanged: (v) => setState(() => _mpg = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _UKTcoSlider(
            label: 'Fuel price (p/litre)',
            value: _fuelPricePence,
            min: 100,
            max: 200,
            step: 1,
            display: '${_fuelPricePence.toStringAsFixed(0)}p/L',
            onChanged: (v) => setState(() => _fuelPricePence = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _UKTcoSlider(
            label: 'Annual insurance (£)',
            value: _annualInsurance,
            min: 300,
            max: 5000,
            step: 50,
            display: AmountFormatter.formatInteger(_annualInsurance),
            onChanged: (v) => setState(() => _annualInsurance = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _UKTcoSlider(
            label: 'Annual MOT & service (£)',
            value: _annualMot,
            min: 0,
            max: 500,
            step: 10,
            display: AmountFormatter.formatInteger(_annualMot),
            onChanged: (v) => setState(() => _annualMot = v),
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
              label: 'Total fuel',
              value: AmountFormatter.ui(_tco!.totalFuel, 'GBP'),
            ),
            ResultTile(
              label: 'Total insurance',
              value: AmountFormatter.ui(_tco!.totalInsurance, 'GBP'),
            ),
            ResultTile(
              label: 'Total MOT & service',
              value: AmountFormatter.ui(_tco!.totalMot, 'GBP'),
            ),
            if (_tco!.totalVed > 0)
              ResultTile(
                label: 'Total VED (road tax)',
                value: AmountFormatter.ui(_tco!.totalVed, 'GBP'),
              ),
            ResultTile(
              label: 'Total interest',
              value: AmountFormatter.ui(_tco!.totalInterest, 'GBP'),
            ),
            const Divider(height: 8),
            ResultTile(
              label: 'Grand total over $termYears years',
              value: AmountFormatter.ui(_tco!.grandTotal, 'GBP'),
              isHighlight: true,
            ),
          ],
        ],
      ],
    );
  }
}

// ── UK HP vs PCP Comparison ────────────────────────────────────────────────────

class _UKHpVsPcpSection extends StatefulWidget {
  final UKProvider p;
  const _UKHpVsPcpSection({required this.p});

  @override
  State<_UKHpVsPcpSection> createState() => _UKHpVsPcpSectionState();
}

class _UKHpVsPcpSectionState extends State<_UKHpVsPcpSection> {
  bool _expanded = false;
  double _gmfvPercent = 30.0;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;

    // HP calculation: standard loan (no GMFV)
    final hp = UKCalculation.calculate(
      vehiclePrice: p.vehiclePrice,
      downPayment: p.downPayment,
      annualRate: p.annualRate,
      termMonths: p.termMonths,
      includeRoadTax: p.includeRoadTax,
      vehicleType: p.vehicleType,
      customVedAnnual: p.customVedAnnual,
      isPcp: false,
      frequency: PaymentFrequency.monthly,
    );

    // PCP calculation with local GMFV slider
    final pcp = UKCalculation.calculate(
      vehiclePrice: p.vehiclePrice,
      downPayment: p.downPayment,
      annualRate: p.annualRate,
      termMonths: p.termMonths,
      includeRoadTax: p.includeRoadTax,
      vehicleType: p.vehicleType,
      customVedAnnual: p.customVedAnnual,
      isPcp: true,
      gmfvPercent: _gmfvPercent,
      frequency: PaymentFrequency.monthly,
    );

    final hpMonthly = hp.baseLoanPayment;
    final pcpMonthly = pcp.baseLoanPayment;
    final hpTotal = hp.totalCost;
    // PCP total: payments only (not GMFV), per spec
    final pcpPaymentsTotal = pcp.baseLoanPayment * pcp.termMonths.toDouble();
    final gmfvBalloon = pcp.gmfvAmount;

    final pcpSavesPerMo = hpMonthly - pcpMonthly;
    final hpSavesOverall = pcpPaymentsTotal + gmfvBalloon - hpTotal;

    return SectionCard(
      title: 'HP vs PCP Comparison',
      children: [
        Row(
          children: [
            Switch(
              value: _expanded,
              onChanged: (v) => setState(() => _expanded = v),
            ),
            const Expanded(
              child: Text('Compare Hire Purchase vs PCP side-by-side'),
            ),
          ],
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.md),
          // GMFV slider
          _UKTcoSlider(
            label: 'GMFV balloon (%)',
            value: _gmfvPercent,
            min: 10,
            max: 60,
            step: 1,
            display:
                '${_gmfvPercent.toStringAsFixed(0)}%  (${AmountFormatter.formatInteger(gmfvBalloon)})',
            onChanged: (v) => setState(() => _gmfvPercent = v),
          ),
          const SizedBox(height: AppSpacing.md),
          // Side-by-side cards
          Row(
            children: [
              Expanded(
                child: _UKFinanceCol(
                  label: 'HP',
                  monthly: AmountFormatter.ui(hpMonthly, 'GBP'),
                  totalLabel: 'Total cost',
                  total: AmountFormatter.ui(hpTotal, 'GBP'),
                  footnote: 'You own it outright',
                  highlight: pcpSavesPerMo <= 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _UKFinanceCol(
                  label: 'PCP',
                  monthly: AmountFormatter.ui(pcpMonthly, 'GBP'),
                  totalLabel: 'Payments total',
                  total: AmountFormatter.ui(pcpPaymentsTotal, 'GBP'),
                  footnote: '+ ${AmountFormatter.formatInteger(gmfvBalloon)} balloon',
                  highlight: pcpSavesPerMo > 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Verdict banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              children: [
                if (pcpSavesPerMo > 0) ...[
                  Text(
                    'PCP saves ${AmountFormatter.ui(pcpSavesPerMo, 'GBP')}/mo during contract',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'but ${AmountFormatter.formatInteger(gmfvBalloon)} balloon payment at end',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Text(
                    'HP: you own it outright — no balloon payment',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (hpSavesOverall > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'HP saves ${AmountFormatter.formatInteger(hpSavesOverall)} overall vs PCP if buying at end',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'PCP total excludes GMFV balloon. HP total = vehicle price + all interest.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _UKFinanceCol extends StatelessWidget {
  final String label;
  final String monthly;
  final String totalLabel;
  final String total;
  final String footnote;
  final bool highlight;

  const _UKFinanceCol({
    required this.label,
    required this.monthly,
    required this.totalLabel,
    required this.total,
    required this.footnote,
    required this.highlight,
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
            '$totalLabel: $total',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
          Text(
            footnote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── UK Early Settlement ────────────────────────────────────────────────────────

class _UKEarlySettlementSection extends StatefulWidget {
  final UKProvider p;
  const _UKEarlySettlementSection({required this.p});

  @override
  State<_UKEarlySettlementSection> createState() =>
      _UKEarlySettlementSectionState();
}

class _UKEarlySettlementSectionState extends State<_UKEarlySettlementSection> {
  bool _expanded = false;
  int _monthsPaid = 12;
  double? _settlement;
  double? _percentPaid;

  void _calculate() {
    final r = widget.p.result!;
    final N = r.termMonths;
    final n = N - _monthsPaid; // remaining payments
    if (n <= 0 || n > N) return;

    // Remaining principal (approximate via amortisation)
    // Use simple Rule of 78 as specified
    final totalInterest = r.totalInterest;
    final interestEarned =
        totalInterest *
        (_monthsPaid * (2 * N - _monthsPaid + 1)) /
        (N * (N + 1));
    final principalRepaid = r.baseLoanPayment * _monthsPaid - interestEarned;
    final remainingPrincipal = (r.loanAmount - principalRepaid).clamp(
      0.0,
      double.infinity,
    );

    // Rule of 78 settlement figure
    final settlementFigure =
        remainingPrincipal + (totalInterest * (n * (n + 1)) / (N * (N + 1)));

    final totalCostPaid = r.baseLoanPayment * _monthsPaid + widget.p.downPayment + (r.vedMonthly * _monthsPaid);
    final pctPaid = totalCostPaid / r.totalCost * 100;

    setState(() {
      _settlement = settlementFigure.clamp(0.0, double.infinity);
      _percentPaid = pctPaid.clamp(0.0, 100.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.p.result!;

    return SectionCard(
      title: 'Early Settlement',
      children: [
        Row(
          children: [
            Switch(
              value: _expanded,
              onChanged: (v) => setState(() => _expanded = v),
            ),
            const Expanded(child: Text('Calculate settlement figure')),
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
                  const Flexible(child: Text('Months already paid', overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Text(
                    '$_monthsPaid months',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _monthsPaid.toDouble(),
                min: 1,
                max: (r.termMonths - 1).toDouble(),
                divisions: r.termMonths - 2,
                onChanged: (v) => setState(() => _monthsPaid = v.round()),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              _calculate();
            },
            icon: const Icon(Icons.receipt_long_rounded),
            label: const Text('Calculate Settlement'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
          ),
          if (_settlement != null) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            ResultTile(
              label: 'Settlement figure (Rule of 78)',
              value: AmountFormatter.ui(_settlement!, 'GBP'),
              isHighlight: true,
            ),
            ResultTile(
              label: 'You\'ve paid',
              value: '${_percentPaid!.toStringAsFixed(1)}% of total cost',
            ),
            ResultTile(
              label: 'Months remaining',
              value: '${r.termMonths - _monthsPaid} months',
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Settlement is calculated using the Rule of 78 (sum of digits). '
              'Your lender may quote a slightly different figure.',
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

// ── UK Affordability Guide ─────────────────────────────────────────────────────

class _UKAffordabilitySection extends StatefulWidget {
  final UKProvider p;
  const _UKAffordabilitySection({required this.p});

  @override
  State<_UKAffordabilitySection> createState() =>
      _UKAffordabilitySectionState();
}

class _UKAffordabilitySectionState extends State<_UKAffordabilitySection> {
  bool _expanded = false;
  double _monthlyIncome = 3500;

  @override
  Widget build(BuildContext context) {
    final r = widget.p.result;

    // Traffic-light: UK thresholds — 15% / 20%
    Color? _trafficColor;
    String _trafficLabel = '';
    if (r != null) {
      final ratio = r.baseLoanPayment / _monthlyIncome;
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
                value: _monthlyIncome.clamp(1500, 15000),
                min: 1500,
                max: 15000,
                divisions: ((15000 - 1500) / 500).round(),
                onChanged: (v) =>
                    setState(() => _monthlyIncome = (v / 500).round() * 500),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AmountFormatter.formatInteger(1500),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    AmountFormatter.formatInteger(15000),
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
            value: '${AmountFormatter.ui(_monthlyIncome * 0.15, 'GBP')}/mo',
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
                    'Your payment ${AmountFormatter.ui(r.baseLoanPayment, 'GBP')}/mo — $_trafficLabel',
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

// Premium-gated tool card with gradient banner (locked) or clean card (unlocked).
// Locked: gradient bg, lock icon, tool name, description, chevron -> PaywallSoft.
// Unlocked: tool icon, tool name, description, chevron -> navigates to tool.

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
