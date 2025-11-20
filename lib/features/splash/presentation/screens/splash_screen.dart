import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _checkAuthState() async {
    // Wait for Firebase to initialize and check auth state
    await Future.delayed(const Duration(seconds: 2)); // Minimum splash time
    
    // Check if user is already logged in
    User? user = FirebaseAuth.instance.currentUser;
    
    // Debug logging
    print('🔍 SplashScreen - Checking auth state...');
    print('🔍 Current user: ${user?.email ?? "No user logged in"}');
    print('🔍 User UID: ${user?.uid ?? "No UID"}');
    
    if (mounted) {
      if (user != null) {
        // User is logged in, go to auth layout which will handle the routing
        print('🔍 User is authenticated, navigating to /auth');
        Navigator.pushReplacementNamed(context, '/auth');
      } else {
        // User is not logged in, go to login/signup screen
        print('🔍 User is not authenticated, navigating to /login_signup');
        Navigator.pushReplacementNamed(context, '/login_signup');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE57F),
      body: Stack(
        children: <Widget>[
          Center(child: Image.asset('assets/images/kp_head.png', height: 250)),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Image.asset('assets/images/kp_logo.png', height: 200),
          ),
        ],
      ),
    );
  }
}
