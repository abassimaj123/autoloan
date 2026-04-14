import 'package:shared_preferences/shared_preferences.dart';

class TrialService {
  static const _keyInstall  = 'install_date';
  static const _keyRewarded = 'rewarded_until';
  static const trialDays    = 7;
  static const rewardMin    = 60;

  final SharedPreferences _prefs;
  TrialService(this._prefs) { _initInstall(); }

  void _initInstall() {
    if (!_prefs.containsKey(_keyInstall)) {
      _prefs.setString(_keyInstall, DateTime.now().toIso8601String());
    }
  }

  DateTime get _install => DateTime.parse(_prefs.getString(_keyInstall)!);
  bool get isTrialActive  => DateTime.now().difference(_install).inDays < trialDays;
  int  get daysRemaining  => (trialDays - DateTime.now().difference(_install).inDays).clamp(0, trialDays);

  bool get isRewardedActive {
    final s = _prefs.getString(_keyRewarded);
    return s != null && DateTime.now().isBefore(DateTime.parse(s));
  }

  int get rewardedMinutesRemaining {
    final s = _prefs.getString(_keyRewarded);
    if (s == null) return 0;
    return DateTime.parse(s).difference(DateTime.now()).inMinutes.clamp(0, rewardMin);
  }

  bool get hasFullAccess => isTrialActive || isRewardedActive;

  Future<void> activateReward() async => _prefs.setString(
      _keyRewarded,
      DateTime.now().add(const Duration(minutes: rewardMin)).toIso8601String());
}
