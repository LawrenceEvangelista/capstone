import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:testapp/providers/localization_provider.dart';

class QuizQa extends StatefulWidget {
  final String storyId;
  const QuizQa({super.key, required this.storyId});

  @override
  State<QuizQa> createState() => _QuizQaState();
}

class _QuizQaState extends State<QuizQa> {
  List<QuizQuestion> questions = [];
  int currentQuestionIndex = 0;
  List<int?> selectedAnswers = [];
  bool isLoading = true;
  bool quizCompleted = false;
  int score = 0;

  final Color mustardYellow = const Color(0xFFFFD93D);
  final Color darkYellow = const Color(0xFFE6C235);

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  /// ✅ Loads quiz questions dynamically and safely
  Future<void> _loadQuizData() async {
    try {
      print('🔍 Loading quiz for story: ${widget.storyId}');
      final dbRef = FirebaseDatabase.instance.ref();

      // Try both possible quiz paths
      final path1 = 'stories/${widget.storyId}/quiz/${widget.storyId}/questions';
      final path2 = 'stories/${widget.storyId}/quiz/questions';

      DataSnapshot snapshot = await dbRef.child(path1).get();

      if (!snapshot.exists) {
        print('⚠️ Path1 not found, trying path2...');
        snapshot = await dbRef.child(path2).get();
      }

      if (snapshot.exists) {
        print('✅ FOUND QUIZ DATA!');
        final questionsData = snapshot.value as Map<dynamic, dynamic>;
        _processQuestionsData(questionsData);
      } else {
        print('❌ No quiz data found for ${widget.storyId}');
        setState(() {
          isLoading = false;
          questions = [];
        });
      }
    } catch (e) {
      print('❌ Error loading quiz: $e');
      setState(() {
        isLoading = false;
        questions = [];
      });
    }
  }

  void _processQuestionsData(Map<dynamic, dynamic> data) {
    List<QuizQuestion> loaded = [];

    data.forEach((id, value) {
      final map = Map<String, dynamic>.from(value);
      final options = _convertOptions(map['optionsEng']);
      loaded.add(
        QuizQuestion(
          id: id.toString(),
          questionEng: map['questionEng']?.toString() ?? 'No question',
          optionsEng: options,
          correctAnswer: _parseCorrectAnswer(map['correctAnswer']),
        ),
      );
    });

    loaded.sort((a, b) => a.id.compareTo(b.id));

    setState(() {
      questions = loaded;
      selectedAnswers = List.filled(loaded.length, null);
      isLoading = false;
    });

    print('🎊 Loaded ${questions.length} questions.');
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
      return optionsData.map((e) => e.toString()).toList();
    }
    if (optionsData is Map) {
      return optionsData.values.map((e) => e.toString()).toList();
    }
    return [];
  }

  void _selectAnswer(int index) {
    setState(() {
      selectedAnswers[currentQuestionIndex] = index;
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() => currentQuestionIndex++);
    } else {
      _calculateScore();
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() => currentQuestionIndex--);
    }
  }

  void _calculateScore() {
    int calculated = 0;
    for (int i = 0; i < questions.length; i++) {
      if (selectedAnswers[i] == questions[i].correctAnswer) calculated++;
    }
    setState(() {
      score = calculated;
      quizCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Consumer<LocalizationProvider>(
        builder: (context, localization, _) => Scaffold(
          backgroundColor: mustardYellow,
          appBar: AppBar(
            title: Text(localization.translate('loadingQuiz')),
            backgroundColor: Color(0xFFFFD93D),
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (questions.isEmpty) {
      return Consumer<LocalizationProvider>(
        builder: (context, localization, _) => Scaffold(
          backgroundColor: mustardYellow,
          appBar: AppBar(
            title: Text(localization.translate('noQuizFound')),
            backgroundColor: Color(0xFFFFD93D),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning, size: 60, color: Colors.black54),
                const SizedBox(height: 20),
                Text(localization.translate('noQuizDataAvailable'),
                    style: const TextStyle(fontSize: 16, color: Colors.black)),
              ],
            ),
          ),
        ),
      );
    }

    if (quizCompleted) return _buildResultsScreen();

    final currentQuestion = questions[currentQuestionIndex];
    final options = currentQuestion.optionsEng;

    return Consumer<LocalizationProvider>(
      builder: (context, localization, _) => Scaffold(
        backgroundColor: mustardYellow,
        appBar: AppBar(
          backgroundColor: mustardYellow,
          title: Text('${localization.translate('question')} ${currentQuestionIndex + 1} ${localization.translate('of')} ${questions.length}'),
        ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / questions.length,
              backgroundColor: Colors.grey[300],
              color: darkYellow,
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  currentQuestion.questionEng,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedAnswers[currentQuestionIndex] == index;
                  return Card(
                    color: isSelected ? darkYellow : Colors.white,
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        options[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () => _selectAnswer(index),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentQuestionIndex > 0)
                  ElevatedButton(
                    onPressed: _previousQuestion,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black),
                    child: Text(localization.translate('previous')),
                  ),
                ElevatedButton(
                  onPressed:
                  selectedAnswers[currentQuestionIndex] != null ? _nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, foregroundColor: Colors.white),
                  child: Text(currentQuestionIndex == questions.length - 1
                      ? localization.translate('finish')
                      : localization.translate('next')),
                ),
              ],
            ),
          ],
        ),
      ),
        ),
    );
  }

  Widget _buildResultsScreen() {
    final percentage = (score / questions.length * 100).round();
    return Consumer<LocalizationProvider>(
      builder: (context, localization, _) => Scaffold(
        backgroundColor: mustardYellow,
        appBar: AppBar(
          title: Text(localization.translate('quizComplete')),
          backgroundColor: mustardYellow,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${localization.translate('score')} $score/${questions.length}', style: const TextStyle(fontSize: 24)),
              Text('($percentage%)', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    currentQuestionIndex = 0;
                    selectedAnswers = List.filled(questions.length, null);
                    score = 0;
                    quizCompleted = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, foregroundColor: Colors.white),
                child: Text(localization.translate('tryAgain')),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localization.translate('back')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuizQuestion {
  final String id;
  final String questionEng;
  final List<String> optionsEng;
  final int correctAnswer;

  QuizQuestion({
    required this.id,
    required this.questionEng,
    required this.optionsEng,
    required this.correctAnswer,
  });
}
