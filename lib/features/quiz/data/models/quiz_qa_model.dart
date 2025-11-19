// lib/features/quiz/data/models/question_model.dart

class QuestionModel {
  final String id;
  final String questionEng;
  final List<String> optionsEng;
  final int correctAnswer;

  QuestionModel({
    required this.id,
    required this.questionEng,
    required this.optionsEng,
    required this.correctAnswer,
  });

  /// Convert Firebase map -> QuestionModel
  factory QuestionModel.fromMap(String id, Map<dynamic, dynamic> map) {
    // Parse options (list or map)
    List<String> parsedOptions = [];
    final rawOptions = map['optionsEng'];

    if (rawOptions is List) {
      parsedOptions = rawOptions.map((e) => e.toString()).toList();
    } else if (rawOptions is Map) {
      parsedOptions = rawOptions.values.map((e) => e.toString()).toList();
    }

    // Correct answer index
    int correct = 0;
    final rawCorrect = map['correctAnswer'];
    if (rawCorrect is int) correct = rawCorrect;
    if (rawCorrect is String) correct = int.tryParse(rawCorrect) ?? 0;

    return QuestionModel(
      id: id,
      questionEng: map['questionEng'] ?? 'No question',
      optionsEng: parsedOptions,
      correctAnswer: correct,
    );
  }
}
