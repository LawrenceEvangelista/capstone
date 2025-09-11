import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class QuizQa extends StatefulWidget {
  final String storyId; // Story ID to dynamically load the quizzes

  // Constructor
  const QuizQa({super.key, required this.storyId});

  @override
  State<QuizQa> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizQa> {
  int? _selectedIndex; // Track selected option
  late Future<List<Map<String, dynamic>>> quizData;

  @override
  void initState() {
    super.initState();
    quizData = fetchQuizData(
      widget.storyId,
    ); // Fetch quizzes based on the story ID
  }

  // Fetch quiz data from Firebase for the specific story
  Future<List<Map<String, dynamic>>> fetchQuizData(String storyId) async {
    List<Map<String, dynamic>> questions = [];
    try {
      // Query to fetch quizzes from the specific story
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('stories')
              .doc(storyId) // Use dynamic storyId
              .collection('quiz') // Quizzes subcollection
              .get();

      // Loop through the snapshot to add each question and options
      snapshot.docs.forEach((doc) {
        var data = doc.data() as Map<String, dynamic>;
        questions.add(data); // Add the question and options to the list
      });
    } catch (e) {
      print("Error fetching quiz data: $e");
    }
    return questions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: const Text('Quiz'),
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
            return const Center(child: Text('No quiz data available'));
          }

          var question =
              snapshot.data![0]; // Assume we're displaying the first question
          List<String> options = [
            question['o1_en'],
            question['o2_en'],
            question['o3_en'],
            question['o4_en'],
          ];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Story Title: ${question['story_title']}', // Dynamically set the story title here
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Display question
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    question['q_en'], // English question
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 16),

                // Display options
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
                            _selectedIndex == index
                                ? Colors.yellow.shade100
                                : Colors.white,
                        border: Border.all(
                          color:
                              _selectedIndex == index
                                  ? Colors.blue
                                  : Colors.grey,
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
