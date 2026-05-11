import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Centralized Firebase Analytics wrapper for AutoLoan (CA/UK/US).
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final _fa = FirebaseAnalytics.instance;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> logAppOpen(String flavor) => _log('app_open', {'flavor': flavor});

  Future<void> logTabChanged(String tab) => _log('tab_changed', {'tab': tab});

  // ── Calculator ────────────────────────────────────────────────────────────

  Future<void> logCalculation({
    required String flavor,   // ca | uk | us
    required double vehiclePrice,
    required double ratePct,
    required int    termMonths,
  }) => _log('calculate', {
    'flavor':              flavor,
    'price_bucket':        _priceBucket(vehiclePrice),
    'rate_bucket':         ratePct < 5 ? '<5%' : ratePct < 10 ? '5-10%' : '>10%',
    'term_months':         termMonths,
  });

  // ── History ───────────────────────────────────────────────────────────────

  Future<void> logHistorySaved(String flavor) => _log('history_saved', {
    'flavor': flavor,
  });

  Future<void> logPdfExported(String flavor) => _log('pdf_exported', {
    'flavor': flavor,
  });

  // ── Paywall ───────────────────────────────────────────────────────────────

  Future<void> logPaywallShown(String type) => _log('paywall_shown', {
    'type': type, // soft | hard
  });

  Future<void> logPaywallDismissed() => _log('paywall_dismissed');

  Future<void> logPurchaseStarted() => _log('purchase_started');

  Future<void> logPurchaseCompleted({required String flavor}) async {
    final prices = {'ca': 3.99, 'uk': 2.99, 'us': 2.99};
    final currencies = {'ca': 'CAD', 'uk': 'GBP', 'us': 'USD'};
    await _log('purchase_completed');
    await _fa.logEvent(name: 'purchase', parameters: {
      'currency': currencies[flavor] ?? 'USD',
      'value':    prices[flavor] ?? 2.99,
      'items':    'premium_autoloan_$flavor',
    });
  }

  Future<void> logPurchaseRestored() => _log('purchase_restored');

  Future<void> logPurchaseFailed() => _log('purchase_failed');

  Future<void> logRewardedAdWatched() => _log('rewarded_ad_watched');

  Future<void> logCompareUsed(String flavor) => _log('compare_used', {
    'flavor': flavor,
  });

  Future<void> logAmortizationViewed(String flavor) => _log('amortization_viewed', {
    'flavor': flavor,
  });

  Future<void> logEarlyPayoffCalculated({
    required String flavor,
    required int monthsSaved,
  }) => _log('early_payoff_calculated', {
    'flavor':       flavor,
    'months_saved': monthsSaved,
  });

  Future<void> logAffordabilityChecked({
    required String flavor,
    required String rating, // excellent | good | stretch | caution
  }) => _log('affordability_checked', {
    'flavor': flavor,
    'rating': rating,
  });

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<void> logLanguageChanged(String lang) => _log('language_changed', {
    'language': lang,
  });

  // ── User property ─────────────────────────────────────────────────────────

  Future<void> setUserPremium(bool isPremium) =>
      _fa.setUserProperty(name: 'is_premium', value: isPremium ? 'true' : 'false');


  // ── Error & limit tracking ──────────────────────────────────────────────
  Future<void> logRewardedAdFailed() => _log('rewarded_ad_failed');
  Future<void> logRewardedDailyLimit() => _log('rewarded_daily_limit_reached');
  Future<void> logBannerFailed() => _log('banner_ad_failed');

  // ── Internals ─────────────────────────────────────────────────────────────

  Future<void> _log(String name, [Map<String, Object>? params]) async {
    if (kDebugMode) {
      debugPrint('[Analytics] $name ${params ?? ''}');
      return;
    }
    await _fa.logEvent(
      name: name,
      parameters: {'app_name': 'AutoLoan', ...?params},
    );
  }

  String _priceBucket(double price) {
    if (price < 15000)  return '<15k';
    if (price < 30000)  return '15-30k';
    if (price < 50000)  return '30-50k';
    if (price < 80000)  return '50-80k';
    return '>80k';
  }
}
