import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:calcwise_core/calcwise_core.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/shared_inputs.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/premium_gate.dart';
import '../../services/ad_service.dart';
import '../../core/freemium/freemium_service.dart';
import '../../main.dart' show paywallSession;
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
import '../../services/review_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/insight_engine.dart';
import '../../widgets/insight_card.dart';
import 'us_provider.dart';
import 'us_logic.dart';

const _kPremiumPrice = r'$2.99';

class USScreen extends StatelessWidget {
  const USScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n      = AppLocalizations.of(context)!;
    final adService = context.read<AdService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('🇺🇸 ${l10n.appNameUS}'),
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
                  onPressed: () => PaywallSoft.show(context, priceLabel: _kPremiumPrice),
                  icon: const Icon(Icons.workspace_premium, size: 16),
                  label: const Text('Premium',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.premiumGold,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
          ),
          if (paywallSession.sessionCount >= 2 && !freemiumService.isPremium)
            IconButton(
              icon: const Icon(Icons.shield_outlined),
              tooltip: 'Watch ad — 60 min free',
              onPressed: () => PaywallHard.show(context, priceLabel: _kPremiumPrice, savingsLabel: r'save $100+'),
            ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l10n.history,
            onPressed: () {
              AnalyticsService.instance.logTabChanged('history');
              paywallSession.recordAction();
              Navigator.push(context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const HistoryScreen(country: 'us'),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration: const Duration(milliseconds: 250),
                  ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: l10n.compareLoans,
            onPressed: () {
              AnalyticsService.instance.logTabChanged('compare');
              AnalyticsService.instance.logCompareUsed('us');
              paywallSession.recordAction();
              Navigator.push(context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const CompareScreen(flavor: 'us'),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration: const Duration(milliseconds: 250),
                  ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () {
              AnalyticsService.instance.logTabChanged('settings');
              Navigator.push(context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const SettingsScreen(flavor: 'us'),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration: const Duration(milliseconds: 250),
                  ));
            },
          ),
        ],
      ),
      body: Consumer<USProvider>(
        builder: (context, p, _) => SafeArea(
          top: false,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: CalcwisePageEntrance(child: Column(
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
                onPressed: () async {
                  if (p.downPayment >= p.vehiclePrice) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Down payment must be less than vehicle price.')),
                    );
                    return;
                  }
                  p.calculate();
                  HapticFeedback.mediumImpact();
                  ReviewService.instance.requestAfterSave();
                  final trigger = await paywallSession.recordAction();
                  if (trigger == PaywallTrigger.soft) {
                    PaywallSoft.show(context, priceLabel: _kPremiumPrice);
                  } else if (trigger == PaywallTrigger.hard) {
                    PaywallHard.show(context, priceLabel: _kPremiumPrice);
                  }
                },
                icon: const Icon(Icons.calculate),
                label: Text(l10n.calculate),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ),

            if (p.result != null)
              _USResults(p: p, adService: adService),

            // ── Lease vs Buy ─────────────────────────────────────────
            _USLeaseSection(p: p),

            // ── Refi Calculator ──────────────────────────────────────
            if (p.result != null)
              _USRefiSection(p: p),

            // ── Total Cost of Ownership ───────────────────────────────
            if (p.result != null)
              _USTcoSection(p: p),

            const SizedBox(height: 16),
            AdBannerWidget(adService: adService),
                      const SizedBox(height: 24),
                    ],
                  )),
                ),
              ),
            ),
          ),
        ),
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
  const _USResults({required this.p, required this.adService});

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
      USCalculation r, NumberFormat fmt, bool hasFull) {
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
        ResultTile(label: l10n.financedAmount, value: fmt.format(r.financedAmount)),
        ResultTile(label: l10n.totalInterest, value: fmt.format(r.totalInterest)),
        ResultTile(label: l10n.downPayment, value: fmt.format(r.downPayment)),
        const Divider(height: 8),
        ResultTile(label: l10n.totalCost, value: fmt.format(r.totalCost), isHighlight: true),
        ResultTile(label: l10n.effectiveRate, value: '${r.effectiveRate.toStringAsFixed(2)}%'),
        const SizedBox(height: 8),
        // ── Smart Insights ────────────────────────────────────────────
        InsightCard(
          insights: InsightEngine.generate(
            vehiclePrice:   r.vehiclePrice,
            loanAmount:     r.financedAmount,
            annualRatePct:  r.effectiveRate,
            termMonths:     r.termMonths,
            monthlyPayment: r.monthlyPayment,
            totalInterest:  r.totalInterest,
            downPayment:    r.downPayment,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            final payment = p.isBiWeekly
                ? 'Bi-weekly: ${fmt.format(r.biWeeklyPayment)}'
                : 'Monthly: ${fmt.format(r.monthlyPayment)}';
            Share.share(
              '🇺🇸 Auto Loan USA\n'
              'Vehicle: ${fmt.format(r.vehiclePrice)}  |  Down: ${fmt.format(r.downPayment)}\n'
              'Financed: ${fmt.format(r.financedAmount)}  |  Rate: ${r.annualRate.toStringAsFixed(2)}% (eff. ${r.effectiveRate.toStringAsFixed(2)}%)  |  ${r.termMonths ~/ 12} yr\n'
              '$payment\n'
              'Total Interest: ${fmt.format(r.totalInterest)}  |  Total Cost: ${fmt.format(r.totalCost)}'
              '${r.taxAmount > 0 ? "\nTax: ${fmt.format(r.taxAmount)}" : ""}',
            );
          },
          icon: const Icon(Icons.share),
          label: const Text('Share'),
        ),
        const SizedBox(height: 8),
        if (hasFull) ...[
          OutlinedButton.icon(
            onPressed: () {
              AnalyticsService.instance.logAmortizationViewed('us');
              adService.showInterstitialThen(() {
                if (context.mounted) {
                  Navigator.push(context, PageRouteBuilder(
                    pageBuilder: (_, __, ___) => AmortizationScreen(
                            loanAmount: r.financedAmount,
                            annualRate: r.effectiveRate,
                            termMonths: r.termMonths,
                            downPayment: r.downPayment,
                            isBiWeekly: p.isBiWeekly,),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration: const Duration(milliseconds: 250),
                  ));
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
                title: l10n.appNameUS,
                currencySymbol: '\$',
                loanAmount: r.financedAmount,
                annualRate: r.effectiveRate,
                termMonths: r.termMonths,
                downPayment: r.downPayment,
                summary: [
                  MapEntry(l10n.vehiclePrice,   '\$${r.vehiclePrice.toStringAsFixed(2)}'),
                  if (r.tradeInValue > 0)
                    MapEntry(l10n.tradeInValue, '-\$${r.tradeInValue.toStringAsFixed(2)}'),
                  MapEntry(l10n.downPayment,    '\$${r.downPayment.toStringAsFixed(2)}'),
                  if (r.dealerFees > 0)
                    MapEntry(l10n.dealerFees,   '\$${r.dealerFees.toStringAsFixed(2)}'),
                  MapEntry(l10n.taxAmount,      '\$${r.taxAmount.toStringAsFixed(2)}'),
                  MapEntry(l10n.financedAmount, '\$${r.financedAmount.toStringAsFixed(2)}'),
                  MapEntry(l10n.annualRate,     '${r.annualRate.toStringAsFixed(2)}%'),
                  MapEntry(l10n.effectiveRate,  '${r.effectiveRate.toStringAsFixed(2)}%'),
                  MapEntry(l10n.termMonths,     '${r.termMonths} mo'),
                  MapEntry(p.isBiWeekly ? l10n.biWeeklyPayment : l10n.monthlyPayment,
                      '\$${r.displayPayment.toStringAsFixed(2)}'),
                  if (p.isBiWeekly)
                    MapEntry('${l10n.monthlyPayment} (equiv.)',
                        '\$${r.monthlyPayment.toStringAsFixed(2)}'),
                ],
              );
              AnalyticsService.instance.logPdfExported('us');
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export PDF'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(context, PageRouteBuilder(
                    pageBuilder: (_, __, ___) => EarlyPayoffScreen(
                        loanAmount: r.financedAmount,
                        annualRate: r.effectiveRate,
                        termMonths: r.termMonths,
                        flavor: 'us',),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration: const Duration(milliseconds: 250),
                  ));
            },
            icon: const Icon(Icons.rocket_launch_outlined),
            label: const Text('Early Payoff'),
          ),
        ] else ...[
          PremiumGate(adService: adService, flavor: 'us'),
        ],
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

  double _residualPercent  = 50.0;
  double _moneyFactor      = 0.00175; // ~4.2% ÷ 2400
  double _capCostReduction = 0;
  double _acquisitionFee   = 795;
  int    _leaseTerm        = 36;

  USLeaseCalculation? _lease;

  void _calculate() {
    setState(() {
      _lease = USLeaseCalculation.calculate(
        vehiclePrice:    widget.p.vehiclePrice,
        downPayment:     widget.p.downPayment,
        capCostReduction: _capCostReduction,
        acquisitionFee:  _acquisitionFee,
        residualPercent: _residualPercent,
        moneyFactor:     _moneyFactor,
        leaseTerm:       _leaseTerm,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final r   = widget.p.result;

    return SectionCard(
      title: 'Lease vs Buy Comparison',
      children: [
        Row(children: [
          Switch(value: _expanded, onChanged: (v) => setState(() => _expanded = v)),
          const Expanded(child: Text('Show Lease vs Buy')),
        ]),
        if (_expanded) ...[
          const SizedBox(height: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Residual Value %'),
              Text('${_residualPercent.toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold)),
            ]),
            Slider(
              value: _residualPercent,
              min: 30, max: 70, divisions: 40,
              onChanged: (v) => setState(() => _residualPercent = v),
            ),
          ]),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: (_moneyFactor * 2400).toStringAsFixed(2),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Equivalent Annual Rate % (÷2400 = money factor)',
              border: OutlineInputBorder(),
              isDense: true,
              suffixText: '%',
            ),
            onChanged: (v) {
              final rate = double.tryParse(v);
              if (rate != null && rate > 0) setState(() => _moneyFactor = rate / 2400);
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _capCostReduction.toStringAsFixed(0),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cap Cost Reduction (\$)',
              border: OutlineInputBorder(),
              isDense: true,
              prefixText: '\$ ',
            ),
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null && val >= 0) setState(() => _capCostReduction = val);
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _acquisitionFee.toStringAsFixed(0),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Acquisition Fee (\$)',
              border: OutlineInputBorder(),
              isDense: true,
              prefixText: '\$ ',
            ),
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null && val >= 0) setState(() => _acquisitionFee = val);
            },
          ),
          const SizedBox(height: 12),
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
                  color: selected ? Colors.white : Theme.of(context).colorScheme.primary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                side: selected
                    ? BorderSide.none
                    : BorderSide(color: Theme.of(context).colorScheme.primary),
                onSelected: (_) => setState(() => _leaseTerm = mo),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.compare),
            label: const Text('Compare'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
          ),
          if (_lease != null && r != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            _USComparisonCard(
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

class _USComparisonCard extends StatelessWidget {
  final NumberFormat fmt;
  final USLeaseCalculation lease;
  final double buyMonthly;
  final int buyTermMonths;
  final int leaseTermMonths;

  const _USComparisonCard({
    required this.fmt,
    required this.lease,
    required this.buyMonthly,
    required this.buyTermMonths,
    required this.leaseTermMonths,
  });

  @override
  Widget build(BuildContext context) {
    final buyTotalOverLeaseTerm = buyMonthly * leaseTermMonths;
    final diff      = lease.totalLeaseCost - buyTotalOverLeaseTerm;
    final leaseWins = diff < 0;
    final absDiff   = diff.abs();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
          child: _USColumn(
            label: 'Lease ($leaseTermMonths mo)',
            monthly: fmt.format(lease.monthlyLease),
            total: fmt.format(lease.totalLeaseCost),
            highlight: leaseWins,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _USColumn(
            label: 'Buy ($buyTermMonths mo)',
            monthly: fmt.format(buyMonthly),
            total: fmt.format(buyTotalOverLeaseTerm),
            highlight: !leaseWins,
            footnote: 'over $leaseTermMonths mo',
          ),
        ),
      ]),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          leaseWins
              ? 'Lease saves ${fmt.format(absDiff)} over $leaseTermMonths months'
              : 'Buy saves ${fmt.format(absDiff)} over $leaseTermMonths months',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Adj cap cost: ${fmt.format(lease.adjCapCost)}  ·  '
        'Residual: ${fmt.format(lease.residualValue)}',
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
    ]);
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: highlight
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
          width: highlight ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(monthly, style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: color, fontWeight: FontWeight.bold)),
        Text('/month', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
        const SizedBox(height: 4),
        Text('Total: $total',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
        if (footnote != null)
          Text(footnote!, style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]),
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
    _balanceCtrl     = TextEditingController(text: r.financedAmount.toStringAsFixed(0));
    _currentRateCtrl = TextEditingController(text: r.effectiveRate.toStringAsFixed(2));
    _moRemainingCtrl = TextEditingController(text: r.termMonths.toString());
    _newRateCtrl     = TextEditingController(text: (r.effectiveRate - 1).clamp(0, 30).toStringAsFixed(2));
    _newTermCtrl     = TextEditingController(text: r.termMonths.toString());
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
    final balance     = double.tryParse(_balanceCtrl.text) ?? 0;
    final currentRate = double.tryParse(_currentRateCtrl.text) ?? 0;
    final moRemaining = int.tryParse(_moRemainingCtrl.text) ?? 0;
    final newRate     = double.tryParse(_newRateCtrl.text) ?? 0;
    final newTerm     = int.tryParse(_newTermCtrl.text) ?? 0;

    if (balance <= 0 || moRemaining <= 0 || newTerm <= 0) return;

    setState(() {
      _refi = USRefiCalculation.calculate(
        currentBalance:          balance,
        currentRate:             currentRate,
        currentMonthsRemaining:  moRemaining,
        newRate:                 newRate,
        newTermMonths:           newTerm,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return SectionCard(
      title: 'Refi Calculator',
      children: [
        Row(children: [
          Switch(value: _expanded, onChanged: (v) => setState(() => _expanded = v)),
          const Expanded(child: Text('Show Refinancing Calculator')),
        ]),
        if (_expanded) ...[
          const SizedBox(height: 12),
          _RefiField(controller: _balanceCtrl, label: 'Current remaining balance (\$)'),
          const SizedBox(height: 8),
          _RefiField(controller: _currentRateCtrl, label: 'Current rate (%)', suffix: '%'),
          const SizedBox(height: 8),
          _RefiField(controller: _moRemainingCtrl, label: 'Months remaining', suffix: 'mo'),
          const SizedBox(height: 8),
          _RefiField(controller: _newRateCtrl, label: 'New rate (%)', suffix: '%'),
          const SizedBox(height: 8),
          _RefiField(controller: _newTermCtrl, label: 'New term (months)', suffix: 'mo'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.refresh),
            label: const Text('Calculate Refi'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
          ),
          if (_refi != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            ResultTile(
              label: 'Current monthly payment',
              value: fmt.format(_refi!.currentMonthly),
            ),
            ResultTile(
              label: 'New monthly payment',
              value: fmt.format(_refi!.newMonthly),
            ),
            ResultTile(
              label: 'Monthly savings',
              value: fmt.format(_refi!.monthlySavings),
              isHighlight: _refi!.monthlySavings > 0,
            ),
            ResultTile(
              label: 'Total interest saved',
              value: fmt.format(_refi!.totalInterestSavings),
            ),
            if (_refi!.breakevenMonths > 0)
              ResultTile(
                label: 'Breakeven',
                value: '${_refi!.breakevenMonths} months',
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _refi!.isWorthIt
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(
                  _refi!.isWorthIt ? Icons.thumb_up_outlined : Icons.thumb_down_outlined,
                  color: _refi!.isWorthIt
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  _refi!.isWorthIt ? 'Worth it — saves money overall' : 'Not worth it — costs more overall',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ]),
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

  const _RefiField({required this.controller, required this.label, this.suffix});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
        isDense: true,
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

  double _annualMiles  = 15000;
  double _mpg          = 28;
  double _gasPrice     = 3.50;
  double _annualIns    = 1400;
  double _annualMaint  = 800;

  USTcoCalculation? _tco;

  void _calculate() {
    final r = widget.p.result!;
    setState(() {
      _tco = USTcoCalculation.calculate(
        annualMiles:       _annualMiles,
        mpg:               _mpg,
        gasPricePerGallon: _gasPrice,
        annualInsurance:   _annualIns,
        annualMaintenance: _annualMaint,
        termMonths:        r.termMonths,
        totalInterest:     r.totalInterest,
        vehiclePrice:      r.vehiclePrice,
        tradeInValue:      r.tradeInValue,
        downPayment:       r.downPayment,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt  = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final fmt2 = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final r    = widget.p.result!;
    final termYears = r.termMonths ~/ 12;

    return SectionCard(
      title: 'Total Cost of Ownership',
      children: [
        Row(children: [
          Switch(value: _expanded, onChanged: (v) => setState(() => _expanded = v)),
          const Expanded(child: Text('Calculate true ownership cost')),
        ]),
        if (_expanded) ...[
          const SizedBox(height: 12),
          _USTcoRow(
            label: 'Annual miles driven',
            value: _annualMiles,
            min: 3000, max: 40000, step: 1000,
            display: '${_annualMiles.toStringAsFixed(0)} mi',
            onChanged: (v) => setState(() => _annualMiles = v),
          ),
          const SizedBox(height: 8),
          _USTcoRow(
            label: 'MPG',
            value: _mpg,
            min: 10, max: 60, step: 1,
            display: '${_mpg.toStringAsFixed(0)} mpg',
            onChanged: (v) => setState(() => _mpg = v),
          ),
          const SizedBox(height: 8),
          _USTcoRow(
            label: 'Gas price (\$/gal)',
            value: _gasPrice,
            min: 1.50, max: 6.00, step: 0.10,
            display: fmt2.format(_gasPrice),
            onChanged: (v) => setState(() => _gasPrice = v),
          ),
          const SizedBox(height: 8),
          _USTcoRow(
            label: 'Annual insurance (\$)',
            value: _annualIns,
            min: 400, max: 5000, step: 100,
            display: fmt.format(_annualIns),
            onChanged: (v) => setState(() => _annualIns = v),
          ),
          const SizedBox(height: 8),
          _USTcoRow(
            label: 'Annual maintenance (\$)',
            value: _annualMaint,
            min: 200, max: 3000, step: 100,
            display: fmt.format(_annualMaint),
            onChanged: (v) => setState(() => _annualMaint = v),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calculate TCO'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
          ),
          if (_tco != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            ResultTile(label: 'Net vehicle cost', value: fmt.format(_tco!.netVehicleCost)),
            ResultTile(label: 'Total interest', value: fmt.format(_tco!.totalInterest)),
            ResultTile(label: 'Total gas', value: fmt.format(_tco!.totalGas)),
            ResultTile(label: 'Total insurance', value: fmt.format(_tco!.totalInsurance)),
            ResultTile(label: 'Total maintenance', value: fmt.format(_tco!.totalMaintenance)),
            const Divider(height: 8),
            ResultTile(
              label: 'True cost of owning over $termYears years',
              value: fmt.format(_tco!.grandTotal),
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
    return Row(children: [
      Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
      Text(display, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          )),
      Flexible(
        child: SizedBox(
          width: 120,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min, max: max,
              divisions: ((max - min) / step).round().clamp(1, 500),
              onChanged: (v) => onChanged((v / step).round() * step),
            ),
          ),
        ),
      ),
    ]);
  }
}
