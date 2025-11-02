import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:testapp/screens/auth/login_signup_screen.dart';
import 'package:testapp/screens/auth/login_screen.dart';
import 'package:testapp/screens/auth/signup_screen.dart';
import 'package:testapp/screens/home/home_screen.dart';
import 'package:testapp/screens/auth/forgot_password_screen.dart';
import 'package:testapp/screens/layout/auth_layout.dart';
import 'package:testapp/screens/favorites/favorites_provider.dart';
import 'package:testapp/screens/favorites/favorites_screen.dart';
import 'package:testapp/screens/story_screen.dart'; // ✅ Added this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp()); // ✅ Corrected
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();

  // Add a static method to handle locale changes
  static void setLocale(BuildContext context, Locale locale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(locale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FavoritesProvider(),
      child: MaterialApp(
        title: 'KwentoPinoy',
        debugShowCheckedModeBanner: false,
        locale: _locale,
        theme: ThemeData(
          primarySwatch: Colors.amber,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: AuthLayout(), // Start with splash screen
        routes: {
          '/auth': (context) => AuthLayout(),
          '/login_signup': (context) => LoginSignupScreen(),
          '/login': (context) => LoginScreen(),
          '/signup': (context) => SignupScreen(),
          '/home': (context) => HomeScreen(),
          '/favorites': (context) => FavoritesScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/home') {
            return MaterialPageRoute(
              builder: (context) => HomeScreen(),
              settings: settings,
            );
          }
          if (settings.name?.startsWith('/story/') == true) {
            final storyId = settings.name!.split('/')[2];
            return MaterialPageRoute(
              builder: (context) => StoryScreen(storyId: storyId),
              settings: settings,
            );
          }
          return null;
        },
      ),
    );
  }
}
