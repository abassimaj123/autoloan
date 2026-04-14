import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/shared_inputs.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/rewarded_button.dart';
import '../../services/ad_service.dart';
import '../../services/trial_service.dart';
import '../../features/amortization/amortization_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/pdf/pdf_export_service.dart';
import 'us_provider.dart';
import 'us_logic.dart';

class USScreen extends StatelessWidget {
  const USScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n         = AppLocalizations.of(context)!;
    final adService    = context.read<AdService>();
    final trialService = context.read<TrialService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('🇺🇸 ${l10n.appNameUS}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l10n.history,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoryScreen(country: 'us'))),
          ),
        ],
      ),
      body: Consumer<USProvider>(
        builder: (context, p, _) => ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // ── Vehicle ───────────────────────────────────────────────
            SectionCard(
              title: l10n.vehicle,
              children: [
                CurrencySliderInput(
                  label: l10n.vehiclePrice,
                  value: p.vehiclePrice,
                  min: 5000, max: 200000, step: 500,
                  onChanged: p.setVehiclePrice,
                ),
                const SizedBox(height: 12),
                CurrencySliderInput(
                  label: l10n.tradeInValue,
                  value: p.tradeInValue,
                  min: 0, max: p.vehiclePrice, step: 500,
                  onChanged: p.setTradeInValue,
                ),
                const SizedBox(height: 12),
                CurrencySliderInput(
                  label: l10n.downPayment,
                  value: p.downPayment,
                  min: 0, max: p.vehiclePrice, step: 500,
                  onChanged: p.setDownPayment,
                ),
                const SizedBox(height: 12),
                CurrencySliderInput(
                  label: l10n.dealerFees,
                  value: p.dealerFees,
                  min: 0, max: 5000, step: 50,
                  onChanged: p.setDealerFees,
                ),
              ],
            ),

            // ── Tax & Rate ────────────────────────────────────────────
            SectionCard(
              title: '${l10n.salesTax} & ${l10n.annualRate}',
              children: [
                PercentSliderInput(
                  label: l10n.salesTax,
                  value: p.salesTaxPercent,
                  min: 0, max: 15, step: 0.1,
                  onChanged: p.setSalesTax,
                ),
                const SizedBox(height: 16),
                RateInputField(
                  label: l10n.annualRate,
                  value: p.annualRate,
                  onChanged: p.setAnnualRate,
                ),
              ],
            ),

            // ── Credit Score ──────────────────────────────────────────
            SectionCard(
              title: l10n.creditScore,
              children: [
                // ignore: deprecated_member_use
                ...CreditScore.values.map((cs) => RadioListTile<CreditScore>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(cs.label),
                      subtitle: Text(_rateAdjLabel(cs, l10n)),
                      value: cs,
                      // ignore: deprecated_member_use
                      groupValue: p.creditScore,
                      // ignore: deprecated_member_use
                      onChanged: (v) { if (v != null) p.setCreditScore(v); },
                    )),
                if (p.result != null)
                  ResultTile(
                    label: l10n.effectiveRate,
                    value: '${p.result!.effectiveRate.toStringAsFixed(2)}%',
                  ),
              ],
            ),

            // ── Term ──────────────────────────────────────────────────
            SectionCard(
              title: l10n.loanTerms,
              children: [
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

            // ── Calculate ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: FilledButton.icon(
                onPressed: p.calculate,
                icon: const Icon(Icons.calculate),
                label: Text(l10n.calculate),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ),

            if (p.result != null)
              _USResults(p: p, adService: adService, trialService: trialService),

            const SizedBox(height: 16),
            AdBannerWidget(adService: adService),
            const SizedBox(height: 24),
          ],
        ),
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

class _USResults extends StatelessWidget {
  final USProvider p;
  final AdService adService;
  final TrialService trialService;
  const _USResults({required this.p, required this.adService, required this.trialService});

  @override
  Widget build(BuildContext context) {
    final l10n    = AppLocalizations.of(context)!;
    final r       = p.result!;
    final fmt     = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final hasFull = trialService.isTrialActive || trialService.isRewardedActive;

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
        ResultTile(label: l10n.loanAmount, value: fmt.format(r.financedAmount)),
        ResultTile(label: l10n.taxAmount, value: fmt.format(r.taxAmount)),
        if (r.tradeInValue > 0)
          ResultTile(label: l10n.tradeInValue, value: fmt.format(r.tradeInValue)),
        const Divider(),
        if (hasFull) ...[
          ResultTile(label: l10n.financedAmount, value: fmt.format(r.financedAmount)),
          ResultTile(label: l10n.totalInterest, value: fmt.format(r.totalInterest)),
          ResultTile(label: l10n.downPayment, value: fmt.format(r.downPayment)),
          const Divider(height: 8),
          ResultTile(label: l10n.totalCost, value: fmt.format(r.totalCost), isHighlight: true),
          ResultTile(label: l10n.effectiveRate, value: '${r.effectiveRate.toStringAsFixed(2)}%'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => adService.showInterstitialThen(() {
              if (context.mounted) {
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AmortizationScreen(
                          loanAmount: r.financedAmount,
                          annualRate: r.effectiveRate,
                          termMonths: r.termMonths,
                          downPayment: r.downPayment,
                        )));
              }
            }),
            icon: const Icon(Icons.table_chart),
            label: Text(l10n.amortization),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => PdfExportService.exportLoanPdf(
              title: l10n.appNameUS,
              currencySymbol: '\$',
              loanAmount: r.financedAmount,
              annualRate: r.effectiveRate,
              termMonths: r.termMonths,
              downPayment: r.downPayment,
              summary: [
                MapEntry(l10n.monthlyPayment, '\$${r.monthlyPayment.toStringAsFixed(2)}'),
                MapEntry(l10n.financedAmount, '\$${r.financedAmount.toStringAsFixed(2)}'),
                MapEntry(l10n.taxAmount, '\$${r.taxAmount.toStringAsFixed(2)}'),
                if (r.tradeInValue > 0)
                  MapEntry(l10n.tradeInValue, '\$${r.tradeInValue.toStringAsFixed(2)}'),
                MapEntry(l10n.downPayment, '\$${r.downPayment.toStringAsFixed(2)}'),
                MapEntry(l10n.effectiveRate, '${r.effectiveRate.toStringAsFixed(2)}%'),
              ],
            ),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export PDF'),
          ),
        ] else ...[
          Text(l10n.unlockFull, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          RewardedButton(adService: adService, trialService: trialService, onUnlocked: () {}),
        ],
      ],
    );
  }
}
