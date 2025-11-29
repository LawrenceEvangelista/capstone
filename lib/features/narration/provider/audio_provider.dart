// lib/features/narration/provider/audio_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:testapp/core/services/google_tts_service.dart';

class AudioProvider extends ChangeNotifier {
  final _tts = GoogleTtsService.instance;

  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool isPlaying = false;

  // NEW — autoplay next page narration
  bool autoPlayNext = true;

  // NEW — synthesis fields
  bool isSynthesizing = false;
  double synthProgress = 0;
  List<String> synthLog = [];

  // Karaoke
  int activeWordIndex = -1;
  List<int> wordTimestamps = [];

  Timer? _pollTimer;

  // last-used settings (for autoplay)
  String? lastPageText;
  String? lastLanguageCode;
  String? lastVoiceName;
  double? lastSpeakingRate;
  double? lastPitch;
  List<Map<String, String>>? lastSsmlSegments;

  // ==========================================================
  // Load + play page narration (supports SSML multi-character)
  // ==========================================================
  Future<void> loadPageFromTts({
    required String pageText,
    required String languageCode,
    String? voiceName,
    double? speakingRate,
    double? pitch,
    List<Map<String, String>>? ssmlSegments,
  }) async {
    await stop();

    // Save these for autoplay
    lastPageText = pageText;
    lastLanguageCode = languageCode;
    lastVoiceName = voiceName;
    lastSpeakingRate = speakingRate;
    lastPitch = pitch;
    lastSsmlSegments = ssmlSegments;

    if (pageText.trim().isEmpty &&
        (ssmlSegments == null || ssmlSegments.isEmpty)) {
      activeWordIndex = -1;
      isPlaying = false;
      duration = Duration.zero;
      notifyListeners();
      return;
    }

    isSynthesizing = true;
    notifyListeners();

    final result = await _tts.synthesizePageToCacheWithTimepoints(
      pageText,
      languageCode: languageCode,
      voiceName: voiceName,
      speakingRate: speakingRate,
      pitch: pitch,
      segments: ssmlSegments,
    );

    isSynthesizing = false;

    final path = result['path'] as String?;
    final tps = result['timepoints'] as List<dynamic>? ?? [];

    wordTimestamps = tps.map((e) => e as int).toList();
    activeWordIndex = -1;

    if (path == null) {
      notifyListeners();
      return;
    }

    // Play MP3
    await _tts.playFromFile(path);
    duration = _tts.player.duration ?? Duration.zero;
    isPlaying = true;

    _startPolling();
    notifyListeners();
  }

  // Karaoke highlight position polling
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      position = _tts.player.position;
      duration = _tts.player.duration ?? Duration.zero;

      for (int i = 0; i < wordTimestamps.length; i++) {
        if (position.inMilliseconds >= wordTimestamps[i]) {
          activeWordIndex = i;
        }
      }

      notifyListeners();

      if (!_tts.player.playing) {
        stop();
      }
    });
  }

  // ==========================================================
  // Basic playback controls
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
    _pollTimer?.cancel();
    notifyListeners();
  }

  Future<void> replay() async {
    await _tts.player.seek(Duration.zero);
    activeWordIndex = -1;
    notifyListeners();
    await play();
  }

  Future<void> stop() async {
    _pollTimer?.cancel();
    try {
      await _tts.stop();
    } catch (_) {}
    isPlaying = false;
    position = Duration.zero;
    activeWordIndex = -1;
    notifyListeners();
  }

  Future<void> seek(int ms) async {
    await _tts.seek(ms.toDouble());
    position = Duration(milliseconds: ms);

    activeWordIndex = -1;
    for (int i = 0; i < wordTimestamps.length; i++) {
      if (position.inMilliseconds >= wordTimestamps[i]) {
        activeWordIndex = i;
      }
    }

    notifyListeners();
  }

  // Reload page when settings changed
  Future<void> reloadWithSettings() async {
    if (lastPageText == null || lastLanguageCode == null) return;

    await loadPageFromTts(
      pageText: lastPageText!,
      languageCode: lastLanguageCode!,
      voiceName: lastVoiceName,
      speakingRate: lastSpeakingRate,
      pitch: lastPitch,
      ssmlSegments: lastSsmlSegments,
    );
  }

  // ==========================================================
  // NEW — Voice Preview (short sample)
  // ==========================================================
  Future<void> playVoicePreview({
    required String sampleText,
    required String languageCode,
    required String voiceName,
    double? speakingRate,
    double? pitch,
  }) async {
    await stop();
    isSynthesizing = true;
    notifyListeners();

    final result = await _tts.synthesizePageToCacheWithTimepoints(
      sampleText,
      languageCode: languageCode,
      voiceName: voiceName,
      speakingRate: speakingRate,
      pitch: pitch,
    );

    isSynthesizing = false;

    final path = result['path'] as String?;
    if (path == null) {
      notifyListeners();
      return;
    }

    await _tts.playFromFile(path);
    duration = _tts.player.duration ?? Duration.zero;
    isPlaying = true;

    _startPolling();
    notifyListeners();
  }

  // ==========================================================
  // Offline Download System (multi-voice supported)
  // ==========================================================
  Future<void> preloadStoryNarration({
    required List<Map<String, dynamic>> fullPages,
    required bool isEnglish,
    required String voiceEn,
    required String voiceTag,
    required double speakingRate,
    required double pitch,
  }) async {
    synthLog.clear();
    synthProgress = 0;
    isSynthesizing = true;
    notifyListeners();

    final total = fullPages.length;

    for (int i = 0; i < total; i++) {
      final page = fullPages[i];

      final text =
          isEnglish ? (page['textEng'] ?? '') : (page['textTag'] ?? '');
      final languageCode = isEnglish ? 'en-US' : 'fil-PH';
      final voice = isEnglish ? voiceEn : voiceTag;

      // segments
      List<Map<String, String>>? segments;
      final raw = page['segments'];
      if (raw is List) {
        try {
          segments =
              raw
                  .where((e) => e != null)
                  .map<Map<String, String>>(
                    (e) => Map<String, String>.from(e as Map),
                  )
                  .toList();
        } catch (_) {
          segments = null;
        }
      }

      if (synthLog.length <= i) {
        synthLog.add("Page ${i + 1} — Synthesizing...");
      } else {
        synthLog[i] = "Page ${i + 1} — Synthesizing...";
      }
      notifyListeners();

      await _tts.synthesizePageToCacheWithTimepoints(
        text,
        languageCode: languageCode,
        voiceName: voice,
        speakingRate: speakingRate,
        pitch: pitch,
        segments: segments,
      );

      synthLog[i] = "Page ${i + 1} — ✔ Cached";
      synthProgress = (i + 1) / total;
      notifyListeners();
    }

    synthLog.add("All pages downloaded ✔");
    synthProgress = 1;
    isSynthesizing = false;
    notifyListeners();
  }
}
