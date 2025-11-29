// lib/features/quiz/presentation/screens/quiz_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:testapp/features/quiz/data/models/quiz_settings.dart';
import 'package:testapp/features/quiz/presentation/screens/quiz_qa.dart';
import 'package:testapp/features/quiz/application/quiz_service.dart';
import 'package:testapp/features/quiz/data/models/question_model.dart';

class QuizEntryScreen extends StatefulWidget {
  final String storyId;
  final String storyTitle;
  final QuizSettings initialSettings;
  final int age;

  const QuizEntryScreen({
    super.key,
    required this.storyId,
    required this.storyTitle,
    required this.initialSettings,
    required this.age,
  });

  @override
  State<QuizEntryScreen> createState() => _QuizEntryScreenState();
}

class _QuizEntryScreenState extends State<QuizEntryScreen> {
  late QuizSettings settings;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    settings = widget.initialSettings;
  }

  Widget _buildDifficultyChips() {
    final all = ['easy', 'medium', 'hard'];
    return Wrap(
      spacing: 8,
      children:
          all.map((d) {
            final selected = settings.difficulties.contains(d);
            return FilterChip(
              label: Text(d.toUpperCase()),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  final list = List<String>.from(settings.difficulties);
                  if (v) {
                    if (!list.contains(d)) list.add(d);
                  } else {
                    list.remove(d);
                  }
                  settings = settings.copyWith(difficulties: list);
                });
              },
            );
          }).toList(),
    );
  }

  Widget _buildLanguageButtons() {
    final options = ['en', 'fil', 'both'];
    return Row(
      children:
          options.map((o) {
            final active = settings.language == o;
            final label =
                o == 'both' ? 'Both' : (o == 'en' ? 'English' : 'Tagalog');
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: active,
                onSelected: (_) {
                  setState(() {
                    settings = settings.copyWith(language: o);
                  });
                },
              ),
            );
          }).toList(),
    );
  }

  Future<void> _startQuiz() async {
    setState(() => _loading = true);
    try {
      // interpret language 'both' as mixing languages - here we still load questions same; TTS will choose
      final List<QuestionModel> questions =
          await QuizService.loadQuestionsForStory(
            storyId: widget.storyId,
            difficulties: settings.difficulties,
            maxQuestions: settings.numQuestions,
          );

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No questions available.')),
        );
        setState(() => _loading = false);
        return;
      }

      // navigate to quiz screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => QuizQa(
                storyId: widget.storyId,
                storyTitle: widget.storyTitle,
                questions: questions,
                languagePref: settings.language,
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading quiz: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Start Quiz', style: GoogleFonts.fredoka()),
        backgroundColor: const Color(0xFFFFD93D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Player age: ${widget.age}',
              style: GoogleFonts.fredoka(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Difficulties (auto recommended):',
              style: GoogleFonts.fredoka(fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildDifficultyChips(),
            const SizedBox(height: 16),
            Text('Language:', style: GoogleFonts.fredoka(fontSize: 14)),
            const SizedBox(height: 8),
            _buildLanguageButtons(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _startQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6D00),
                    ),
                    child:
                        _loading
                            ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Text('Start', style: GoogleFonts.fredoka()),
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
