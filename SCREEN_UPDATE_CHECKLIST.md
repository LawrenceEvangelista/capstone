# Screen Update Checklist & Examples

This document shows which screens still need localization updates and provides examples for each.

## 📋 Screens Status

### ✅ Already Prepared (Infrastructure)
- `main.dart` - Already configured with LocalizationProvider
- `login_screen.dart` - Ready for localization updates
- `signup_screen.dart` - Ready for localization updates
- `home_screen.dart` - Ready for localization updates
- `profile_screen.dart` - Ready for localization updates (+ can add language switcher)
- All other screens - Ready for localization updates

### 🔄 Priority Screens for Update

| Screen | Priority | Hardcoded Strings | Status |
|--------|----------|-------------------|--------|
| LoginScreen | 🔴 High | 10+ | Ready to update |
| SignupScreen | 🔴 High | 8+ | Ready to update |
| HomeScreen | 🔴 High | 8+ | Ready to update |
| DictionaryScreen | 🟡 Medium | 5+ | Ready to update |
| ProfileScreen | 🔴 High | 10+ | Ready to update |
| FavoritesScreen | 🟡 Medium | 5+ | Ready to update |
| StoryScreen | 🟡 Medium | 8+ | Ready to update |

## 📝 Examples: Converting Screens

### Example 1: Login Screen Update

**File:** `lib/features/auth/presentation/screens/login_screen.dart`

**Current hardcoded strings to replace:**
- `'Log In'`
- `'Welcome back!'`
- `'Email'`
- `'Password'`
- `'Forgot Password?'`
- `'Don't have an account?'`
- `'Create Account'`
- `'Continue with Google'`

**Implementation:**

```dart
import 'package:provider/provider.dart';
import 'package:testapp/providers/localization_provider.dart';

class LoginScreen extends StatefulWidget {
  // ... existing code ...
}

class _LoginScreenState extends State<LoginScreen> {
  // ... existing code ...

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    
    return Scaffold(
      // ... existing scaffold setup ...
      appBar: AppBar(
        title: Text(localization.translate('login')), // Changed from 'Log In'
      ),
      body: Column(
        children: [
          Text(localization.translate('welcomeBack')), // Changed from 'Welcome back!'
          
          // Email field
          TextFormField(
            decoration: InputDecoration(
              labelText: localization.translate('email'), // Changed from 'Email'
              hintText: localization.translate('email'),
            ),
          ),
          
          // Password field
          TextFormField(
            decoration: InputDecoration(
              labelText: localization.translate('password'), // Changed from 'Password'
              hintText: localization.translate('password'),
            ),
          ),
          
          // Forgot password link
          TextButton(
            onPressed: () {},
            child: Text(localization.translate('forgotPassword')), // Changed from 'Forgot Password?'
          ),
          
          // Login button
          ElevatedButton(
            onPressed: () {},
            child: Text(localization.translate('login')), // Changed from 'Log In'
          ),
          
          // Don't have account
          Row(
            children: [
              Text(localization.translate('dontHaveAccount')), // Changed
              TextButton(
                onPressed: () {},
                child: Text(localization.translate('signup')), // Changed from 'Sign Up'
              ),
            ],
          ),
          
          // Google sign in
          ElevatedButton(
            onPressed: () {},
            child: Text(localization.translate('continueWithGoogle')), // Changed
          ),
        ],
      ),
    );
  }
}
```

### Example 2: Profile Screen with Language Switcher

**File:** `lib/features/auth/presentation/screens/profile_screen.dart`

```dart
import 'package:provider/provider.dart';
import 'package:testapp/providers/localization_provider.dart';
import 'package:testapp/core/widgets/language_switcher.dart';

class _ProfileScreenState extends State<ProfileScreen> {
  // ... existing code ...

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(localization.translate('profile')), // Changed from 'My Profile'
      ),
      body: ListView(
        children: [
          // Profile content...
          
          // Add language switcher
          Padding(
            padding: const EdgeInsets.all(24),
            child: LanguageSwitcher(
              primaryColor: _primaryColor,
              accentColor: _accentColor,
            ),
          ),
          
          // Edit profile button
          ListTile(
            title: Text(localization.translate('editProfile')), // Changed
            onTap: () {},
          ),
          
          // Change password button
          ListTile(
            title: Text(localization.translate('changePassword')), // Changed
            onTap: () {},
          ),
          
          // Logout button
          ListTile(
            title: Text(localization.translate('logout')), // Changed
            textColor: Colors.red,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
```

### Example 3: Home Screen Update

**File:** `lib/features/home/presentation/screens/home_screen.dart`

```dart
import 'package:provider/provider.dart';
import 'package:testapp/providers/localization_provider.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('home')), // Changed from 'Home'
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: localization.translate('searchStories'), // Changed
              ),
            ),
            
            // Categories section
            Text(localization.translate('categories')), // Changed from 'Categories'
            // ... categories list ...
            
            // Recent stories section
            Text(localization.translate('recentSearches')), // Changed
            // ... stories list ...
            
            // See all button
            TextButton(
              onPressed: () {},
              child: Text(localization.translate('seeAll')), // Changed from 'See All'
            ),
          ],
        ),
      ),
    );
  }
}
```

### Example 4: Dictionary Screen Update

**File:** `lib/features/dictionary/presentation/screens/dictionary_screen.dart`

```dart
class DictionaryScreen extends StatefulWidget {
  // ... existing code ...
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('dictionary')), // Changed from 'Dictionary'
      ),
      body: Column(
        children: [
          // Search field
          TextField(
            decoration: InputDecoration(
              hintText: localization.translate('search'), // Changed from 'Search'
            ),
          ),
          
          // Words list or error state
          if (_words.isEmpty)
            Center(
              child: Text(localization.translate('noResults')), // Changed
            ),
          else
            ListView.builder(
              itemCount: _words.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(_words[index].word),
                subtitle: Text(_words[index].definition),
              ),
            ),
        ],
      ),
    );
  }
}
```

### Example 5: Favorites Screen Update

**File:** `lib/features/favorites/presentation/screens/favorites_screen.dart`

```dart
class FavoritesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    final favorites = Provider.of<FavoritesProvider>(context).favorites;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('favorites')), // Changed
      ),
      body: favorites.isEmpty
          ? Center(
              child: Text(localization.translate('noFavorites')), // Changed
            )
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(favorites[index].title),
                trailing: IconButton(
                  icon: Icon(Icons.favorite),
                  onPressed: () {},
                  tooltip: localization.translate('removeFromFavorites'), // Changed
                ),
              ),
            ),
    );
  }
}
```

## 🚀 Implementation Strategy

### Phase 1: High Priority (User-Facing)
1. LoginScreen
2. SignupScreen
3. HomeScreen
4. ProfileScreen (+ add language switcher)

### Phase 2: Medium Priority (Feature Screens)
5. DictionaryScreen
6. StoryScreen
7. FavoritesScreen

### Phase 3: Low Priority (Dialogs & Utility)
8. Error dialogs
9. Success messages
10. Toast notifications

## ⚡ Quick Copy-Paste Blocks

### Import Block (Copy to top of file)
```dart
import 'package:provider/provider.dart';
import 'package:testapp/providers/localization_provider.dart';
```

### Get Localization (Copy inside build method)
```dart
final localization = Provider.of<LocalizationProvider>(context);
```

### Text Replacement Pattern
```dart
// Before
Text('Hello World')

// After
Text(localization.translate('helloWorld'))
```

### Button Label Pattern
```dart
// Before
ElevatedButton(
  onPressed: () {},
  child: Text('Click Me'),
)

// After
ElevatedButton(
  onPressed: () {},
  child: Text(localization.translate('clickMe')),
)
```

## ✅ Verification Steps

After updating each screen:

1. **Check for compilation errors**
   ```bash
   flutter analyze
   ```

2. **Test in English**
   - Run app
   - Verify all text displays correctly
   - Check layout hasn't broken

3. **Test in Tagalog**
   - Find language switcher (Profile screen)
   - Switch to Tagalog
   - Verify all text updates
   - Check Tagalog text fits in UI

4. **Test persistence**
   - Switch language to Tagalog
   - Close app completely
   - Reopen app
   - Verify app opens in Tagalog

## 🎯 Success Criteria

For each screen update:
- [ ] All hardcoded strings replaced with `translate()` calls
- [ ] All keys exist in both app_en.arb and app_fil.arb
- [ ] No compilation errors
- [ ] English strings display correctly
- [ ] Tagalog strings display correctly
- [ ] UI layout not broken in either language
- [ ] Language switching works live (no restart needed)

## 📊 Translation Coverage Tracker

Use this to track which screens have been converted:

| Screen | Strings Found | Strings Updated | % Complete | Status |
|--------|---|---|---|---|
| LoginScreen | 10+ | 0 | 0% | ⏳ Not Started |
| SignupScreen | 8+ | 0 | 0% | ⏳ Not Started |
| HomeScreen | 8+ | 0 | 0% | ⏳ Not Started |
| DictionaryScreen | 5+ | 0 | 0% | ⏳ Not Started |
| ProfileScreen | 10+ | 0 | 0% | ⏳ Not Started |
| FavoritesScreen | 5+ | 0 | 0% | ⏳ Not Started |
| StoryScreen | 8+ | 0 | 0% | ⏳ Not Started |

## 💡 Pro Tips

1. **Use Consumer widget for localized buttons** (rebuilds only button, not whole screen)
   ```dart
   Consumer<LocalizationProvider>(
     builder: (context, localization, _) => 
       ElevatedButton(
         child: Text(localization.translate('save')),
       ),
   )
   ```

2. **Use const widgets** where possible for performance
   ```dart
   const LanguageSwitcher(
     primaryColor: Color(0xFFFFD93D),
     accentColor: Color(0xFF8E24AA),
   )
   ```

3. **Test dialogs** - Remember to get localization inside dialog builder
   ```dart
   showDialog(
     context: context,
     builder: (context) {
       final loc = Provider.of<LocalizationProvider>(context);
       return AlertDialog(
         title: Text(loc.translate('title')),
       );
     },
   )
   ```

## 📞 Questions?

Refer to:
- **Main Docs**: `LOCALIZATION.md`
- **Implementation Guide**: `IMPLEMENTATION_GUIDE.md`
- **Available Keys**: `lib/l10n/app_en.arb` and `lib/l10n/app_fil.arb`
