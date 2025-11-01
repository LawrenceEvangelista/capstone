import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

class QuizSelectionScreen extends StatefulWidget {
  const QuizSelectionScreen({super.key});

  @override
  _QuizSelectionScreenState createState() => _QuizSelectionScreenState();
}

class _QuizSelectionScreenState extends State<QuizSelectionScreen> {
  String searchQuery = '';
  String selectedCategory = 'All Categories';
  String selectedQuizStatus = 'All';
  List<StoryWithQuiz> stories = [];
  bool isLoading = true;

  List<String> allCategories = ['Folktale', 'Legend', 'Fables', 'Fiction'];
  List<String> quizStatuses = ['All', 'Completed', 'Incomplete'];

  @override
  void initState() {
    super.initState();
    _loadStoriesWithQuizzes();
  }

  Future<void> _loadStoriesWithQuizzes() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('stories')
          .get();

      if (snapshot.exists) {
        final storiesData = snapshot.value as Map<dynamic, dynamic>;
        List<StoryWithQuiz> loadedStories = [];

        storiesData.forEach((storyId, storyData) {
          final hasQuiz = storyData['quiz'] != null;
          loadedStories.add(StoryWithQuiz(
            id: storyId.toString(),
            titleEng: storyData['titleEng'] ?? 'No Title',
            titleTag: storyData['titleTag'] ?? 'Walang Pamagat',
            category: storyData['typeEng'] ?? 'Unknown',
            hasQuiz: hasQuiz,
            progress: 0.0, // You can track user progress here
          ));
        });

        setState(() {
          stories = loadedStories;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading stories: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD93D),
        title: Text('Story Quizzes', style: GoogleFonts.sniglet(fontSize: 20)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          _buildSearchBar(),

          // Filters
          _buildFilters(),

          // Story List
          Expanded(child: _buildStoryList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
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
          onChanged: (value) => setState(() => searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search stories...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildCategoryFilter(),
            const SizedBox(width: 16),
            _buildStatusFilter(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Row(
      children: [
        Text('Category:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCategory,
              onChanged: (newCategory) => setState(() => selectedCategory = newCategory!),
              items: ['All Categories', ...allCategories].map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category, style: TextStyle(fontSize: 14)),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Row(
      children: [
        Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedQuizStatus,
              onChanged: (newStatus) => setState(() => selectedQuizStatus = newStatus!),
              items: quizStatuses.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status, style: TextStyle(fontSize: 14)),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoryList() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    final filteredStories = stories.where((story) {
      final matchesCategory = selectedCategory == 'All Categories' ||
          story.category == selectedCategory;
      final matchesSearch = story.titleEng.toLowerCase().contains(searchQuery.toLowerCase()) ||
          story.titleTag.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesStatus = selectedQuizStatus == 'All' ||
          (selectedQuizStatus == 'Completed' && story.progress == 1.0) ||
          (selectedQuizStatus == 'Incomplete' && story.progress < 1.0);

      return matchesCategory && matchesSearch && matchesStatus;
    }).toList();

    if (filteredStories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No stories found', style: TextStyle(fontSize: 18)),
            Text('Try changing your filters', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildStoryCard(filteredStories[index]),
    );
  }

  Widget _buildStoryCard(StoryWithQuiz story) {
    return GestureDetector(
      onTap: story.hasQuiz ? () => _startQuiz(story) : null,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: story.hasQuiz ? Colors.blue.shade100 : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Story Image/Icon
            _buildStoryImage(story),

            // Story Details
            _buildStoryDetails(story),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryImage(StoryWithQuiz story) {
    return Container(
      width: 120,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          bottomLeft: Radius.circular(10),
        ),
        color: Colors.grey[50],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            story.hasQuiz ? Icons.quiz : Icons.article,
            size: 40,
            color: story.hasQuiz ? Colors.blue : Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            story.hasQuiz ? 'Quiz Ready' : 'No Quiz',
            style: TextStyle(
              fontSize: 12,
              color: story.hasQuiz ? Colors.blue : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryDetails(StoryWithQuiz story) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              story.titleEng,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              story.titleTag,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCategoryColor(story.category),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                story.category,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            if (story.hasQuiz) _buildQuizProgress(story),
            if (!story.hasQuiz)
              Text(
                'Quiz coming soon',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizProgress(StoryWithQuiz story) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: story.progress,
          backgroundColor: Colors.grey[200],
          color: story.progress == 1.0 ? Colors.green : Colors.blue,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 4),
        Text(
          story.progress == 0.0
              ? 'Take quiz'
              : story.progress == 1.0
              ? 'Completed!'
              : '${(story.progress * 100).toInt()}% complete',
          style: TextStyle(
            fontSize: 12,
            color: story.progress == 1.0 ? Colors.green : Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'legend': return Colors.orange;
      case 'folktale': return Colors.green;
      case 'fables': return Colors.purple;
      case 'fiction': return Colors.blue;
      default: return Colors.grey;
    }
  }

  void _startQuiz(StoryWithQuiz story) {
    // Navigate to actual quiz screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActualQuizScreen(storyId: story.id),
      ),
    );
  }
}

class StoryWithQuiz {
  final String id;
  final String titleEng;
  final String titleTag;
  final String category;
  final bool hasQuiz;
  final double progress;

  StoryWithQuiz({
    required this.id,
    required this.titleEng,
    required this.titleTag,
    required this.category,
    required this.hasQuiz,
    required this.progress,
  });
}

// Placeholder for your actual quiz screen
class ActualQuizScreen extends StatelessWidget {
  final String storyId;

  const ActualQuizScreen({super.key, required this.storyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quiz for $storyId')),
      body: Center(child: Text('Actual Quiz Screen for $storyId')),
    );
  }
}