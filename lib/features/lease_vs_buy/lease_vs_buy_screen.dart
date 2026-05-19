import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:calcwise_core/calcwise_core.dart' hide SectionCard, ResultTile;
import '../../widgets/shared_inputs.dart';
import '../../widgets/paywall_hard.dart';
import '../../widgets/paywall_soft.dart';
import '../../core/freemium/freemium_service.dart';
import '../../main.dart' show paywallSession;
import '../../services/analytics_service.dart';

class LeaseVsBuyScreen extends StatefulWidget {
  final String flavor; // 'us' | 'ca' | 'uk'
  const LeaseVsBuyScreen({super.key, required this.flavor});

  @override
  State<LeaseVsBuyScreen> createState() => _LeaseVsBuyScreenState();
}

class _LeaseVsBuyScreenState extends State<LeaseVsBuyScreen> {
  // ── Buy inputs ─────────────────────────────────────────────────────────────
  double _msrp = 35000;
  double _buyDown = 5000;
  int _buyTerm = 60;
  double _buyApr = 7.0;
  double _residualPercent = 50.0;
  double _annualInsurance = 1400;

  // ── Lease inputs ───────────────────────────────────────────────────────────
  double _leaseMonthly = 399;
  int _leaseTerm = 36;
  double _leaseDown = 2000;
  double _acquisitionFee = 795;
  double _dispositionFee = 395;
  double _mileageLimit = 12000;
  double _overageCostPerMile = 0.25;
  double _estimatedMiles = 12000;

  _LvBResult? _result;

  String get _sym => widget.flavor == 'uk' ? '£' : '\$';
  String get _distLabel => widget.flavor == 'uk' ? 'km' : 'miles';

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView('lease_vs_buy');
  }

  void _calculate() {
    setState(() {
      _result = _LvBResult.compute(
        msrp: _msrp,
        buyDown: _buyDown,
        buyTerm: _buyTerm,
        buyApr: _buyApr,
        residualPercent: _residualPercent,
        annualInsurance: _annualInsurance,
        leaseMonthly: _leaseMonthly,
        leaseTerm: _leaseTerm,
        leaseDown: _leaseDown,
        acquisitionFee: _acquisitionFee,
        dispositionFee: _dispositionFee,
        mileageLimit: _mileageLimit,
        overageCostPerMile: _overageCostPerMile,
        estimatedMiles: _estimatedMiles,
      );
    });
  }

  Future<void> _checkPaywall() async {
    final trigger = await paywallSession.recordAction();
    if (!mounted) return;
    if (trigger == PaywallTrigger.hard) {
      PaywallHard.show(context);
    } else if (trigger == PaywallTrigger.soft) {
      PaywallSoft.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: _sym, decimalDigits: 2);
    final fmt0 = NumberFormat.currency(symbol: _sym, decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lease vs Buy'),
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: CalcwisePageEntrance(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Results hero ──────────────────────────────────────
                      if (_result != null) ...[
                        _ResultsCard(
                          r: _result!,
                          fmt: fmt,
                          fmt0: fmt0,
                          sym: _sym,
                          leaseTerm: _leaseTerm,
                          buyTerm: _buyTerm,
                          distLabel: _distLabel,
                        ),
                        const SizedBox(height: 8),
                      ],

                      // ── Buy section ───────────────────────────────────────
                      SectionCard(
                        title: 'Buy — Loan Details',
                        children: [
                          CurrencyTextInput(
                            label: 'Vehicle Price (MSRP)',
                            value: _msrp,
                            symbol: _sym,
                            helperText: 'e.g. 35 000',
                            onChanged: (v) => setState(() => _msrp = v),
                          ),
                          const SizedBox(height: 12),
                          CurrencySliderInput(
                            label: 'Down Payment',
                            value: _buyDown,
                            min: 0,
                            max: _msrp * 0.5,
                            step: 500,
                            symbol: _sym,
                            onChanged: (v) => setState(() => _buyDown = v),
                          ),
                          const SizedBox(height: 12),
                          DurationChips(
                            label: 'Loan Term',
                            options: const [24, 36, 48, 60, 72, 84],
                            selected: _buyTerm,
                            onSelected: (v) => setState(() => _buyTerm = v),
                          ),
                          const SizedBox(height: 12),
                          RateInputField(
                            label: 'Interest Rate (APR %)',
                            value: _buyApr,
                            onChanged: (v) => setState(() => _buyApr = v),
                          ),
                          const SizedBox(height: 12),
                          PercentSliderInput(
                            label: 'Residual Value after term (% of MSRP)',
                            value: _residualPercent,
                            min: 20,
                            max: 70,
                            step: 1,
                            decimals: 0,
                            onChanged: (v) =>
                                setState(() => _residualPercent = v),
                          ),
                          const SizedBox(height: 12),
                          CurrencySliderInput(
                            label: 'Annual Insurance Cost',
                            value: _annualInsurance,
                            min: 400,
                            max: 6000,
                            step: 100,
                            symbol: _sym,
                            onChanged: (v) =>
                                setState(() => _annualInsurance = v),
                          ),
                        ],
                      ),

                      // ── Lease section ─────────────────────────────────────
                      SectionCard(
                        title: 'Lease Details',
                        children: [
                          _NumericField(
                            label: 'Monthly Lease Payment',
                            value: _leaseMonthly,
                            prefix: '$_sym ',
                            onChanged: (v) => setState(() => _leaseMonthly = v),
                          ),
                          const SizedBox(height: 12),
                          DurationChips(
                            label: 'Lease Term',
                            options: const [24, 36, 48],
                            selected: _leaseTerm,
                            onSelected: (v) => setState(() => _leaseTerm = v),
                          ),
                          const SizedBox(height: 12),
                          CurrencySliderInput(
                            label: 'Down Payment / Cap Cost Reduction',
                            value: _leaseDown,
                            min: 0,
                            max: 10000,
                            step: 250,
                            symbol: _sym,
                            onChanged: (v) => setState(() => _leaseDown = v),
                          ),
                          const SizedBox(height: 12),
                          CurrencySliderInput(
                            label: 'Acquisition Fee',
                            value: _acquisitionFee,
                            min: 0,
                            max: 2000,
                            step: 50,
                            symbol: _sym,
                            onChanged: (v) =>
                                setState(() => _acquisitionFee = v),
                          ),
                          const SizedBox(height: 12),
                          CurrencySliderInput(
                            label: 'Disposition Fee (at end)',
                            value: _dispositionFee,
                            min: 0,
                            max: 1000,
                            step: 25,
                            symbol: _sym,
                            onChanged: (v) =>
                                setState(() => _dispositionFee = v),
                          ),
                          const SizedBox(height: 12),
                          _NumericField(
                            label: 'Mileage Limit per Year ($_distLabel)',
                            value: _mileageLimit,
                            suffix: _distLabel,
                            onChanged: (v) =>
                                setState(() => _mileageLimit = v),
                          ),
                          const SizedBox(height: 12),
                          _NumericField(
                            label: 'Overage Cost per $_distLabel',
                            value: _overageCostPerMile,
                            prefix: '$_sym ',
                            decimals: 3,
                            onChanged: (v) =>
                                setState(() => _overageCostPerMile = v),
                          ),
                          const SizedBox(height: 12),
                          _NumericField(
                            label: 'Estimated Annual $_distLabel Driven',
                            value: _estimatedMiles,
                            suffix: _distLabel,
                            onChanged: (v) =>
                                setState(() => _estimatedMiles = v),
                          ),
                        ],
                      ),

                      // ── Calculate button ──────────────────────────────────
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          await _checkPaywall();
                          if (!mounted) return;
                          _calculate();
                        },
                        icon: const Icon(Icons.compare_arrows_rounded),
                        label: const Text('Compare Lease vs Buy'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),

                      const SizedBox(height: 16),
                      const CalcwiseAdFooter(),
                      const SizedBox(height: 24),
                    ],
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

// ── Calculation model ──────────────────────────────────────────────────────────

class _LvBResult {
  final double buyMonthly;
  final double buyTotalCost;
  final double buyTotalInterest;
  final double buyInsuranceCost;
  final double leaseTotalCost;
  final double leaseOverageCost;
  final double breakEvenMiles; // miles/yr where lease becomes more expensive
  final bool leaseIsChEaper;
  final double saving;
  final double estimatedAnnualMiles;

  const _LvBResult({
    required this.buyMonthly,
    required this.buyTotalCost,
    required this.buyTotalInterest,
    required this.buyInsuranceCost,
    required this.leaseTotalCost,
    required this.leaseOverageCost,
    required this.breakEvenMiles,
    required this.leaseIsChEaper,
    required this.saving,
    required this.estimatedAnnualMiles,
  });

  factory _LvBResult.compute({
    required double msrp,
    required double buyDown,
    required int buyTerm,
    required double buyApr,
    required double residualPercent,
    required double annualInsurance,
    required double leaseMonthly,
    required int leaseTerm,
    required double leaseDown,
    required double acquisitionFee,
    required double dispositionFee,
    required double mileageLimit,
    required double overageCostPerMile,
    required double estimatedMiles,
  }) {
    // ── Buy monthly payment via standard amortization formula ──────────────
    final principal = (msrp - buyDown).clamp(0.0, double.infinity);
    final monthlyRate = buyApr / 12 / 100;
    double buyMonthly;
    if (monthlyRate == 0 || principal <= 0) {
      buyMonthly = buyTerm > 0 ? principal / buyTerm : 0;
    } else {
      buyMonthly = principal *
          monthlyRate *
          pow(1 + monthlyRate, buyTerm) /
          (pow(1 + monthlyRate, buyTerm) - 1);
    }
    final buyTotalPayments = buyMonthly * buyTerm;
    final buyTotalInterest = (buyTotalPayments - principal).clamp(
      0.0,
      double.infinity,
    );
    // Total buy cost = down + all monthly payments + insurance over term
    // (depreciation is already captured in buy payments; we add insurance separately)
    final buyTermYears = buyTerm / 12;
    final buyInsuranceCost = annualInsurance * buyTermYears;
    final buyTotalCost = buyDown + buyTotalPayments + buyInsuranceCost;

    // ── Lease total cost ───────────────────────────────────────────────────
    // Overage: miles driven beyond limit × overage rate per mile
    final totalLeaseAllowance = mileageLimit * leaseTerm / 12;
    final totalEstimated = estimatedMiles * leaseTerm / 12;
    final overageMiles = (totalEstimated - totalLeaseAllowance).clamp(
      0.0,
      double.infinity,
    );
    final leaseOverageCost = overageMiles * overageCostPerMile;
    final leaseTotalCost = leaseDown +
        acquisitionFee +
        leaseMonthly * leaseTerm +
        dispositionFee +
        leaseOverageCost;

    // ── Break-even mileage ─────────────────────────────────────────────────
    // At what annual mileage does total lease cost equal total buy cost
    // (over the same lease term, ignoring depreciation benefit of buying)?
    // base lease cost (no overage) vs buy-term-scaled cost
    final baseLeaseCost =
        leaseDown + acquisitionFee + leaseMonthly * leaseTerm + dispositionFee;
    final buyOverLeaseTerm =
        buyDown + buyMonthly * leaseTerm + annualInsurance * (leaseTerm / 12);
    // breakEven: baseLeaseCost + overageCostPerMile*(x*leaseTerm/12 - mileageLimit*leaseTerm/12) = buyOverLeaseTerm
    // solve for x (annual miles)
    double breakEvenMiles = -1;
    if (overageCostPerMile > 0 && leaseTerm > 0) {
      final slope = overageCostPerMile * leaseTerm / 12;
      final intercept = baseLeaseCost - overageCostPerMile * totalLeaseAllowance;
      // intercept + slope * x = buyOverLeaseTerm => x = (buyOverLeaseTerm - intercept) / slope
      final x = (buyOverLeaseTerm - intercept) / slope;
      if (x > 0) breakEvenMiles = x;
    }

    final saving = (buyTotalCost - leaseTotalCost).abs();
    final leaseIsChEaper = leaseTotalCost < buyTotalCost;

    return _LvBResult(
      buyMonthly: buyMonthly,
      buyTotalCost: buyTotalCost,
      buyTotalInterest: buyTotalInterest,
      buyInsuranceCost: buyInsuranceCost,
      leaseTotalCost: leaseTotalCost,
      leaseOverageCost: leaseOverageCost,
      breakEvenMiles: breakEvenMiles,
      leaseIsChEaper: leaseIsChEaper,
      saving: saving,
      estimatedAnnualMiles: estimatedMiles,
    );
  }
}

// ── Results card ───────────────────────────────────────────────────────────────

class _ResultsCard extends StatelessWidget {
  final _LvBResult r;
  final NumberFormat fmt;
  final NumberFormat fmt0;
  final String sym;
  final int leaseTerm;
  final int buyTerm;
  final String distLabel;

  const _ResultsCard({
    required this.r,
    required this.fmt,
    required this.fmt0,
    required this.sym,
    required this.leaseTerm,
    required this.buyTerm,
    required this.distLabel,
  });

  @override
  Widget build(BuildContext context) {
    final leaseWins = r.leaseIsChEaper;
    final primary = Theme.of(context).colorScheme.primary;
    final outline = Theme.of(context).colorScheme.outline;

    return SectionCard(
      title: 'Comparison Results',
      children: [
        // ── Side-by-side columns ───────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _CompCol(
                label: 'Buy ($buyTerm mo)',
                total: fmt0.format(r.buyTotalCost),
                highlight: !leaseWins,
                primary: primary,
                outline: outline,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CompCol(
                label: 'Lease ($leaseTerm mo)',
                total: fmt0.format(r.leaseTotalCost),
                highlight: leaseWins,
                primary: primary,
                outline: outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Winner banner ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                leaseWins
                    ? Icons.directions_car_rounded
                    : Icons.payments_rounded,
                color: primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  leaseWins
                      ? 'Leasing saves ${fmt0.format(r.saving)} over $leaseTerm months'
                      : 'Buying saves ${fmt0.format(r.saving)} over $leaseTerm months',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),

        // ── Buy breakdown ──────────────────────────────────────────────────
        Text(
          'Buy Breakdown',
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        ResultTile(
          label: 'Monthly payment',
          value: fmt.format(r.buyMonthly),
        ),
        ResultTile(
          label: 'Total interest paid',
          value: fmt.format(r.buyTotalInterest),
        ),
        ResultTile(
          label: 'Insurance over term',
          value: fmt.format(r.buyInsuranceCost),
        ),
        ResultTile(
          label: 'Total buy cost',
          value: fmt0.format(r.buyTotalCost),
          isHighlight: true,
        ),
        const SizedBox(height: 12),

        // ── Lease breakdown ────────────────────────────────────────────────
        Text(
          'Lease Breakdown',
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        if (r.leaseOverageCost > 0)
          ResultTile(
            label: 'Estimated mileage overage',
            value: fmt.format(r.leaseOverageCost),
          ),
        ResultTile(
          label: 'Total lease cost',
          value: fmt0.format(r.leaseTotalCost),
          isHighlight: true,
        ),

        // ── Break-even mileage ─────────────────────────────────────────────
        if (r.breakEvenMiles > 0) ...[
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 6),
          ResultTile(
            label: 'Break-even annual $distLabel\n(lease = buy cost)',
            value: '${r.breakEvenMiles.toStringAsFixed(0)} $distLabel/yr',
          ),
          Text(
            r.isAboveBreakEven
                ? 'Your mileage exceeds break-even — buying may be cheaper long-term.'
                : 'Your mileage is under break-even — leasing competes well.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],

        const SizedBox(height: 8),
        Text(
          'For informational purposes only. Not financial advice.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

// ── Comparison column widget ───────────────────────────────────────────────────

class _CompCol extends StatelessWidget {
  final String label;
  final String total;
  final bool highlight;
  final Color primary;
  final Color outline;

  const _CompCol({
    required this.label,
    required this.total,
    required this.highlight,
    required this.primary,
    required this.outline,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? primary : Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.smPlus),
      decoration: BoxDecoration(
        border: Border.all(
          color: highlight ? primary : outline,
          width: highlight ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          if (highlight)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'BETTER',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Total',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: color),
          ),
          Text(
            total,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Extension for break-even check ────────────────────────────────────────────

extension on _LvBResult {
  bool get isAboveBreakEven {
    return breakEvenMiles > 0 && estimatedAnnualMiles > breakEvenMiles;
  }
}

// ── Simple numeric text field ──────────────────────────────────────────────────

class _NumericField extends StatefulWidget {
  final String label;
  final double value;
  final String? prefix;
  final String? suffix;
  final int decimals;
  final ValueChanged<double> onChanged;

  const _NumericField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.prefix,
    this.suffix,
    this.decimals = 0,
  });

  @override
  State<_NumericField> createState() => _NumericFieldState();
}

class _NumericFieldState extends State<_NumericField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.value.toStringAsFixed(widget.decimals),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        prefixText: widget.prefix,
        suffixText: widget.suffix,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (s) {
        final cleaned = s.replaceAll(',', '.');
        final v = double.tryParse(cleaned);
        if (v != null && v >= 0) widget.onChanged(v);
      },
    );
  }
}
