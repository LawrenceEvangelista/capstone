# KwentoPinoy - Bilingual Localization Implementation

## Overview
The KwentoPinoy app now supports complete bilingual UI/UX with English and Tagalog/Filipino (fil) language support. This document outlines the localization infrastructure and how to use it throughout the application.

## Project Structure

### Localization Files

```
lib/
├── l10n/
│   ├── app_en.arb          # English translations (90+ keys)
│   └── app_fil.arb         # Tagalog translations (90+ keys)
├── core/
│   ├── localization/
│   │   └── app_localization.dart    # Localization service class
│   └── widgets/
│       └── language_switcher.dart   # Language switcher UI widget
└── providers/
    └── localization_provider.dart   # State management for language
```

### Supported Languages

- **English (en)** - Default language
- **Tagalog/Filipino (fil)** - Additional language support

## Key Components

### 1. AppLocalization Service (`lib/core/localization/app_localization.dart`)

Static service class providing:
- Translation management for both English and Tagalog
- SharedPreferences persistence for language selection
- 90+ translation keys covering all UI/UX elements

**Static Methods:**
```dart
// Get translated string
String getString(String key, {String languageCode = 'en'})

// Change language (persisted to SharedPreferences)
Future<void> setLanguage(String languageCode)

// Retrieve saved language preference
Future<String> getLanguage()

// Get supported languages list
List<String> get supportedLanguages  // Returns: ['en', 'fil']

// Convert language code to display name
String getLanguageName(String code)  // Returns: 'English' or 'Tagalog'

// Create Locale from language code
Locale getLocale(String languageCode)
```

### 2. LocalizationProvider (`lib/providers/localization_provider.dart`)

Provider for state management using Provider package:
- Manages current active language
- Notifies listeners when language changes
- Integrates with AppLocalization service

**Key Properties/Methods:**
```dart
String get currentLanguage        // Current language code
Locale get locale                 // Current Locale
Future<void> changeLanguage(String languageCode)  // Change & persist language
String translate(String key)      // Get translated string for key
```

### 3. LanguageSwitcher Widget (`lib/core/widgets/language_switcher.dart`)

Reusable UI widget for language selection:
- Displays English/Tagalog toggle buttons
- Highlights selected language
- Integrates with LocalizationProvider

**Usage:**
```dart
LanguageSwitcher(
  primaryColor: Color(0xFFFFD93D),
  accentColor: Color(0xFF8E24AA),
)
```

### 4. ARB Translation Files (`lib/l10n/*.arb`)

**app_en.arb** (English) and **app_fil.arb** (Tagalog) contain 90+ keys:

#### Authentication Keys
- `appTitle` - App name
- `welcomeBack`, `weMissedYou` - Welcome messages
- `email`, `password`, `confirmPassword` - Form fields
- `login`, `signup`, `signupButton` - Authentication buttons
- `continueWithGoogle` - Social login
- `forgotPassword`, `resetPassword`, `sendResetLink` - Password recovery

#### Navigation Keys
- `home`, `dictionary`, `favorites`, `profile`, `settings`

#### Common UI Keys
- `search`, `searchStories`, `categories`, `stories`, `allStories`, `seeAll`
- `loading`, `error`, `tryAgain`
- `save`, `cancel`, `delete`, `add`, `edit`, `close`, `back`, `next`
- `ok`, `yes`, `no`

#### Language & Settings Keys
- `language`, `english`, `tagalog`, `settings`

#### Feature Keys
- `lesson`, `vocabulary`, `quiz`, `narration`, `startQuiz`
- `addToFavorites`, `removeFromFavorites`, `shareStory`
- `yourScore`, `correct`, `incorrect`, `totalQuestions`

#### Message Keys
- `oopsError`, `accountDeleted`, `passwordChanged`, `profileUpdated`
- `noResults`, `noFavorites`

## Integration in main.dart

The app is configured with:

1. **Localization Provider** - Added to MultiProvider
2. **Supported Locales** - English (en) and Filipino (fil)
3. **Locale Binding** - MaterialApp reads locale from LocalizationProvider

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => FavoritesProvider()),
    ChangeNotifierProvider(create: (_) => RecentlyViewedProvider()),
    ChangeNotifierProvider(create: (_) => LocalizationProvider()),
  ],
  child: const MyApp(),
)

// In MaterialApp
MaterialApp(
  locale: localizationProvider.locale,
  supportedLocales: const [
    Locale('en'),
    Locale('fil'),
  ],
  // ... rest of configuration
)
```

## pubspec.yaml Configuration

Added localization generation flag:

```yaml
flutter:
  generate: true  # Enables ARB file processing
```

## Usage Examples

### In Screens/Widgets

**Before Localization:**
```dart
Text('Welcome Back!')
```

**After Localization:**
```dart
final localizationProvider = Provider.of<LocalizationProvider>(context);

Text(localizationProvider.translate('welcomeBack'))
// OR using AppLocalization directly
Text(AppLocalization.getString('welcomeBack', languageCode: 'en'))
```

### Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testapp/providers/localization_provider.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('home')),
      ),
      body: Column(
        children: [
          Text(localization.translate('welcomeBack')),
          ElevatedButton(
            onPressed: () => localization.changeLanguage('fil'),
            child: Text(localization.translate('tagalog')),
          ),
        ],
      ),
    );
  }
}
```

## Adding Language Switcher to Screens

To add the language switcher widget to existing screens (e.g., Profile):

```dart
import 'package:testapp/core/widgets/language_switcher.dart';

// Inside build method:
LanguageSwitcher(
  primaryColor: const Color(0xFFFFD93D),
  accentColor: const Color(0xFF8E24AA),
),
```

## Migration Checklist

To fully migrate a screen to use localization:

- [ ] Import `LocalizationProvider`
- [ ] Get provider instance: `Provider.of<LocalizationProvider>(context)`
- [ ] Replace all hardcoded strings with `provider.translate('key')`
- [ ] Add translation keys to both `app_en.arb` and `app_fil.arb` if new
- [ ] Test both English and Tagalog modes

## Language Persistence

- Language selection is automatically saved to SharedPreferences using key: `selected_language`
- App restarts with the previously selected language
- Defaults to English ('en') if no preference saved

## ARB File Format

Each ARB file follows the Application Resource Bundle specification:

```json
{
  "@@locale": "en",
  "appTitle": "KwentoPinoy",
  "welcomeBack": "Welcome Back!",
  ...
}
```

- `@@locale`: Language code identifier
- Keys should be camelCase
- Values are the translated strings

## Supported Language Codes

| Code | Language | Display Name |
|------|----------|--------------|
| `en` | English | English |
| `fil` | Filipino/Tagalog | Tagalog |

## Dependencies

- **provider** (^6.1.1) - State management
- **shared_preferences** (^2.2.2) - Persist language preference
- **translator** (^1.0.4+1) - Available for dynamic translation if needed

## Next Steps / Future Enhancements

1. **Update All Screens** - Replace hardcoded strings with localized keys
2. **Add More Languages** - Create additional .arb files (e.g., app_es.arb for Spanish)
3. **Localization Unit Tests** - Add tests to verify all keys exist in both languages
4. **RTL Support** - Consider adding support for right-to-left languages
5. **Dynamic Translation** - Explore translator package for runtime translation APIs

## Troubleshooting

### App not responding to language changes
- Ensure screen is wrapped with `Provider.of<LocalizationProvider>(context)`
- Verify LocalizationProvider is in MultiProvider at app root

### Translations not showing
- Check that key exists in both app_en.arb and app_fil.arb
- Verify key spelling (case-sensitive)
- Run `flutter pub get` after adding new keys

### SharedPreferences not persisting language
- Check app has required permissions in AndroidManifest.xml and Info.plist
- Verify `setLanguage()` is awaited properly

## Support

For questions or issues with localization, refer to:
- Flutter Localization: https://flutter.dev/docs/development/accessibility-and-localization/internationalization
- ARB Format: https://github.com/google/app-resource-bundle
- Provider Pattern: https://pub.dev/packages/provider
