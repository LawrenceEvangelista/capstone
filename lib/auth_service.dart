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
// Fixed Google Sign In method
  Future<UserCredential> signInWithGoogle({bool isSignUp = false}) async {
    try {
      // First, sign out from previous session to ensure clean state
      await _googleSignIn.signOut();

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

      // Sign in with credential - this automatically creates the account if it doesn't exist
      final UserCredential userCredential = await firebaseAuth.signInWithCredential(credential);

      print("Google Sign-In successful! User: ${userCredential.user?.email}");
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("AuthService signInWithGoogle FirebaseAuthException: ${e.code} - ${e.message}");
      await _googleSignIn.signOut(); // Clean up on error
      rethrow;
    } catch (e) {
      print("AuthService signInWithGoogle error: $e");
      await _googleSignIn.signOut(); // Clean up on error
      rethrow;
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
      await firebaseAuth.signOut(); // Sign out from Firebase first
      await _googleSignIn.signOut(); // Then sign out from Google
      print("Sign out successful");
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