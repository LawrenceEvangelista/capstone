// lib/features/quiz/presentation/screens/age_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:testapp/features/quiz/presentation/screens/quiz_entry_screen.dart';
import 'package:testapp/features/quiz/application/quiz_service.dart';
import 'package:testapp/features/quiz/data/models/quiz_settings.dart';

class AgePickerScreen extends StatelessWidget {
  final String storyId;
  final String storyTitle;

  const AgePickerScreen({
    super.key,
    required this.storyId,
    required this.storyTitle,
  });

  void _openEntry(BuildContext ctx, int age) {
    final defaults = QuizService.defaultDifficultiesForAge(age);
    final settings = QuizSettings(
      difficulties: defaults,
      language:
          'auto', // 'auto' => use UI to choose en/fil/both (default shows UI)
      numQuestions: 10,
    );

    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder:
            (_) => QuizEntryScreen(
              storyId: storyId,
              storyTitle: storyTitle,
              initialSettings: settings,
              age: age,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = [
      {'label': '4 - 5', 'age': 5},
      {'label': '6 - 7', 'age': 6},
      {'label': '8 - 9', 'age': 8},
      {'label': '10 - 12', 'age': 10},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Who is playing?', style: GoogleFonts.fredoka()),
        backgroundColor: const Color(0xFFFFD93D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'How old is the child?',
              style: GoogleFonts.fredoka(fontSize: 20),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children:
                    groups.map((g) {
                      final label = g['label']!.toString();
                      final age = g['age'] as int;
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _openEntry(context, age),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label,
                              style: GoogleFonts.fredoka(fontSize: 22),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Recommended',
                              style: GoogleFonts.fredoka(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
