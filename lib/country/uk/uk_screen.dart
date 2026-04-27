import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/shared_inputs.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/premium_gate.dart';
import '../../services/ad_service.dart';
import '../../core/freemium/freemium_service.dart';
import '../../core/freemium/paywall_service.dart';
import '../../widgets/paywall_soft.dart';
import '../../widgets/paywall_hard.dart';
import '../../features/amortization/amortization_screen.dart';
import '../../features/history/history_screen.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../../features/pdf/pdf_export_service.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/compare/compare_screen.dart';
import '../../features/early_payoff/early_payoff_screen.dart';
import '../../services/analytics_service.dart';
import '../../core/theme/app_theme.dart';
import 'uk_provider.dart';
import 'uk_logic.dart';

class UKScreen extends StatelessWidget {
  const UKScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n      = AppLocalizations.of(context)!;
    final adService = context.read<AdService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('🇬🇧 ${l10n.appNameUK}'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: freemiumService.isPremiumNotifier,
            builder: (_, isPremium, _) => isPremium
              ? const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Tooltip(
                    message: 'Premium active',
                    child: Icon(Icons.verified_rounded, color: AppTheme.premiumGold, size: 22),
                  ),
                )
              : TextButton.icon(
                  onPressed: () => PaywallSoft.show(context, priceLabel: '£2.99'),
                  icon: const Icon(Icons.workspace_premium, size: 16),
                  label: const Text('Premium',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.premiumGold,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
          ),
          if (paywallService.shouldShowRewarded && !freemiumService.isPremium)
            IconButton(
              icon: const Icon(Icons.shield_outlined),
              tooltip: 'Watch ad — 60 min free',
              onPressed: () => PaywallHard.show(context, priceLabel: '£2.99', savingsLabel: 'save £100+'),
            ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l10n.history,
            onPressed: () {
              AnalyticsService.instance.logTabChanged('history');
              paywallService.recordAction();
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen(country: 'uk')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: l10n.compareLoans,
            onPressed: () {
              AnalyticsService.instance.logTabChanged('compare');
              AnalyticsService.instance.logCompareUsed('uk');
              paywallService.recordAction();
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CompareScreen(flavor: 'uk')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () {
              AnalyticsService.instance.logTabChanged('settings');
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen(flavor: 'uk')));
            },
          ),
        ],
      ),
      body: Consumer<UKProvider>(
        builder: (context, p, _) => SafeArea(
          top: false,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          children: [
            // ── Vehicle ───────────────────────────────────────────────
            SectionCard(
              title: l10n.vehicle,
              children: [
                CurrencySliderInput(
                  label: '${l10n.vehiclePrice} (VAT incl.)',
                  value: p.vehiclePrice,
                  min: 3000, max: 150000, step: 500,
                  symbol: '£',
                  onChanged: p.setVehiclePrice,
                ),
                const SizedBox(height: 12),
                CurrencySliderInput(
                  label: l10n.downPayment,
                  value: p.downPayment,
                  min: 0, max: p.vehiclePrice * 0.9, step: 500,
                  symbol: '£',
                  onChanged: p.setDownPayment,
                ),
                if (p.result != null) ...[
                  const SizedBox(height: 8),
                  ResultTile(
                    label: l10n.loanAmount,
                    value: NumberFormat.currency(symbol: '£', decimalDigits: 2)
                        .format(p.result!.loanAmount),
                  ),
                ],
              ],
            ),

            // ── Loan Terms ────────────────────────────────────────────
            SectionCard(
              title: l10n.loanTerms,
              children: [
                RateInputField(
                  label: '${l10n.annualRate} (APR)',
                  value: p.annualRate,
                  onChanged: p.setAnnualRate,
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
                const SizedBox(height: 16),
                DurationChips(
                  label: l10n.termMonths,
                  options: const [24, 36, 48, 60, 72, 84],
                  selected: p.termMonths,
                  onSelected: p.setTermMonths,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Switch(value: p.isBiWeekly, onChanged: p.setIsBiWeekly),
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
                ]),
              ],
            ),

            // ── Financing Type (Standard / PCP) ──────────────────────
            SectionCard(
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
                        onPressed: () => p.setIsPcp(false),
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
                        onPressed: () => p.setIsPcp(true),
                        child: Text(l10n.pcp),
                      ),
                    ),
                  ],
                ),
                if (p.isPcp) ...[
                  const SizedBox(height: 12),
                  PercentSliderInput(
                    label: l10n.gmfvPercent,
                    value: p.gmfvPercent,
                    min: 10, max: 60, step: 1,
                    onChanged: p.setGmfvPercent,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.gmfv}: £${(p.vehiclePrice * p.gmfvPercent / 100).toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.pcpNote,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),

            // ── Road Tax (VED) ────────────────────────────────────────
            SectionCard(
              title: l10n.roadTax,
              children: [
                Row(
                  children: [
                    Switch(
                      value: p.includeRoadTax,
                      onChanged: p.setIncludeRoadTax,
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<VehicleType>(
                    // ignore: deprecated_member_use
                    value: p.vehicleType,
                    isExpanded: true,
                    decoration: InputDecoration(
                        labelText: l10n.vehicleType,
                        border: const OutlineInputBorder(),
                        isDense: true),
                    items: VehicleType.values.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.label),
                    )).toList(),
                    onChanged: (v) { if (v != null) p.setVehicleType(v); },
                  ),
                  if (p.vehicleType == VehicleType.custom) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: p.customVedAnnual.toStringAsFixed(0),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Custom annual VED (£)',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixText: '£ ',
                      ),
                      onChanged: (v) {
                        final val = double.tryParse(v);
                        if (val != null && val >= 0) p.setCustomVedAnnual(val);
                      },
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    () {
                      final annual = p.vehicleType == VehicleType.custom
                          ? p.customVedAnnual
                          : p.vehicleType.vedAnnual;
                      return 'Annual VED: £${annual.toStringAsFixed(0)}  ·  '
                          'Monthly: £${(annual / 12).toStringAsFixed(2)}';
                    }(),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.primary),
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
                          Icon(Icons.info_outline,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary),
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
            ),

            // ── Calculate ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: FilledButton.icon(
                onPressed: () {
                  if (p.downPayment >= p.vehiclePrice) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Down payment must be less than vehicle price.')),
                    );
                    return;
                  }
                  p.calculate();
                  final trigger = paywallService.recordAction();
                  if (trigger == PaywallTrigger.soft) {
                    PaywallSoft.show(context, priceLabel: '£2.99');
                  } else if (trigger == PaywallTrigger.hard) {
                    PaywallHard.show(context, priceLabel: '£2.99', savingsLabel: 'save £100+');
                  }
                },
                icon: const Icon(Icons.calculate),
                label: Text(l10n.calculate),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ),

            if (p.result != null)
              _UKResults(p: p, adService: adService),

            const SizedBox(height: 16),
            AdBannerWidget(adService: adService),
            const SizedBox(height: 24),
          ],
        ),
        ),
      ),
      ),
    );
  }
}

class _UKResults extends StatelessWidget {
  final UKProvider p;
  final AdService adService;
  const _UKResults({required this.p, required this.adService});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final r    = p.result!;
    final fmt  = NumberFormat.currency(symbol: '£', decimalDigits: 2);

    return ListenableBuilder(
      listenable: Listenable.merge([
        freemiumService.isPremiumNotifier,
        freemiumService.isRewardedNotifier,
      ]),
      builder: (context, _) {
        final hasFull = freemiumService.isPremium || freemiumService.isRewarded;
        return _buildCard(context, l10n, r, fmt, hasFull);
      },
    );
  }

  Widget _buildCard(BuildContext context, AppLocalizations l10n,
      UKCalculation r, NumberFormat fmt, bool hasFull) {
    return SectionCard(
      title: l10n.results,
      children: [
        ResultTile(
          label: p.isBiWeekly
              ? (r.isPcp ? l10n.pcpPayment : l10n.biWeeklyPayment)
              : (r.isPcp ? l10n.pcpPayment : l10n.monthlyPayment),
          value: fmt.format(r.displayPayment),
          isHighlight: true,
        ),
        if (p.isBiWeekly)
          ResultTile(label: '${l10n.monthlyPayment} (equiv.)', value: fmt.format(r.monthlyPayment)),
        if (r.vedMonthly > 0) ...[
          ResultTile(
            label: '  ${l10n.roadTax} /${p.isBiWeekly ? "2wk" : "mo"}',
            value: fmt.format(p.isBiWeekly ? r.vedBiWeekly : r.vedMonthly),
          ),
          ResultTile(
            label: '  ${l10n.loanOnly}',
            value: fmt.format(p.isBiWeekly ? r.biWeeklyLoanPayment : r.baseLoanPayment),
          ),
        ],
        if (r.isPcp)
          ResultTile(label: l10n.pcpFinalPayment, value: fmt.format(r.gmfvAmount)),
        ResultTile(label: l10n.loanAmount, value: fmt.format(r.loanAmount)),
        const Divider(),
        // Cost breakdown — always visible
        ResultTile(label: l10n.financedAmount, value: fmt.format(r.loanAmount)),
        ResultTile(label: l10n.totalInterest, value: fmt.format(r.totalInterest)),
        if (r.vedTotal > 0)
          ResultTile(label: l10n.totalVed, value: fmt.format(r.vedTotal)),
        ResultTile(label: l10n.downPayment, value: fmt.format(r.downPayment)),
        const Divider(height: 8),
        ResultTile(label: l10n.totalCost, value: fmt.format(r.totalCost), isHighlight: true),
        if (r.isPcp)
          ResultTile(
            label: 'Total if buying at end',
            value: fmt.format(r.pcpTotalIfBuy),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            final payment = p.isBiWeekly
                ? 'Bi-weekly: ${fmt.format(r.biWeeklyPayment)}'
                : '${r.isPcp ? "PCP payment" : "Monthly"}: ${fmt.format(r.monthlyPayment)}';
            Share.share(
              '🇬🇧 Auto Loan UK\n'
              'Vehicle: ${fmt.format(r.vehiclePrice)}  |  Down: ${fmt.format(r.downPayment)}\n'
              'Loan: ${fmt.format(r.loanAmount)}  |  Rate: ${r.annualRate.toStringAsFixed(2)}%  |  ${r.termMonths ~/ 12} yr\n'
              '$payment\n'
              'Total Interest: ${fmt.format(r.totalInterest)}  |  Total Cost: ${fmt.format(r.totalCost)}'
              '${r.vedTotal > 0 ? "\nRoad Tax (VED): ${fmt.format(r.vedTotal)}" : ""}',
            );
          },
          icon: const Icon(Icons.share),
          label: const Text('Share'),
        ),
        const SizedBox(height: 8),
        if (hasFull) ...[
          OutlinedButton.icon(
            onPressed: () {
              AnalyticsService.instance.logAmortizationViewed('uk');
              adService.showInterstitialThen(() {
                if (context.mounted) {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AmortizationScreen(
                            loanAmount: r.loanAmount,
                            annualRate: r.annualRate,
                            termMonths: r.termMonths,
                            downPayment: r.downPayment,
                            balloonAmount: r.isPcp ? r.gmfvAmount : 0,
                            insuranceMonthly: r.vedMonthly,
                            currencySymbol: '£',
                            title: 'Amortisation Schedule',
                            isBiWeekly: p.isBiWeekly,
                          )));
                }
              });
            },
            icon: const Icon(Icons.table_chart),
            label: const Text('Amortisation Schedule'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              PdfExportService.exportLoanPdf(
                title: l10n.appNameUK,
                currencySymbol: '£',
                loanAmount: r.loanAmount,
                annualRate: r.annualRate,
                termMonths: r.termMonths,
                downPayment: r.downPayment,
                balloonAmount: r.isPcp ? r.gmfvAmount : 0,
                insuranceMonthly: r.vedMonthly,
                summary: [
                  MapEntry(l10n.vehiclePrice,   '£${r.vehiclePrice.toStringAsFixed(2)}'),
                  MapEntry(l10n.downPayment,    '£${r.downPayment.toStringAsFixed(2)}'),
                  MapEntry(l10n.loanAmount,     '£${r.loanAmount.toStringAsFixed(2)}'),
                  MapEntry(l10n.annualRate,     '${r.annualRate.toStringAsFixed(2)}%'),
                  MapEntry(l10n.termMonths,     '${r.termMonths} mo'),
                  if (r.isPcp) ...[
                    MapEntry(l10n.financingType, l10n.pcp),
                    MapEntry(l10n.gmfv,         '£${r.gmfvAmount.toStringAsFixed(2)}'),
                  ],
                  MapEntry(r.isPcp ? l10n.pcpPayment : l10n.monthlyPayment,
                      '£${r.monthlyPayment.toStringAsFixed(2)}'),
                  if (p.isBiWeekly)
                    MapEntry(l10n.biWeeklyPayment,
                        '£${r.biWeeklyPayment.toStringAsFixed(2)}'),
                  if (r.vedMonthly > 0) ...[
                    MapEntry('${l10n.roadTax} /mo', '£${r.vedMonthly.toStringAsFixed(2)}'),
                    MapEntry(l10n.totalVed,     '£${r.vedTotal.toStringAsFixed(2)}'),
                  ],
                  if (r.isPcp) ...[
                    MapEntry(l10n.pcpFinalPayment, '£${r.gmfvAmount.toStringAsFixed(2)}'),
                    MapEntry('Total if buying at end', '£${r.pcpTotalIfBuy.toStringAsFixed(2)}'),
                  ],
                ],
              );
              AnalyticsService.instance.logPdfExported('uk');
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export PDF'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => EarlyPayoffScreen(
                        loanAmount: r.loanAmount,
                        annualRate: r.annualRate,
                        termMonths: r.termMonths,
                        currencySymbol: '£',
                        flavor: 'uk',
                      )));
            },
            icon: const Icon(Icons.rocket_launch_outlined),
            label: const Text('Early Payoff'),
          ),
        ] else ...[
          PremiumGate(adService: adService, flavor: 'uk'),
        ],
      ],
    );
  }
}
