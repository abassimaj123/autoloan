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
      AnalyticsService.instance.logCompareUsed('ca');
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
      if (mounted) context.read<CAProvider>().calculate();
    });
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) context.read<CAProvider>().saveSnapshot();
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
                _CACalculatorTab(
                  validated: _validated,
                  onCalculate: _debouncedCalculate,
                  adService: adService,
                ),
                // Tab 1: Compare
                CompareScreen(flavor: 'ca', showAppBar: false),
                // Tab 2: History
                HistoryScreen(
                  key: ValueKey(_historyRefreshKey),
                  country: 'ca',
                  showAppBar: false,
                  onClear: () => setState(() => _historyRefreshKey++),
                ),
                // Tab 3: Lease vs Buy
                const LeaseVsBuyScreen(flavor: 'ca', showAppBar: false),
              ],
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
                              ],
                            ),
                          )
                        else
                          CalcwiseEmptyState(
                            icon: Icons.directions_car_outlined,
                            title: Localizations.localeOf(context).languageCode == 'fr'
                                ? 'Pas encore de résultats'
                                : 'No results yet',
                            body: Localizations.localeOf(context).languageCode == 'fr'
                                ? 'Entrez le prix du véhicule pour voir votre analyse.'
                                : 'Enter the vehicle price to see your analysis.',
                          ),
                        // ── Input sections ────────────────────────────────
                        _CAVehicleSection(p: p, validated: validated, onCalculate: onCalculate),
                        _CAProvinceSection(p: p, onCalculate: onCalculate),
                        _CALoanTermsSection(p: p, validated: validated, onCalculate: onCalculate),
                        _CAInsuranceSection(p: p, onCalculate: onCalculate),
                        // ── Extra tools ───────────────────────────────────
                        if (p.result != null) _CATcoSection(p: p),
                        _CALeaseSection(p: p),
                        _CATradeInSection(p: p),
                        _CAAffordabilitySection(p: p),
                        _CAQuickToolsSection(p: p),
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
          errorText: validated && p.vehiclePrice <= 0 ? 'Required' : null,
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
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
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
            value: NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(p.result!.taxAmount),
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
          errorText: validated && p.annualRate <= 0 ? 'Required' : null,
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
          label: '${l10n.lifeDisability} (\$${p.insurance.lifeDisabilityAmount.toStringAsFixed(0)}/${l10n.month})',
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
    return Column(
      children: [
        // ── Reverse Affordability ──────────────────────────────────────
        const SizedBox(height: AppSpacing.md),
        ReverseSolveCard(
          title: 'What vehicle price can I afford?',
          targetLabel: 'Target monthly payment',
          resultLabel: 'Max vehicle price',
          prefix: '\$',
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
                pageBuilder: (_, __, ___) => const CashbackVsLowAprScreen(flavor: 'ca'),
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
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

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
    CACalculation r,
    NumberFormat fmt,
    bool hasFull,
  ) {
    return SectionCard(
      title: l10n.results,
      children: [
        // ── Hero monthly payment ──────────────────────────────────────────
        CalcwiseHeroCard(
          label: p.isBiWeekly ? l10n.biWeeklyPayment : l10n.monthlyPayment,
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
        ResultTile(label: l10n.loanAmount, value: fmt.format(r.loanAmount)),
        ResultTile(
          label: '${l10n.taxAmount} (${r.provinceCode})',
          value: fmt.format(r.taxAmount),
        ),
        const Divider(),
        // Cost breakdown — always visible
        ResultTile(label: l10n.financedAmount, value: fmt.format(r.loanAmount)),
        ResultTile(
          label: l10n.totalInterest,
          value: fmt.format(r.totalInterest),
        ),
        if (r.insuranceTotal > 0)
          ResultTile(
            label: l10n.totalInsurances,
            value: fmt.format(r.insuranceTotal),
          ),
        ResultTile(label: l10n.downPayment, value: fmt.format(r.downPayment)),
        const Divider(height: 8),
        ResultTile(
          label: l10n.totalCost,
          value: fmt.format(r.totalCost),
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
            final payment = p.isBiWeekly
                ? 'Bi-weekly: ${fmt.format(r.biWeeklyPayment)}'
                : 'Monthly: ${fmt.format(r.monthlyPayment)}';
            try {
              await Share.share(
                'Auto Loan CA\n'
                'Vehicle: ${fmt.format(r.vehiclePrice)}  |  Down: ${fmt.format(r.downPayment)}\n'
                'Loan: ${fmt.format(r.loanAmount)}  |  Rate: ${r.annualRate.toStringAsFixed(2)}%  |  ${r.termMonths ~/ 12} yr\n'
                '$payment\n'
                'Total Interest: ${fmt.format(r.totalInterest)}  |  Total Cost: ${fmt.format(r.totalCost)}\n'
                'Tax (${r.provinceCode}): ${fmt.format(r.taxAmount)}',
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
              try {
                await PdfExportService.exportLoanPdf(
                  title: l10n.appNameCA,
                  currencySymbol: '\$',
                  loanAmount: r.loanAmount,
                  annualRate: r.annualRate,
                  termMonths: r.termMonths,
                  downPayment: r.downPayment,
                  insuranceMonthly: p.insurance.monthlyTotal(r.termMonths),
                  summary: [
                    MapEntry(
                      l10n.vehiclePrice,
                      '\$${r.vehiclePrice.toStringAsFixed(2)}',
                    ),
                    MapEntry(
                      '${l10n.taxAmount} (${r.provinceCode})',
                      '\$${r.taxAmount.toStringAsFixed(2)}',
                    ),
                    MapEntry(
                      l10n.downPayment,
                      '\$${r.downPayment.toStringAsFixed(2)}',
                    ),
                    MapEntry(
                      l10n.loanAmount,
                      '\$${r.loanAmount.toStringAsFixed(2)}',
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
                      '\$${r.monthlyPayment.toStringAsFixed(2)}',
                    ),
                    if (p.isBiWeekly)
                      MapEntry(
                        l10n.biWeeklyPayment,
                        '\$${r.biWeeklyPayment.toStringAsFixed(2)}',
                      ),
                    if (r.insuranceTotal > 0)
                      MapEntry(
                        l10n.totalInsurances,
                        '\$${r.insuranceTotal.toStringAsFixed(2)}',
                      ),
                  ],
                );
                AnalyticsService.instance.logPdfExported('ca');
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PDF exported successfully'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
              } catch (e) {
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export failed'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
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
                    flavor: 'ca',
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
          PremiumGate(adService: adService, flavor: 'ca'),
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
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
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
          // Residual %
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
          // Money factor
          TextFormField(
            initialValue: (_moneyFactor * 2400).toStringAsFixed(2),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Equivalent Annual Rate % (÷2400 = money factor)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
              fmt: fmt,
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

class _ComparisonCard extends StatelessWidget {
  final NumberFormat fmt;
  final CALeaseCalculation lease;
  final double buyMonthly;
  final int buyTermMonths;
  final int leaseTermMonths;

  const _ComparisonCard({
    required this.fmt,
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
        Row(
          children: [
            Expanded(
              child: _ComparisonColumn(
                label: 'Lease ($leaseTermMonths mo)',
                monthly: fmt.format(lease.monthlyLease),
                total: fmt.format(lease.totalLeaseCost),
                highlight: leaseWins,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ComparisonColumn(
                label: 'Buy ($buyTermMonths mo)',
                monthly: fmt.format(buyMonthly),
                total: fmt.format(buyTotalOverLeaseTerm),
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
                ? 'Lease saves ${fmt.format(absDiff)} over $leaseTermMonths months'
                : 'Buy saves ${fmt.format(absDiff)} over $leaseTermMonths months',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Residual: ${fmt.format(lease.residualValue)} · '
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
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final fmt2 = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
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
            label: 'Fuel price (\$/L)',
            value: _fuelPrice,
            min: 1.00,
            max: 2.50,
            step: 0.05,
            display: fmt2.format(_fuelPrice),
            onChanged: (v) => setState(() => _fuelPrice = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _TcoSlider(
            label: 'Annual insurance (\$)',
            value: _annualInsurance,
            min: 600,
            max: 5000,
            step: 100,
            display: fmt.format(_annualInsurance),
            onChanged: (v) => setState(() => _annualInsurance = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _TcoSlider(
            label: 'Annual maintenance (\$)',
            value: _annualMaint,
            min: 200,
            max: 3000,
            step: 100,
            display: fmt.format(_annualMaint),
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
              value: fmt.format(_tco!.netVehicleCost),
            ),
            ResultTile(
              label: 'Total interest',
              value: fmt.format(_tco!.totalInterest),
            ),
            ResultTile(label: 'Total fuel', value: fmt.format(_tco!.totalFuel)),
            ResultTile(
              label: 'Total insurance',
              value: fmt.format(_tco!.totalInsurance),
            ),
            ResultTile(
              label: 'Total maintenance',
              value: fmt.format(_tco!.totalMaintenance),
            ),
            const Divider(height: 8),
            ResultTile(
              label: 'True cost of ownership over $termYears years',
              value: fmt.format(_tco!.grandTotal),
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
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return SectionCard(
      title: 'Trade-In Value Calculator',
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
            symbol: '\$',
            onChanged: (v) => setState(() => _tradeInValue = v),
          ),
          const SizedBox(height: AppSpacing.md),
          CurrencySliderInput(
            label: 'Remaining balance on current loan',
            value: _remaining,
            min: 0,
            max: 30000,
            step: 500,
            symbol: '\$',
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
                    ? 'Equity of ${fmt.format(_result!.netTradeIn)} applied to down payment'
                    : 'Negative equity of ${fmt.format(_result!.netTradeIn.abs())} added to loan',
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
              value: fmt.format(_result!.netTradeIn),
            ),
            ResultTile(
              label: 'Effective down payment',
              value: fmt.format(_result!.effectiveDownPayment),
            ),
            ResultTile(
              label: 'Adjusted loan amount',
              value: fmt.format(_result!.adjustedLoanAmount),
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
                    content: Text('Down payment updated to ${fmt.format(dp)}'),
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
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final fmt2 = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

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
          // Income slider
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
                    fmt.format(2000),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    fmt.format(20000),
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
            value: '${fmt2.format(maxRecommended)}/mo',
          ),
          ResultTile(
            label: 'Max affordable vehicle (at current rate/term)',
            value: fmt.format(maxVehicle),
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
                    'Your payment ${fmt2.format(r.monthlyPayment)}/mo — $_trafficLabel',
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
