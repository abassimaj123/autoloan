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
import 'uk_provider.dart';
import 'uk_logic.dart';

class UKScreen extends StatelessWidget {
  const UKScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n         = AppLocalizations.of(context)!;
    final adService    = context.read<AdService>();
    final trialService = context.read<TrialService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('🇬🇧 ${l10n.appNameUK}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l10n.history,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoryScreen(country: 'uk'))),
          ),
        ],
      ),
      body: Consumer<UKProvider>(
        builder: (context, p, _) => ListView(
          padding: const EdgeInsets.all(12),
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
                  min: 0, max: p.vehiclePrice * 0.5, step: 500,
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
                onPressed: p.calculate,
                icon: const Icon(Icons.calculate),
                label: Text(l10n.calculate),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ),

            if (p.result != null)
              _UKResults(p: p, adService: adService, trialService: trialService),

            const SizedBox(height: 16),
            AdBannerWidget(adService: adService),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _UKResults extends StatelessWidget {
  final UKProvider p;
  final AdService adService;
  final TrialService trialService;
  const _UKResults({required this.p, required this.adService, required this.trialService});

  @override
  Widget build(BuildContext context) {
    final l10n    = AppLocalizations.of(context)!;
    final r       = p.result!;
    final fmt     = NumberFormat.currency(symbol: '£', decimalDigits: 2);
    final hasFull = trialService.isTrialActive || trialService.isRewardedActive;

    return SectionCard(
      title: l10n.results,
      children: [
        ResultTile(
          label: l10n.monthlyPayment,
          value: fmt.format(r.monthlyPayment),
          isHighlight: true,
        ),
        if (r.vedMonthly > 0) ...[
          ResultTile(
            label: '  ${l10n.roadTax} /mo',
            value: fmt.format(r.vedMonthly),
          ),
          ResultTile(
            label: '  ${l10n.loanOnly}',
            value: fmt.format(r.baseLoanPayment),
          ),
        ],
        ResultTile(label: l10n.loanAmount, value: fmt.format(r.loanAmount)),
        const Divider(),
        if (hasFull) ...[
          // Cost breakdown
          ResultTile(label: l10n.financedAmount, value: fmt.format(r.loanAmount)),
          ResultTile(label: l10n.totalInterest, value: fmt.format(r.totalInterest)),
          if (r.vedTotal > 0)
            ResultTile(label: l10n.totalVed, value: fmt.format(r.vedTotal)),
          ResultTile(label: l10n.downPayment, value: fmt.format(r.downPayment)),
          const Divider(height: 8),
          ResultTile(label: l10n.totalCost, value: fmt.format(r.totalCost), isHighlight: true),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => adService.showInterstitialThen(() {
              if (context.mounted) {
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AmortizationScreen(
                          loanAmount: r.loanAmount,
                          annualRate: r.annualRate,
                          termMonths: r.termMonths,
                          downPayment: r.downPayment,
                          insuranceMonthly: r.vedMonthly,
                          currencySymbol: '£',
                          title: 'Amortisation Schedule',
                        )));
              }
            }),
            icon: const Icon(Icons.table_chart),
            label: const Text('Amortisation Schedule'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => PdfExportService.exportLoanPdf(
              title: l10n.appNameUK,
              currencySymbol: '£',
              loanAmount: r.loanAmount,
              annualRate: r.annualRate,
              termMonths: r.termMonths,
              downPayment: r.downPayment,
              insuranceMonthly: r.vedMonthly,
              summary: [
                MapEntry(l10n.monthlyPayment, '£${r.monthlyPayment.toStringAsFixed(2)}'),
                MapEntry(l10n.loanAmount, '£${r.loanAmount.toStringAsFixed(2)}'),
                if (r.vedMonthly > 0) ...[
                  MapEntry('${l10n.roadTax} /mo', '£${r.vedMonthly.toStringAsFixed(2)}'),
                  MapEntry(l10n.loanOnly, '£${r.baseLoanPayment.toStringAsFixed(2)}'),
                ],
                MapEntry(l10n.downPayment, '£${r.downPayment.toStringAsFixed(2)}'),
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
