class QuestionModel {
  final String questionEng;
  final String questionTag;
  final List<String> optionsEng;
  final List<String> optionsTag;
  final int correctAnswer;
  final String explanationEng;
  final String explanationTag;

  QuestionModel({
    required this.questionEng,
    required this.questionTag,
    required this.optionsEng,
    required this.optionsTag,
    required this.correctAnswer,
    required this.explanationEng,
    required this.explanationTag,
  });

  factory QuestionModel.fromMap(Map<dynamic, dynamic> map) {
    return QuestionModel(
      questionEng: map['questionEng'] ?? '',
      questionTag: map['questionTag'] ?? '',
      optionsEng:
          (map['optionsEng'] as List?)?.map((e) => e.toString()).toList() ?? [],
      optionsTag:
          (map['optionsTag'] as List?)?.map((e) => e.toString()).toList() ?? [],
      correctAnswer: map['correctAnswer'] ?? 0,
      explanationEng: map['explanationEng'] ?? '',
      explanationTag: map['explanationTag'] ?? '',
    );
  }

  get shuffledCorrectIndex => null;

  get shuffledOptionsEng => null;

  void operator [](String other) {}
}

/**class QuestionModel {
  final String id;
  final String questionEng;
  final String? questionTag;
  final List<String> optionsEng;
  final List<String>? optionsTag;
  final int? correctAnswer;
  final int? shuffledCorrectIndex;
  final List<String>? shuffledOptionsEng;
  final List<String>? shuffledOptionsTag;
  final String? type; // 'text', 'image', 'audio'
  final String? imageUrl;
  final String? audioUrl;

  QuestionModel({
    required this.id,
    required this.questionEng,
    this.questionTag,
    required this.optionsEng,
    this.optionsTag,
    this.correctAnswer,
    this.shuffledCorrectIndex,
    this.shuffledOptionsEng,
    this.shuffledOptionsTag,
    this.type,
    this.imageUrl,
    this.audioUrl,
  });

  factory QuestionModel.fromMap(Map<String, dynamic> data, String id) {
    return QuestionModel(
      id: id,
      questionEng: data['questionEng'] ?? '',
      questionTag: data['questionTag'],
      optionsEng: List<String>.from(data['optionsEng'] ?? []),
      optionsTag: data['optionsTag'] != null
          ? List<String>.from(data['optionsTag'])
          : null,
      correctAnswer: data['correctAnswer'],
      shuffledCorrectIndex: data['shuffledCorrectIndex'],
      shuffledOptionsEng: data['shuffledOptionsEng'] != null
          ? List<String>.from(data['shuffledOptionsEng'])
          : null,
      shuffledOptionsTag: data['shuffledOptionsTag'] != null
          ? List<String>.from(data['shuffledOptionsTag'])
          : null,
      type: data['type'],
      imageUrl: data['imageUrl'],
      audioUrl: data['audioUrl'],
    );
  }
}
**/
