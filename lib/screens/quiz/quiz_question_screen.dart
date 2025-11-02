// lib/screens/quiz/quiz_question_screen.dart

import 'package:flutter/material.dart';
import '../../services/quiz_service.dart'; // Import the service

class QuizQuestionScreen extends StatefulWidget {
  final String storyId;
  const QuizQuestionScreen({super.key, required this.storyId});

  @override
  State<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen> {
  int? _selectedIndex;
  late Future<List<Map<String, dynamic>>> quizData;
  final QuizService _quizService = QuizService(); // Use the service

  @override
  void initState() {
    super.initState();
    // Fetch data using the service
    quizData = _quizService.fetchQuizData(widget.storyId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Quiz Question'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: quizData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading quiz data'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No quiz data available for this story.'));
          }

          var question = snapshot.data![0];
          List<String> options = [
            question['o1_en'] as String,
            question['o2_en'] as String,
            question['o3_en'] as String,
            question['o4_en'] as String,
          ];

          // UI Design (Question, Options) is Preserved
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Story Title: ${question['story_title']}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Display question (Design Preserved)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    question['q_en'] as String,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 16),

                // Display options (Design Preserved)
                for (int index = 0; index < options.length; index++)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                        _selectedIndex == index ? Colors.yellow.shade100 : Colors.white,
                        border: Border.all(
                          color: _selectedIndex == index ? Colors.blue : Colors.grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        options[index],
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}