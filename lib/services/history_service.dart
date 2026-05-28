import 'dart:convert';
import 'package:calcwise_core/calcwise_core.dart' hide SectionCard, ResultTile;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/freemium/freemium_service.dart';

class HistoryService {
  static const _key = 'loan_history';
  final SharedPreferences _prefs;

  HistoryService(this._prefs);

  List<Map<String, dynamic>> getAll() {
    final raw = _prefs.getStringList(_key) ?? [];
    return raw
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList()
        .reversed
        .toList();
  }

  List<Map<String, dynamic>> getFree() =>
      getAll().take(MonetizationConfig.freeHistoryLimit).toList();

  Future<void> add(String country, Map<String, dynamic> data) async {
    var all = getAll().reversed.toList();
    all.add({
      ...data,
      'country': country,
      if (!data.containsKey('timestamp'))
        'timestamp': DateTime.now().toIso8601String(),
    });
    // Freemium gate — FIFO: trim oldest entries when free user exceeds limit
    if (!freemiumService.hasFullAccess &&
        all.length > MonetizationConfig.freeCalculationLimit) {
      all = all
          .skip(all.length - MonetizationConfig.freeCalculationLimit)
          .toList();
    }
    await _prefs.setStringList(_key, all.map((e) => jsonEncode(e)).toList());
  }

  Future<void> clear() async => _prefs.remove(_key);
}
