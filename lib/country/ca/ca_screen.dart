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
import 'ca_provider.dart';
import 'ca_logic.dart';
import 'ca_taxes.dart';

class CAScreen extends StatelessWidget {
  const CAScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n      = AppLocalizations.of(context)!;
    final adService = context.read<AdService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('🇨🇦 ${l10n.appNameCA}'),
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
                  onPressed: () => PaywallSoft.show(context, priceLabel: r'$3.99 CAD'),
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
              onPressed: () => PaywallHard.show(context, priceLabel: r'$3.99 CAD', savingsLabel: r'save $100 CAD+'),
            ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l10n.history,
            onPressed: () {
              AnalyticsService.instance.logTabChanged('history');
              paywallService.recordAction();
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen(country: 'ca')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: l10n.compareLoans,
            onPressed: () {
              AnalyticsService.instance.logTabChanged('compare');
              AnalyticsService.instance.logCompareUsed('ca');
              paywallService.recordAction();
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CompareScreen(flavor: 'ca')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () {
              AnalyticsService.instance.logTabChanged('settings');
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen(flavor: 'ca')));
            },
          ),
        ],
      ),
      body: Consumer<CAProvider>(
        builder: (context, p, _) => SafeArea(
          top: false,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          children: [
            // ── Vehicle ──────────────────────────────────────────────
            SectionCard(
              title: l10n.vehicle,
              children: [
                CurrencySliderInput(
                  label: l10n.vehiclePrice,
                  value: p.vehiclePrice,
                  min: 5000,
                  max: 150000,
                  step: 500,
                  onChanged: p.setVehiclePrice,
                ),
                const SizedBox(height: 12),
                CurrencySliderInput(
                  label: l10n.downPayment,
                  value: p.dpAmount,
                  min: 0,
                  max: p.vehiclePrice * 0.5,
                  step: 500,
                  onChanged: (v) {
                    p.setDpIsPercent(false);
                    p.setDownPayment(v);
                  },
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Switch(value: p.dpIsPercent, onChanged: p.setDpIsPercent),
                  Text(' ${l10n.usePercentage}'),
                  if (p.dpIsPercent) ...[
                    const SizedBox(width: 8),
                    Text('${p.downPayment.toStringAsFixed(1)}%',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ]),
              ],
            ),

            // ── Province & Tax ────────────────────────────────────────
            SectionCard(
              title: l10n.province,
              children: [
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: p.provinceCode,
                  isExpanded: true,
                  decoration: InputDecoration(
                      labelText: l10n.province,
                      border: const OutlineInputBorder(),
                      isDense: true),
                  // Compact display when closed: "ON · 13%"
                  selectedItemBuilder: (ctx) => kCAProvinces.map((prov) =>
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${prov.code} · '
                          '${(prov.totalRate * 100).toStringAsFixed(prov.totalRate == 0.14975 ? 3 : 0)}%',
                          overflow: TextOverflow.ellipsis,
                        ),
                      )).toList(),
                  // Full name in dropdown list
                  items: kCAProvinces
                      .map((prov) => DropdownMenuItem(
                            value: prov.code,
                            child: Text(
                              '${prov.code}  ${prov.nameEn}  '
                              '${(prov.totalRate * 100).toStringAsFixed(prov.totalRate == 0.14975 ? 3 : 0)}%',
                            ),
                          ))
                      .toList(),
                  onChanged: (v) { if (v != null) p.setProvinceCode(v); },
                ),
                if (p.result != null) ...[
                  const SizedBox(height: 8),
                  ResultTile(
                    label: l10n.taxAmount,
                    value: NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                        .format(p.result!.taxAmount),
                  ),
                ],
              ],
            ),

            // ── Loan Terms ────────────────────────────────────────────
            SectionCard(
              title: l10n.loanTerms,
              children: [
                RateInputField(
                  label: l10n.annualRate,
                  value: p.annualRate,
                  onChanged: p.setAnnualRate,
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

            // ── Insurance ─────────────────────────────────────────────
            SectionCard(
              title: l10n.insurance,
              children: [
                _InsuranceRow(
                  label: '${l10n.lifeDisability} '
                      '(\$${p.insurance.lifeDisabilityAmount.toStringAsFixed(0)}/${l10n.month})',
                  value: p.insurance.lifeDisability,
                  onChanged: p.setLifeDisability,
                ),
                _InsuranceRow(
                  label: l10n.extendedWarranty,
                  value: p.insurance.extendedWarranty,
                  onChanged: p.setExtendedWarranty,
                ),
                if (p.insurance.extendedWarranty)
                  CurrencySliderInput(
                    label: '${l10n.extendedWarranty} Total',
                    value: p.insurance.warrantyAmount,
                    min: 0, max: 5000, step: 100,
                    onChanged: p.setWarrantyAmount,
                  ),
                _InsuranceRow(
                  label: l10n.gap,
                  value: p.insurance.gap,
                  onChanged: p.setGap,
                ),
                if (p.insurance.gap)
                  CurrencySliderInput(
                    label: '${l10n.gap} Total',
                    value: p.insurance.gapAmount,
                    min: 0, max: 2000, step: 50,
                    onChanged: p.setGapAmount,
                  ),
              ],
            ),

            // ── Calculate ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: FilledButton.icon(
                onPressed: () {
                  if (p.dpAmount >= p.vehiclePrice) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Down payment must be less than vehicle price.')),
                    );
                    return;
                  }
                  p.calculate();
                  final trigger = paywallService.recordAction();
                  if (trigger == PaywallTrigger.soft) {
                    PaywallSoft.show(context, priceLabel: r'$3.99 CAD');
                  } else if (trigger == PaywallTrigger.hard) {
                    PaywallHard.show(context, priceLabel: r'$3.99 CAD', savingsLabel: r'save $100 CAD+');
                  }
                },
                icon: const Icon(Icons.calculate),
                label: Text(l10n.calculate),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ),

            // ── Results ──────────────────────────────────────────────
            if (p.result != null)
              _CAResults(p: p, adService: adService),

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

class _InsuranceRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _InsuranceRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(children: [
        Switch(value: value, onChanged: onChanged),
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
      ]);
}

class _CAResults extends StatelessWidget {
  final CAProvider p;
  final AdService adService;
  const _CAResults({required this.p, required this.adService});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final r    = p.result!;
    final fmt  = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

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
      CACalculation r, NumberFormat fmt, bool hasFull) {
    return SectionCard(
      title: l10n.results,
      children: [
        ResultTile(
          label: p.isBiWeekly ? l10n.biWeeklyPayment : l10n.monthlyPayment,
          value: fmt.format(r.displayPayment),
          isHighlight: true,
        ),
        if (p.isBiWeekly)
          ResultTile(label: '${l10n.monthlyPayment} (equiv.)', value: fmt.format(r.monthlyPayment)),
        ResultTile(label: l10n.loanAmount, value: fmt.format(r.loanAmount)),
        ResultTile(label: '${l10n.taxAmount} (${r.provinceCode})', value: fmt.format(r.taxAmount)),
        const Divider(),
        // Cost breakdown — always visible
        ResultTile(label: l10n.financedAmount, value: fmt.format(r.loanAmount)),
        ResultTile(label: l10n.totalInterest, value: fmt.format(r.totalInterest)),
        if (r.insuranceTotal > 0)
          ResultTile(label: l10n.totalInsurances, value: fmt.format(r.insuranceTotal)),
        ResultTile(label: l10n.downPayment, value: fmt.format(r.downPayment)),
        const Divider(height: 8),
        ResultTile(label: l10n.totalCost, value: fmt.format(r.totalCost), isHighlight: true),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            final payment = p.isBiWeekly
                ? 'Bi-weekly: ${fmt.format(r.biWeeklyPayment)}'
                : 'Monthly: ${fmt.format(r.monthlyPayment)}';
            Share.share(
              '🇨🇦 Auto Loan CA\n'
              'Vehicle: ${fmt.format(r.vehiclePrice)}  |  Down: ${fmt.format(r.downPayment)}\n'
              'Loan: ${fmt.format(r.loanAmount)}  |  Rate: ${r.annualRate.toStringAsFixed(2)}%  |  ${r.termMonths ~/ 12} yr\n'
              '$payment\n'
              'Total Interest: ${fmt.format(r.totalInterest)}  |  Total Cost: ${fmt.format(r.totalCost)}\n'
              'Tax (${r.provinceCode}): ${fmt.format(r.taxAmount)}',
            );
          },
          icon: const Icon(Icons.share),
          label: const Text('Share'),
        ),
        const SizedBox(height: 8),
        if (hasFull) ...[
          OutlinedButton.icon(
            onPressed: () {
              AnalyticsService.instance.logAmortizationViewed('ca');
              adService.showInterstitialThen(() {
                if (context.mounted) {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AmortizationScreen(
                            loanAmount: r.loanAmount,
                            annualRate: r.annualRate,
                            termMonths: r.termMonths,
                            downPayment: r.downPayment,
                            insuranceMonthly: p.insurance.monthlyTotal(r.termMonths),
                            isBiWeekly: p.isBiWeekly,
                          )));
                }
              });
            },
            icon: const Icon(Icons.table_chart),
            label: Text(l10n.amortization),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              PdfExportService.exportLoanPdf(
                title: l10n.appNameCA,
                currencySymbol: '\$',
                loanAmount: r.loanAmount,
                annualRate: r.annualRate,
                termMonths: r.termMonths,
                downPayment: r.downPayment,
                insuranceMonthly: p.insurance.monthlyTotal(r.termMonths),
                summary: [
                  MapEntry(l10n.vehiclePrice,   '\$${r.vehiclePrice.toStringAsFixed(2)}'),
                  MapEntry('${l10n.taxAmount} (${r.provinceCode})',
                      '\$${r.taxAmount.toStringAsFixed(2)}'),
                  MapEntry(l10n.downPayment,    '\$${r.downPayment.toStringAsFixed(2)}'),
                  MapEntry(l10n.loanAmount,     '\$${r.loanAmount.toStringAsFixed(2)}'),
                  MapEntry(l10n.annualRate,     '${r.annualRate.toStringAsFixed(2)}%'),
                  MapEntry(l10n.termMonths,     '${r.termMonths} mo (${r.termMonths ~/ 12} yr)'),
                  MapEntry(l10n.monthlyPayment, '\$${r.monthlyPayment.toStringAsFixed(2)}'),
                  if (p.isBiWeekly)
                    MapEntry(l10n.biWeeklyPayment, '\$${r.biWeeklyPayment.toStringAsFixed(2)}'),
                  if (r.insuranceTotal > 0)
                    MapEntry(l10n.totalInsurances, '\$${r.insuranceTotal.toStringAsFixed(2)}'),
                ],
              );
              AnalyticsService.instance.logPdfExported('ca');
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
                        flavor: 'ca',
                      )));
            },
            icon: const Icon(Icons.rocket_launch_outlined),
            label: const Text('Early Payoff'),
          ),
        ] else ...[
          PremiumGate(adService: adService, flavor: 'ca'),
        ],
      ],
    );
  }
}

