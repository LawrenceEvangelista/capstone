// lib/features/quiz/presentation/screens/story_quiz_start_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:testapp/features/quiz/data/models/question_model.dart';
import 'package:testapp/features/quiz/presentation/screens/quiz_qa.dart';
import '../../../../providers/localization_provider.dart';

class StoryQuizStartScreen extends StatefulWidget {
  final String storyId;
  final String storyTitle;
  final String storyImage;

  const StoryQuizStartScreen({
    super.key,
    required this.storyId,
    required this.storyTitle,
    required this.storyImage,
  });

  @override
  State<StoryQuizStartScreen> createState() => _StoryQuizStartScreenState();
}

class _StoryQuizStartScreenState extends State<StoryQuizStartScreen> {
  final DatabaseReference _storiesRef = FirebaseDatabase.instance.ref().child(
    'stories',
  );
  bool _loading = true;
  int _availableQuestions = 0;
  List<Map<String, dynamic>> _flatQuestions = [];

  static const int kQuestionsPerAttempt = 10;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _loading = true);
    try {
      final DataSnapshot snap =
          (await _storiesRef.child(widget.storyId).once()).snapshot;
      if (snap.value != null && snap.value is Map) {
        final data = snap.value as Map;
        final quizNode = data['quiz'];

        List<Map<String, dynamic>> collected = [];

        if (quizNode != null && quizNode is Map) {
          // Case A: quiz/questions direct
          if (quizNode.containsKey('questions') &&
              quizNode['questions'] is Map) {
            final questions = quizNode['questions'] as Map;
            for (var k in questions.keys) {
              final q = questions[k];
              if (q is Map) {
                collected.add({'id': k, ...Map<String, dynamic>.from(q)});
              }
            }
          } else {
            // Case B: multiple quizzes under quiz/
            for (var quizKey in (quizNode).keys) {
              final qChild = quizNode[quizKey];
              if (qChild is Map &&
                  qChild.containsKey('questions') &&
                  qChild['questions'] is Map) {
                final questions = qChild['questions'] as Map;
                for (var k in questions.keys) {
                  final q = questions[k];
                  if (q is Map) {
                    // annotate with parent quiz id so we can trace later
                    collected.add({
                      'id': k,
                      'parentQuizId': quizKey,
                      ...Map<String, dynamic>.from(q),
                    });
                  }
                }
              }
            }
          }
        }

        setState(() {
          _flatQuestions = collected;
          _availableQuestions = collected.length;
          _loading = false;
        });
      } else {
        setState(() {
          _flatQuestions = [];
          _availableQuestions = 0;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading story quiz questions: $e');
      setState(() {
        _flatQuestions = [];
        _availableQuestions = 0;
        _loading = false;
      });
    }
  }

  void _startQuiz() {
    if (_flatQuestions.isEmpty) return;

    final rnd = Random();
    final shuffled = List<Map<String, dynamic>>.from(_flatQuestions)
      ..shuffle(rnd);
    final take = shuffled.take(kQuestionsPerAttempt).toList();

    // Shuffle options for each question if options exist
    for (var q in take) {
      if (q.containsKey('optionsEng') && q['optionsEng'] is List) {
        // keep correctAnswer index mapping — we will shuffle pairs of (option, originalIndex)
        final List options = List.from(q['optionsEng']);
        final int correctIndex =
            (q['correctAnswer'] is int) ? q['correctAnswer'] as int : 0;

        List<Map<String, dynamic>> pairs = [];
        for (int i = 0; i < options.length; i++) {
          pairs.add({'text': options[i], 'originalIndex': i});
        }
        pairs.shuffle(rnd);

        // build new options and translate correct index
        q['shuffledOptionsEng'] = pairs.map((e) => e['text']).toList();
        q['shuffledCorrectIndex'] = pairs.indexWhere(
          (e) => e['originalIndex'] == correctIndex,
        );
      }
      // same for Tag if your QuizQa wants both languages
      if (q.containsKey('optionsTag') && q['optionsTag'] is List) {
        final List optionsTag = List.from(q['optionsTag']);
        // we already shuffled using optionsEng pairs if both exist — keep consistent by mapping via index, skip for brevity
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => QuizQa(
              storyId: widget.storyId,
              storyTitle: widget.storyTitle,
              questions: take.map((q) => QuestionModel.fromMap(q)).toList(),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(
      context,
      listen: false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('startQuiz')),
        backgroundColor: const Color(0xFFFFD93D),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    if (widget.storyImage.isNotEmpty)
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(widget.storyImage),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      widget.storyTitle,
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localization.translate('quizInstructions') ??
                          'Answer the questions. Good luck!',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Chip(label: Text('Available: $_availableQuestions')),
                        const SizedBox(width: 12),
                        Chip(label: Text('Per attempt: $kQuestionsPerAttempt')),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed:
                          _availableQuestions >= kQuestionsPerAttempt
                              ? _startQuiz
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6D00),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 36,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        localization.translate('startQuiz'),
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(localization.translate('back')),
                    ),
                  ],
                ),
              ),
    );
  }
}
