import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../providers/localization_provider.dart';

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

  final Color yellow = const Color(0xFFFFD93D);
  final Color dark = Colors.black87;

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  /// ✅ Automatically detects where your quiz questions are located
  Future<void> _loadQuizData() async {
    try {
      final db = FirebaseDatabase.instance.ref();

      // Try both possible Firebase paths
      final path1 = 'stories/${widget.storyId}/quiz/questions';
      final path2 = 'stories/${widget.storyId}/quiz/owl_legend/questions';

      DataSnapshot snapshot = await db.child(path1).get();

      if (!snapshot.exists) {
        snapshot = await db.child(path2).get();
      }

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        _processQuestionsData(data);
      } else {
        setState(() {
          isLoading = false;
          questions = [];
        });
        debugPrint('❌ No quiz found for story: ${widget.storyId}');
      }
    } catch (e) {
      debugPrint('❌ Error loading quiz: $e');
      setState(() {
        isLoading = false;
        questions = [];
      });
    }
  }

  void _processQuestionsData(Map<dynamic, dynamic> data) {
    final loaded = <QuizQuestion>[];
    data.forEach((id, value) {
      final map = Map<String, dynamic>.from(value);
      loaded.add(
        QuizQuestion(
          id: id.toString(),
          questionEng: map['questionEng'] ?? 'No question',
          optionsEng: List<String>.from(map['optionsEng'] ?? []),
          correctAnswer: int.tryParse(map['correctAnswer'].toString()) ?? 0,
        ),
      );
    });

    setState(() {
      questions = loaded;
      selectedAnswers = List.filled(loaded.length, null);
      isLoading = false;
    });
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

  void _calculateScore() {
    int correct = 0;
    for (int i = 0; i < questions.length; i++) {
      if (selectedAnswers[i] == questions[i].correctAnswer) correct++;
    }
    setState(() {
      score = correct;
      quizCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: yellow,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );
    }

    if (questions.isEmpty) {
      final localization = Provider.of<LocalizationProvider>(context, listen: false);
      return Scaffold(
        backgroundColor: yellow,
        appBar: AppBar(
          title: Text(localization.translate('noQuizFound')),
          backgroundColor: yellow,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.black54),
              const SizedBox(height: 16),
              Text(
                localization.translate('noQuizDataAvailable'),
                style: GoogleFonts.fredoka(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, foregroundColor: Colors.white),
                child: Text(localization.translate('back')),
              ),
            ],
          ),
        ),
      );
    }

    if (quizCompleted) {
      final localization = Provider.of<LocalizationProvider>(context, listen: false);
      final percent = ((score / questions.length) * 100).round();
      return Scaffold(
        backgroundColor: yellow,
        appBar: AppBar(
          title: Text(localization.translate('quizComplete')),
          backgroundColor: yellow,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${localization.translate('score')} $score / ${questions.length}',
                  style: GoogleFonts.fredoka(fontSize: 24, fontWeight: FontWeight.bold)),
              Text('$percent%', style: GoogleFonts.fredoka(fontSize: 20, color: dark)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    currentQuestionIndex = 0;
                    quizCompleted = false;
                    score = 0;
                    selectedAnswers = List.filled(questions.length, null);
                  });
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: dark, foregroundColor: Colors.white),
                child: Text(localization.translate('tryAgain')),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localization.translate('back'), style: const TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      );
    }

    final q = questions[currentQuestionIndex];

    return Consumer<LocalizationProvider>(
      builder: (context, localization, _) => Scaffold(
        backgroundColor: yellow,
        appBar: AppBar(
          backgroundColor: yellow,
          title: Text(
            '${localization.translate('question')} ${currentQuestionIndex + 1}/${questions.length}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.sniglet(fontSize: 20),
          ),
        ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / questions.length,
              backgroundColor: Colors.white,
              color: dark,
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  q.questionEng,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.fredoka(fontSize: 18, color: dark),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: q.optionsEng.length,
                itemBuilder: (context, i) {
                  final isSelected = selectedAnswers[currentQuestionIndex] == i;
                  return Card(
                    color: isSelected ? dark : Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        q.optionsEng[i],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.fredoka(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () => _selectAnswer(i),
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
                    onPressed: () => setState(() => currentQuestionIndex--),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, foregroundColor: dark),
                    child: Consumer<LocalizationProvider>(
                      builder: (context, localization, _) =>
                        Text(localization.translate('previous')),
                    ),
                  ),
                ElevatedButton(
                  onPressed:
                  selectedAnswers[currentQuestionIndex] != null ? _nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: dark, foregroundColor: Colors.white),
                  child: Text(
                    currentQuestionIndex == questions.length - 1 ? localization.translate('finish') : localization.translate('next'),
                  ),
                ),
              ],
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
