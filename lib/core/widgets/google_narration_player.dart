import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testapp/features/narration/provider/audio_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class GoogleNarrationPlayer extends StatelessWidget {
  final String text;
  final String language;
  final Color primaryColor;
  final Color accentColor;

  /// Called every time the position or duration changes
  final Function(double position, double duration)? onPositionChanged;

  const GoogleNarrationPlayer({
    super.key,
    required this.text,
    required this.language,
    required this.primaryColor,
    required this.accentColor,
    this.onPositionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audio, _) {
        // notify parent for text highlight
        if (onPositionChanged != null) {
          onPositionChanged!(audio.position, audio.duration);
        }

        final double max = audio.duration > 0 ? audio.duration : 1;
        final double value = audio.position.clamp(0, max);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Play / Stop button
              InkWell(
                onTap: () {
                  if (audio.isPlaying) {
                    audio.stop();
                  } else {
                    audio.playText(text, languageCode: language);
                  }
                },
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    audio.isPlaying ? Icons.stop : Icons.play_arrow_rounded,
                    size: 30,
                    color: primaryColor,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Progress bar + time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      minHeight: 6,
                      value: value / max,
                      backgroundColor: Colors.grey.shade300,
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(6),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatMs(value),
                          style: GoogleFonts.fredoka(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          _formatMs(max),
                          style: GoogleFonts.fredoka(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Format milliseconds into mm:ss
  String _formatMs(double ms) {
    final totalSeconds = (ms / 1000).floor();
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }
}
