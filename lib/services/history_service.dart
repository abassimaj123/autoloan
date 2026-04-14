import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  static const _key       = 'loan_history';
  static const _freeLimit = 5;
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

  List<Map<String, dynamic>> getFree() => getAll().take(_freeLimit).toList();

  Future<void> add(String country, Map<String, dynamic> data) async {
    final all = getAll().reversed.toList();
    all.add({...data, 'country': country});
    await _prefs.setStringList(_key, all.map((e) => jsonEncode(e)).toList());
  }

  Future<void> clear() async => _prefs.remove(_key);
}
