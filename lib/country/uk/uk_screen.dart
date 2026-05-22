import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:calcwise_core/calcwise_core.dart' hide SectionCard, ResultTile;
import '../../l10n/app_localizations.dart';
import '../../widgets/shared_inputs.dart';
import '../../widgets/premium_gate.dart';
import '../../core/freemium/freemium_service.dart';
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
import '../../services/analytics_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/insight_engine.dart';
import '../../widgets/insight_card.dart';
import 'uk_provider.dart';
import 'uk_logic.dart';

class UKScreen extends StatefulWidget {
  const UKScreen({super.key});

  @override
  State<UKScreen> createState() => _UKScreenState();
}

class _UKScreenState extends State<UKScreen> {
  Timer? _debounce;
  Timer? _saveDebounce;
  bool _validated = false;
  int _selectedTab = 0;
  int _historyRefreshKey = 0;
  bool _wasPremium = false;

  @override
  void initState() {
    super.initState();
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
    _saveDebounce?.cancel();
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
      AnalyticsService.instance.logTabChanged('history');
    } else if (i == 3) {
      AnalyticsService.instance.logTabChanged('lease_vs_buy');
    }
    if (i > 0) {
      final trigger = await paywallSession.recordAction();
      if (!mounted) return;
      if (trigger == PaywallTrigger.hard) PaywallHard.show(context);
      else if (trigger == PaywallTrigger.soft) PaywallSoft.show(context);
      if (!mounted) return;
    }
    setState(() {
      _selectedTab = i;
      if (i == 2) _historyRefreshKey++;
    });
  }

  void _debouncedCalculate() {
    if (!_validated) setState(() => _validated = true);
    _debounce?.cancel();
    _debounce = Timer(AppDuration.page, () {
      if (mounted) context.read<UKProvider>().calculate();
    });
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) context.read<UKProvider>().saveSnapshot();
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
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history_rounded),
            label: l10n.history,
          ),
          const NavigationDestination(
            icon: Icon(Icons.balance_outlined),
            selectedIcon: Icon(Icons.balance_rounded),
            label: 'Lease vs Buy',
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
                _UKCalculatorTab(
                  validated: _validated,
                  onCalculate: _debouncedCalculate,
                  adService: adService,
                ),
                // Tab 1: Compare
                CompareScreen(flavor: 'uk', showAppBar: false),
                // Tab 2: History
                HistoryScreen(
                  key: ValueKey(_historyRefreshKey),
                  country: 'uk',
                  showAppBar: false,
                  onClear: () => setState(() => _historyRefreshKey++),
                ),
                // Tab 3: Lease vs Buy
                const LeaseVsBuyScreen(flavor: 'uk', showAppBar: false),
              ],
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
                              ],
                            ),
                          )
                        else
                          const CalcwiseEmptyState(
                            icon: Icons.directions_car_outlined,
                            title: 'No results yet',
                            body: 'Enter the vehicle price to see your analysis.',
                          ),
                        // ── Input sections ────────────────────────────────
                        _UKVehicleSection(p: p, validated: validated, onCalculate: onCalculate),
                        _UKLoanTermsSection(p: p, validated: validated, onCalculate: onCalculate),
                        _UKFinancingTypeSection(p: p, onCalculate: onCalculate),
                        _UKRoadTaxSection(p: p, onCalculate: onCalculate),
                        // ── Extra tools ───────────────────────────────────
                        if (p.result != null && p.isPcp) _UKPcpHpSection(p: p),
                        if (p.result != null) _UKCostOfCreditSection(p: p),
                        if (p.result != null) _UKEarlySettlementSection(p: p),
                        if (p.result != null) _UKTcoSection(p: p),
                        if (p.result != null) _UKHpVsPcpSection(p: p),
                        _UKAffordabilitySection(p: p),
                        _UKQuickToolsSection(p: p),
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
            value: NumberFormat.currency(symbol: '£', decimalDigits: 2).format(p.result!.loanAmount),
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
        Row(
          children: [
            Switch(
              value: p.isBiWeekly,
              onChanged: (v) {
                p.setIsBiWeekly(v);
                onCalculate();
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.biWeeklyToggle),
                  Text(
                    l10n.biWeeklySubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    return SectionCard(
      title: l10n.financingType,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: !p.isPcp
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
                onPressed: () {
                  p.setIsPcp(false);
                  onCalculate();
                },
                child: Text(l10n.standardLoan),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: p.isPcp
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
                onPressed: () {
                  p.setIsPcp(true);
                  onCalculate();
                },
                child: Text(l10n.pcp),
              ),
            ),
          ],
        ),
        if (p.isPcp) ...[
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
              child: Text(l10n.includeRoadTax, style: Theme.of(context).textTheme.bodyMedium),
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
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
        ],
        if (!p.includeRoadTax)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Tooltip(
              triggerMode: TooltipTriggerMode.tap,
              showDuration: const Duration(seconds: 6),
              preferBelow: true,
              message: 'VED Annual Rates\n'
                  'Electric:            £0\n'
                  'Petrol <1000cc:  £180\n'
                  'Diesel / Hybrid:  £190\n'
                  'Petrol >1000cc:  £280\n'
                  'Diesel surcharge: £590',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.primary),
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
                pageBuilder: (_, __, ___) => const CashbackVsLowAprScreen(flavor: 'uk'),
                transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                transitionDuration: AppDuration.base,
              ),
            );
          },
          icon: const Icon(Icons.local_offer_rounded),
          label: const Text('Cash-Back vs Low-APR'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
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
    final fmt = NumberFormat.currency(symbol: '£', decimalDigits: 2);

    return ListenableBuilder(
      listenable: Listenable.merge([
        freemiumService.isPremiumNotifier,
        freemiumService.isRewardedNotifier,
      ]),
      builder: (context, _) {
        final hasFull =
            freemiumService.hasFullAccess || freemiumService.isRewarded;
        return _buildCard(context, l10n, r, fmt, hasFull);
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    AppLocalizations l10n,
    UKCalculation r,
    NumberFormat fmt,
    bool hasFull,
  ) {
    return SectionCard(
      title: l10n.results,
      children: [
        // ── Hero monthly payment ──────────────────────────────────────────
        CalcwiseHeroCard(
          label: p.isBiWeekly
              ? (r.isPcp ? l10n.pcpPayment : l10n.biWeeklyPayment)
              : (r.isPcp ? l10n.pcpPayment : l10n.monthlyPayment),
          value: fmt.format(r.displayPayment),
          secondary: 'Principal & Interest',
          stats: [
            (label: l10n.totalInterest, value: fmt.format(r.totalInterest)),
            (label: l10n.totalCost, value: fmt.format(r.totalCost)),
          ],
        ),
        if (p.isBiWeekly)
          ResultTile(
            label: '${l10n.monthlyPayment} (equiv.)',
            value: fmt.format(r.monthlyPayment),
          ),
        if (r.vedMonthly > 0) ...[
          ResultTile(
            label: '  ${l10n.roadTax} /${p.isBiWeekly ? "2wk" : "mo"}',
            value: fmt.format(p.isBiWeekly ? r.vedBiWeekly : r.vedMonthly),
          ),
          ResultTile(
            label: '  ${l10n.loanOnly}',
            value: fmt.format(
              p.isBiWeekly ? r.biWeeklyLoanPayment : r.baseLoanPayment,
            ),
          ),
        ],
        if (r.isPcp)
          ResultTile(
            label: l10n.pcpFinalPayment,
            value: fmt.format(r.gmfvAmount),
          ),
        ResultTile(label: l10n.loanAmount, value: fmt.format(r.loanAmount)),
        const Divider(),
        // Cost breakdown — always visible
        ResultTile(label: l10n.financedAmount, value: fmt.format(r.loanAmount)),
        ResultTile(
          label: l10n.totalInterest,
          value: fmt.format(r.totalInterest),
        ),
        if (r.vedTotal > 0)
          ResultTile(label: l10n.totalVed, value: fmt.format(r.vedTotal)),
        ResultTile(label: l10n.downPayment, value: fmt.format(r.downPayment)),
        const Divider(height: 8),
        ResultTile(
          label: l10n.totalCost,
          value: fmt.format(r.totalCost),
          isHighlight: true,
        ),
        if (r.isPcp)
          ResultTile(
            label: 'Total if buying at end',
            value: fmt.format(r.pcpTotalIfBuy),
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
            final payment = p.isBiWeekly
                ? 'Bi-weekly: ${fmt.format(r.biWeeklyPayment)}'
                : '${r.isPcp ? "PCP payment" : "Monthly"}: ${fmt.format(r.monthlyPayment)}';
            try {
              await Share.share(
                'Auto Loan UK\n'
                'Vehicle: ${fmt.format(r.vehiclePrice)}  |  Down: ${fmt.format(r.downPayment)}\n'
                'Loan: ${fmt.format(r.loanAmount)}  |  Rate: ${r.annualRate.toStringAsFixed(2)}%  |  ${r.termMonths ~/ 12} yr\n'
                '$payment\n'
                'Total Interest: ${fmt.format(r.totalInterest)}  |  Total Cost: ${fmt.format(r.totalCost)}'
                '${r.vedTotal > 0 ? "\nRoad Tax (VED): ${fmt.format(r.vedTotal)}" : ""}',
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
          label: const Text('Share'),
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
                      '£${r.vehiclePrice.toStringAsFixed(2)}',
                    ),
                    MapEntry(
                      l10n.downPayment,
                      '£${r.downPayment.toStringAsFixed(2)}',
                    ),
                    MapEntry(
                      l10n.loanAmount,
                      '£${r.loanAmount.toStringAsFixed(2)}',
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
                        '£${r.gmfvAmount.toStringAsFixed(2)}',
                      ),
                    ],
                    MapEntry(
                      r.isPcp ? l10n.pcpPayment : l10n.monthlyPayment,
                      '£${r.monthlyPayment.toStringAsFixed(2)}',
                    ),
                    if (p.isBiWeekly)
                      MapEntry(
                        l10n.biWeeklyPayment,
                        '£${r.biWeeklyPayment.toStringAsFixed(2)}',
                      ),
                    if (r.vedMonthly > 0) ...[
                      MapEntry(
                        '${l10n.roadTax} /mo',
                        '£${r.vedMonthly.toStringAsFixed(2)}',
                      ),
                      MapEntry(
                        l10n.totalVed,
                        '£${r.vedTotal.toStringAsFixed(2)}',
                      ),
                    ],
                    if (r.isPcp) ...[
                      MapEntry(
                        l10n.pcpFinalPayment,
                        '£${r.gmfvAmount.toStringAsFixed(2)}',
                      ),
                      MapEntry(
                        'Total if buying at end',
                        '£${r.pcpTotalIfBuy.toStringAsFixed(2)}',
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
            label: const Text('Export PDF'),
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
            label: const Text('Early Payoff'),
          ),
        ] else ...[
          PremiumGate(adService: adService, flavor: 'uk'),
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
    final fmt = NumberFormat.currency(symbol: '£', decimalDigits: 2);
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
      isBiWeekly: p.isBiWeekly,
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
                monthly: fmt.format(pcpMonthly),
                total: fmt.format(pcpTotal),
                footnote: 'incl. £${r.gmfvAmount.toStringAsFixed(0)} balloon',
                highlight: pcpSavesPerMo > 0,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _UKCompareCol(
                label: 'HP',
                monthly: fmt.format(hpMonthly),
                total: fmt.format(hpTotal),
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
                  'PCP saves ${fmt.format(pcpSavesPerMo)}/mo during contract',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              if (hpSavesTotal > 0)
                Text(
                  'HP saves ${fmt.format(hpSavesTotal)} total (if buying at end of PCP)',
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
    final fmt = NumberFormat.currency(symbol: '£', decimalDigits: 2);
    final r = p.result!;

    // Total amount payable = all monthly payments + balloon if PCP
    final totalPayable = r.isPcp
        ? r.baseLoanPayment * r.termMonths +
              r.gmfvAmount +
              r.downPayment +
              r.vedTotal
        : r.monthlyPayment * r.termMonths + r.downPayment;
    final costOfCredit = totalPayable - p.vehiclePrice;

    // APR flat-rate warning: if rate looks like a flat rate (typically < 5%)
    final flatRateAprApprox = p.annualRate * 1.8;
    final looksLikeFlat = p.annualRate < 6.0;

    return SectionCard(
      title: 'Total Cost of Credit',
      children: [
        ResultTile(label: 'Vehicle price', value: fmt.format(p.vehiclePrice)),
        ResultTile(
          label: r.isPcp
              ? 'Total amount payable (if buying)'
              : 'Total amount payable',
          value: fmt.format(totalPayable),
          isHighlight: true,
        ),
        ResultTile(label: 'Cost of credit', value: fmt.format(costOfCredit)),
        if (r.vedTotal > 0)
          ResultTile(
            label: 'Includes VED (road tax)',
            value: fmt.format(r.vedTotal),
          ),
        if (r.isPcp) ...[
          ResultTile(
            label: 'Optional final balloon',
            value: fmt.format(r.gmfvAmount),
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
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border(
              left: BorderSide(
                color: AppTheme.accent.withValues(alpha: 0.7),
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
    final fmt = NumberFormat.currency(symbol: '£', decimalDigits: 0);
    final fmt2 = NumberFormat.currency(symbol: '£', decimalDigits: 2);
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
            display: fmt.format(_annualInsurance),
            onChanged: (v) => setState(() => _annualInsurance = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _UKTcoSlider(
            label: 'Annual MOT & service (£)',
            value: _annualMot,
            min: 0,
            max: 500,
            step: 10,
            display: fmt.format(_annualMot),
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
              value: fmt2.format(_tco!.totalFuel),
            ),
            ResultTile(
              label: 'Total insurance',
              value: fmt2.format(_tco!.totalInsurance),
            ),
            ResultTile(
              label: 'Total MOT & service',
              value: fmt2.format(_tco!.totalMot),
            ),
            if (_tco!.totalVed > 0)
              ResultTile(
                label: 'Total VED (road tax)',
                value: fmt2.format(_tco!.totalVed),
              ),
            ResultTile(
              label: 'Total interest',
              value: fmt2.format(_tco!.totalInterest),
            ),
            const Divider(height: 8),
            ResultTile(
              label: 'Grand total over $termYears years',
              value: fmt2.format(_tco!.grandTotal),
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
    final fmt = NumberFormat.currency(symbol: '£', decimalDigits: 2);
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
      isBiWeekly: false,
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
      isBiWeekly: false,
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
                '${_gmfvPercent.toStringAsFixed(0)}%  (£${gmfvBalloon.toStringAsFixed(0)})',
            onChanged: (v) => setState(() => _gmfvPercent = v),
          ),
          const SizedBox(height: AppSpacing.md),
          // Side-by-side cards
          Row(
            children: [
              Expanded(
                child: _UKFinanceCol(
                  label: 'HP',
                  monthly: fmt.format(hpMonthly),
                  totalLabel: 'Total cost',
                  total: fmt.format(hpTotal),
                  footnote: 'You own it outright',
                  highlight: pcpSavesPerMo <= 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _UKFinanceCol(
                  label: 'PCP',
                  monthly: fmt.format(pcpMonthly),
                  totalLabel: 'Payments total',
                  total: fmt.format(pcpPaymentsTotal),
                  footnote: '+ £${gmfvBalloon.toStringAsFixed(0)} balloon',
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
                    'PCP saves ${fmt.format(pcpSavesPerMo)}/mo during contract',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'but £${gmfvBalloon.toStringAsFixed(0)} balloon payment at end',
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
                    'HP saves £${hpSavesOverall.toStringAsFixed(0)} overall vs PCP if buying at end',
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

    final totalCostPaid = r.displayPayment * _monthsPaid + widget.p.downPayment;
    final pctPaid = totalCostPaid / r.totalCost * 100;

    setState(() {
      _settlement = settlementFigure.clamp(0.0, double.infinity);
      _percentPaid = pctPaid.clamp(0.0, 100.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '£', decimalDigits: 2);
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
                  const Text('Months already paid'),
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
              value: fmt.format(_settlement!),
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
    final fmt = NumberFormat.currency(symbol: '£', decimalDigits: 0);
    final fmt2 = NumberFormat.currency(symbol: '£', decimalDigits: 2);

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
                  const Text('Gross monthly income'),
                  Text(
                    fmt.format(_monthlyIncome),
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
                    fmt.format(1500),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    fmt.format(15000),
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
            value: '${fmt2.format(_monthlyIncome * 0.15)}/mo',
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
                    'Your payment ${fmt2.format(r.baseLoanPayment)}/mo — $_trafficLabel',
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
