// lib/features/stories/presentation/widgets/highlighted_text.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final int activeIndex;
  final double fontSize;

  const HighlightedText({
    super.key,
    required this.text,
    required this.activeIndex,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final words = text.trim().isEmpty ? <String>[] : text.split(RegExp(r'\s+'));

    return Wrap(
      alignment: WrapAlignment.center,
      children: List.generate(words.length, (i) {
        final isActive = i == activeIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          child: Text(
            words[i],
            style: GoogleFonts.fredoka(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.orange : Colors.black87,
            ),
          ),
        );
      }),
    );
  }
}
