import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:testapp/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:testapp/core/widgets/language_switcher.dart';
import 'package:provider/provider.dart';
import 'package:testapp/providers/localization_provider.dart';
import 'package:testapp/providers/recently_viewed_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _usernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _newEmailController = TextEditingController();
  final _emailPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEditingUsername = false;
  bool _isEditingPassword = false;
  bool _isEditingEmail = false;
  bool _isLoadingUsername = false;
  bool _isLoadingPassword = false;
  bool _isLoadingProfilePicture = false;
  bool _isLoadingEmail = false;
  bool _isPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isEmailPasswordVisible = false;
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  // Consistent app colors - using theme colors
  final Color _backgroundColor = const Color(0xFFFFF176); // Light yellow background
  final Color _primaryColor = const Color(0xFFFFD93D); // Mustard yellow (consistent primary)
  final Color _accentColor = const Color(0xFF8E24AA); // Purple accent
  final Color _errorColor = const Color(0xFFE53935); // Red (semantic color)

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _usernameController.text = currentUser.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newEmailController.dispose();
    _emailPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 30),
        title: Text(
          localization.translate('profile'),
          style: GoogleFonts.fredoka(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: <Widget>[
                const SizedBox(height: 20),
                // Profile avatar with upload functionality
                FadeInDown(
                  child: Center(
                    child: Stack(
                      children: [
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: _primaryColor, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryColor.withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: _buildProfileAvatar(),
                        ),
                        // Upload button
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isLoadingProfilePicture ? null : _pickProfileImage,
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: _accentColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: _isLoadingProfilePicture
                                  ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
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
                const SizedBox(height: 30),
                // Section title
                FadeInDown(
                  delay: const Duration(milliseconds: 200),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        localization.translate('editProfile'),
                        style: GoogleFonts.fredoka(
                          textStyle: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Username field
                FadeInDown(
                  delay: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_outline,
                              color: _primaryColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _usernameController,
                              enabled: _isEditingUsername,
                              style: GoogleFonts.fredoka(
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              validator: (value) {
                                if (_isEditingUsername &&
                                    (value == null || value.isEmpty)) {
                                  return localization.translate('username');
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: localization.translate('username'),
                                labelStyle: GoogleFonts.fredoka(
                                  textStyle: TextStyle(
                                    color: _primaryColor,
                                    fontSize: 16,
                                  ),
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: _isLoadingUsername
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isEditingUsername ? Icons.save : Icons.edit,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                            onPressed: _isLoadingUsername
                                ? null
                                : () async {
                                    if (_isEditingUsername) {
                                      if (_formKey.currentState!.validate()) {
                                        await _handleUsernameUpdate();
                                      }
                                    } else {
                                      setState(() => _isEditingUsername = true);
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Email change section
                FadeInDown(
                  delay: const Duration(milliseconds: 300),
                  child: Column(
                    children: [
                      if (_isEditingEmail) ...[
                        // Current Email Display
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.email_outlined,
                                    color: _primaryColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    enabled: false,
                                    initialValue: FirebaseAuth.instance.currentUser?.email ?? '',
                                    style: GoogleFonts.fredoka(
                                      textStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    decoration: InputDecoration(
                                      labelText: localization.translate('currentEmail'),
                                      labelStyle: GoogleFonts.fredoka(
                                        textStyle: TextStyle(
                                          color: _primaryColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // New Email Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.mail_outline,
                                    color: _primaryColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _newEmailController,
                                    style: GoogleFonts.fredoka(
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    decoration: InputDecoration(
                                      labelText: localization.translate('newEmail'),
                                      labelStyle: GoogleFonts.fredoka(
                                        textStyle: TextStyle(
                                          color: _primaryColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                      hintText: localization.translate('enterNewEmail'),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Password Verification Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.lock_outline,
                                    color: _primaryColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _emailPasswordController,
                                    obscureText: !_isEmailPasswordVisible,
                                    style: GoogleFonts.fredoka(
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    decoration: InputDecoration(
                                      labelText: localization.translate('passwordLabel'),
                                      labelStyle: GoogleFonts.fredoka(
                                        textStyle: TextStyle(
                                          color: _primaryColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                      hintText: localization.translate('enterPasswordToVerify'),
                                      border: InputBorder.none,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isEmailPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                          color: _primaryColor,
                                        ),
                                        onPressed: () {
                                          setState(() => _isEmailPasswordVisible = !_isEmailPasswordVisible);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Confirm Email Change Button
                        if (_isEditingEmail)
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _isLoadingEmail
                                      ? null
                                      : () {
                                          setState(() => _isEditingEmail = false);
                                          _newEmailController.clear();
                                          _emailPasswordController.clear();
                                          _isEmailPasswordVisible = false;
                                        },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.grey.withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withValues(alpha: 0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    child: Center(
                                      child: Text(
                                        localization.translate('cancelButton'),
                                        style: GoogleFonts.fredoka(
                                          textStyle: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _isLoadingEmail
                                      ? null
                                      : () async {
                                          final emailError = _validateEmailChange();
                                          if (emailError != null) {
                                            _showErrorPopup(emailError);
                                          } else {
                                            await _handleEmailChange();
                                          }
                                        },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    child: Center(
                                      child: _isLoadingEmail
                                          ? SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : Text(
                                              localization.translate('confirmButton'),
                                              style: GoogleFonts.fredoka(
                                                textStyle: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                      const SizedBox(height: 16),
                      // Change Email Button - Large Kid-Friendly Version
                      if (!_isEditingEmail)
                        GestureDetector(
                          onTap: _isLoadingEmail
                              ? null
                              : () {
                                  setState(() => _isEditingEmail = !_isEditingEmail);
                                },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.25),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 18.0,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.mail_outline_rounded,
                                    color: Colors.blue,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Change Email',
                                        style: GoogleFonts.fredoka(
                                          textStyle: TextStyle(
                                            color: _primaryColor,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        _isEditingEmail ? 'Tap to close' : 'Update your email address',
                                        style: GoogleFonts.fredoka(
                                          textStyle: TextStyle(
                                            color: Colors.grey.withValues(alpha: 0.7),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: _isLoadingEmail
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Icon(
                                          _isEditingEmail ? Icons.expand_less : Icons.expand_more,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Password section
                FadeInDown(
                  delay: const Duration(milliseconds: 400),
                  child: Column(
                    children: [
                      if (_isEditingPassword) ...[
                        // Current Password Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.lock_outline,
                                    color: _primaryColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _currentPasswordController,
                                    obscureText: !_isPasswordVisible,
                                    style: GoogleFonts.fredoka(
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    decoration: InputDecoration(
                                      labelText: localization.translate('currentPassword'),
                                      labelStyle: GoogleFonts.fredoka(
                                        textStyle: TextStyle(
                                          color: _primaryColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                      border: InputBorder.none,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                          color: _primaryColor,
                                        ),
                                        onPressed: () {
                                          setState(() => _isPasswordVisible = !_isPasswordVisible);
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return localization.translate('enterCurrentPassword');
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // New Password Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.vpn_key_outlined,
                                    color: _primaryColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _newPasswordController,
                                    obscureText: !_isNewPasswordVisible,
                                    style: GoogleFonts.fredoka(
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    decoration: InputDecoration(
                                      labelText: localization.translate('newPassword'),
                                      labelStyle: GoogleFonts.fredoka(
                                        textStyle: TextStyle(
                                          color: _primaryColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                      border: InputBorder.none,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                          color: _primaryColor,
                                        ),
                                        onPressed: () {
                                          setState(() => _isNewPasswordVisible = !_isNewPasswordVisible);
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return localization.translate('enterNewPassword');
                                      }
                                      if (value.length < 6) {
                                        return localization.translate('passwordMinChars');
                                      }
                                      if (value == _currentPasswordController.text) {
                                        return 'New password must be different from current password';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Confirm Password Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_circle_outline,
                                    color: _primaryColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: !_isNewPasswordVisible,
                                    style: GoogleFonts.fredoka(
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Confirm New Password',
                                      labelStyle: GoogleFonts.fredoka(
                                        textStyle: TextStyle(
                                          color: _primaryColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                      border: InputBorder.none,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                          color: _primaryColor,
                                        ),
                                        onPressed: () {
                                          setState(() => _isNewPasswordVisible = !_isNewPasswordVisible);
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please confirm your password';
                                      }
                                      if (value != _newPasswordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Confirm Password Change Button
                        if (_isEditingPassword)
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _isLoadingPassword
                                      ? null
                                      : () {
                                          setState(() => _isEditingPassword = false);
                                          _currentPasswordController.clear();
                                          _newPasswordController.clear();
                                          _confirmPasswordController.clear();
                                          _isPasswordVisible = false;
                                          _isNewPasswordVisible = false;
                                        },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.grey.withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withValues(alpha: 0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    child: Center(
                                      child: Text(
                                        localization.translate('cancelButton'),
                                        style: GoogleFonts.fredoka(
                                          textStyle: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _isLoadingPassword
                                      ? null
                                      : () async {
                                          if (_formKey.currentState!.validate()) {
                                            await _handlePasswordChange();
                                          }
                                        },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    child: Center(
                                      child: _isLoadingPassword
                                          ? SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : Text(
                                              localization.translate('confirmButton'),
                                              style: GoogleFonts.fredoka(
                                                textStyle: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                      const SizedBox(height: 16),
                      // Change Password Button - Large Kid-Friendly Version
                      if (!_isEditingPassword)
                        GestureDetector(
                          onTap: _isLoadingPassword
                              ? null
                              : () {
                                  setState(() => _isEditingPassword = !_isEditingPassword);
                                },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.25),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 18.0,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.lock_outline_rounded,
                                    color: Colors.orange,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        localization.translate('changePassword'),
                                        style: GoogleFonts.fredoka(
                                          textStyle: TextStyle(
                                            color: _primaryColor,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        _isEditingPassword ? 'Tap to close' : 'Keep your account secure',
                                        style: GoogleFonts.fredoka(
                                          textStyle: TextStyle(
                                            color: Colors.grey.withValues(alpha: 0.7),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: _isLoadingPassword
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Icon(
                                          _isEditingPassword ? Icons.expand_less : Icons.expand_more,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Language Switcher
                FadeInDown(
                  delay: const Duration(milliseconds: 400),
                  child: LanguageSwitcher(
                    primaryColor: _primaryColor,
                    accentColor: _accentColor,
                  ),
                ),
                const SizedBox(height: 40),
                // Delete account button
                FadeInDown(
                  delay: const Duration(milliseconds: 500),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_errorColor.withValues(alpha: 0.8), _errorColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _errorColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        _showDeleteAccountDialog(context);
                      },
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
                          const Icon(
                            Icons.delete_forever,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            localization.translate('delete'),
                            style: GoogleFonts.fredoka(
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Logout button
                FadeInDown(
                  delay: const Duration(milliseconds: 600),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: OutlinedButton(
                      onPressed: () {
                        _handleLogout(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _primaryColor, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: _primaryColor, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            localization.translate('logout'),
                            style: GoogleFonts.fredoka(
                              textStyle: TextStyle(
                                color: _primaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Custom SnackBar
  void _showCartoonishSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        backgroundColor: _accentColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    try {
      await _authService.signOut();
      // Clear recently viewed data on logout
      if (context.mounted) {
        Provider.of<RecentlyViewedProvider>(context, listen: false).clearRecentlyViewed();
      }
      Navigator.pushReplacementNamed(context, '/');
    } catch (error) {
      _showLogoutErrorDialog(context, error.toString());
    }
  }

  void _showLogoutErrorDialog(BuildContext context, String errorMessage) {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            title: Text(
              localization.translate('logoutError'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.fredoka(
                textStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _errorColor,
                ),
              ),
            ),
            content: Text(
              '${localization.translate('failedToLogout')}: $errorMessage',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.fredoka(
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: _primaryColor),
                child: Text(
                  localization.translate('ok'),
                  style: GoogleFonts.fredoka(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            title: Text(
              localization.translate('deleteAccount'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.fredoka(
                textStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _errorColor,
                ),
              ),
            ),
            content: Text(
              localization.translate('deleteAccountConfirm'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.fredoka(
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(foregroundColor: _primaryColor),
                child: Text(
                  localization.translate('cancel'),
                  style: GoogleFonts.fredoka(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final result = await _showDeleteAccountCredentialsDialog(
                      context,
                    );
                    if (result == true) {
                      await _authService.deleteAccount(
                        email: FirebaseAuth.instance.currentUser!.email!,
                        password: _currentPasswordController.text,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                        Navigator.pushReplacementNamed(context, '/');
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      _showDeleteAccountErrorDialog(context, e.toString());
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _errorColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  'Delete',
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

  Future<bool> _showDeleteAccountCredentialsDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              title: Text(
                'Re-authenticate',
                style: GoogleFonts.fredoka(
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter your password to confirm account deletion.',
                    style: GoogleFonts.fredoka(
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: TextField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      style: GoogleFonts.fredoka(
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: GoogleFonts.fredoka(
                          textStyle: TextStyle(color: _primaryColor),
                        ),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(foregroundColor: _primaryColor),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.fredoka(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _errorColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'Confirm',
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
            );
          },
        ) ??
        false;
  }

  void _showDeleteAccountErrorDialog(
    BuildContext context,
    String errorMessage,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            title: Text(
              'Error Deleting Account',
              style: GoogleFonts.fredoka(
                textStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _errorColor,
                ),
              ),
            ),
            content: Text(
              'Failed to delete account. Error: $errorMessage',
              style: GoogleFonts.fredoka(
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: _primaryColor),
                child: Text(
                  'OK',
                  style: GoogleFonts.fredoka(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // Build profile avatar with photo or default icon
  Widget _buildProfileAvatar() {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser?.photoURL != null && currentUser!.photoURL!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          currentUser.photoURL!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: Icon(
                Icons.person,
                size: 80,
                color: const Color(0xFFFF6D00),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[300],
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                ),
              ),
            );
          },
        ),
      );
    }
    
    return Icon(
      Icons.person,
      size: 80,
      color: const Color(0xFFFF6D00),
    );
  }

  // Pick profile image from gallery or camera
  Future<void> _pickProfileImage() async {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(localization.translate('gallery')),
                onTap: () async {
                  Navigator.pop(context);
                  await _uploadProfileImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(localization.translate('camera')),
                onTap: () async {
                  Navigator.pop(context);
                  await _uploadProfileImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Upload selected image to Firebase Storage
  Future<void> _uploadProfileImage(ImageSource source) async {
    try {
      setState(() => _isLoadingProfilePicture = true);
      
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile == null) {
        setState(() => _isLoadingProfilePicture = false);
        return;
      }

      final imageFile = File(pickedFile.path);
      
      print("🎬 Starting profile picture upload from ${source.name}");
      print("📁 File path: ${imageFile.path}");
      
      // Upload to Firebase with 60-second timeout
      await _authService.uploadProfileImage(
        userId: FirebaseAuth.instance.currentUser!.uid,
        imageFile: imageFile,
      ).timeout(
        Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Profile picture upload took too long. Please check your connection.');
        },
      );

      setState(() => _isLoadingProfilePicture = false);
      
      _showCartoonishSnackBar('Profile picture updated! 📸');
    } catch (e) {
      setState(() => _isLoadingProfilePicture = false);
      
      String errorMessage = 'Error uploading picture';
      if (e is TimeoutException) {
        errorMessage = 'Upload timed out - check your internet connection';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied - check storage permissions';
      }
      
      _showCartoonishSnackBar('$errorMessage 😕');
      print("❌ Upload error: $e");
    }
  }

  // Handle password change with validation
  Future<void> _handlePasswordChange() async {
    try {
      setState(() => _isLoadingPassword = true);
      
      await _authService.resetPasswordFromCurrentPassword(
        email: FirebaseAuth.instance.currentUser!.email!,
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      setState(() {
        _isEditingPassword = false;
        _isLoadingPassword = false;
        // Clear password fields for security
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _isPasswordVisible = false;
        _isNewPasswordVisible = false;
      });
      
      _showCartoonishSnackBar('Password updated! 🔐');
    } catch (e) {
      setState(() => _isLoadingPassword = false);
      _showCartoonishSnackBar('Error: ${e.toString()} 😕');
    }
  }

  // Update username with error handling
  Future<void> _handleUsernameUpdate() async {
    try {
      setState(() => _isLoadingUsername = true);
      
      await _authService.updateUsername(
        username: _usernameController.text.trim(),
      );

      setState(() {
        _isEditingUsername = false;
        _isLoadingUsername = false;
      });
      
      _showCartoonishSnackBar('Username updated! 🎉');
    } catch (e) {
      setState(() => _isLoadingUsername = false);
      _showCartoonishSnackBar('Error: ${e.toString()} 😕');
    }
  }

  // Handle email change with verification
  // Validate email change fields and return error message if any
  String? _validateEmailChange() {
    final newEmail = _newEmailController.text.trim();
    final password = _emailPasswordController.text.trim();
    
    if (newEmail.isEmpty) {
      return '📧 Oops! Please enter a new email';
    }
    
    if (!RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$').hasMatch(newEmail)) {
      return '❌ That doesn\'t look like a real email!';
    }
    
    if (newEmail == FirebaseAuth.instance.currentUser?.email) {
      return '✨ Use a different email, not the old one!';
    }
    
    if (password.isEmpty) {
      return '🔐 Don\'t forget your password!';
    }
    
    return null;
  }

  // Show error message as a popup dialog
  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Oops!',
                style: GoogleFonts.fredoka(
                  textStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53935),
                  ),
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: GoogleFonts.fredoka(
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Got it! 👍',
                style: GoogleFonts.fredoka(
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEmailChange() async {
    try {
      setState(() => _isLoadingEmail = true);
      
      final currentEmail = FirebaseAuth.instance.currentUser?.email;
      final newEmail = _newEmailController.text.trim();
      final password = _emailPasswordController.text.trim();
      
      // Validation checks
      if (currentEmail == null) {
        throw Exception('Current email not found');
      }
      
      if (newEmail.isEmpty) {
        throw Exception('New email is required');
      }
      
      if (!newEmail.contains('@')) {
        throw Exception('Invalid email format');
      }
      
      if (newEmail == currentEmail) {
        throw Exception('New email must be different from current email');
      }
      
      if (password.isEmpty) {
        throw Exception('Password is required for security');
      }
      
      print('📧 Starting email change: $currentEmail → $newEmail');
      print('🔑 Reauthenticating with password...');

      // Change email (sends verification link to new email)
      await _authService.changeEmail(
        currentEmail: currentEmail,
        password: password,
        newEmail: newEmail,
      );

      setState(() {
        _isEditingEmail = false;
        _isLoadingEmail = false;
        // Clear email fields for security
        _newEmailController.clear();
        _emailPasswordController.clear();
        _isEmailPasswordVisible = false;
      });
      
      print('✅ Verification email sent successfully!');
      _showCartoonishSnackBar(
        'Verification email sent to $newEmail! ✉️\nPlease verify to complete the change.',
      );
    } catch (e) {
      setState(() => _isLoadingEmail = false);
      
      print('❌ Email change error: $e');
      
      String errorMessage = 'Error changing email';
      if (e.toString().contains('wrong-password') || e.toString().contains('invalid-credential')) {
        errorMessage = 'Incorrect password';
      } else if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'Email already in use';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email format';
      } else if (e.toString().contains('Current email not found')) {
        errorMessage = 'Current email not found';
      } else if (e.toString().contains('must be different')) {
        errorMessage = 'New email must be different';
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      _showCartoonishSnackBar('$errorMessage 😕');
    }
  }
}
