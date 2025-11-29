// lib/features/quiz/data/sources/quiz_firebase_source.dart
import 'package:firebase_database/firebase_database.dart';

class QuizFirebaseSource {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Returns the first quiz folder key under stories/{storyId}/quiz
  Future<String?> getFirstQuizFolder(String storyId) async {
    final ref = _db.child('stories/$storyId/quiz');
    final snap = await ref.get();
    if (!snap.exists || snap.value == null) return null;
    if (snap.value is Map) {
      final map = snap.value as Map;
      if (map.isEmpty) return null;
      return map.keys.first.toString();
    }
    return null;
  }

  /// Returns the map of questions for a difficulty under storyId -> quizFolder -> difficulty
  Future<Map<dynamic, dynamic>?> getQuestionsByDifficulty(
    String storyId,
    String quizFolder,
    String difficulty,
  ) async {
    final ref = _db.child('stories/$storyId/quiz/$quizFolder/$difficulty');
    final snap = await ref.get();
    if (!snap.exists || snap.value == null) return null;
    if (snap.value is Map) return snap.value as Map;
    return null;
  }
}
