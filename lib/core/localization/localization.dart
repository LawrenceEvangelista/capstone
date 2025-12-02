import 'dart:convert';
import 'package:flutter/services.dart';

class AppLocalization {
  static final Map<String, Map<String, String>> _translations = {
    'en': {},
    'fil': {},
  };

  static Future<void> loadLocalization(String languageCode) async {
    if (_translations[languageCode]!.isNotEmpty) return;

    try {
      final String jsonString = await rootBundle.loadString(
        'lib/l10n/app_$languageCode.arb',
      );
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      
      // Filter out Flutter metadata keys (those starting with @@)
      jsonMap.forEach((key, value) {
        if (!key.startsWith('@@')) {
          _translations[languageCode]![key] = value.toString();
        }
      });
    } catch (e) {
      print('Error loading localization for $languageCode: $e');
    }
  }

  static String getString(String key, {String languageCode = 'en'}) {
    return _translations[languageCode]?[key] ?? key;
  }

  static Future<String> getStringAsync(String key, {String languageCode = 'en'}) async {
    await loadLocalization(languageCode);
    return getString(key, languageCode: languageCode);
  }

  static Future<void> preloadTranslations(String languageCode) async {
    await loadLocalization(languageCode);
  }
}
