import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:testapp/features/stories/presentation/screens/story_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../../../providers/localization_provider.dart';

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
  Timer? _searchTimer;
  int _currentPage = 0;
  bool _hasMoreStories = true;
  bool _isLoadingMore = false;

  // Firebase references
  final DatabaseReference _databaseReference =
  FirebaseDatabase.instance.ref().child('stories');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<String> readStatuses = ['All Status', 'Read', 'Unread'];
  List<String> allCategories = ['Folktale', 'Legend', 'Fable'];
  List<Map<String, dynamic>> allStories = [];
  Map<String, String> imageUrlCache = {}; // Cache for image URLs

  @override
  void initState() {
    super.initState();
    fetchStories();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  /// Generate Firebase Storage URL without needing to fetch it
  /// This avoids the trial-and-error PNG/JPG requests
  Future<String> _getImageUrl(String storyKey) async {
    // Return cached URL if available
    if (imageUrlCache.containsKey(storyKey)) {
      return imageUrlCache[storyKey]!;
    }

    String imageUrl = '';
    try {
      // Try PNG first (single request)
      imageUrl = await _storage
          .ref('images/$storyKey.png')
          .getDownloadURL();
    } catch (e) {
      try {
        // Fall back to JPG if PNG doesn't exist
        imageUrl = await _storage
            .ref('images/$storyKey.jpg')
            .getDownloadURL();
      } catch (e) {
        // Use placeholder if neither exists
        imageUrl = '';
      }
    }

    // Cache the result
    imageUrlCache[storyKey] = imageUrl;
    return imageUrl;
  }

  Future<void> fetchStories({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _hasMoreStories = true;
      allStories.clear();
    }

    if (!_hasMoreStories || _isLoadingMore) return;

    setState(() {
      if (allStories.isEmpty) {
        isLoading = true;
      } else {
        _isLoadingMore = true;
      }
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

        // Get all story keys
        List<String> storyKeys = data.keys.cast<String>().toList();

        // Pagination: get 10 stories per page
        const int pageSize = 10;
        int startIndex = _currentPage * pageSize;
        int endIndex = (startIndex + pageSize).clamp(0, storyKeys.length);

        if (startIndex >= storyKeys.length) {
          _hasMoreStories = false;
          setState(() {
            _isLoadingMore = false;
          });
          return;
        }

        // Get stories for current page
        List<String> pageKeys = storyKeys.sublist(startIndex, endIndex);

        // Fetch images concurrently (optimization #2)
        await Future.wait(
          pageKeys.map((key) async {
            final value = data[key];

            if (value is Map) {
              String imageUrl = await _getImageUrl(key);

              // OPTIMIZATION: Don't fetch textEng/textTag/pages here (lazy-load in StoryScreen)
              final title = value['titleEng'] ?? value['titleTag'] ?? 'No Title';

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
                'imageUrl': imageUrl,
                'category': normalizedCategory,
                'isRead': isRead,
                'progress': value['progress'] ?? 0.0,
              });
            }
          }),
        );

        // Update categories (only on first page)
        if (_currentPage == 0) {
          allCategories = <String>{...validCategories, ...categories}
              .toList()
            ..sort();
        }

        setState(() {
          allStories.addAll(fetchedStories);
          _currentPage++;
          _hasMoreStories = endIndex < storyKeys.length;
          isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('Error fetching stories: $e');
      setState(() {
        isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD93D),
        title: Consumer<LocalizationProvider>(
          builder: (context, localization, _) =>
            Text(localization.translate('stories')),
        ),
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
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  // OPTIMIZATION #5: Debounce search (500ms delay)
                  _searchTimer?.cancel();
                  _searchTimer = Timer(const Duration(milliseconds: 500), () {
                    setState(() {
                      searchQuery = value;
                    });
                  });
                },
                decoration: InputDecoration(
                  hintText: localization.translate('searchStories'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                  searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchTimer?.cancel();
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
                  Consumer<LocalizationProvider>(
                    builder: (context, localization, _) =>
                      Text('${localization.translate('filterByCategory')} '),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: selectedCategory,
                    onChanged: (newCategory) {
                      setState(() {
                        selectedCategory = newCategory!;
                      });
                    },
                    items: ['All Categories', ...allCategories]
                        .map((String value) => DropdownMenuItem<String>(
                        value: value,
                        child: SizedBox(
                          width: 150,
                          child: Text(
                            _localizedLabel(value, localization),
                            style: GoogleFonts.fredoka(
                              fontSize: 13,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ))
                        .toList(),
                  ),
                  const SizedBox(width: 16),
                  Consumer<LocalizationProvider>(
                    builder: (context, localization, _) =>
                      Text('${localization.translate('filterByReadStatus')} '),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: selectedReadStatus,
                    onChanged: (newStatus) {
                      setState(() {
                        selectedReadStatus = newStatus!;
                      });
                    },
                    items: readStatuses
                        .map((String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        _localizedLabel(value, localization),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
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

  String _localizedLabel(String value, LocalizationProvider localization) {
    String mappedKey = value.toLowerCase();

    if (value == 'All Categories' || value == 'All Status') {
      mappedKey = 'allStories';
    } else if (value == 'Fable' || value == 'Fables') {
      mappedKey = 'fable';
    } else if (value == 'Folktale') {
      mappedKey = 'folktale';
    } else if (value == 'Legend') {
      mappedKey = 'legend';
    } else if (value == 'Read') {
      mappedKey = 'read';
    } else if (value == 'Unread') {
      mappedKey = 'unread';
    } else {
      mappedKey = value.replaceAll(' ', '').toLowerCase();
    }

    final translated = localization.translate(mappedKey);
    if (translated == mappedKey) return value;
    return translated;
  }

  Widget _buildStoryList() {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
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
      return Center(
        child: Text(localization.translate('noStoriesMatching'),
            style: const TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: () => fetchStories(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filteredStories.length + (_hasMoreStories ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          // Show loading indicator at bottom when more stories available
          if (index == filteredStories.length) {
            // Trigger load more when user scrolls to bottom
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_isLoadingMore) {
                fetchStories();
              }
            });
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

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
                fetchStories(refresh: true);
              });
            },
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Story image from Firebase Storage with error handling
                  Container(
                    width: 120,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: story['imageUrl'].isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: story['imageUrl'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    )
                        : Container(
                      color: Colors.grey.shade300,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${localization.translate('categories')}: ${_localizedLabel(story['category'], localization)}',
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
                                story['isRead'] ? localization.translate('read') : localization.translate('unread'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: story['isRead'] ? Colors.green : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: story['progress'] ?? 0.0,
                                  backgroundColor: Colors.grey.withValues(alpha: 0.3),
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
