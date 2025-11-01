import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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

  final Color mustardYellow = Color(0xFFFFD93D);
  final Color darkYellow = Color(0xFFE6C235);

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    try {
      print('🔍 Loading quiz for story: ${widget.storyId}');

      // Use YOUR exact path: stories/{storyId}/quiz/owl_legend/questions
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('stories/${widget.storyId}/quiz/owl_legend/questions')
          .get();

      if (snapshot.exists) {
        print('✅ FOUND QUIZ DATA!');
        final questionsData = snapshot.value as Map<dynamic, dynamic>;
        _processQuestionsData(questionsData);
      } else {
        print('❌ No data found at stories/${widget.storyId}/quiz/owl_legend/questions');
        setState(() {
          isLoading = false;
          questions = [];
        });
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        isLoading = false;
        questions = [];
      });
    }
  }

  void _processQuestionsData(Map<dynamic, dynamic> questionsData) {
    List<QuizQuestion> loadedQuestions = [];

    questionsData.forEach((questionId, questionData) {
      print('=== Processing Question $questionId ===');
      final questionMap = _convertToMap(questionData);

      if (questionMap != null) {
        final optionsEng = _convertOptions(questionMap['optionsEng']);
        print('➡️ Options for $questionId: $optionsEng');
        print('➡️ Options length: ${optionsEng.length}');

        loadedQuestions.add(QuizQuestion(
          id: questionId.toString(),
          questionEng: questionMap['questionEng']?.toString() ?? 'No question',
          optionsEng: optionsEng,
          correctAnswer: _parseCorrectAnswer(questionMap['correctAnswer']),
        ));
      }
    });

    loadedQuestions.sort((a, b) => a.id.compareTo(b.id));

    setState(() {
      questions = loadedQuestions;
      selectedAnswers = List.filled(loadedQuestions.length, null);
      isLoading = false;
    });

    print('🎊 FINAL: Loaded ${questions.length} questions');
    if (questions.isNotEmpty) {
      print('🎯 First question options: ${questions[0].optionsEng}');
    }
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
    if (optionsData == null) {
      print('⚠️ optionsData is null');
      return [];
    }

    print('🔄 Converting options: $optionsData');
    print('🔄 Type: ${optionsData.runtimeType}');

    if (optionsData is List) {
      print('✅ Options is List, length: ${optionsData.length}');
      return optionsData.map((item) => item.toString()).toList();
    }

    if (optionsData is Map) {
      print('✅ Options is Map, entries: ${optionsData.entries.length}');
      final entries = optionsData.entries.toList();
      entries.sort((a, b) {
        final keyA = a.key is int ? a.key : int.tryParse(a.key.toString()) ?? 0;
        final keyB = b.key is int ? b.key : int.tryParse(b.key.toString()) ?? 0;
        return (keyA as Comparable).compareTo(keyB);
      });
      final result = entries.map((entry) => entry.value.toString()).toList();
      print('✅ Converted map to list: $result');
      return result;
    }

    print('❌ Unknown options type: ${optionsData.runtimeType}');
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
              SizedBox(height: 16),
              Text('No quiz questions found'),
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
    final options = currentQuestion.optionsEng;
    final questionText = currentQuestion.questionEng;

    print('🎯 BUILD: Current question has ${options.length} options');
    print('🎯 Options: $options');

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / questions.length,
              backgroundColor: Colors.grey[300],
              color: darkYellow,
            ),
            SizedBox(height: 8),
            Text(
              '${currentQuestionIndex + 1} of ${questions.length}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
            SizedBox(height: 20),

            // Question
            Card(
              elevation: 4,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  questionText,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Options - FIXED VERSION
            Expanded(
              child: options.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning, size: 50, color: Colors.black54),
                    SizedBox(height: 10),
                    Text('No options available', style: TextStyle(color: Colors.black87)),
                    Text('Check data structure', style: TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedAnswers[currentQuestionIndex] == index;
                  return Card(
                    color: isSelected ? darkYellow : Colors.white,
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black87 : Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index), // A, B, C
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        options[index],
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: Radio<int>(
                        value: index,
                        groupValue: selectedAnswers[currentQuestionIndex],
                        onChanged: (value) => _selectAnswer(value!),
                        activeColor: Colors.black87,
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  ),
                ElevatedButton(
                  onPressed: selectedAnswers[currentQuestionIndex] != null ? _nextQuestion : null,
                  child: Text(
                    currentQuestionIndex == questions.length - 1 ? 'Finish' : 'Next',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
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
              onPressed: () {
                setState(() {
                  currentQuestionIndex = 0;
                  selectedAnswers = List.filled(questions.length, null);
                  score = 0;
                  quizCompleted = false;
                });
              },
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
  final List<String> optionsEng;
  final int correctAnswer;

  QuizQuestion({
    required this.id,
    required this.questionEng,
    required this.optionsEng,
    required this.correctAnswer,
  });
}