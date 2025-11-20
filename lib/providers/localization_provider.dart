import 'package:flutter/material.dart';
import 'package:testapp/core/localization/app_localization.dart';

class LocalizationProvider extends ChangeNotifier {
  late String _currentLanguage;

  LocalizationProvider() {
    _currentLanguage = 'en'; // Default to English
    _initializeLanguage();
  }

  Future<void> _initializeLanguage() async {
    _currentLanguage = await AppLocalization.getLanguage();
    notifyListeners();
  }

  String get currentLanguage => _currentLanguage;

  Locale get locale => AppLocalization.getLocale(_currentLanguage);

  Future<void> changeLanguage(String languageCode) async {
    if (AppLocalization.supportedLanguages.contains(languageCode)) {
      _currentLanguage = languageCode;
      await AppLocalization.setLanguage(languageCode);
      notifyListeners();
    }
  }

  String translate(String key) {
    return AppLocalization.getString(key, languageCode: _currentLanguage);
  }
}
