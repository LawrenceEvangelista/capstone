import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:testapp/features/stories/presentation/screens/story_screen.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});

  @override
  _StoriesScreenState createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  String searchQuery = '';
  String selectedCategory = 'All Categories';
  String selectedReadStatus = 'All Status';
  bool isLoading = true;

  // Firebase references
  final DatabaseReference _databaseReference =
  FirebaseDatabase.instance.ref().child('stories');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<String> readStatuses = ['All Status', 'Read', 'Unread'];
  List<String> allCategories = ['Folktale', 'Legend', 'Fable'];
  List<Map<String, dynamic>> allStories = [];

  @override
  void initState() {
    super.initState();
    fetchStories();
  }

  Future<void> fetchStories() async {
    setState(() {
      isLoading = true;
    });

    try {
      DatabaseEvent event = await _databaseReference.once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null && snapshot.value is Map) {
        Map<dynamic, dynamic> data = snapshot.value as Map;
        List<Map<String, dynamic>> fetchedStories = [];

        // Predefined valid categories with proper capitalization
        final validCategories = {'Folktale', 'Legend', 'Fable'};
        Set<String> categories = {};

        // Use Future.wait to fetch all images concurrently
        await Future.wait(
          data.entries.map((entry) async {
            final key = entry.key;
            final value = entry.value;

            if (value is Map) {
              String imageUrl = '';

              try {
                // Try to get PNG image from Firebase Storage
                imageUrl = await _storage
                    .ref('images/$key.png')
                    .getDownloadURL();
              } catch (e) {
                try {
                  // If PNG doesn't exist, try JPG
                  imageUrl = await _storage
                      .ref('images/$key.jpg')
                      .getDownloadURL();
                } catch (e) {
                  print('Error loading image for $key: $e');
                }
              }

              final title = value['titleEng'] ?? value['titleTag'] ?? 'No Title';
              final text = value['textEng'] ?? value['textTag'] ?? '';

              // Get the typeEng and normalize it for consistent categories
              String rawCategory = value['typeEng'] ?? '';
              String normalizedCategory = 'Uncategorized';

              // Normalize the category (case-insensitive matching)
              if (rawCategory.isNotEmpty) {
                String lowerCaseCategory = rawCategory.toLowerCase();

                if (lowerCaseCategory == 'folktale' || lowerCaseCategory == 'folktales') {
                  normalizedCategory = 'Folktale';
                } else if (lowerCaseCategory == 'legend' || lowerCaseCategory == 'legends') {
                  normalizedCategory = 'Legend';
                } else if (lowerCaseCategory == 'fable' || lowerCaseCategory == 'fables') {
                  normalizedCategory = 'Fable';
                } else {
                  // Only add as category if it's not a story title (simple heuristic - words > 3)
                  if (rawCategory.split(' ').length <= 3 && !rawCategory.contains('The')) {
                    normalizedCategory = rawCategory;
                  } else {
                    normalizedCategory = 'Uncategorized';
                  }
                }
              }

              // Add normalized category to our valid set
              if (normalizedCategory != 'Uncategorized') {
                categories.add(normalizedCategory);
              }

              final isRead = value['isRead'] ?? false;

              fetchedStories.add({
                'id': key,
                'title': title,
                'text': text,
                'imageUrl': imageUrl,
                'category': normalizedCategory,
                'isRead': isRead,
                'progress': value['progress'] ?? 0.0,
              });
            }
          }),
        );

        //orig
        //allCategories = <dynamic>{...validCategories, ...categories} // Remove duplicates
            //.toList()
          //..sort(); // <--- Error occurs here because the first line hasn't ended.

        setState(() {
          allStories = fetchedStories;
          // Use the predefined categories as a base and add any valid ones we found

          // FIX 1: Combine the sets into a list. The result of .toList() is a List.
          // FIX 2: Use the cascade operator (..) to apply sort() directly to the List.
          allCategories = <String>{...validCategories, ...categories}.toList()
            ..sort(); // The cascade operator applies sort() and returns the List itself.

          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching stories: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD93D),
        title: const Text('Stories'),
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
                  hintText: 'Search a story...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                  searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        searchQuery = '';
                      });
                    },
                  )
                      : null,
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

          // Filters: Category and Read Status
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
                  const Text('Filter by Read Status: '),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: selectedReadStatus,
                    onChanged: (newStatus) {
                      setState(() {
                        selectedReadStatus = newStatus!;
                      });
                    },
                    items:
                    readStatuses
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
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildStoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryList() {
    // Filter the stories by category, read status, and search query
    List<Map<String, dynamic>> filteredStories =
    allStories.where((story) {
      bool matchesCategory =
          selectedCategory == 'All Categories' ||
              story['category'] == selectedCategory;
      bool matchesReadStatus =
          selectedReadStatus == 'All Status' ||
              (selectedReadStatus == 'Read' && story['isRead'] == true) ||
              (selectedReadStatus == 'Unread' && story['isRead'] == false);
      bool matchesSearchQuery = story['title'].toLowerCase().contains(
        searchQuery.toLowerCase(),
      );

      return matchesCategory && matchesReadStatus && matchesSearchQuery;
    }).toList();

    if (filteredStories.isEmpty) {
      return const Center(
        child: Text('No stories match your filters',
            style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchStories,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filteredStories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          var story = filteredStories[index];
          return GestureDetector(
            onTap: () {
              // Navigate to StoryScreen and pass the selected story ID
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoryScreen(storyId: story['id']),
                ),
              ).then((_) {
                // Refresh the stories list when returning from StoryScreen
                // to update read status
                fetchStories();
              });
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
                  // Story image from Firebase Storage
                  Container(
                    width: 120,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      image: DecorationImage(
                        image: NetworkImage(story['imageUrl']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Story Details
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            story['title'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Category: ${story['category']}',
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          Row(
                            children: [
                              Icon(
                                story['isRead'] ? Icons.visibility : Icons.visibility_off,
                                size: 16,
                                color: story['isRead'] ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                story['isRead'] ? 'Read' : 'Unread',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: story['isRead'] ? Colors.green : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: story['progress'] ?? 0.0,
                                  backgroundColor: Colors.grey.withOpacity(0.3),
                                  color: Colors.blueAccent,
                                  minHeight: 5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${((story['progress'] ?? 0.0) * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
      ),
    );
  }
}