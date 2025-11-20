# Bilingual Implementation Guide

## Quick Start: Adding Localization to a Screen

This guide shows how to convert a hardcoded screen to use bilingual localization.

### Step 1: Import Required Packages

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testapp/providers/localization_provider.dart';
```

### Step 2: Update Widget Build Method

**Before:**
```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome Back!'),
      ),
      body: Column(
        children: [
          Text('My Profile'),
          ElevatedButton(
            onPressed: () {},
            child: Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
```

**After:**
```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get localization provider
    final localization = Provider.of<LocalizationProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('welcomeBack')),
      ),
      body: Column(
        children: [
          Text(localization.translate('profile')),
          ElevatedButton(
            onPressed: () {},
            child: Text(localization.translate('logout')),
          ),
        ],
      ),
    );
  }
}
```

### Step 3: Add Missing Keys to ARB Files

If you use a key that doesn't exist in the translation files:

**lib/l10n/app_en.arb:**
```json
{
  "@@locale": "en",
  ...existing keys...,
  "myNewKey": "My English Text"
}
```

**lib/l10n/app_fil.arb:**
```json
{
  "@@locale": "fil",
  ...existing keys...,
  "myNewKey": "Ang Aking Tagalog na Teksto"
}
```

### Available Translation Keys

Below are all 90+ keys available for use:

#### Authentication
| Key | English | Tagalog |
|-----|---------|---------|
| `appTitle` | KwentoPinoy | KwentoPinoy |
| `welcomeBack` | Welcome Back! | Ulit muli! |
| `weMissedYou` | We Missed You! 😊 | Namiss mo kami! 😊 |
| `email` | Email | Email |
| `password` | Password | Password |
| `confirmPassword` | Confirm Password | Kumpirmahin ang Password |
| `login` | Log In | Mag-Login |
| `signup` | Sign Up | Mag-Sign Up |
| `signupButton` | Create Account | Lumikha ng Account |
| `continueWithGoogle` | Continue with Google | Magpatuloy sa Google |
| `dontHaveAccount` | Don't have an account? | Walang account pa? |
| `haveAccount` | Already have an account? | Mayroon na akong account |
| `forgotPassword` | Forgot Password? | Nakalimutan ang Password? |
| `resetPassword` | Reset Password | I-reset ang Password |
| `sendResetLink` | Send Reset Link | Magpadala ng Reset Link |
| `checkEmail` | Check your email for password reset instructions | Tingnan ang iyong email para sa mga tagubilin sa pag-reset ng password |

#### Navigation & Main Features
| Key | English | Tagalog |
|-----|---------|---------|
| `dictionary` | Dictionary | Diksyunaryo |
| `home` | Home | Tahanan |
| `favorites` | Favorite Stories | Mga Paboritong Kuwento |
| `profile` | My Profile | Aking Profil |

#### Search & Browse
| Key | English | Tagalog |
|-----|---------|---------|
| `search` | Search | Maghanap |
| `searchStories` | Search stories... | Maghanap ng mga kuwento... |
| `categories` | Categories | Mga Kategorya |
| `stories` | Stories | Mga Kuwento |
| `allStories` | All Stories | Lahat ng Kuwento |
| `seeAll` | See All | Tingnan Lahat |
| `recentSearches` | Recent Searches | Mga Kamakailang Paghahanap |
| `clearAll` | Clear All | Burahin Lahat |

#### User Feedback
| Key | English | Tagalog |
|-----|---------|---------|
| `noResults` | No results found | Walang resulta na natagpuan |
| `loading` | Loading... | Naglo-load... |
| `error` | Error | Error |
| `tryAgain` | Try Again | Subukan Ulit |
| `oopsError` | Oops! An Error Occurred | Oops! May Error |

#### Common Actions
| Key | English | Tagalog |
|-----|---------|---------|
| `save` | Save | I-save |
| `cancel` | Cancel | Kanselahin |
| `delete` | Delete | Tanggapin |
| `add` | Add | Magdagdag |
| `edit` | Edit | I-edit |
| `close` | Close | Sarado |
| `back` | Back | Bumalik |
| `next` | Next | Susunod |
| `previous` | Previous | Nakaraang |
| `done` | Done | Tapos na |
| `ok` | OK | OK |
| `yes` | Yes | Oo |
| `no` | No | Hindi |

#### Profile & Settings
| Key | English | Tagalog |
|-----|---------|---------|
| `username` | Username | Username |
| `displayName` | Display Name | Pangalan na Ipapakita |
| `uploadPhoto` | Upload Photo | I-upload ang Larawan |
| `selectPhoto` | Select Photo | Piliin ang Larawan |
| `logout` | Log Out | Mag-logout |
| `editProfile` | Edit Profile | I-edit ang Profil |
| `changePassword` | Change Password | Baguhin ang Password |
| `currentPassword` | Current Password | Kasalukuyang Password |
| `newPassword` | New Password | Bagong Password |
| `language` | Language | Wika |
| `english` | English | Ingles |
| `tagalog` | Tagalog | Tagalog |
| `settings` | Settings | Mga Setting |
| `about` | About | Tungkol |
| `privacyPolicy` | Privacy Policy | Patakaran sa Privacy |
| `termsOfService` | Terms of Service | Mga Tuntunin ng Serbisyo |
| `contactUs` | Contact Us | Makipag-ugnayan sa Amin |
| `version` | Version | Bersyon |

#### Features & Learning
| Key | English | Tagalog |
|-----|---------|---------|
| `lesson` | Lesson | Leksyon |
| `vocabulary` | Vocabulary | Bokabularyo |
| `quiz` | Quiz | Quiz |
| `narration` | Narration | Pagkukuwento |
| `startQuiz` | Start Quiz | Simulan ang Quiz |
| `yourScore` | Your Score | Ang Iyong Puntos |
| `correct` | Correct | Tama |
| `incorrect` | Incorrect | Mali |
| `totalQuestions` | Total Questions | Kabuuang Mga Tanong |

#### Stories & Favorites
| Key | English | Tagalog |
|-----|---------|---------|
| `addToFavorites` | Add to Favorites | Idagdag sa Mga Paborito |
| `removeFromFavorites` | Remove from Favorites | Alisin mula sa Mga Paborito |
| `shareStory` | Share Story | Ibahagi ang Kuwento |
| `readMore` | Read More | Basahin pa |
| `noFavorites` | No favorite stories yet | Walang paboritong kuwento pa |

#### Status Messages
| Key | English | Tagalog |
|-----|---------|---------|
| `accountDeleted` | Account successfully deleted | Account ay matagumpay na naalis |
| `passwordChanged` | Password successfully changed | Password ay matagumpay na binago |
| `profileUpdated` | Profile successfully updated | Profil ay matagumpay na i-update |

### Example: Updating Home Screen

**Original home_screen.dart:**
```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: ListView(
        children: [
          Text('Categories'),
          // ... categories list
          Text('Recent Stories'),
          // ... stories list
        ],
      ),
    );
  }
}
```

**Updated home_screen.dart:**
```dart
import 'package:provider/provider.dart';
import 'package:testapp/providers/localization_provider.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('home')),
      ),
      body: ListView(
        children: [
          Text(localization.translate('categories')),
          // ... categories list
          Text(localization.translate('recentSearches')),
          // ... stories list
        ],
      ),
    );
  }
}
```

## Adding Language Switcher to Profile Screen

**In profile_screen.dart:**

```dart
import 'package:testapp/core/widgets/language_switcher.dart';

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    
    return Scaffold(
      // ... existing code ...
      body: ListView(
        children: [
          // ... existing profile content ...
          
          SizedBox(height: 24),
          
          // Add language switcher
          LanguageSwitcher(
            primaryColor: const Color(0xFFFFD93D),
            accentColor: const Color(0xFF8E24AA),
          ),
          
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
```

## Tips & Best Practices

1. **Always use `Provider.of<LocalizationProvider>(context)` or `Consumer` widget** to ensure UI rebuilds on language change

2. **Add keys in both .arb files simultaneously** to avoid missing translations

3. **Use consistent key naming** - follow camelCase for new keys

4. **Test both languages** after each screen update to ensure all strings are translated

5. **Consider pluralization** - For complex plural forms, you may need custom handling beyond simple key lookups

6. **Use const where possible** - Mark widgets/parameters as const for performance:
   ```dart
   const LanguageSwitcher(
     primaryColor: Color(0xFFFFD93D),
     accentColor: Color(0xFF8E24AA),
   )
   ```

## Common Patterns

### Using in Dialogs

```dart
showDialog(
  context: context,
  builder: (context) {
    final localization = Provider.of<LocalizationProvider>(context);
    return AlertDialog(
      title: Text(localization.translate('oopsError')),
      content: Text(localization.translate('tryAgain')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(localization.translate('cancel')),
        ),
      ],
    );
  },
);
```

### Using in Buttons

```dart
ElevatedButton(
  onPressed: () {},
  child: Consumer<LocalizationProvider>(
    builder: (context, localization, _) {
      return Text(localization.translate('addToFavorites'));
    },
  ),
)
```

### Using in Form Labels

```dart
TextFormField(
  decoration: InputDecoration(
    hintText: localization.translate('search'),
    labelText: localization.translate('searchStories'),
  ),
)
```

## Completion Checklist

- [ ] All static text replaced with localization keys
- [ ] Both language options tested in the app
- [ ] Language persists across app restarts
- [ ] Language switcher widget visible to users
- [ ] All new keys added to both .arb files
- [ ] No compilation errors after changes
- [ ] Tested on actual device

## Need Help?

Refer to:
- `LOCALIZATION.md` - Complete localization documentation
- `lib/core/localization/app_localization.dart` - Service implementation
- `lib/providers/localization_provider.dart` - State management
- `lib/l10n/app_en.arb` and `app_fil.arb` - Available keys
