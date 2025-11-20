import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

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

  // Password reset (send email link)
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

  // Upload profile image to Firebase Storage
  Future<String?> uploadProfileImage({required String userId, required File imageFile}) async {
    try {
      print("📸 Starting profile image upload for user: $userId");
      print("📦 File size: ${imageFile.lengthSync() / 1024 / 1024} MB");
      
      final storageRef = FirebaseStorage.instance.ref();
      final profileImagesRef = storageRef.child("profile_images/$userId.jpg");
      
      // Set metadata for better performance
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=3600',
      );
      
      print("⬆️ Uploading to Firebase Storage...");
      // Upload the file with timeout
      final uploadTask = profileImagesRef.putFile(imageFile, metadata);
      
      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print("📤 Upload progress: ${progress.toStringAsFixed(2)}%");
      });
      
      await uploadTask;
      print("✅ Upload complete, fetching download URL...");
      
      // Get the download URL (with timeout)
      String downloadURL = await profileImagesRef
          .getDownloadURL()
          .timeout(Duration(seconds: 30));
      
      print("🔗 Download URL obtained, updating profile...");
      
      // Update the user's photo URL
      await currentUser?.updatePhotoURL(downloadURL);
      
      print("✨ Profile image updated successfully!");
      return downloadURL;
    } catch (e) {
      print("❌ AuthService uploadProfileImage error: $e");
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
      // Re-authenticate user before deleting
      await currentUser?.reauthenticateWithCredential(credential);
      await currentUser?.delete();
      await signOut();
    } catch (e) {
      print("AuthService deleteAccount error: $e");
      rethrow;
    }
  }

  // Reset password with current password (from profile screen)
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
      // Re-authenticate user before updating password
      await currentUser?.reauthenticateWithCredential(credential);
      await currentUser?.updatePassword(newPassword);
    } catch (e) {
      print("AuthService resetPasswordFromCurrentPassword error: $e");
      rethrow;
    }
  }

  // Change email with password verification
  Future<void> changeEmail({
    required String currentEmail,
    required String password,
    required String newEmail,
  }) async {
    try {
      print('📧 [AuthService] Email change initiated');
      print('📧 Current email: $currentEmail');
      print('📧 New email: $newEmail');
      
      if (currentUser == null) {
        throw Exception('No user is currently logged in');
      }
      
      // Step 1: Re-authenticate user before changing email
      print('🔑 [AuthService] Creating email auth credential...');
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentEmail,
        password: password,
      );
      
      print('🔑 [AuthService] Re-authenticating user...');
      await currentUser!.reauthenticateWithCredential(credential);
      print('✅ [AuthService] Re-authentication successful');
      
      // Step 2: Update email
      print('📧 [AuthService] Sending verification email to new address...');
      await currentUser!.verifyBeforeUpdateEmail(newEmail);
      
      print("✨ [AuthService] Verification email sent to $newEmail");
    } catch (e) {
      print("❌ [AuthService] Email change failed: $e");
      rethrow;
    }
  }
}
