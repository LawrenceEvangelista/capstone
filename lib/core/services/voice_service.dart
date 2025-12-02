import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;

  VoiceService._internal();

  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;

  Future<void> init() async {
    if (!_initialized) {
      await _speech.initialize();
      _initialized = true;
    }
  }

  bool get isListening => _speech.isListening;

  Future<void> startListening(Function(String text) onText) async {
    await init();

    await _speech.listen(
      onResult: (result) {
        onText(result.recognizedWords);
      },
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }
}
