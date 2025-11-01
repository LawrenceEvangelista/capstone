import 'package:flutter/material.dart';
import 'quiz_qa.dart';

class QuizHomeScreen extends StatelessWidget {
  const QuizHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mustard yellow color
    final Color mustardYellow = Color(0xFFFFD93D);
    final Color darkYellow = Color(0xFFE6C235);

    return Scaffold(
      backgroundColor: mustardYellow,
      appBar: AppBar(
        title: Text(
          'Story Quizzes',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: mustardYellow,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Quiz Icon
            Icon(
              Icons.quiz,
              size: 100,
              color: Colors.black87,
            ),
            SizedBox(height: 20),

            // Title
            Text(
              'Test Your Knowledge',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),

            // Subtitle
            Text(
              'Take quizzes about your favorite stories and legends',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),

            // Story Cards
            Expanded(
              child: ListView(
                children: [
                  // Owl Legend Quiz Card
                  _buildStoryCard(
                    context: context,
                    title: 'The Legend of the Owl Quiz',
                    subtitle: '',
                    storyId: 'owl_legend', // This should match your Firebase key
                    color: darkYellow,
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String storyId,
    required Color color,
    bool enabled = true,
  }) {
    return Card(
      elevation: 4,
      color: color,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: enabled ? Colors.black87 : Colors.grey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            enabled ? Icons.auto_stories : Icons.lock,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.black54,
          ),
        ),
        trailing: enabled
            ? Icon(Icons.arrow_forward_ios, color: Colors.black87, size: 16)
            : null,
        onTap: enabled
            ? () {
          // Navigate to the quiz
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizQa(
                storyId: 'story1', // Your story ID
              ),
            ),
          );
        }
            : null,
      ),
    );
  }
}