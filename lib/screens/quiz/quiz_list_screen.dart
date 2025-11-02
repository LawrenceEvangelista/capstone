// lib/screens/quiz/quiz_list_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/story_model.dart';
import '../../widgets/quiz_story_card.dart';
import 'quiz_question_screen.dart'; // Import the screen you navigate to

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  String searchQuery = '';
  String selectedCategory = 'All Categories';
  String selectedQuizStatus = 'All';

  List<String> allCategories = ['Folktale', 'Legend', 'Fables', 'Fiction'];
  List<String> quizStatuses = ['All', 'Completed', 'Incomplete'];

  // Mock data using the new StoryModel
  List<StoryModel> allStories = [
    StoryModel(id: 's1', title: 'Story 1 - Folktale', category: 'Folktale', progress: 0.75),
    StoryModel(id: 's2', title: 'Story 2 - Legend', category: 'Legend', progress: 0.5),
    StoryModel(id: 's3', title: 'Story 3 - Fables', category: 'Fables', progress: 1.0),
    StoryModel(id: 's4', title: 'Story 4 - Fiction', category: 'Fiction', progress: 0.0),
  ];

  @override
  Widget build(BuildContext context) {
    // UI Design (App Bar, Search, Filters) is Preserved
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD93D),
        title: Text('Quiz List', style: GoogleFonts.sniglet(fontSize: 20)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar (Design Preserved)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              // ... search bar container and decoration code
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.black, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search a story or category...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ),

          // Category & Quiz Status Filter (Design Preserved)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Filter by Category: '),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: selectedCategory,
                    onChanged: (newCategory) {
                      setState(() {
                        selectedCategory = newCategory!;
                      });
                    },
                    items:
                    ['All Categories', ...allCategories]
                        .map(
                          (String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                    )
                        .toList(),
                  ),
                  const SizedBox(width: 16),
                  const Text('Filter by Quiz Status: '),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: selectedQuizStatus,
                    onChanged: (newStatus) {
                      setState(() {
                        selectedQuizStatus = newStatus!;
                      });
                    },
                    items:
                    quizStatuses
                        .map(
                          (String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                    )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),

          // Filtered Story List
          Expanded(child: _buildStoryList()),
        ],
      ),
    );
  }

  Widget _buildStoryList() {
    // Filtering Logic is Preserved but updated to use StoryModel
    List<StoryModel> filteredStories =
    allStories.where((story) {
      final matchesCategory =
          selectedCategory == 'All Categories' ||
              story.category == selectedCategory;

      final matchesSearch = story.title.toLowerCase().contains(
        searchQuery.toLowerCase(),
      );

      final matchesQuizStatus =
          selectedQuizStatus == 'All' ||
              (selectedQuizStatus == 'Completed' && story.progress == 1.0) ||
              (selectedQuizStatus == 'Incomplete' && story.progress < 1.0);

      return matchesCategory && matchesSearch && matchesQuizStatus;
    }).toList();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        var story = filteredStories[index];

        return QuizStoryCard(
          story: story,
          onTap: () {
            // Navigate to the actual quiz screen, passing the story ID
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => QuizQuestionScreen(storyId: story.id),
              ),
            );
          },
        );
      },
    );
  }
}