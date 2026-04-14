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
import 'ca_provider.dart';
import 'ca_taxes.dart';

class CAScreen extends StatelessWidget {
  const CAScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n         = AppLocalizations.of(context)!;
    final adService    = context.read<AdService>();
    final trialService = context.read<TrialService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('🇨🇦 ${l10n.appNameCA}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l10n.history,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoryScreen(country: 'ca'))),
          ),
        ],
      ),
      body: Consumer<CAProvider>(
        builder: (context, p, _) => ListView(
          padding: const EdgeInsets.all(12),
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
                onPressed: p.calculate,
                icon: const Icon(Icons.calculate),
                label: Text(l10n.calculate),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ),

            // ── Results ──────────────────────────────────────────────
            if (p.result != null)
              _CAResults(p: p, adService: adService, trialService: trialService),

            const SizedBox(height: 16),
            AdBannerWidget(adService: adService),
            const SizedBox(height: 24),
          ],
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
  final TrialService trialService;
  const _CAResults({required this.p, required this.adService, required this.trialService});

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
        ResultTile(label: l10n.loanAmount, value: fmt.format(r.loanAmount)),
        ResultTile(label: '${l10n.taxAmount} (${r.provinceCode})', value: fmt.format(r.taxAmount)),
        const Divider(),
        if (hasFull) ...[
          // BUG #3: explicit cost breakdown
          ResultTile(label: l10n.financedAmount, value: fmt.format(r.loanAmount)),
          ResultTile(label: l10n.totalInterest, value: fmt.format(r.totalInterest)),
          if (r.insuranceTotal > 0)
            ResultTile(label: l10n.totalInsurances, value: fmt.format(r.insuranceTotal)),
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
                          insuranceMonthly: p.insurance.monthlyTotal,
                        )));
              }
            }),
            icon: const Icon(Icons.table_chart),
            label: Text(l10n.amortization),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => PdfExportService.exportLoanPdf(
              title: l10n.appNameCA,
              currencySymbol: '\$',
              loanAmount: r.loanAmount,
              annualRate: r.annualRate,
              termMonths: r.termMonths,
              downPayment: r.downPayment,
              insuranceMonthly: p.insurance.monthlyTotal,
              summary: [
                MapEntry(p.isBiWeekly ? l10n.biWeeklyPayment : l10n.monthlyPayment,
                    '\$${r.displayPayment.toStringAsFixed(2)}'),
                MapEntry(l10n.loanAmount, '\$${r.loanAmount.toStringAsFixed(2)}'),
                MapEntry('${l10n.taxAmount} (${r.provinceCode})',
                    '\$${r.taxAmount.toStringAsFixed(2)}'),
                MapEntry(l10n.downPayment, '\$${r.downPayment.toStringAsFixed(2)}'),
                if (r.insuranceTotal > 0)
                  MapEntry(l10n.totalInsurances,
                      '\$${r.insuranceTotal.toStringAsFixed(2)}'),
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
