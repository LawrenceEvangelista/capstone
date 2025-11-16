import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:testapp/features/favorites/provider/favorites_provider.dart';
import 'package:testapp/features/stories/presentation/screens/story_screen.dart';
import 'package:testapp/providers/localization_provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String searchQuery = '';
  String selectedCategory = 'All Categories';
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Map<String, String> imageCache = {}; // Cache for image URLs

  @override
  void initState() {
    super.initState();
    _preloadImages();
  }

  // Preload all favorite images
  Future<void> _preloadImages() async {
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    final favorites = favoritesProvider.favorites;

    for (var story in favorites) {
      final storyId = story['id'];
      if (storyId != null && !imageCache.containsKey(storyId)) {
        final imageUrl = await _getImageUrl(storyId);
        if (mounted) {
          setState(() {
            imageCache[storyId] = imageUrl;
          });
        }
      }
    }
  }

  // Get image URL from Firebase Storage
  Future<String> _getImageUrl(String storyId) async {
    try {
      // Try PNG first
      return await _storage.ref('images/$storyId.png').getDownloadURL();
    } catch (e) {
      try {
        // Try JPG if PNG doesn't exist
        return await _storage.ref('images/$storyId.jpg').getDownloadURL();
      } catch (e) {
        print('Error loading image for $storyId: $e');
        return '';
      }
    }
  }

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
        title: Consumer<LocalizationProvider>(
          builder: (context, localization, _) => Text(
            localization.translate('favorites'),
            style: GoogleFonts.sniglet(fontSize: 20),
          ),
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
                Consumer<LocalizationProvider>(
                  builder: (context, localization, _) => Text(localization.translate('filterByCategory')),
                ),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Add stories to your favorites to see them here',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

        // Get cached image URL or empty string
        final String imageUrl = imageCache[storyId] ?? '';

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
                    // Image from Firebase Storage
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
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        ),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                                color: const Color(0xFFFFD93D),
                                strokeWidth: 2,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.image,
                            color: Colors.grey,
                            size: 40,
                          ),
                        )
                            : FutureBuilder<String>(
                          future: _getImageUrl(storyId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFFD93D),
                                  strokeWidth: 2,
                                ),
                              );
                            }
                            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                              // Cache the URL
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    imageCache[storyId] = snapshot.data!;
                                  });
                                }
                              });
                              return Image.network(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              );
                            }
                            return const Icon(
                              Icons.image,
                              color: Colors.grey,
                              size: 40,
                            );
                          },
                        ),
                      ),
                    ),

                    // Story Details
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.fredoka(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: Text(
                                'Category: $category',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.fredoka(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to continue reading',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.fredoka(
                                fontSize: 14,
                                color: Colors.black54,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const Spacer(),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white,
                                color: const Color(0xFFFFD93D),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(progress * 100).toInt()}% read',
                              style: GoogleFonts.fredoka(
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

              // ❤️ Favorite Icon
              Positioned(
                top: 8,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    // Remove from favorites when the heart is tapped
                    favoritesProvider.removeFavorite(storyId);
                    // Remove from image cache
                    setState(() {
                      imageCache.remove(storyId);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 24,
                    ),
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