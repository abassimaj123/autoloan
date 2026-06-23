import 'package:calcwise_core/calcwise_core.dart' hide SectionCard, ResultTile;

/// Firebase Analytics wrapper for AutoLoan.
/// Common events inherited from CalcwiseAnalytics.
/// AutoLoan adds flavor-scoped overrides (ca | uk | us) and app-specific events.
class AnalyticsService extends CalcwiseAnalytics {
  AnalyticsService._() : super(appName: 'AutoLoan');
  static final AnalyticsService instance = AnalyticsService._();

  // ── Lifecycle (flavor-scoped overrides) ───────────────────────────────────

  @override
  Future<void> logAppOpen([String? flavor]) =>
      log('app_open', {if (flavor != null) 'flavor': flavor});

  // ── Calculator (rich params — kept as override) ───────────────────────────

  Future<void> logCalculation({
    required String flavor, // ca | uk | us
    required double vehiclePrice,
    required double ratePct,
    required int termMonths,
  }) => log('calculate', {
    'flavor': flavor,
    'price_bucket': _priceBucket(vehiclePrice),
    'rate_bucket': ratePct < 5
        ? '<5%'
        : ratePct < 10
        ? '5-10%'
        : '>10%',
    'term_months': termMonths,
  });

  Future<void> logSave() => log('calculation_saved');

  // ── History (flavor-scoped overrides) ────────────────────────────────────

  @override
  Future<void> logHistorySaved([String? flavor]) =>
      log('history_saved', {if (flavor != null) 'flavor': flavor});

  @override
  Future<void> logPdfExported([String? flavor]) =>
      log('pdf_exported', {if (flavor != null) 'flavor': flavor});

  // ── App-specific features ─────────────────────────────────────────────────

  Future<void> logCompareUsed(String flavor) =>
      log('compare_used', {'flavor': flavor});

  Future<void> logAmortizationViewed(String flavor) =>
      log('amortization_viewed', {'flavor': flavor});

  Future<void> logEarlyPayoffCalculated({
    required String flavor,
    required int monthsSaved,
  }) => log('early_payoff_calculated', {
    'flavor': flavor,
    'months_saved': monthsSaved,
  });

  Future<void> logAffordabilityChecked({
    required String flavor,
    required String rating, // excellent | good | stretch | caution
  }) => log('affordability_checked', {'flavor': flavor, 'rating': rating});

  // ── Universal events (Phase 2) ────────────────────────────────────────────

  Future<void> logOnboardingComplete() => log('onboarding_complete');
  Future<void> logOnboardingSkipped() => log('onboarding_skipped');
  Future<void> logFirstCalculate() => log('first_calculate');
  Future<void> logDarkModeToggled(bool enabled) =>
      log('dark_mode_toggled', {'enabled': '$enabled'});
  Future<void> logLanguageChanged(String lang) =>
      log('language_changed', {'language': lang});
  Future<void> logShareTapped() => log('share_tapped');
  Future<void> logExportStarted() => log('export_started');
  Future<void> logUpgradeButtonTapped(String source) =>
      log('upgrade_tapped', {'source': source});
  Future<void> logFeatureGated(String feature) =>
      log('feature_gated', {'feature': feature});

  // ── AutoLoan domain events (Phase 2) ──────────────────────────────────────

  Future<void> logCashbackVsAprCalculated() =>
      log('cashback_vs_apr_calculated');
  Future<void> logCompareLoansUsed() => log('compare_loans_used');
  Future<void> logEarlyPayoffCalculatedV2() =>
      log('early_payoff_calculated_v2');
  Future<void> logTotalCostCompared() => log('total_cost_compared');
  Future<void> logRefiCalculatorViewed() => log('refi_calculator_viewed');

  Future<void> logPaywallConverted(String source) =>
      log('paywall_converted', {'source': source});

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _priceBucket(double price) {
    if (price < 15000) return '<15k';
    if (price < 30000) return '15-30k';
    if (price < 50000) return '30-50k';
    if (price < 80000) return '50-80k';
    return '>80k';
  }
}
