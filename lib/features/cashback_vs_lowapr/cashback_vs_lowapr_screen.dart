import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:calcwise_core/calcwise_core.dart' hide SectionCard, ResultTile;
import '../../l10n/app_localizations.dart';
import '../../widgets/shared_inputs.dart';
import '../../country/ca/ca_provider.dart';
import '../../country/uk/uk_provider.dart';
import '../../country/us/us_provider.dart';

/// Cash-Back vs Low-APR comparator.
///
/// Classic dealer-decision moment:
///   "Take $2 000 cash back at 7 % APR, or 0 % APR financing?"
///
/// Computes both scenarios and renders a side-by-side [ComparisonView]
/// with a winner badge on the lower total cost.
class CashbackVsLowAprScreen extends StatefulWidget {
  final String flavor; // 'us' | 'ca' | 'uk'
  const CashbackVsLowAprScreen({super.key, this.flavor = 'us'});

  @override
  State<CashbackVsLowAprScreen> createState() => _CashbackVsLowAprScreenState();
}

class _CashbackVsLowAprScreenState extends State<CashbackVsLowAprScreen> {
  // Shared inputs
  double _vehiclePrice = 35000;
  double _downPayment = 5000;
  int _termMonths = 60;

  // Scenario A — Cash back + standard APR
  double _cashBack = 2000;
  double _rateA = 7.0;

  // Scenario B — Low APR (often 0 %) + no cash back
  double _rateB = 0.0;

  String get _currencySymbol => widget.flavor == 'uk' ? '£' : '\$';

  @override
  void initState() {
    super.initState();
    // Pre-fill from the main calculator provider so the user sees their own
    // values instead of hardcoded defaults when this screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (widget.flavor) {
        case 'ca':
          final p = context.read<CAProvider>();
          setState(() {
            _vehiclePrice = p.vehiclePrice;
            _downPayment = p.dpAmount;
            _termMonths = p.termMonths;
            _rateA = p.annualRate;
          });
        case 'uk':
          final p = context.read<UKProvider>();
          setState(() {
            _vehiclePrice = p.vehiclePrice;
            _downPayment = p.downPayment;
            _termMonths = p.termMonths;
            _rateA = p.annualRate;
          });
        case 'us':
          final p = context.read<USProvider>();
          setState(() {
            _vehiclePrice = p.vehiclePrice;
            _downPayment = p.downPayment;
            _termMonths = p.termMonths;
            _rateA = p.annualRate;
          });
      }
    });
  }

  _Result _compute(double loan, double aprPct, int n) {
    if (loan <= 0 || n <= 0) {
      return const _Result(monthly: 0, totalInterest: 0, totalCost: 0);
    }
    final r = aprPct / 100 / 12;
    double monthly;
    if (r == 0) {
      monthly = loan / n;
    } else {
      monthly = loan * r * pow(1 + r, n) / (pow(1 + r, n) - 1);
    }
    final totalPaid = monthly * n;
    final interest = totalPaid - loan;
    return _Result(
      monthly: monthly,
      totalInterest: interest,
      totalCost: totalPaid,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Touch l10n so localization gen stays referenced even if unused locally.
    AppLocalizations.of(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final fmt = NumberFormat.currency(
      symbol: _currencySymbol,
      decimalDigits: 2,
    );

    final loanA = (_vehiclePrice - _downPayment - _cashBack).clamp(
      0.0,
      double.infinity,
    );
    final loanB = (_vehiclePrice - _downPayment).clamp(0.0, double.infinity);

    final resA = _compute(loanA, _rateA, _termMonths);
    final resB = _compute(loanB, _rateB, _termMonths);

    final aWins = resA.totalCost <= resB.totalCost;
    final winnerIndex = aWins ? 0 : 1;
    final savings = (resA.totalCost - resB.totalCost).abs();

    final monthlyLabel = isSpanish ? 'Pago mensual' : 'Monthly Payment';
    final interestLabel = isSpanish ? 'Interés total' : 'Total Interest';
    final costLabel = isSpanish ? 'Costo total' : 'Total Cost';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSpanish ? 'Reembolso vs Tasa Baja' : 'Cash-Back vs Low-APR',
        ),
      ),
      body: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionCard(
                      title: isSpanish ? 'Vehículo' : 'Vehicle',
                      children: [
                        CurrencyTextInput(
                          label: isSpanish
                              ? 'Precio del vehículo'
                              : 'Vehicle price',
                          value: _vehiclePrice,
                          symbol: _currencySymbol,
                          helperText: 'e.g. 35 000',
                          onChanged: (v) => setState(() => _vehiclePrice = v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CurrencyTextInput(
                          label: isSpanish ? 'Pago inicial' : 'Down payment',
                          value: _downPayment,
                          symbol: _currencySymbol,
                          helperText: 'e.g. 5 000',
                          onChanged: (v) => setState(() => _downPayment = v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _termChips(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SectionCard(
                      title: isSpanish
                          ? 'Escenario A — Reembolso'
                          : 'Scenario A — Cash-Back',
                      children: [
                        CurrencyTextInput(
                          label: isSpanish
                              ? 'Reembolso en efectivo'
                              : 'Cash-back amount',
                          value: _cashBack,
                          symbol: _currencySymbol,
                          helperText: 'e.g. 2 000',
                          onChanged: (v) => setState(() => _cashBack = v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        RateInputField(
                          label: isSpanish
                              ? 'Tasa anual estándar'
                              : 'Standard APR',
                          value: _rateA,
                          onChanged: (v) => setState(() => _rateA = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SectionCard(
                      title: isSpanish
                          ? 'Escenario B — Tasa Baja'
                          : 'Scenario B — Low APR',
                      children: [
                        RateInputField(
                          label: isSpanish
                              ? 'Tasa promocional'
                              : 'Promotional APR',
                          value: _rateB,
                          onChanged: (v) => setState(() => _rateB = v),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          isSpanish
                              ? 'Sin reembolso — préstamo completo a esta tasa.'
                              : 'No cash-back — full loan at this rate.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ComparisonView(
                      title: isSpanish ? 'Resultados' : 'Results',
                      winnerIndex: winnerIndex,
                      scenarios: [
                        ComparisonScenario(
                          label: isSpanish ? 'A — Reembolso' : 'A — Cash-Back',
                          metrics: {
                            monthlyLabel: fmt.format(resA.monthly),
                            interestLabel: fmt.format(resA.totalInterest),
                            costLabel: fmt.format(resA.totalCost),
                          },
                        ),
                        ComparisonScenario(
                          label: isSpanish ? 'B — Tasa Baja' : 'B — Low APR',
                          metrics: {
                            monthlyLabel: fmt.format(resB.monthly),
                            interestLabel: fmt.format(resB.totalInterest),
                            costLabel: fmt.format(resB.totalCost),
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              aWins
                                  ? (isSpanish
                                        ? 'Reembolso gana — ahorra ${fmt.format(savings)} en total'
                                        : 'Cash-Back wins — saves ${fmt.format(savings)} overall')
                                  : (isSpanish
                                        ? 'Tasa Baja gana — ahorra ${fmt.format(savings)} en total'
                                        : 'Low-APR wins — saves ${fmt.format(savings)} overall'),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isSpanish
                          ? 'Para fines informativos. No es asesoramiento financiero.'
                          : 'For informational purposes only. Not financial advice.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppTextSize.xs,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const CalcwiseAdFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _termChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: const [24, 36, 48, 60, 72, 84].map((mo) {
        final selected = mo == _termMonths;
        return ChoiceChip(
          label: Text('$mo mo'),
          selected: selected,
          onSelected: (_) {
            HapticFeedback.selectionClick();
            setState(() => _termMonths = mo);
          },
        );
      }).toList(),
    );
  }
}

class _Result {
  final double monthly;
  final double totalInterest;
  final double totalCost;
  const _Result({
    required this.monthly,
    required this.totalInterest,
    required this.totalCost,
  });
}
