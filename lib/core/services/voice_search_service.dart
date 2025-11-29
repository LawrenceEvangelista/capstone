//lib\core\services\voice_search_service.dart
//WIDGET REUSABLE VOICE SEARCH SERVICE
// voice_search_service.dart
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;

  VoiceService._internal();

  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;

  /// Initialize mic for speech recognition
  Future<void> init() async {
    if (!_initialized) {
      _initialized = await _speech.initialize();
    }
  }

  /// Start listening for voice input
  Future<void> start(Function(String) onResult) async {
    await init();

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
    );
  }

  /// Stop listening
  Future<void> stop() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
