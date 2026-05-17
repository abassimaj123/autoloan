import 'package:flutter/foundation.dart';

class AdConfig {
  static const bool _debug = kDebugMode;

  // ── Universal test IDs (Android) ──────────────────────────────────────────
  static const _bannerTest = 'ca-app-pub-3940256099942544/6300978111';
  static const _interTest = 'ca-app-pub-3940256099942544/1033173712';
  static const _rewardedTest = 'ca-app-pub-3940256099942544/5224354917';
  static const _appOpenTest = 'ca-app-pub-3940256099942544/9257395921';
  static const _appIdTest = 'ca-app-pub-3940256099942544~3347511713';

  // ── Universal test IDs (iOS) ──────────────────────────────────────────────
  // TODO iOS: replace with production iOS ad unit IDs before App Store submission.
  // Not consumed today — only read when activate_ios.sh wires up an iOS build.
  static const _bannerTestIOS = 'ca-app-pub-3940256099942544/2934735716';
  static const _interTestIOS = 'ca-app-pub-3940256099942544/4411468910';
  static const _rewardedTestIOS = 'ca-app-pub-3940256099942544/1712485313';
  static const _appOpenTestIOS = 'ca-app-pub-3940256099942544/5575463023';
  static const _appIdTestIOS = 'ca-app-pub-3940256099942544~1458002511';

  // iOS production unit IDs per flavor — TODO before App Store submission
  static const _banneriOSCA = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _banneriOSUK = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _banneriOSUS = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _interiOSCA = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _interiOSUK = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _interiOSUS = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _rewardediOSCA = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _rewardediOSUK = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _rewardediOSUS = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _appOpeniOSCA = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _appOpeniOSUK = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _appOpeniOSUS = 'ca-app-pub-5379540026739666/XXXXXXXXXX';

  // ── Production IDs — TODO: replace before release ─────────────────────────
  static const _bannerCA = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _bannerUK = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _bannerUS = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _interCA = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _interUK = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _interUS = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _rewardedCA = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _rewardedUK = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _rewardedUS = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _appOpenCA = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _appOpenUK = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _appOpenUS = 'ca-app-pub-5379540026739666/XXXXXXXXXX';

  final String flavor;
  AdConfig(this.flavor);

  String get bannerId => _debug
      ? _bannerTest
      : (flavor == 'ca'
            ? _bannerCA
            : flavor == 'uk'
            ? _bannerUK
            : _bannerUS);
  String get interId => _debug
      ? _interTest
      : (flavor == 'ca'
            ? _interCA
            : flavor == 'uk'
            ? _interUK
            : _interUS);
  String get rewardedId => _debug
      ? _rewardedTest
      : (flavor == 'ca'
            ? _rewardedCA
            : flavor == 'uk'
            ? _rewardedUK
            : _rewardedUS);
  String get appOpenId => _debug
      ? _appOpenTest
      : (flavor == 'ca'
            ? _appOpenCA
            : flavor == 'uk'
            ? _appOpenUK
            : _appOpenUS);

  // iOS getters — only consumed if/when activate_ios.sh is run. Currently dead code on Android.
  String get banneriOSId => _debug
      ? _bannerTestIOS
      : (flavor == 'ca'
            ? _banneriOSCA
            : flavor == 'uk'
            ? _banneriOSUK
            : _banneriOSUS);
  String get interiOSId => _debug
      ? _interTestIOS
      : (flavor == 'ca'
            ? _interiOSCA
            : flavor == 'uk'
            ? _interiOSUK
            : _interiOSUS);
  String get rewardediOSId => _debug
      ? _rewardedTestIOS
      : (flavor == 'ca'
            ? _rewardediOSCA
            : flavor == 'uk'
            ? _rewardediOSUK
            : _rewardediOSUS);
  String get appOpeniOSId => _debug
      ? _appOpenTestIOS
      : (flavor == 'ca'
            ? _appOpeniOSCA
            : flavor == 'uk'
            ? _appOpeniOSUK
            : _appOpeniOSUS);

  static String get appId =>
      _debug ? _appIdTest : 'ca-app-pub-5379540026739666~XXXXXXXXXX';
  static String get appIdIOS =>
      _debug ? _appIdTestIOS : 'ca-app-pub-5379540026739666~XXXXXXXXXX';

  // Interstitial/rewarded thresholds — shared across all flavors
  static const int calcThreshold = 8;
  static const int cooldownMinutes = 5;
}
