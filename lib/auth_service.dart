import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  // Email & Password Sign In
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print("AuthService signIn error: $e");
      rethrow; // Rethrow to handle in UI
    }
  }

  // Google Sign In
  // In auth_service.dart
  Future<UserCredential> signInWithGoogle({bool isSignUp = false}) async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If sign in was canceled by user
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'google-sign-in-canceled',
          message: 'Google sign in was canceled by the user',
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Check if this user exists in Firebase already
      try {
        final userMethods = await firebaseAuth.fetchSignInMethodsForEmail(googleUser.email);
        final isNewUser = userMethods.isEmpty;

        // If it's a login attempt but user doesn't exist
        if (!isSignUp && isNewUser) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No user found for this Google account. Please sign up first.',
          );
        }

        // If it's a signup attempt but user exists
        if (isSignUp && !isNewUser) {
          throw FirebaseAuthException(
            code: 'account-exists',
            message: 'An account already exists with this email. Please log in instead.',
          );
        }
      } catch (e) {
        if (e is FirebaseAuthException) {
          rethrow;
        }
        // Continue if error checking methods (likely means new user)
      }

      // Once signed in, return the UserCredential
      return await firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      print("AuthService signInWithGoogle error: $e");
      rethrow; // Rethrow to handle in UI
    }
  }

  // Create user with email and password (renamed for consistency)
  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    try {
      return await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print("AuthService createAccount error: $e");
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // Sign out from Google
      await firebaseAuth.signOut(); // Sign out from Firebase
    } catch (e) {
      print("AuthService signOut error: $e");
      rethrow;
    }
  }

  // Password reset
  Future<void> resetPassword({required String email}) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print("AuthService resetPassword error: $e");
      rethrow;
    }
  }

  // Update username
  Future<void> updateUsername({required String username}) async {
    try {
      await currentUser?.updateDisplayName(username);
    } catch (e) {
      print("AuthService updateUsername error: $e");
      rethrow;
    }
  }

  // Delete account
  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await currentUser?.reauthenticateWithCredential(credential);
      await currentUser?.delete();
      await signOut();
    } catch (e) {
      print("AuthService deleteAccount error: $e");
      rethrow;
    }
  }

  // Reset password with current password
  Future<void> resetPasswordFromCurrentPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await currentUser?.reauthenticateWithCredential(credential);
      await currentUser?.updatePassword(newPassword);
    } catch (e) {
      print("AuthService resetPasswordFromCurrentPassword error: $e");
      rethrow;
    }
  }
}