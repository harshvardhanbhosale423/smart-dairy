import 'package:flutter/material.dart';
import 'strings_en.dart';
import 'strings_mr.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String translate(String key) {
    if (locale.languageCode == 'mr') {
      return StringsMr.values[key] ?? StringsEn.values[key] ?? key;
    }
    return StringsEn.values[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'mr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizationExtension on BuildContext {
  String tr(String key) {
    return AppLocalizations.of(this).translate(key);
  }
}

