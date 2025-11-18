import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:just_audio/just_audio.dart';
import '../services/narration_service.dart';

class NarrationPlayer extends StatefulWidget {
  final String storyId;
  final int currentPage;
  final String language;
  final int totalPages;
  final Color primaryColor;
  final Color accentColor;
  final Function(double position, double duration)? onPositionChanged;

  const NarrationPlayer({
    super.key,
    required this.storyId,
    required this.currentPage,
    required this.language,
    required this.totalPages,
    required this.primaryColor,
    required this.accentColor,
    this.onPositionChanged,
  });

  @override
  State<NarrationPlayer> createState() => _NarrationPlayerState();
}

class _NarrationPlayerState extends State<NarrationPlayer> {
  final NarrationService _narrationService = NarrationService();
  late AudioPlayer _audioPlayer;
  bool _isAvailable = false;
  bool _isLoading = false;
  bool _isPlaying = false;
  String? _currentNarrationUrl;
  double _currentPosition = 0;
  double _duration = 0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioListeners();
    _checkNarrationAvailability();
  }

  void _setupAudioListeners() {
    // Listen for duration changes
    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration?.inMilliseconds.toDouble() ?? 0;
        });
      }
    });

    // Listen for position changes
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          // Ensure position doesn't exceed duration
          final newPosition = position.inMilliseconds.toDouble();
          _currentPosition = newPosition > _duration ? _duration : newPosition;
        });
        // Notify parent about position change for text sync
        widget.onPositionChanged?.call(_currentPosition, _duration);
      }
    });

    // Listen for playback state changes
    _audioPlayer.playerStateStream.listen((playerState) {
      if (mounted) {
        setState(() {
          _isPlaying = playerState.playing;
        });

        // Auto-stop when completed
        if (playerState.processingState == ProcessingState.completed) {
          setState(() {
            _isPlaying = false;
            _currentPosition = 0;
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(NarrationPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check availability when page or language changes
    if (oldWidget.currentPage != widget.currentPage ||
        oldWidget.language != widget.language) {
      _audioPlayer.stop();
      _checkNarrationAvailability();
      setState(() {
        _isPlaying = false;
        _currentPosition = 0;
      });
    }
  }

  Future<void> _checkNarrationAvailability() async {
    setState(() {
      _isLoading = true;
    });

    print('🎧 NarrationPlayer: Checking narration for story=${widget.storyId}, page=${widget.currentPage}, language=${widget.language}');

    final isAvailable = await _narrationService.isNarrationAvailable(
      widget.storyId,
      widget.currentPage,
      widget.language,
    );

    print('🎧 NarrationPlayer: Narration available = $isAvailable');

    if (isAvailable) {
      final url = await _narrationService.fetchNarrationUrl(
        widget.storyId,
        widget.currentPage,
        widget.language,
      );

      print('🎧 NarrationPlayer: Fetched URL = $url');

      if (mounted) {
        setState(() {
          _isAvailable = true;
          _currentNarrationUrl = url;
          _isLoading = false;
        });

        // Initialize audio with the fetched URL
        if (url != null) {
          try {
            await _audioPlayer.setUrl(url);
            print('✅ Audio loaded successfully: $url');
          } catch (e) {
            print('❌ Error loading audio: $e');
            if (mounted) {
              setState(() {
                _isAvailable = false;
              });
            }
          }
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isAvailable = false;
          _currentNarrationUrl = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      print('Error toggling playback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
    }
  }

  Future<void> _seekToPosition(double value) async {
    try {
      await _audioPlayer.seek(Duration(milliseconds: value.toInt()));
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return FadeIn(
        duration: const Duration(milliseconds: 300),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SizedBox(
              height: 40,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: widget.primaryColor,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (!_isAvailable || _currentNarrationUrl == null) {
      return const SizedBox.shrink();
    }

    return FadeIn(
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: widget.primaryColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.headphones,
                    color: widget.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Narration',
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Page ${widget.currentPage}/${widget.totalPages}',
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Play button and progress
              Row(
                children: [
                  // Play/Pause button
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Progress bar and time
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress slider
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                          ),
                          child: Slider(
                            value: _currentPosition.clamp(0, _duration > 0 ? _duration : 1),
                            max: _duration > 0 ? _duration : 1,
                            onChanged: _seekToPosition,
                            activeColor: widget.primaryColor,
                            inactiveColor: Colors.grey[300],
                          ),
                        ),
                        // Time display
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(
                                Duration(milliseconds: _currentPosition.toInt()),
                              ),
                              style: GoogleFonts.fredoka(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              _formatDuration(
                                Duration(milliseconds: _duration.toInt()),
                              ),
                              style: GoogleFonts.fredoka(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Volume icon
                  Icon(
                    Icons.volume_up,
                    color: widget.primaryColor,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
