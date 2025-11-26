// lib/features/quiz/models/quiz_settings.dart
class QuizSettings {
  final List<String> difficulties;
  final String language; // 'en', 'fil', 'both', or 'auto'
  final int numQuestions;

  QuizSettings({
    required this.difficulties,
    required this.language,
    required this.numQuestions,
  });

  QuizSettings copyWith({
    List<String>? difficulties,
    String? language,
    int? numQuestions,
  }) {
    return QuizSettings(
      difficulties: difficulties ?? this.difficulties,
      language: language ?? this.language,
      numQuestions: numQuestions ?? this.numQuestions,
    );
  }
}
