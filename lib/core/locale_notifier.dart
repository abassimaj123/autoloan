import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends ChangeNotifier {
  static const _keyLang = 'app_language';

  final SharedPreferences _prefs;
  final String flavor;
  Locale _locale;

  LocaleNotifier(this._prefs, this.flavor)
      : _locale = _initLocale(_prefs, flavor);

  static Locale _initLocale(SharedPreferences prefs, String flavor) {
    if (flavor != 'ca') return const Locale('en');
    final saved = prefs.getString(_keyLang);
    if (saved != null) return Locale(saved);
    final deviceLang =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return deviceLang == 'fr' ? const Locale('fr') : const Locale('en');
  }

  Locale get locale  => _locale;
  bool   get isFrench => _locale.languageCode == 'fr';

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    _prefs.setString(_keyLang, locale.languageCode);
    notifyListeners();
  }
}
