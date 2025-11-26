// lib/features/quiz/application/quiz_service.dart
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:testapp/features/quiz/data/models/question_model.dart';

class QuizService {
  // Map ages to default difficulty sets (Option A: AUTO)
  // returns a list of difficulties to use (e.g., ['easy'], ['medium','easy'], etc.)
  static List<String> defaultDifficultiesForAge(int age) {
    if (age <= 5) return ['easy'];
    if (age <= 7) return ['easy', 'medium'];
    if (age <= 9) return ['medium'];
    if (age <= 12) return ['medium', 'hard'];
    return ['medium', 'hard'];
  }

  static Future<List<QuestionModel>> loadQuestionsForStory({
    required String storyId,
    List<String>? difficulties, // e.g. ['easy','medium']
    int maxQuestions = 10,
  }) async {
    final ref = FirebaseDatabase.instance.ref('stories/$storyId/quiz');
    final snap = await ref.get();
    if (!snap.exists || snap.value == null || snap.value is! Map) {
      return [];
    }

    // first folder inside "quiz"
    final quizFolderKey = (snap.value as Map).keys.first;
    final baseRef = ref.child(quizFolderKey);

    final List<QuestionModel> all = [];

    final diffs =
        (difficulties == null || difficulties.isEmpty)
            ? ['easy', 'medium', 'hard']
            : difficulties;

    for (final dif in diffs) {
      final difSnap = await baseRef.child(dif).get();
      if (!difSnap.exists || difSnap.value == null || difSnap.value is! Map) {
        continue;
      }
      final raw = difSnap.value as Map;
      raw.forEach((qid, qdata) {
        if (qdata is Map) {
          final map = Map<String, dynamic>.from(qdata);
          map['id'] = qid.toString();
          map['difficulty'] = dif;
          try {
            all.add(QuestionModel.fromJson(map));
          } catch (e) {
            // ignore malformed question but log if you want
            // print('Malformed question $qid: $e');
          }
        }
      });
    }

    // shuffle and pick up to maxQuestions (balanced selection optional)
    all.shuffle(Random());
    return all.take(maxQuestions).toList();
  }
}
