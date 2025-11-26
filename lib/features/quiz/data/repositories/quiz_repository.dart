// lib/features/quiz/data/repositories/quiz_repository.dart
import 'package:testapp/features/quiz/data/sources/quiz_firebase_source.dart';
import 'package:testapp/features/quiz/data/models/question_model.dart';

class QuizRepository {
  final QuizFirebaseSource source;

  QuizRepository({required this.source});

  /// Load all questions for given difficulties (list), returns list of QuestionModel
  Future<List<QuestionModel>> loadQuestions({
    required String storyId,
    required List<String> difficulties,
  }) async {
    final folder = await source.getFirstQuizFolder(storyId);
    if (folder == null) return [];

    final List<QuestionModel> all = [];

    for (final dif in difficulties) {
      final map = await source.getQuestionsByDifficulty(storyId, folder, dif);
      if (map == null) continue;

      map.forEach((qid, qdata) {
        if (qdata is Map) {
          final dataMap = Map<String, dynamic>.from(qdata);
          dataMap['id'] = qid.toString();
          dataMap['difficulty'] = dif;
          try {
            all.add(QuestionModel.fromJson(dataMap));
          } catch (e) {
            // skip invalid entry but log in debug
            // print('Invalid question $qid: $e');
          }
        }
      });
    }

    return all;
  }
}
