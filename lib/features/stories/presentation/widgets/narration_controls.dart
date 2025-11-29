import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../narration/provider/audio_provider.dart';

class NarrationControls extends StatelessWidget {
  final Color primaryColor;
  final Color buttonColor;

  const NarrationControls({
    super.key,
    required this.primaryColor,
    required this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioProvider>(context);

    final position = audio.position;
    final duration =
        audio.duration.inMilliseconds == 0 ? Duration.zero : audio.duration;

    final progress =
        duration.inMilliseconds == 0
            ? 0.0
            : position.inMilliseconds / duration.inMilliseconds;

    final disabled = audio.isSynthesizing;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Main Controls
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _button(
                  icon: Icons.replay,
                  onTap: disabled ? null : audio.replay,
                  dim: disabled,
                  bg: Colors.white,
                  fg: primaryColor,
                ),
                const SizedBox(width: 20),
                _button(
                  icon: audio.isPlaying ? Icons.pause : Icons.play_arrow,
                  onTap:
                      disabled
                          ? null
                          : () =>
                              audio.isPlaying ? audio.pause() : audio.play(),
                  dim: disabled,
                  bg: buttonColor,
                  fg: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.white,
                borderRadius: BorderRadius.circular(10),
                color: primaryColor,
              ),
            ),
          ],
        ),

        // Synthesizing overlay
        if (audio.isSynthesizing)
          Positioned(
            bottom: 48,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Synthesizing narration...",
                style: GoogleFonts.fredoka(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _button({
    required IconData icon,
    required VoidCallback? onTap,
    required bool dim,
    required Color bg,
    required Color fg,
  }) {
    return Opacity(
      opacity: dim ? 0.4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6),
            ],
          ),
          child: Icon(icon, size: 28, color: fg),
        ),
      ),
    );
  }
}
