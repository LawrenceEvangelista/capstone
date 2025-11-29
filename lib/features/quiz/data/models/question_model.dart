import 'dart:math';

class QuestionModel {
  final String id;
  final String difficulty;
  final String question;
  final List<String> choices; // original order
  final String answer;

  // Optional assets
  final String? image;
  final String? audio;

  // Runtime shuffle fields
  late final List<String> shuffledChoices;
  late final int shuffledCorrectIndex;

  QuestionModel({
    required this.id,
    required this.difficulty,
    required this.question,
    required this.choices,
    required this.answer,
    this.image,
    this.audio,
  }) {
    _shuffleChoices();
  }

  /// Shuffle choices and compute correct index
  void _shuffleChoices() {
    shuffledChoices = List<String>.from(choices);
    shuffledChoices.shuffle(Random());

    shuffledCorrectIndex = shuffledChoices.indexOf(answer);
  }

  /// Firebase JSON loader (Story Quiz Screen)
  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      choices:
          (json['choices'] as List<dynamic>).map((e) => e.toString()).toList(),
      answer: json['answer']?.toString() ?? '',
      image: json['image']?.toString(),
      audio: json['audio']?.toString(),
    );
  }

  /// Firebase loader (QuizList Screen)
  factory QuestionModel.fromMap(Map<dynamic, dynamic> map) {
    return QuestionModel(
      id: map['id']?.toString() ?? '',
      difficulty: map['difficulty']?.toString() ?? '',
      question: map['question']?.toString() ?? '',
      choices:
          (map['choices'] as List<dynamic>).map((e) => e.toString()).toList(),
      answer: map['answer']?.toString() ?? '',
      image: map['image']?.toString(),
      audio: map['audio']?.toString(),
    );
  }
}
