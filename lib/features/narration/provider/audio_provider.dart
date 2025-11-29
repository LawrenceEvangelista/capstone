// lib/features/narration/provider/audio_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:testapp/core/services/google_tts_service.dart';

class AudioProvider extends ChangeNotifier {
  final _tts = GoogleTtsService.instance;

  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool isPlaying = false;

  // Highlighting index (based on % progress)
  int activeWordIndex = -1;
  int totalWords = 0;
  List<String> words = [];

  Timer? _pollTimer;

  // Last narration settings
  String? lastText;
  String? lastLanguageCode;
  String? lastVoiceName;
  double lastPitch = 0.0;
  double lastRate = 1.0;

  // ==========================================================
  // LOAD + PLAY PAGE NARRATION
  // ==========================================================
  Future<void> loadPage({
    required String text,
    required String languageCode,
    required String voiceName,
    double pitch = 0.0,
    double speakingRate = 1.0,
  }) async {
    await stop();

    if (text.trim().isEmpty) return;

    // Save for reload/autoplay
    lastText = text;
    lastLanguageCode = languageCode;
    lastVoiceName = voiceName;
    lastPitch = pitch;
    lastRate = speakingRate;

    // Split words for highlighting
    words = text.split(" ");
    totalWords = words.length;

    notifyListeners();

    // Synthesize using API Key
    final result = await _tts.synthesizeWithMarks(
      text: text,
      languageCode: languageCode,
      voiceName: voiceName,
      pitch: pitch,
      speakingRate: speakingRate,
    );

    if (result == null || result["path"] == null) {
      return;
    }

    final path = result["path"];

    // PLAY audio
    await _tts.playFromPath(path);
    duration = _tts.player.duration ?? Duration.zero;
    isPlaying = true;

    _startPolling();
    notifyListeners();
  }

  // ==========================================================
  // POLLING — update highlight + progress
  // ==========================================================
  void _startPolling() {
    _pollTimer?.cancel();

    _pollTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      position = _tts.player.position;
      duration = _tts.player.duration ?? Duration.zero;

      // Highlight index based on percentage progress
      if (duration.inMilliseconds > 0) {
        final progress = position.inMilliseconds / duration.inMilliseconds;
        activeWordIndex = (progress * totalWords).floor();
      }

      notifyListeners();

      if (!_tts.player.playing) stop();
    });
  }

  // ==========================================================
  // BASIC CONTROLS
  // ==========================================================
  Future<void> play() async {
    await _tts.player.play();
    isPlaying = true;
    _startPolling();
    notifyListeners();
  }

  Future<void> pause() async {
    await _tts.player.pause();
    isPlaying = false;
    notifyListeners();
  }

  Future<void> replay() async {
    await _tts.player.seek(Duration.zero);
    activeWordIndex = -1;
    _startPolling();
    notifyListeners();
  }

  Future<void> stop() async {
    _pollTimer?.cancel();
    await _tts.stop();
    isPlaying = false;
    position = Duration.zero;
    activeWordIndex = -1;
    notifyListeners();
  }

  // ==========================================================
  // RELOAD (after language or voice change)
  // ==========================================================
  Future<void> reload() async {
    if (lastText == null || lastLanguageCode == null || lastVoiceName == null) {
      return;
    }

    await loadPage(
      text: lastText!,
      languageCode: lastLanguageCode!,
      voiceName: lastVoiceName!,
      pitch: lastPitch,
      speakingRate: lastRate,
    );
  }
}
