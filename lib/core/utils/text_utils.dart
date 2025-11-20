import 'package:flutter/material.dart';

class TextUtils {
  /// Get responsive font size based on screen width
  static double getResponsiveFontSize(BuildContext context, {
    required double baseSize,
    double minSize = 8,
    double maxSize = 48,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 375; // Base on standard mobile width
    final fontSize = baseSize * scaleFactor;
    return fontSize.clamp(minSize, maxSize);
  }

  /// Safely display text with automatic wrapping and ellipsis
  static Widget safeText(
    String text, {
    required TextStyle style,
    int maxLines = 2,
    TextOverflow overflow = TextOverflow.ellipsis,
    TextAlign textAlign = TextAlign.center,
  }) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }

  /// Get responsive padding based on screen width
  static double getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 320) return 6;
    if (screenWidth < 360) return 8;
    if (screenWidth < 420) return 12;
    return 16;
  }
}
