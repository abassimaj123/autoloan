import 'package:flutter/foundation.dart';

class AdConfig {
  static const bool _debug = kDebugMode;

  // ── Universal test IDs ────────────────────────────────────────────────────
  static const _bannerTest   = 'ca-app-pub-3940256099942544/6300978111';
  static const _interTest    = 'ca-app-pub-3940256099942544/1033173712';
  static const _rewardedTest = 'ca-app-pub-3940256099942544/5224354917';
  static const _appOpenTest  = 'ca-app-pub-3940256099942544/9257395921';
  static const _appIdTest    = 'ca-app-pub-3940256099942544~3347511713';

  // ── Production IDs — TODO: replace before release ─────────────────────────
  static const _bannerCA    = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _bannerUK    = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _bannerUS    = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _interCA     = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _interUK     = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _interUS     = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _rewardedCA  = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _rewardedUK  = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _rewardedUS  = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _appOpenCA   = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _appOpenUK   = 'ca-app-pub-5379540026739666/XXXXXXXXXX';
  static const _appOpenUS   = 'ca-app-pub-5379540026739666/XXXXXXXXXX';

  final String flavor;
  AdConfig(this.flavor);

  String get bannerId   => _debug ? _bannerTest   : (flavor == 'ca' ? _bannerCA   : flavor == 'uk' ? _bannerUK   : _bannerUS);
  String get interId    => _debug ? _interTest    : (flavor == 'ca' ? _interCA    : flavor == 'uk' ? _interUK    : _interUS);
  String get rewardedId => _debug ? _rewardedTest : (flavor == 'ca' ? _rewardedCA : flavor == 'uk' ? _rewardedUK : _rewardedUS);
  String get appOpenId  => _debug ? _appOpenTest  : (flavor == 'ca' ? _appOpenCA  : flavor == 'uk' ? _appOpenUK  : _appOpenUS);

  static String get appId => _debug ? _appIdTest : 'ca-app-pub-5379540026739666~XXXXXXXXXX';
}
