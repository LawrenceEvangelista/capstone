import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/texttospeech/v1.dart' as tts;
import 'package:googleapis_auth/auth_io.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class GoogleTtsService {
  GoogleTtsService._();
  static final GoogleTtsService instance = GoogleTtsService._();

  final String _credPath = 'assets/google_service_account.json';

  AuthClient? _client;
  tts.TexttospeechApi? _api;

  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  Future<void> _init() async {
    if (_api != null) return;

    final jsonStr = await rootBundle.loadString(_credPath);
    final jsonMap = json.decode(jsonStr);

    final credentials = ServiceAccountCredentials.fromJson(jsonMap);

    final scopes = [
      'https://www.googleapis.com/auth/cloud-platform',
      'https://www.googleapis.com/auth/cloud-platform.read-only',
    ];

    _client = await clientViaServiceAccount(credentials, scopes);
    _api = tts.TexttospeechApi(_client!);
  }

  String _fileNameFor(String text, String lang) {
    final hash = md5.convert(utf8.encode("$lang|$text")).toString();
    return "tts_$hash.mp3";
  }

  Future<File> _cacheFile(String text, String lang) async {
    final dir = await getTemporaryDirectory();
    final cacheDir = Directory("${dir.path}/gcloud_tts_cache");

    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }

    return File("${cacheDir.path}/${_fileNameFor(text, lang)}");
  }

  Future<String?> synthesizeToCache(
    String text, {
    required String languageCode,
  }) async {
    await _init();

    final file = await _cacheFile(text, languageCode);

    if (file.existsSync()) return file.path;

    try {
      final request = tts.SynthesizeSpeechRequest(
        input: tts.SynthesisInput(text: text),
        voice: tts.VoiceSelectionParams(languageCode: languageCode),
        audioConfig: tts.AudioConfig(audioEncoding: 'MP3'),
      );

      final response = await _api!.text.synthesize(request);
      final bytes = base64.decode(response.audioContent!);
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      print("TTS error: $e");
      return null;
    }
  }

  Future<void> playFromFile(String path) async {
    await _player.setFilePath(path);
    await _player.play();
  }

  Future<void> stop() async => _player.stop();

  Future<double?> getDuration() async {
    return _player.duration?.inMilliseconds.toDouble();
  }

  Future<double?> getPosition() async {
    return _player.position.inMilliseconds.toDouble();
  }

  Future<void> seek(double ms) async {
    await _player.seek(Duration(milliseconds: ms.toInt()));
  }
}
