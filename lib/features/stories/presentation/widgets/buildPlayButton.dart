import 'package:flutter/material.dart';

class BuildPlayButton extends StatelessWidget {
  final VoidCallback onPlay;
  final Color primaryColor;

  const BuildPlayButton({
    super.key,
    required this.onPlay,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPlay,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(Icons.volume_up_rounded, color: primaryColor, size: 24),
        ),
      ),
    );
  }
}
