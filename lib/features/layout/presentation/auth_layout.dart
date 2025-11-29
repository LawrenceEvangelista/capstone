import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:testapp/features/layout/presentation/bottomnav.dart';
import 'package:testapp/features/auth/presentation/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:testapp/providers/recently_viewed_provider.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream:
          FirebaseAuth.instance.authStateChanges(), // Listen to auth changes
      builder: (context, snapshot) {
        print('🔍 AuthLayout - StreamBuilder state: ${snapshot.connectionState}');
        print('🔍 AuthLayout - Has data: ${snapshot.hasData}');
        if (snapshot.hasData) {
          print('🔍 AuthLayout - User authenticated: ${snapshot.data?.email}');
          
          // ✅ Initialize recently viewed provider with current user
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              final recentlyViewedProvider = Provider.of<RecentlyViewedProvider>(context, listen: false);
              recentlyViewedProvider.setCurrentUserId(snapshot.data?.uid);
            }
          });
        } else {
          print('🔍 AuthLayout - No user authenticated');
          
          // ✅ Clear user ID for logged out state
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              final recentlyViewedProvider = Provider.of<RecentlyViewedProvider>(context, listen: false);
              recentlyViewedProvider.setCurrentUserId(null);
            }
          });
        }
        
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
          return const LoginScreen();
        }
      },
    );
  }
}
