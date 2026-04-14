import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/ad_config.dart';

/// Manages App Open ads and shows one when the app resumes from background.
/// Register as a [WidgetsBindingObserver] in main().
///
/// Disabled: App Open is too aggressive at first launch.
/// Re-enable by setting [_enabled] to true once UX is validated.
class AppOpenAdManager with WidgetsBindingObserver {
  static const bool _enabled = false;

  final AdConfig _cfg;
  AppOpenAd? _ad;
  DateTime?  _loadTime;
  bool       _isShowing = false;

  AppOpenAdManager(this._cfg);

  /// App Open ads expire after 4 hours.
  bool get _isExpired {
    if (_loadTime == null) return true;
    return DateTime.now().difference(_loadTime!).inHours >= 4;
  }

  /// Pre-load an App Open ad. Call once at startup, then again after each show.
  Future<void> loadAd() async {
    if (!_enabled) return;
    AppOpenAd.load(
      adUnitId: _cfg.appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loadTime = DateTime.now();
        },
        onAdFailedToLoad: (_) => _ad = null,
      ),
    );
  }

  /// Show the ad if one is loaded, not expired, and not already showing.
  Future<void> showAdIfAvailable() async {
    if (!_enabled) return;
    if (_isShowing || _ad == null || _isExpired) {
      if (_ad == null || _isExpired) loadAd(); // reload if needed
      return;
    }
    _isShowing = true;
    _ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        _isShowing = false;
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _ad = null;
        _isShowing = false;
        loadAd();
      },
    );
    await _ad!.show();
  }

  /// Called automatically when the app comes back to foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      showAdIfAvailable();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ad?.dispose();
  }
}
