import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class QuizNav extends StatefulWidget {
  final String quizPath;
  final String language;

  const QuizNav({
    super.key,
    required this.quizPath,
    required this.language,
  });

  @override
  State<QuizNav> createState() => _QuizNavState();
}

class _QuizNavState extends State<QuizNav> {
  List<QuizQuestion> questions = [];
  int currentQuestionIndex = 0;
  List<int?> selectedAnswers = [];
  bool isLoading = true;
  bool quizCompleted = false;
  int score = 0;

  final Color mustardYellow = Color(0xFFFFD93D);
  final Color darkYellow = Color(0xFFE6C235);

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    try {
      print('🔍 Loading quiz for story: ${widget.quizPath}');

      // Path for your structure: stories/{storyId}/quiz/questions
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('stories/${widget.quizPath}/quiz/questions')
          .get();

      if (snapshot.exists) {
        print('✅ FOUND QUIZ DATA at stories/${widget.quizPath}/quiz/questions!');
        final questionsData = snapshot.value as Map<dynamic, dynamic>;
        _processQuestionsData(questionsData);
      } else {
        print('❌ No data found at stories/${widget.quizPath}/quiz/questions');

        // Try alternative paths in case structure varies
        await _tryAlternativePaths();
      }

    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        isLoading = false;
        questions = [];
      });
    }
  }

  Future<void> _tryAlternativePaths() async {
    final alternativePaths = [
      'stories/${widget.quizPath}/questions', // If quiz is missing
      'quizzes/${widget.quizPath}/questions', // If using separate quizzes
      '${widget.quizPath}/questions', // Direct path
    ];

    for (String path in alternativePaths) {
      try {
        final snapshot = await FirebaseDatabase.instance.ref().child(path).get();
        if (snapshot.exists) {
          print('✅ FOUND DATA at alternative path: $path');
          final questionsData = snapshot.value as Map<dynamic, dynamic>;
          _processQuestionsData(questionsData);
          return;
        }
      } catch (e) {
        print('❌ Error checking path $path: $e');
      }
    }

    // If no data found anywhere
    setState(() {
      isLoading = false;
      questions = [];
    });
  }

  void _processQuestionsData(Map<dynamic, dynamic> questionsData) {
    List<QuizQuestion> loadedQuestions = [];

    questionsData.forEach((questionId, questionData) {
      final questionMap = _convertToMap(questionData);

      if (questionMap != null) {
        final optionsEng = _convertOptions(questionMap['optionsEng']);
        final optionsTag = _convertOptions(questionMap['optionsTag']);

        loadedQuestions.add(QuizQuestion(
          id: questionId.toString(),
          questionEng: questionMap['questionEng']?.toString() ?? 'No question',
          questionTag: questionMap['questionTag']?.toString() ?? 'No question',
          optionsEng: optionsEng,
          optionsTag: optionsTag,
          correctAnswer: _parseCorrectAnswer(questionMap['correctAnswer']),
          explanationEng: questionMap['explanationEng']?.toString() ?? '',
          explanationTag: questionMap['explanationTag']?.toString() ?? '',
        ));
      }
    });

    // Sort questions
    loadedQuestions.sort((a, b) => a.id.compareTo(b.id));

    setState(() {
      questions = loadedQuestions;
      selectedAnswers = List.filled(loadedQuestions.length, null);
      isLoading = false;
    });

    print('🎊 Loaded ${questions.length} questions');
  }

  Map<String, dynamic>? _convertToMap(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      return data.map<String, dynamic>((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  int _parseCorrectAnswer(dynamic correctAnswer) {
    if (correctAnswer == null) return 0;
    if (correctAnswer is int) return correctAnswer;
    if (correctAnswer is String) return int.tryParse(correctAnswer) ?? 0;
    return 0;
  }

  List<String> _convertOptions(dynamic optionsData) {
    if (optionsData == null) return [];
    if (optionsData is List) {
      return optionsData.map((item) => item.toString()).toList();
    }
    if (optionsData is Map) {
      final entries = optionsData.entries.toList();
      entries.sort((a, b) {
        final keyA = a.key is int ? a.key : int.tryParse(a.key.toString()) ?? 0;
        final keyB = b.key is int ? b.key : int.tryParse(b.key.toString()) ?? 0;
        return (keyA as Comparable).compareTo(keyB);
      });
      return entries.map((entry) => entry.value.toString()).toList();
    }
    return [];
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      selectedAnswers[currentQuestionIndex] = answerIndex;
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      _calculateScore();
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    }
  }

  void _calculateScore() {
    int calculatedScore = 0;
    for (int i = 0; i < questions.length; i++) {
      if (selectedAnswers[i] == questions[i].correctAnswer) {
        calculatedScore++;
      }
    }
    setState(() {
      score = calculatedScore;
      quizCompleted = true;
    });
  }

  void _restartQuiz() {
    setState(() {
      currentQuestionIndex = 0;
      selectedAnswers = List.filled(questions.length, null);
      score = 0;
      quizCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: mustardYellow,
        appBar: AppBar(
          title: Text('Loading Quiz...'),
          backgroundColor: mustardYellow,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading questions...'),
            ],
          ),
        ),
      );
    }

    if (quizCompleted) {
      return _buildResultsScreen();
    }

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: mustardYellow,
        appBar: AppBar(
          title: Text('No Quiz Found'),
          backgroundColor: mustardYellow,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64),
              SizedBox(height: 20),
              Text('Quiz not found at: owl_legend/questions'),
              SizedBox(height: 10),
              Text('Make sure your Firebase has this exact path'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];
    final options = widget.language == 'tag' ? currentQuestion.optionsTag : currentQuestion.optionsEng;
    final questionText = widget.language == 'tag' ? currentQuestion.questionTag : currentQuestion.questionEng;

    return Scaffold(
      backgroundColor: mustardYellow,
      appBar: AppBar(
        leading: BackButton(),
        title: Text('Question ${currentQuestionIndex + 1} of ${questions.length}'),
        backgroundColor: mustardYellow,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Progress
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / questions.length,
              backgroundColor: Colors.grey[300],
              color: darkYellow,
            ),
            SizedBox(height: 20),

            // Question
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  questionText,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Options
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedAnswers[currentQuestionIndex] == index;
                  return Card(
                    color: isSelected ? darkYellow : Colors.white,
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(String.fromCharCode(65 + index)),
                      ),
                      title: Text(options[index]),
                      trailing: Radio(
                        value: index,
                        groupValue: selectedAnswers[currentQuestionIndex],
                        onChanged: (value) => _selectAnswer(value!),
                      ),
                      onTap: () => _selectAnswer(index),
                    ),
                  );
                },
              ),
            ),

            // Navigation
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentQuestionIndex > 0)
                  ElevatedButton(
                    onPressed: _previousQuestion,
                    child: Text('Previous'),
                  ),
                ElevatedButton(
                  onPressed: selectedAnswers[currentQuestionIndex] != null ? _nextQuestion : null,
                  child: Text(currentQuestionIndex == questions.length - 1 ? 'Finish' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final percentage = (score / questions.length * 100).round();

    return Scaffold(
      backgroundColor: mustardYellow,
      appBar: AppBar(
        title: Text('Quiz Complete!'),
        backgroundColor: mustardYellow,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Score: $score/${questions.length}', style: TextStyle(fontSize: 24)),
            Text('($percentage%)', style: TextStyle(fontSize: 18)),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _restartQuiz,
              child: Text('Try Again'),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizQuestion {
  final String id;
  final String questionEng;
  final String questionTag;
  final List<String> optionsEng;
  final List<String> optionsTag;
  final int correctAnswer;
  final String explanationEng;
  final String explanationTag;

  QuizQuestion({
    required this.id,
    required this.questionEng,
    required this.questionTag,
    required this.optionsEng,
    required this.optionsTag,
    required this.correctAnswer,
    required this.explanationEng,
    required this.explanationTag,
  });
}