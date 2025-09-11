import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:testapp/screens/favorites/favorites_provider.dart';
import 'package:testapp/screens/story_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String searchQuery = '';
  String selectedCategory = 'All Categories';

  @override
  Widget build(BuildContext context) {
    // Get favorites from provider
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final favorites = favoritesProvider.favorites;

    // Extract unique categories from favorites
    Set<String> categories = {'All Categories'};
    for (var story in favorites) {
      if (story['category'] != null && story['category'].toString().isNotEmpty) {
        categories.add(story['category'].toString());
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD93D),
        title: Text('Favorites', style: GoogleFonts.sniglet(fontSize: 20)),
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

          // Category Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('Filter by Category:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: categories.contains(selectedCategory) ? selectedCategory : 'All Categories',
                  onChanged: (newCategory) {
                    setState(() {
                      selectedCategory = newCategory!;
                    });
                  },
                  items: categories.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Filtered Stories
          Expanded(
            child: _buildStoryList(favorites),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryList(List<Map<String, dynamic>> allStories) {
    // Filter stories based on search query and selected category
    List<Map<String, dynamic>> filteredStories = allStories
        .where(
          (story) =>
      (selectedCategory == 'All Categories' ||
          story['category'] == selectedCategory) &&
          (story['title'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          )),
    )
        .toList();

    if (filteredStories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No favorite stories found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Add stories to your favorites to see them here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        var story = filteredStories[index];
        final String storyId = story['id'] ?? '';
        final String title = story['title'] ?? 'No Title';
        final String category = story['category'] ?? 'Uncategorized';
        final double progress = story['progress'] ?? 0.0;

        // Get the favorites provider to check favorite status
        final favoritesProvider = Provider.of<FavoritesProvider>(context);

        return GestureDetector(
          onTap: () {
            // Navigate to StoryScreen when tapped
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StoryScreen(storyId: storyId),
              ),
            );
          },
          child: Stack(
            children: [
              Container(
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
                      child: story['image'] != null
                          ? Image.asset(
                        story['image'].toString(),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.image,
                          color: Colors.grey,
                          size: 40,
                        ),
                      )
                          : const Icon(Icons.image, color: Colors.grey, size: 40),
                    ),

                    // Story Details
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Category: $category',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap to continue reading',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                fontStyle: FontStyle.italic,
                              ),
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
                              '${(progress * 100).toInt()}% read',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ❤️ Favorite Icon
              Positioned(
                top: 8,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    // Remove from favorites when the heart is tapped
                    favoritesProvider.removeFavorite(storyId);
                  },
                  child: Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}