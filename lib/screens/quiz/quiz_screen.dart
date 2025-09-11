import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  String searchQuery = '';
  String selectedCategory = 'All Categories';
  String selectedQuizStatus = 'All';

  List<String> allCategories = ['Folktale', 'Legend', 'Fables', 'Fiction'];
  List<String> quizStatuses = ['All', 'Completed', 'Incomplete'];

  List<Map<String, String>> allStories = [
    {'title': 'Story 1 - Folktale', 'category': 'Folktale', 'progress': '0.75'},
    {'title': 'Story 2 - Legend', 'category': 'Legend', 'progress': '0.5'},
    {'title': 'Story 3 - Fables', 'category': 'Fables', 'progress': '1.0'},
    {'title': 'Story 4 - Fiction', 'category': 'Fiction', 'progress': '0.0'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD93D),
        title: Text('Quiz', style: GoogleFonts.sniglet(fontSize: 20)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
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

          // Category & Quiz Status Filter
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
    List<Map<String, String>> filteredStories =
        allStories.where((story) {
          final matchesCategory =
              selectedCategory == 'All Categories' ||
              story['category'] == selectedCategory;

          final matchesSearch = story['title']!.toLowerCase().contains(
            searchQuery.toLowerCase(),
          );

          final progress = double.tryParse(story['progress'] ?? '0') ?? 0.0;

          final matchesQuizStatus =
              selectedQuizStatus == 'All' ||
              (selectedQuizStatus == 'Completed' && progress == 1.0) ||
              (selectedQuizStatus == 'Incomplete' && progress < 1.0);

          return matchesCategory && matchesSearch && matchesQuizStatus;
        }).toList();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        var story = filteredStories[index];

        final double progress =
            double.tryParse(story['progress'] ?? '0') ?? 0.0;

        return GestureDetector(
          onTap: () {
            // TODO: Navigate to actual quiz screen for this story
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opening quiz for: ${story['title']}')),
            );
          },
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Image Placeholder
                Container(
                  width: 120,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    border: Border.all(color: Colors.grey, width: 2),
                    color: Colors.white,
                  ),
                  child: const Center(
                    child: Icon(Icons.image, color: Colors.grey, size: 40),
                  ),
                ),

                // Story Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story['title']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Short description or intro here.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const Spacer(),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white,
                          color: Colors.blueAccent,
                          minHeight: 6,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          progress == 0.0
                              ? 'Not taken yet'
                              : '${(progress * 100).toInt()}% quiz taken',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
