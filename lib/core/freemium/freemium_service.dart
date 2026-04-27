import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final freemiumService = FreemiumService._();

class FreemiumService {
  FreemiumService._();

  static const _keyPremium       = 'is_premium';
  static const _keyRewarded      = 'rewarded_until';
  static const _keyRewardedDay   = 'rewarded_day';
  static const _keyRewardedCount = 'rewarded_count';

  /// Free users see only this many history entries.
  static const int freeHistoryLimit  = 5;
  static const int rewardedMinutes   = 60;
  static const int maxRewardedPerDay = 2;

  late SharedPreferences _prefs;
  Timer? _rewardedExpiry;

  final isPremiumNotifier  = ValueNotifier<bool>(false);
  final isRewardedNotifier = ValueNotifier<bool>(false);

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    isPremiumNotifier.value = _prefs.getBool(_keyPremium) ?? false;
    _refreshRewarded();
  }

  void _refreshRewarded() {
    final s = _prefs.getString(_keyRewarded);
    final active = s != null && DateTime.now().isBefore(DateTime.parse(s));
    isRewardedNotifier.value = active;
    if (active) {
      final expiry   = DateTime.parse(s);
      final remaining = expiry.difference(DateTime.now());
      _rewardedExpiry?.cancel();
      _rewardedExpiry = Timer(remaining, () {
        isRewardedNotifier.value = false;
      });
    } else {
      _rewardedExpiry?.cancel();
    }
  }

  bool get isPremium  => isPremiumNotifier.value;
  bool get isRewarded { _refreshRewarded(); return isRewardedNotifier.value; }

  /// Ads (banner + interstitial) are hidden for Premium and Rewarded users.
  /// Both tiers enjoy an ad-free experience; Premium is permanent, Rewarded lasts 60 min.
  bool get showAds => !isPremium && !isRewarded;

  /// Max history entries visible to free users.
  int get historyLimit => isPremium ? 999999 : freeHistoryLimit;

  int get rewardedMinutesLeft {
    _refreshRewarded();
    if (!isRewardedNotifier.value) return 0;
    final s = _prefs.getString(_keyRewarded)!;
    return DateTime.parse(s)
        .difference(DateTime.now())
        .inMinutes
        .clamp(0, rewardedMinutes);
  }

  /// True if the user may watch a rewarded ad right now:
  ///   no active rewarded session (no extend while active)
  ///   daily cap not reached (max [maxRewardedPerDay] per day)
  bool canWatchRewarded() {
    if (isPremium) return false;
    if (isRewardedNotifier.value) return false;
    return _todayCount() < maxRewardedPerDay;
  }

  int _todayKey() {
    final n = DateTime.now();
    return n.year * 10000 + n.month * 100 + n.day;
  }

  int _todayCount() {
    final savedDay = _prefs.getInt(_keyRewardedDay) ?? -1;
    if (savedDay != _todayKey()) return 0;
    return _prefs.getInt(_keyRewardedCount) ?? 0;
  }

  Future<void> activateRewarded() async {
    if (!canWatchRewarded()) return;
    final today = _todayKey();
    final count = _todayCount();
    await _prefs.setString(
      _keyRewarded,
      DateTime.now()
          .add(const Duration(minutes: rewardedMinutes))
          .toIso8601String(),
    );
    await _prefs.setInt(_keyRewardedDay, today);
    await _prefs.setInt(_keyRewardedCount, count + 1);
    isRewardedNotifier.value = true;
    _rewardedExpiry?.cancel();
    _rewardedExpiry = Timer(const Duration(minutes: rewardedMinutes), () {
      isRewardedNotifier.value = false;
    });
  }

  Future<void> activatePremium() async {
    isPremiumNotifier.value = true;
    await _prefs.setBool(_keyPremium, true);
  }

  /// DEV only — force premium without IAP (remove before release).
  void debugUnlockPremium() {
    if (kDebugMode) activatePremium();
  }
}
