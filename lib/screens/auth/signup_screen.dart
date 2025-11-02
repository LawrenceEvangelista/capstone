import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart'; // Added for animations
import 'package:testapp/services/auth_service.dart';
import '../home/home_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import FontAwesomeIcons

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

  // Cartoonish colors - matching login screen
  final Color _backgroundColor = const Color(0xFFFFF176); // Light yellow
  final Color _primaryColor = const Color(0xFFFF6D00); // Orange
  final Color _accentColor = const Color(0xFF8E24AA); // Purple
  final Color _buttonColor = const Color(0xFFFF9800); // Orange

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (_formKey.currentState!.validate()) {
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
          await user.updateDisplayName(_usernameController.text.trim());
          // If you have a method to upload profile image, call it here
          if (_profileImage != null) {
            // Example: await _authService.uploadProfileImage(user.uid, _profileImage!);
          }
        }

        // Use PageRouteBuilder for fade transition
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => const HomeScreen(),
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
      } on FirebaseAuthException catch (e) {
        setState(() {
          errorMessage = e.message ?? 'An error occurred during registration';
          _isLoading = false;
        });
        _showCartoonishErrorDialog(context, errorMessage);
        print("Signup Error: ${e.message}");
      } catch (e) {
        setState(() {
          errorMessage = 'Failed to register. Please check your connection.';
          _isLoading = false;
        });
        _showCartoonishErrorDialog(context, errorMessage);
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
          const HomeScreen(),
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
            Text(
              'Oops! Signup Error',
              style: GoogleFonts.fredoka(
                textStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          errorMessage,
          style: GoogleFonts.fredoka(
            textStyle: const TextStyle(fontSize: 16),
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
        backgroundColor: _backgroundColor,
        body: Container(
        decoration: BoxDecoration(
        // Optional cartoon background pattern
        image: const DecorationImage(
        image: AssetImage('assets/cartoon_background.png'),
    opacity: 0.1,
    fit: BoxFit.cover,
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
    const SizedBox(height: 20),
    // Title with animation
    FadeInDown(
    duration: const Duration(milliseconds: 600),
    child: Stack(
    alignment: Alignment.center,
    children: [
    // Text shadow effect
    Text(
    'Join The Fun!',
    textAlign: TextAlign.center,
    style: GoogleFonts.fredoka(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    foreground:
    Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..color = Colors.white,
    ),
    ),
    // Main text
    Text(
    'Join The Fun!',
    textAlign: TextAlign.center,
    style: GoogleFonts.fredoka(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    color: _primaryColor,
    ),
    ),
    ],
    ),
    ),

    // Subtitle with animation
    FadeInDown(
    delay: const Duration(milliseconds: 100),
    duration: const Duration(milliseconds: 600),
    child: Text(
    'Create your awesome account 🎉',
    textAlign: TextAlign.center,
    style: GoogleFonts.fredoka(
    fontSize: 18,
    color: Colors.black87,
    ),
    ),
    ),
    const SizedBox(height: 25),

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
    color: Colors.white,
    shape: BoxShape.circle,
    border: Border.all(
    color: _primaryColor,
    width: 3,
    ),
    boxShadow: [
    BoxShadow(
    color: _primaryColor.withOpacity(0.3),
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
    color: _accentColor,
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
    colors: [_buttonColor, _accentColor],
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
    color: _accentColor,
    fontWeight: FontWeight.w500,
    ),
    ),
    ),
    ),
    const SizedBox(height: 25),

    // Username field with animation
    FadeInDown(
    delay: const Duration(milliseconds: 400),
    duration: const Duration(milliseconds: 600),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    children: [
    Icon(
    Icons.person_rounded,
    color: _primaryColor,
    size: 24,
    ),
    const SizedBox(width: 8),
    Text(
    'Username',
    style: GoogleFonts.fredoka(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: _primaryColor,
    ),
    ),
    ],
    ),
    const SizedBox(height: 8),
    Container(
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(25),
    boxShadow: [
    BoxShadow(
    color: Colors.grey.withOpacity(0.2),
    blurRadius: 10,
    offset: const Offset(0, 5),
    ),
    ],
    ),
    child: TextFormField(
    controller: _usernameController,
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'Please enter your username';
    }
    return null;
    },
    decoration: InputDecoration(
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(25),
    borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
    ),
    prefixIcon: Container(
    margin: const EdgeInsets.only(
    left: 15,
    right: 10,
    ),
    child: Icon(
    Icons.badge_rounded,
    color: _accentColor,
    ),
    ),
    hintText: 'Your awesome name',
    hintStyle: GoogleFonts.fredoka(
    color: Colors.grey,
    ),
    ),
    style: GoogleFonts.fredoka(fontSize: 16),
    ),
    ),
    ],
    ),
    ),
    const SizedBox(height: 16),

    // Email field with animation
    FadeInDown(
    delay: const Duration(milliseconds: 500),
    duration: const Duration(milliseconds: 600),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    children: [
    Icon(
    Icons.email_rounded,
    color: _primaryColor,
    size: 24,
    ),
    const SizedBox(width: 8),
    Text(
    'Email',
    style: GoogleFonts.fredoka(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: _primaryColor,
    ),
    ),
    ],
    ),
    const SizedBox(height: 8),
    Container(
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(25),
    boxShadow: [
    BoxShadow(
    color: Colors.grey.withOpacity(0.2),
    blurRadius: 10,
    offset:
    const Offset(0, 5),
    ),
    ],
    ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email';
          }
          if (!RegExp(
            r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$',
          ).hasMatch(value)) {
            return 'Invalid email format';
          }
          return null;
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(
              left: 15,
              right: 10,
            ),
            child: Icon(
              Icons.alternate_email,
              color: _accentColor,
            ),
          ),
          hintText: 'your.email@example.com',
          hintStyle: GoogleFonts.fredoka(
            color: Colors.grey,
          ),
        ),
        style: GoogleFonts.fredoka(fontSize: 16),
      ),
    ),
    ],
    ),
    ),
      const SizedBox(height: 16),

      // Password field with animation
      FadeInDown(
        delay: const Duration(milliseconds: 600),
        duration: const Duration(milliseconds: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lock_rounded,
                  color: _primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Password',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  prefixIcon: Container(
                    margin: const EdgeInsets.only(
                      left: 15,
                      right: 10,
                    ),
                    child: Icon(
                      Icons.vpn_key_rounded,
                      color: _accentColor,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: _accentColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  hintText: '••••••••',
                  hintStyle: GoogleFonts.fredoka(
                    color: Colors.grey,
                  ),
                ),
                style: GoogleFonts.fredoka(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Confirm Password field with animation
      FadeInDown(
        delay: const Duration(milliseconds: 700),
        duration: const Duration(milliseconds: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: _primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Confirm Password',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  prefixIcon: Container(
                    margin: const EdgeInsets.only(
                      left: 15,
                      right: 10,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: _accentColor,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: _accentColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible =
                        !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                  hintText: '••••••••',
                  hintStyle: GoogleFonts.fredoka(
                    color: Colors.grey,
                  ),
                ),
                style: GoogleFonts.fredoka(fontSize: 16),
              ),
            ),
          ],
        ),
      ),

      // Show error message if any
      if (errorMessage.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            errorMessage,
            style: GoogleFonts.fredoka(
              color: Colors.red,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),

      const SizedBox(height: 30),

      // Create Account button with animation
      FadeInDown(
        delay: const Duration(milliseconds: 800),
        duration: const Duration(milliseconds: 600),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_buttonColor, _primaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child:
          _isLoading
              ? const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          )
              : ElevatedButton(
            onPressed: register,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Create Account',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.how_to_reg_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Google Sign-Up Button
      FadeInDown(
        delay: const Duration(milliseconds: 900),
        duration: const Duration(milliseconds: 600),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _handleGoogleSignUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const FaIcon(
              FontAwesomeIcons.google,
              color: Colors.redAccent,
              size: 20,
            ),
            label: Text(
              'Sign Up with Google',
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Log in link with animation
      FadeInDown(
        delay: const Duration(milliseconds: 1000),
        duration: const Duration(milliseconds: 600),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Already have an account?",
              style: GoogleFonts.fredoka(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: Text(
                "Log In",
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _accentColor,
                ),
              ),
            ),
          ],
        ),
      ),

      // Cartoon characters (optional)
      FadeInUp(
        delay: const Duration(milliseconds: 1100),
        duration: const Duration(milliseconds: 800),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/images/cartoon1.png',
                    ),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/images/cartoon2.png',
                    ),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
    ],
    ),
    ),
    ),
    ),
    ),
        ),
    );
  }
}