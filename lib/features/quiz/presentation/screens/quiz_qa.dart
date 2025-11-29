// Features/quiz/presentation/screens/quiz_qa.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:testapp/features/quiz/data/models/question_model.dart';

class QuizQa extends StatefulWidget {
  final String storyId;
  final String storyTitle;
  final List<QuestionModel> questions;
  final String languagePref;

  const QuizQa({
    super.key,
    required this.storyId,
    required this.storyTitle,
    required this.questions,
    required this.languagePref,
  });

  @override
  State<QuizQa> createState() => _QuizQaState();
}

class _QuizQaState extends State<QuizQa> {
  int _current = 0;
  int _score = 0;
  late List<int> _selected;

  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _selected = List.filled(widget.questions.length, -1);
  }

  void _submitAnswer(int selectedIndex) {
    setState(() {
      _selected[_current] = selectedIndex;

      final q = widget.questions[_current];
      final int correctIndex = q.shuffledCorrectIndex;

      if (selectedIndex == correctIndex) {
        _score++;
      }
    });
  }

  Future<void> _finishQuiz() async {
    final int total = widget.questions.length;
    final double percent = total > 0 ? (_score / total) : 0.0;

    // Save attempt to user_progress/{uid}/{storyId}/attempts/{pushId}
    if (_user != null) {
      try {
        final attemptRef =
            _db
                .child('user_progress')
                .child(_user.uid)
                .child(widget.storyId)
                .child('attempts')
                .push();
        await attemptRef.set({
          'score': _score,
          'total': total,
          'percent': percent,
          'timestamp': DateTime.now().toIso8601String(),
        });

        // update lastScore
        final lastRef = _db
            .child('user_progress')
            .child(_user.uid)
            .child(widget.storyId)
            .child('lastScore');
        await lastRef.set({
          'score': _score,
          'total': total,
          'percent': percent,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // ignore save errors but log
        debugPrint('Error saving attempt: $e');
      }
    }

    // Show results dialog
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Quiz Completed', style: GoogleFonts.fredoka()),
            content: Text(
              'You scored $_score / $total (${(percent * 100).toStringAsFixed(0)}%)',
              style: GoogleFonts.fredoka(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  Navigator.of(context).pop(); // go back to story screen
                },
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  Widget _buildQuestionCard(QuestionModel q, int index) {
    final String questionText = q.question;
    final List<String> options = q.shuffledChoices;
    final int selected = _selected[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Q${index + 1}.',
          style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(questionText, style: GoogleFonts.fredoka(fontSize: 16)),
        const SizedBox(height: 12),

        ...List.generate(options.length, (i) {
          final bool isSelected = selected == i;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: InkWell(
              onTap: () {
                if (_selected[_current] == -1) {
                  _submitAnswer(i);
                } else {
                  setState(() {
                    _selected[_current] = i;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? Colors.orange.shade100
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.orange : Colors.black12,
                  ),
                ),
                child: Text(options[i], style: GoogleFonts.fredoka()),
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.questions.length;
    final q = widget.questions[_current];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.storyTitle),
        backgroundColor: const Color(0xFFFFD93D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_current + 1) / total,
              backgroundColor: Colors.grey.shade200,
              color: Colors.orange,
              minHeight: 6,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: _buildQuestionCard(q, _current),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_current > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _current--),
                      child: const Text('Previous'),
                    ),
                  ),
                if (_current > 0) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_current < total - 1) {
                        setState(() => _current++);
                      } else {
                        _finishQuiz();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6D00),
                    ),
                    child: Text(_current < total - 1 ? 'Next' : 'Finish'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
