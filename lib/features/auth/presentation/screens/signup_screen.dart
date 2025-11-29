import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart'; // Added for animations
import 'package:testapp/core/services/auth_service.dart';
import 'package:testapp/features/layout/presentation/bottomnav.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import FontAwesomeIcons
import 'package:testapp/core/widgets/language_switcher.dart';
import 'package:provider/provider.dart';
import 'package:testapp/providers/localization_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  File? _profileImage;
  final picker = ImagePicker();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String errorMessage = '';
  final AuthService _authService = AuthService();

  // Consistent app colors - using theme colors
  final Color _primaryColor = const Color(0xFFFFD93D); // Mustard yellow (consistent primary)
  final Color _accentColor = const Color(0xFF8E24AA); // Purple accent

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        errorMessage = '';
      });
      try {
        UserCredential userCredential = await _authService.createAccount(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // After successful account creation, update the username/displayName
        User? user = userCredential.user;
        if (user != null) {
          final username = _usernameController.text.trim();
          
          // Update Firebase Auth display name
          await user.updateDisplayName(username);
          
          // Register username in Firestore for login lookup
          try {
            await _authService.registerUsername(
              username: username,
              email: _emailController.text.trim(),
              uid: user.uid,
            );
          } catch (usernameError) {
            print("Warning: Failed to register username in Firestore: $usernameError");
            // Continue with signup even if username registration fails
          }
          
          // Upload profile image if selected
          if (_profileImage != null) {
            try {
              await _authService.uploadProfileImage(
                userId: user.uid, 
                imageFile: _profileImage!
              );
            } catch (e) {
              print("Profile image upload failed: $e");
              // Continue with signup even if image upload fails
            }
          }
        }

        // Use PageRouteBuilder for fade transition
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) => const BottomNav(),
              transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          errorMessage = e.message ?? 'An error occurred during registration';
          _isLoading = false;
        });
        if (context.mounted) {
          _showCartoonishErrorDialog(context, errorMessage);
        }
        print("Signup Error: ${e.message}");
      } catch (e) {
        setState(() {
          errorMessage = 'Failed to register. Please check your connection.';
          _isLoading = false;
        });
        if (context.mounted) {
          _showCartoonishErrorDialog(context, errorMessage);
        }
        print("Signup General Error: $e");
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() {
      _isLoading = true;
      errorMessage = '';
    });
    try {
      await _authService.signInWithGoogle(isSignUp: true);
      // Navigate to home or next screen after successful signup
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
          const BottomNav(),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Google Sign-Up Failed: ${e.toString()}';
        _isLoading = false;
      });
      _showCartoonishErrorDialog(context, errorMessage);
      print("Google Sign-Up Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _profileImage = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  void _showCartoonishErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.error_outline, color: _primaryColor, size: 28),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Oops! Signup Error',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.fredoka(
                  textStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        content: Flexible(
          child: Text(
            errorMessage,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.fredoka(
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
            ),
            child: Text(
              'OK',
              style: GoogleFonts.fredoka(
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFE57F), // Bright yellow top
              Color(0xFFFFD54F), // Golden middle
              Color(0xFFFFC947), // Warm orange bottom
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                  // Language Switcher at top right - Compact design
                  Align(
                    alignment: Alignment.topRight,
                    child: SizedBox(
                      child: LanguageSwitcher(
                        primaryColor: _primaryColor,
                        accentColor: _accentColor,
                        isCompact: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Top decorative elements
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFloatingStars(),
                        SizedBox(width: 20),
                        _buildFloatingStars(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title with animation
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Consumer<LocalizationProvider>(
                      builder: (context, localization, _) => Text(
                        localization.translate('letsGetStarted'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Subtitle with animation
                  FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    duration: const Duration(milliseconds: 600),
                    child: Consumer<LocalizationProvider>(
                      builder: (context, localization, _) => Text(
                        localization.translate('createAccount'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Profile picture selector with animation
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 600),
                    child: Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[200],
                              backgroundImage:
                                  _profileImage != null
                                      ? FileImage(_profileImage!)
                                      : null,
                              child:
                                  _profileImage == null
                                      ? Icon(
                                          Icons.person_outline,
                                          size: 50,
                                          color: Color(0xFF8E24AA),
                                        )
                                      : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: getImage,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFFFA07A),
                                      Color(0xFF8E24AA)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Upload text with animation
                  FadeInDown(
                    delay: const Duration(milliseconds: 300),
                    duration: const Duration(milliseconds: 600),
                    child: Center(
                      child: Text(
                        'Upload profile picture',
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Username field with animation
                  FadeInDown(
                    delay: const Duration(milliseconds: 400),
                    duration: const Duration(milliseconds: 600),
                    child: Consumer<LocalizationProvider>(
                      builder: (context, localization, _) => _buildTextField(
                        controller: _usernameController,
                        label: localization.translate('username'),
                        hint: localization.translate('yourAwesomeName'),
                        icon: Icons.person_rounded,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localization.translate('pleaseEnterUsername');
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Email field with animation
                  FadeInDown(
                    delay: const Duration(milliseconds: 500),
                    duration: const Duration(milliseconds: 600),
                    child: Consumer<LocalizationProvider>(
                      builder: (context, localization, _) => _buildTextField(
                        controller: _emailController,
                        label: localization.translate('email'),
                        hint: localization.translate('emailExample'),
                        icon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localization.translate('pleaseEnterEmail');
                          }
                          if (!RegExp(
                            r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$',
                          ).hasMatch(value)) {
                            return localization.translate('invalidEmailFormat');
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Password field with animation
                  FadeInDown(
                    delay: const Duration(milliseconds: 600),
                    duration: const Duration(milliseconds: 600),
                    child: Consumer<LocalizationProvider>(
                      builder: (context, localization, _) => _buildPasswordField(
                        controller: _passwordController,
                        label: localization.translate('password'),
                        hint: '••••••••',
                        isVisible: _isPasswordVisible,
                        onVisibilityToggle: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localization.translate('pleaseEnterPassword');
                          }
                          if (value.length < 6) {
                            return localization.translate('passwordMinChars');
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Confirm Password field with animation
                  FadeInDown(
                    delay: const Duration(milliseconds: 700),
                    duration: const Duration(milliseconds: 600),
                    child: Consumer<LocalizationProvider>(
                      builder: (context, localization, _) => _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: localization.translate('confirmPassword'),
                        hint: '••••••••',
                        isVisible: _isConfirmPasswordVisible,
                        onVisibilityToggle: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localization.translate('pleaseEnterPassword');
                          }
                          if (value != _passwordController.text) {
                            return localization.translate('passwordsDontMatch');
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  // Show error message if any
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        errorMessage,
                        style: GoogleFonts.fredoka(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Create Account button with animation
                  FadeInDown(
                    delay: const Duration(milliseconds: 800),
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFFA07A).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFA07A),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.how_to_reg_rounded,
                                      size: 24),
                                  SizedBox(width: 12),
                                  Consumer<LocalizationProvider>(
                                    builder: (context, localization, _) => Text(
                                      localization.translate('signupButton'),
                                      style: GoogleFonts.fredoka(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Google Sign-Up Button
                  FadeInDown(
                    delay: const Duration(milliseconds: 900),
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _handleGoogleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        icon: const FaIcon(
                          FontAwesomeIcons.google,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        label: Consumer<LocalizationProvider>(
                          builder: (context, localization, _) => Text(
                            localization.translate('continueWithGoogle'),
                            style: GoogleFonts.fredoka(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Log in link with animation
                  FadeInDown(
                    delay: const Duration(milliseconds: 1000),
                    duration: const Duration(milliseconds: 600),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Consumer<LocalizationProvider>(
                          builder: (context, localization, _) => Text(
                            localization.translate('haveAccount'),
                            style: GoogleFonts.fredoka(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Consumer<LocalizationProvider>(
                          builder: (context, localization, _) => TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            child: Text(
                              localization.translate('login'),
                              style: GoogleFonts.fredoka(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom decorative elements
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSmallStar(),
                        SizedBox(width: 16),
                        _buildSmallStar(),
                        SizedBox(width: 16),
                        _buildSmallStar(),
                      ],
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              prefixIcon: Icon(icon, color: Color(0xFF8E24AA)),
              hintText: hint,
              hintStyle: GoogleFonts.fredoka(
                color: Colors.grey,
              ),
            ),
            style: GoogleFonts.fredoka(fontSize: 16),
          ),
        ),
      ],
    );
  }

  // Helper widget for password fields
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: !isVisible,
            validator: validator,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              prefixIcon: Icon(Icons.lock_rounded,
                  color: Color(0xFF8E24AA)),
              suffixIcon: IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_off : Icons.visibility,
                  color: Color(0xFF8E24AA),
                ),
                onPressed: onVisibilityToggle,
              ),
              hintText: hint,
              hintStyle: GoogleFonts.fredoka(
                color: Colors.grey,
              ),
            ),
            style: GoogleFonts.fredoka(fontSize: 16),
          ),
        ),
      ],
    );
  }

  // Helper widget for floating stars
  Widget _buildFloatingStars() {
    return Column(
      children: [
        Icon(Icons.star_rounded, color: Colors.white, size: 24),
        SizedBox(height: 8),
        Icon(Icons.star_rounded,
            color: Colors.white.withValues(alpha: 0.6), size: 16),
      ],
    );
  }

  // Helper widget for small stars
  Widget _buildSmallStar() {
    return Icon(Icons.star_rounded, color: Colors.white, size: 20);
  }
}
