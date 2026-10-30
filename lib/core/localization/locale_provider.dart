import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'selected_locale_code';
  Locale _locale = const Locale('mr'); // Default to Marathi for local rural dairy comfort

  Locale get locale => _locale;
  bool get isMarathi => _locale.languageCode == 'mr';

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code != null) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (!['en', 'mr'].contains(newLocale.languageCode)) return;
    _locale = newLocale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, newLocale.languageCode);
  }

  Future<void> toggleLocale() async {
    final nextCode = _locale.languageCode == 'mr' ? 'en' : 'mr';
    await setLocale(Locale(nextCode));
  }
}

