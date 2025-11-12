// lib/services/quiz_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class QuizService {
  // Method to fetch quiz data from Firebase for a specific story
  Future<List<Map<String, dynamic>>> fetchQuizData(String storyId) async {
    List<Map<String, dynamic>> questions = [];
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('stories')
          .doc(storyId)
          .collection('quiz')
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        questions.add(data);
      }
    } catch (e) {
      print("Error fetching quiz data in QuizService: $e");
    }
    return questions;
  }
}