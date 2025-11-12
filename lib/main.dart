import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
// 🧠 Providers (state management)
import 'package:testapp/features/favorites/provider/favorites_provider.dart';
import 'package:testapp/features/stories/provider/recently_viewed_provider.dart';
// 🖥 Screens
import 'package:testapp/features/splash/presentation/screens/splash_screen.dart';
import 'package:testapp/features/auth/presentation/screens/login_signup_screen.dart';
import 'package:testapp/features/auth/presentation/screens/login_screen.dart';
import 'package:testapp/features/auth/presentation/screens/signup_screen.dart';
import 'package:testapp/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:testapp/features/layout/presentation/auth_layout.dart';
import 'package:testapp/features/home/presentation/screens/home_screen.dart';
import 'package:testapp/features/stories/presentation/screens/story_screen.dart';
import 'package:testapp/features/favorites/presentation/screens/favorites_screen.dart';
// 🧭 Layout
import 'package:testapp/features/layout/presentation/bottomnav.dart';
import 'package:testapp/core/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => RecentlyViewedProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

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
    return MaterialApp(
      title: 'KwentoPinoy',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        primaryColor: const Color(0xFFFFD93D),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFD93D),
          foregroundColor: Color(0xFF2D2D2D),
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD93D),
            foregroundColor: const Color(0xFF2D2D2D),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFFFFD93D),
          linearMinHeight: 6,
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/auth': (context) => AuthLayout(),
        '/login_signup': (context) => LoginSignupScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/forgot_password': (context) =>
            ForgotPasswordScreen(authService: AuthService()),
        '/home': (context) => BottomNav(),
        '/favorites': (context) => FavoritesScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          return MaterialPageRoute(
            builder: (context) => BottomNav(),
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
    ); // <-- This closes MaterialApp
  }
}