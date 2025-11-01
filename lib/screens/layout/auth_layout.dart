import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:testapp/screens/layout/bottomnav.dart';
import 'package:testapp/screens/auth/login_screen.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream:
          FirebaseAuth.instance.authStateChanges(), // Listen to auth changes
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          // User is logged in, show HomeScreen directly
          return const BottomNav(); // Return HomeScreen directly instead of navigation
        } else {
          // If not logged in, show LoginScreen
          return LoginScreen();
        }
      },
    );
  }
}
