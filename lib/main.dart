import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:testapp/core/firebase/firebase_options.dart';
import 'package:provider/provider.dart';
// 🧠 Providers (state management)
import 'package:testapp/providers/recently_viewed_provider.dart';
import 'package:testapp/providers/localization_provider.dart';
import 'package:testapp/features/favorites/provider/favorites_provider.dart';
// 🖥 Screens
import 'package:testapp/features/auth/presentation/screens/login_screen.dart';
import 'package:testapp/features/auth/presentation/screens/signup_screen.dart';
import 'package:testapp/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:testapp/features/layout/presentation/auth_layout.dart';
import 'package:testapp/features/stories/presentation/screens/story_screen.dart';
import 'package:testapp/features/favorites/presentation/screens/favorites_screen.dart';
// 🧭 Layout
import 'package:testapp/features/layout/presentation/bottomnav.dart';
import 'package:testapp/core/services/auth_service.dart';
import 'package:testapp/features/splash/presentation/screens/splash_screen.dart';

// ✅ Global RouteObserver for detecting route changes
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => RecentlyViewedProvider()),
        ChangeNotifierProvider(create: (_) => LocalizationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationProvider>(
      builder: (context, localizationProvider, _) {
        return MaterialApp(
          title: 'KwentoPinoy',
          debugShowCheckedModeBanner: false,
          locale: localizationProvider.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('fil'),
          ],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
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
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: Color(0xFFFFD93D),
              linearMinHeight: 6,
            ),
            textTheme: const TextTheme(),
          ),
          home: const SplashScreen(),
          navigatorObservers: [routeObserver],
          routes: {
            '/auth': (context) => const AuthLayout(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/login_signup': (context) => const LoginScreen(),
            '/forgot_password': (context) =>
                ForgotPasswordScreen(authService: AuthService()),
            '/home': (context) => const BottomNav(),
            '/favorites': (context) => const FavoritesScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/home') {
              return MaterialPageRoute(
                builder: (context) => const BottomNav(),
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
        );
      },
    );
  }
}
