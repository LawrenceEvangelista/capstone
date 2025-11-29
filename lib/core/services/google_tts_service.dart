import 'dart:convert';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Vertex AI TTS using API KEY mode (Easiest + Recommended)
class GoogleTtsService {
  GoogleTtsService._();
  static final GoogleTtsService instance = GoogleTtsService._();

  final String _apiKey = "AIzaSyC17UWq-wRPy04N1qsmlfFCfpIxD3dxGVI";

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  // -------------------------------------------------------------
  // Cache audio to local file
  // -------------------------------------------------------------
  Future<File> _cacheFile(String text, String voice) async {
    final hash = md5.convert(utf8.encode("$voice|$text")).toString();
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/tts_$hash.mp3");

    return file;
  }

  // -------------------------------------------------------------
  // Synthesize speech with SSML + <mark> tags for word syncing
  // -------------------------------------------------------------
  Future<Map<String, dynamic>?> synthesizeWithMarks({
    required String text,
    required String languageCode,
    required String voiceName,
    double pitch = 0.0,
    double speakingRate = 1.0,
  }) async {
    try {
      final file = await _cacheFile(text, voiceName);

      if (await file.exists()) {
        return {"path": file.path, "timepoints": []};
      }

      // Split into words → generate <mark name="w0"/> Word
      final words = text.split(" ");
      final StringBuffer ssml = StringBuffer("<speak>");
      for (int i = 0; i < words.length; i++) {
        ssml.write('<mark name="w$i"/> ${words[i]} ');
      }
      ssml.write("</speak>");

      final url =
          "https://texttospeech.googleapis.com/v1beta1/text:synthesize?key=$_apiKey";

      final body = {
        "input": {"ssml": ssml.toString()},
        "voice": {"languageCode": languageCode, "name": voiceName},
        "audioConfig": {
          "audioEncoding": "MP3",
          "pitch": pitch,
          "speakingRate": speakingRate,
        },
      };

      final res = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode != 200) {
        print("TTS ERROR: ${res.body}");
        return null;
      }

      final data = jsonDecode(res.body);

      if (!data.containsKey("audioContent")) return null;

      final audioBytes = base64.decode(data["audioContent"]);
      await file.writeAsBytes(audioBytes);

      return {"path": file.path, "timepoints": []};
    } catch (e) {
      print("TTS ERROR: $e");
      return null;
    }
  }

  // -------------------------------------------------------------
  // Simple playback helper
  // -------------------------------------------------------------
  Future<void> playFromPath(String path) async {
    try {
      await _player.setFilePath(path);
      await _player.play();
    } catch (e) {
      print("Play error: $e");
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }
}
