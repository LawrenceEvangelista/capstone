import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:testapp/features/stories/data/models/story_model.dart';
import 'package:testapp/features/quiz/presentation/screens/quiz_qa.dart'; // ✅ Correct import path

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

  // ✅ Corrected story IDs to match Firebase
  List<StoryModel> allStories = [
    StoryModel(
      id: 'story1', // 👈 matches your Firebase story node
      title: 'The Owl Legend',
      category: 'Legend',
      progress: 0.8,
    ),
    StoryModel(
      id: 'story2',
      title: 'The Monkey and the Turtle',
      category: 'Fables',
      progress: 1.0,
    ),
    StoryModel(
      id: 'story3',
      title: 'The Origin of the Pineapple',
      category: 'Folktale',
      progress: 0.5,
    ),
    StoryModel(
      id: 'story4',
      title: 'The Secret Mountain',
      category: 'Fiction',
      progress: 0.0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD93D),
        title: Text('Story Quizzes', style: GoogleFonts.sniglet(fontSize: 20)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
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

          // 🧩 Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('Category: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: selectedCategory,
                  onChanged: (newCategory) {
                    setState(() {
                      selectedCategory = newCategory!;
                    });
                  },
                  items: ['All Categories', ...allCategories]
                      .map((value) => DropdownMenuItem(
                    value: value,
                    child: Text(value),
                  ))
                      .toList(),
                ),
                const Spacer(),
                const Text('Status: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: selectedQuizStatus,
                  onChanged: (newStatus) {
                    setState(() {
                      selectedQuizStatus = newStatus!;
                    });
                  },
                  items: quizStatuses
                      .map((value) => DropdownMenuItem(
                    value: value,
                    child: Text(value),
                  ))
                      .toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 🗂️ Filtered Story List
          Expanded(child: _buildStoryList()),
        ],
      ),
    );
  }

  Widget _buildStoryList() {
    // 🧠 Filtering logic
    List<StoryModel> filteredStories = allStories.where((story) {
      final matchesCategory = selectedCategory == 'All Categories' ||
          story.category == selectedCategory;
      final matchesSearch =
      story.title.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesStatus = selectedQuizStatus == 'All' ||
          (selectedQuizStatus == 'Completed' && story.progress == 1.0) ||
          (selectedQuizStatus == 'Incomplete' && story.progress < 1.0);
      return matchesCategory && matchesSearch && matchesStatus;
    }).toList();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        var story = filteredStories[index];

        return GestureDetector(
          onTap: () {
            // ✅ Opens the actual quiz screen for this story
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizQa(storyId: story.id),
              ),
            );
          },
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                    const Icon(Icons.menu_book, color: Colors.black, size: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          story.title,
                          style: GoogleFonts.fredoka(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          story.category,
                          style: GoogleFonts.fredoka(
                              fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: story.progress,
                            backgroundColor: Colors.grey.shade200,
                            color: const Color(0xFFFFD93D),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
