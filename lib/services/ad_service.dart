import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/config/ad_config.dart';
import '../core/freemium/freemium_service.dart';
import './analytics_service.dart';

class AdService {
  final AdConfig _cfg;
  InterstitialAd? _inter;
  RewardedAd?     _rewarded;

  // ── Interstitial frequency gate ───────────────────────────────────────────
  static const int _calcThreshold  = 8;            // show after every 8 calculations
  static const int _cooldownMinutes = 5;           // 5-minute minimum cooldown
  int       _calcCount      = 0;
  DateTime? _lastInterTime;

  AdService(this._cfg);

  String get bannerId        => _cfg.bannerId;
  bool   get isRewardedReady => _rewarded != null &&
      !freemiumService.isPremium &&
      !freemiumService.isRewarded;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadInter();
    _loadRewarded();
  }

  // ── Interstitial ──────────────────────────────────────────────────────────

  void _loadInter() => InterstitialAd.load(
    adUnitId: _cfg.interId,
    request: const AdRequest(),
    adLoadCallback: InterstitialAdLoadCallback(
      onAdLoaded:       (a) => _inter = a,
      onAdFailedToLoad: (_) => _inter = null,
    ),
  );

  /// Show interstitial immediately (bypasses the calc counter).
  /// Used for explicit trigger points. Calls [onDone] when dismissed or if no ad ready.
  void showInterstitialThen(void Function() onDone) {
    if (freemiumService.isRewarded || freemiumService.isPremium) { onDone(); return; }
    if (_inter == null) { onDone(); return; }
    _lastInterTime = DateTime.now();
    _calcCount = 0;
    _inter!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose(); _inter = null; _loadInter(); onDone();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose(); _inter = null; _loadInter(); onDone();
      },
    );
    _inter!.show();
  }

  /// Call after every completed calculation.
  /// Shows interstitial after [_calcThreshold] calculations with [_cooldownMinutes] cooldown.
  void onCalculation() {
    if (!freemiumService.showAds) return;
    _calcCount++;
    if (_calcCount < _calcThreshold) return;
    if (_lastInterTime != null) {
      final elapsed = DateTime.now().difference(_lastInterTime!).inMinutes;
      if (elapsed < _cooldownMinutes) return;
    }
    if (_inter == null) return;
    _calcCount = 0;
    _lastInterTime = DateTime.now();
    _inter!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) { ad.dispose(); _inter = null; _loadInter(); },
      onAdFailedToShowFullScreenContent: (ad, _) { ad.dispose(); _inter = null; _loadInter(); },
    );
    _inter!.show();
  }

  // ── Rewarded ──────────────────────────────────────────────────────────────

  void _loadRewarded() => RewardedAd.load(
    adUnitId: _cfg.rewardedId,
    request: const AdRequest(),
    rewardedAdLoadCallback: RewardedAdLoadCallback(
      onAdLoaded:       (a) => _rewarded = a,
      onAdFailedToLoad: (_) {
          _rewarded = null;
          AnalyticsService.instance.logRewardedAdFailed();
        },
    ),
  );

  Future<bool> showRewarded() async {
    if (_rewarded == null) return false;
    final completer = Completer<bool>();
    bool earned = false;
    _rewarded!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose(); _rewarded = null; _loadRewarded();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose(); _rewarded = null; _loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    _rewarded!.show(onUserEarnedReward: (ad, reward) {
      earned = true;
    });
    return completer.future;
  }
}
