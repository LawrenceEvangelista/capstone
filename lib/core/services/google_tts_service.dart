// lib/core/services/google_tts_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class GoogleTtsService {
  GoogleTtsService._();
  static final GoogleTtsService instance = GoogleTtsService._();

  final String _credPath = 'assets/google_service_account.json';

  AuthClient? _client;
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  // ----------------------------
  // Init authenticated client
  // ----------------------------
  Future<void> _init() async {
    if (_client != null) return;

    final jsonStr = await rootBundle.loadString(_credPath);
    final jsonMap = json.decode(jsonStr);
    final credentials = ServiceAccountCredentials.fromJson(jsonMap);

    const scopes = ['https://www.googleapis.com/auth/cloud-platform'];

    _client = await clientViaServiceAccount(credentials, scopes);
  }

  // ----------------------------
  // Cache paths + file helpers
  // ----------------------------
  String _fileNameFor(
    String text,
    String lang, {
    String? voiceName,
    double? speakingRate,
    double? pitch,
    String? ssmlFingerprint,
  }) {
    // include voice + params + optional ssml fingerprint for uniqueness
    final key =
        "$lang|${voiceName ?? ''}|${speakingRate ?? ''}|${pitch ?? ''}|${ssmlFingerprint ?? ''}|$text";
    final hash = md5.convert(utf8.encode(key)).toString();
    return "tts_$hash.mp3";
  }

  Future<Directory> _cacheDir() async {
    final dir = await getTemporaryDirectory();
    final cacheDir = Directory("${dir.path}/gcloud_tts_cache");
    if (!cacheDir.existsSync()) cacheDir.createSync(recursive: true);
    return cacheDir;
  }

  Future<File> _cacheFile(
    String text,
    String lang, {
    String? voiceName,
    double? speakingRate,
    double? pitch,
    String? ssmlFingerprint,
  }) async {
    final cacheDir = await _cacheDir();
    return File(
      "${cacheDir.path}/${_fileNameFor(text, lang, voiceName: voiceName, speakingRate: speakingRate, pitch: pitch, ssmlFingerprint: ssmlFingerprint)}",
    );
  }

  // accompanying JSON metadata path
  Future<File> _metaFileFor(File audioFile) async {
    final p = audioFile.path;
    return File(p.replaceAll(RegExp(r'\.mp3$'), '.json'));
  }

  // ----------------------------
  // Build SSML string from either plain text or segments (multi-voice)
  // segments: optional List<Map<String,String>> where each map: {'voiceName':..., 'text':...}
  // If segments provided, we create <speak><voice name="...">text</voice>...</speak>
  // ----------------------------
  String _buildSsml(String text, {List<Map<String, String>>? segments}) {
    if (segments != null && segments.isNotEmpty) {
      final buffer = StringBuffer('<speak>');
      for (final seg in segments) {
        final vn = seg['voiceName'];
        final t = seg['text'] ?? '';
        if (vn != null && vn.isNotEmpty) {
          buffer.write('<voice name="$vn">${_escapeSsml(t)}</voice>');
        } else {
          buffer.write(_escapeSsml(t));
        }
      }
      buffer.write('</speak>');
      return buffer.toString();
    }

    return '<speak>${_escapeSsml(text)}</speak>';
  }

  String _escapeSsml(String s) {
    // basic escaping - avoid raw < & etc.
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  // ----------------------------
  // Synthesize page with timepoints and caching metadata
  //
  // Accepts:
  // - text: page text (or ignored if using segments)
  // - languageCode: e.g. en-US or fil-PH
  // - voiceName: optional main voice if not using segments
  // - speakingRate: 0.5..2.0
  // - pitch: -20..20 (Google uses semitone-like values; we'll pass small floats)
  // - segments: optional multi-voice segments list [{ 'voiceName': 'en-US-Studio-O', 'text': 'Once upon...' }, ...]
  //
  // Returns:
  // { 'path': String?, 'timepoints': List<int> } where timepoints are milliseconds
  // ----------------------------
  Future<Map<String, dynamic>> synthesizePageToCacheWithTimepoints(
    String text, {
    required String languageCode,
    String? voiceName,
    double? speakingRate,
    double? pitch,
    List<Map<String, String>>? segments,
  }) async {
    await _init();

    // Build SSML (segments wins if provided)
    final ssml = _buildSsml(text, segments: segments);

    // fingerprint to include in cache key (shortened)
    final ssmlFingerprint = md5
        .convert(utf8.encode(ssml))
        .toString()
        .substring(0, 8);

    final audioFile = await _cacheFile(
      text,
      languageCode,
      voiceName: voiceName,
      speakingRate: speakingRate,
      pitch: pitch,
      ssmlFingerprint: ssmlFingerprint,
    );

    final metaFile = await _metaFileFor(audioFile);

    // If audio + metadata exist and metadata matches parameters, load metadata (no synth)
    if (audioFile.existsSync() && metaFile.existsSync()) {
      try {
        final meta =
            jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
        // basic validation: language + voice + rate + pitch fingerprint
        if ((meta['languageCode'] == languageCode) &&
            (meta['voiceName'] == (voiceName ?? meta['voiceName'])) &&
            (meta['ssmlFingerprint'] == ssmlFingerprint) &&
            (meta['speakingRate'] == (speakingRate ?? meta['speakingRate'])) &&
            (meta['pitch'] == (pitch ?? meta['pitch']))) {
          final tps =
              (meta['timepoints'] as List<dynamic>?)
                  ?.map((e) => e as int)
                  .toList() ??
              <int>[];
          return {'path': audioFile.path, 'timepoints': tps};
        }
        // else continue to synthesize
      } catch (_) {
        // fallthrough to synth
      }
    }

    try {
      final url = Uri.parse(
        'https://texttospeech.googleapis.com/v1/text:synthesize',
      );

      final requestBody = {
        'input': {'ssml': ssml},
        'voice': {
          'languageCode': languageCode,
          if (voiceName != null) 'name': voiceName,
        },
        'audioConfig': {
          'audioEncoding': 'MP3',
          if (speakingRate != null) 'speakingRate': speakingRate,
          if (pitch != null) 'pitch': pitch,
        },
        // request word-level timepoints
        'enableTimePointing': ['WORD'],
      };

      final resp = await _client!.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final jsonRes = jsonDecode(resp.body) as Map<String, dynamic>;

      // ensure audioContent exists
      final audioContent = jsonRes['audioContent'] as String?;
      if (audioContent == null) {
        return {'path': null, 'timepoints': <int>[]};
      }

      final bytes = base64.decode(audioContent);
      await audioFile.writeAsBytes(bytes);

      // parse timepoints
      final List<int> timepoints = [];
      if (jsonRes['timepoints'] != null && jsonRes['timepoints'] is List) {
        for (final tp in jsonRes['timepoints'] as List) {
          // each tp has { markName, timeSeconds }
          final sec = double.parse(tp['timeSeconds'].toString());
          timepoints.add((sec * 1000).round());
        }
      }

      // save metadata
      final meta = {
        'languageCode': languageCode,
        'voiceName': voiceName,
        'speakingRate': speakingRate,
        'pitch': pitch,
        'ssmlFingerprint': ssmlFingerprint,
        'timepoints': timepoints,
        'generatedAt': DateTime.now().toIso8601String(),
      };
      await metaFile.writeAsString(jsonEncode(meta));

      return {'path': audioFile.path, 'timepoints': timepoints};
    } catch (e) {
      print('Google TTS synthesis error: $e');
      return {'path': null, 'timepoints': <int>[]};
    }
  }

  // ----------------------------
  // Play local file
  // ----------------------------
  Future<void> playFromFile(String path) async {
    try {
      await _player.setFilePath(path);
      int attempts = 0;
      while (_player.duration == null && attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 70));
        attempts++;
      }
      await _player.play();
    } catch (e) {
      print('Google TTS play error: $e');
    }
  }

  // ----------------------------
  // Stop
  // ----------------------------
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  // ----------------------------
  // Seek (ms)
  // ----------------------------
  Future<void> seek(double ms) async {
    try {
      await _player.seek(Duration(milliseconds: ms.toInt()));
    } catch (_) {}
  }
}
