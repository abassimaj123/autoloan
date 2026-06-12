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
  // Not consumed today — only read when activate_ios.sh wires up an iOS build.
  static const _bannerTestIOS = 'ca-app-pub-3940256099942544/2934735716';
  static const _interTestIOS = 'ca-app-pub-3940256099942544/4411468910';
  static const _rewardedTestIOS = 'ca-app-pub-3940256099942544/1712485313';
  static const _appOpenTestIOS = 'ca-app-pub-3940256099942544/5575463023';
  static const _appIdTestIOS = 'ca-app-pub-3940256099942544~1458002511';

  // ── Production IDs injected via --dart-define-from-file=admob.json ──────────
  // Per flavor (ca/uk/us). Blank values fall back to Google TEST ads, so a
  // release build NEVER embeds a 'XXXXXXXXXX' placeholder — at worst it serves
  // Google test ads. Fill admob.json from admob.google.com before shipping.
  // Android
  static const _prodBannerCA = String.fromEnvironment('ADMOB_BANNER_ANDROID_CA');
  static const _prodBannerUK = String.fromEnvironment('ADMOB_BANNER_ANDROID_UK');
  static const _prodBannerUS = String.fromEnvironment('ADMOB_BANNER_ANDROID_US');
  static const _prodInterCA = String.fromEnvironment('ADMOB_INTERSTITIAL_ANDROID_CA');
  static const _prodInterUK = String.fromEnvironment('ADMOB_INTERSTITIAL_ANDROID_UK');
  static const _prodInterUS = String.fromEnvironment('ADMOB_INTERSTITIAL_ANDROID_US');
  static const _prodRewardedCA = String.fromEnvironment('ADMOB_REWARDED_ANDROID_CA');
  static const _prodRewardedUK = String.fromEnvironment('ADMOB_REWARDED_ANDROID_UK');
  static const _prodRewardedUS = String.fromEnvironment('ADMOB_REWARDED_ANDROID_US');
  static const _prodAppOpenCA = String.fromEnvironment('ADMOB_APPOPEN_ANDROID_CA');
  static const _prodAppOpenUK = String.fromEnvironment('ADMOB_APPOPEN_ANDROID_UK');
  static const _prodAppOpenUS = String.fromEnvironment('ADMOB_APPOPEN_ANDROID_US');
  static const _prodAppIdAndroid = String.fromEnvironment('ADMOB_APP_ID_ANDROID');
  // iOS (only consumed when an iOS build is wired up)
  static const _prodBannerIOSCA = String.fromEnvironment('ADMOB_BANNER_IOS_CA');
  static const _prodBannerIOSUK = String.fromEnvironment('ADMOB_BANNER_IOS_UK');
  static const _prodBannerIOSUS = String.fromEnvironment('ADMOB_BANNER_IOS_US');
  static const _prodInterIOSCA = String.fromEnvironment('ADMOB_INTERSTITIAL_IOS_CA');
  static const _prodInterIOSUK = String.fromEnvironment('ADMOB_INTERSTITIAL_IOS_UK');
  static const _prodInterIOSUS = String.fromEnvironment('ADMOB_INTERSTITIAL_IOS_US');
  static const _prodRewardedIOSCA = String.fromEnvironment('ADMOB_REWARDED_IOS_CA');
  static const _prodRewardedIOSUK = String.fromEnvironment('ADMOB_REWARDED_IOS_UK');
  static const _prodRewardedIOSUS = String.fromEnvironment('ADMOB_REWARDED_IOS_US');
  static const _prodAppOpenIOSCA = String.fromEnvironment('ADMOB_APPOPEN_IOS_CA');
  static const _prodAppOpenIOSUK = String.fromEnvironment('ADMOB_APPOPEN_IOS_UK');
  static const _prodAppOpenIOSUS = String.fromEnvironment('ADMOB_APPOPEN_IOS_US');
  static const _prodAppIdIOS = String.fromEnvironment('ADMOB_APP_ID_IOS');

  // Pick the prod value for the active flavor, else fall back to test.
  static String _byFlavor(
    String flavor,
    String ca,
    String uk,
    String us,
    String fallback,
  ) {
    final v = flavor == 'ca'
        ? ca
        : flavor == 'uk'
        ? uk
        : us;
    return v.isNotEmpty ? v : fallback;
  }

  final String flavor;
  AdConfig(this.flavor);

  String get bannerId => _debug
      ? _bannerTest
      : _byFlavor(flavor, _prodBannerCA, _prodBannerUK, _prodBannerUS, _bannerTest);
  String get interId => _debug
      ? _interTest
      : _byFlavor(flavor, _prodInterCA, _prodInterUK, _prodInterUS, _interTest);
  String get rewardedId => _debug
      ? _rewardedTest
      : _byFlavor(
          flavor, _prodRewardedCA, _prodRewardedUK, _prodRewardedUS, _rewardedTest);
  String get appOpenId => _debug
      ? _appOpenTest
      : _byFlavor(
          flavor, _prodAppOpenCA, _prodAppOpenUK, _prodAppOpenUS, _appOpenTest);

  // iOS getters — only consumed if/when activate_ios.sh is run. Currently dead code on Android.
  String get banneriOSId => _debug
      ? _bannerTestIOS
      : _byFlavor(flavor, _prodBannerIOSCA, _prodBannerIOSUK, _prodBannerIOSUS,
          _bannerTestIOS);
  String get interiOSId => _debug
      ? _interTestIOS
      : _byFlavor(flavor, _prodInterIOSCA, _prodInterIOSUK, _prodInterIOSUS,
          _interTestIOS);
  String get rewardediOSId => _debug
      ? _rewardedTestIOS
      : _byFlavor(flavor, _prodRewardedIOSCA, _prodRewardedIOSUK,
          _prodRewardedIOSUS, _rewardedTestIOS);
  String get appOpeniOSId => _debug
      ? _appOpenTestIOS
      : _byFlavor(flavor, _prodAppOpenIOSCA, _prodAppOpenIOSUK,
          _prodAppOpenIOSUS, _appOpenTestIOS);

  static String get appId => _debug
      ? _appIdTest
      : (_prodAppIdAndroid.isNotEmpty ? _prodAppIdAndroid : _appIdTest);
  static String get appIdIOS => _debug
      ? _appIdTestIOS
      : (_prodAppIdIOS.isNotEmpty ? _prodAppIdIOS : _appIdTestIOS);

  // Interstitial/rewarded thresholds — shared across all flavors
  static const int calcThreshold = 3;
  static const int cooldownMinutes = 5;
}
