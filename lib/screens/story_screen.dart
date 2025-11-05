import 'package:flutter/material.dart';
import 'package:page_flip/page_flip.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:testapp/screens/favorites/favorites_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:testapp/providers/recently_viewed_provider.dart';

class StoryScreen extends StatefulWidget {
  final String storyId;

  const StoryScreen({Key? key, required this.storyId}) : super(key: key);

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final _controller = GlobalKey<PageFlipWidgetState>();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool isLoading = true;
  bool _isEnglish = true;
  String storyTitle = '';
  List<Map<String, String>> storyPages = [];
  String errorMessage = '';
  Map<String, dynamic> storyData = {};

  // Consistent app colors - using theme colors
  final Color _backgroundColor = const Color(0xFFFFF176); // Light yellow background
  final Color _primaryColor = const Color(0xFFFFD93D); // Mustard yellow (consistent primary)
  final Color _accentColor = const Color(0xFF8E24AA); // Purple accent
  final Color _buttonColor = const Color(0xFFFFD93D); // Mustard yellow buttons

  @override
  void initState() {
    super.initState();
    _fetchStoryData();
    _trackStoryView();
  }

  Future<void> _trackStoryView() async {
    try {
      // Fetch story data from Firebase
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('stories/${widget.storyId}')
          .once();

      if (snapshot.snapshot.value != null && snapshot.snapshot.value is Map) {
        final data = snapshot.snapshot.value as Map;

        // Get image URL from Firebase Storage
        String imageUrl = '';
        try {
          imageUrl = await _storage
              .ref('images/${widget.storyId}.png')
              .getDownloadURL();
        } catch (e) {
          try {
            imageUrl = await _storage
                .ref('images/${widget.storyId}.jpg')
                .getDownloadURL();
          } catch (e) {
            print('Error loading image: $e');
          }
        }

        final storyData = {
          'id': widget.storyId,
          'title': data['titleEng'] ?? data['titleTag'] ?? 'No Title',
          'imageUrl': imageUrl,
          'progress': data['progress'] ?? 0.0,
        };

        // Add to recently viewed
        if (mounted) {
          await Provider.of<RecentlyViewedProvider>(context, listen: false)
              .addRecentlyViewed(storyData);
        }
      }
    } catch (e) {
      print('Error tracking story view: $e');
    }
  }

  Future<String> _loadPageImage(int pageNumber) async {
    try {
      // Try with space format first: "PAGE 1.png"
      String imageUrl = await _storage
          .ref('storypages/${widget.storyId}/PAGE $pageNumber.png')
          .getDownloadURL();
      print('Successfully loaded: storypages/${widget.storyId}/PAGE $pageNumber.png');
      return imageUrl;
    } catch (e) {
      print('Error loading PAGE $pageNumber.png: $e');

      // Try alternative format: "page1.png"
      try {
        String imageUrl = await _storage
            .ref('storypages/${widget.storyId}/page$pageNumber.png')
            .getDownloadURL();
        print('Successfully loaded: storypages/${widget.storyId}/page$pageNumber.png');
        return imageUrl;
      } catch (e) {
        print('Error loading page$pageNumber.png: $e');

        // Try JPG format
        try {
          String imageUrl = await _storage
              .ref('storypages/${widget.storyId}/PAGE $pageNumber.jpg')
              .getDownloadURL();
          print('Successfully loaded: storypages/${widget.storyId}/PAGE $pageNumber.jpg');
          return imageUrl;
        } catch (e) {
          print('Error loading PAGE $pageNumber.jpg: $e');
          return ''; // Return empty if all attempts fail
        }
      }
    }
  }

  Future<void> _fetchStoryData() async {
    try {
      final DatabaseReference storyRef = FirebaseDatabase.instance
          .ref()
          .child('stories')
          .child(widget.storyId);

      DatabaseEvent event = await storyRef.once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null && snapshot.value is Map) {
        Map<dynamic, dynamic> data = snapshot.value as Map;

        final String? titleEng = data['titleEng'];
        final String? titleTag = data['titleTag'];
        final String? category = data['category'] ?? 'Uncategorized';

        List<Map<String, String>> combinedPages = [];

        // Access the 'pages' node
        if (data['pages'] != null && data['pages'] is Map) {
          Map<dynamic, dynamic> pagesData = data['pages'] as Map;

          // Sort pages by their keys (page1, page2, etc.) to maintain order
          List<String> sortedPageKeys = pagesData.keys
              .map((key) => key.toString())
              .toList();
          sortedPageKeys.sort((a, b) {
            // Extract numbers from "pageX" and compare
            int numA = int.tryParse(a.replaceAll('page', '')) ?? 0;
            int numB = int.tryParse(b.replaceAll('page', '')) ?? 0;
            return numA.compareTo(numB);
          });

          // Load images from Firebase Storage for each page
          for (int i = 0; i < sortedPageKeys.length; i++) {
            String pageKey = sortedPageKeys[i];
            if (pagesData[pageKey] is Map) {
              Map<dynamic, dynamic> pageContent = pagesData[pageKey] as Map;

              // Load the image URL from Firebase Storage
              String imageUrl = await _loadPageImage(i + 1);

              combinedPages.add({
                'textEng': pageContent['textEng'] ?? '',
                'textTag': pageContent['textTag'] ?? '',
                'image': imageUrl, // Use Firebase Storage URL instead of asset
              });
            }
          }
        }

        // Get cover image for favorites
        String coverImageUrl = '';
        try {
          coverImageUrl = await _storage
              .ref('images/${widget.storyId}.png')
              .getDownloadURL();
        } catch (e) {
          try {
            coverImageUrl = await _storage
                .ref('images/${widget.storyId}.jpg')
                .getDownloadURL();
          } catch (e) {
            print('Error loading cover image: $e');
          }
        }

        // Store story data for favorites
        storyData = {
          'id': widget.storyId,
          'titleEng': titleEng,
          'titleTag': titleTag,
          'category': category,
          'title': _isEnglish ? (titleEng ?? 'No Title') : (titleTag ?? 'Walang Pamagat'),
          'image': coverImageUrl.isNotEmpty ? coverImageUrl : (combinedPages.isNotEmpty ? combinedPages[0]['image'] : ''),
          'progress': 0.5,
        };

        setState(() {
          storyTitle = _isEnglish ? (titleEng ?? 'No Title') : (titleTag ?? 'Walang Pamagat');
          storyPages = combinedPages;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Story not found or invalid format';
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error loading story: $error';
        isLoading = false;
      });
    }
  }

  void _toggleLanguage() {
    setState(() {
      _isEnglish = !_isEnglish;
      // Update the story title based on the current language
      if (storyData['titleEng'] != null && storyData['titleTag'] != null) {
        storyTitle = _isEnglish
            ? storyData['titleEng']
            : storyData['titleTag'];
      }
    });
  }

  void _showQuizDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Row(
          children: [
            Icon(Icons.quiz, color: Theme.of(context).primaryColor, size: 28),
            const SizedBox(width: 10),
            Text(
              'Coming Soon!',
              style: GoogleFonts.fredoka(
                textStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Quiz feature is coming soon for this story! Stay tuned.',
          style: GoogleFonts.fredoka(
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
            ),
            child: Text(
              'OK',
              style: GoogleFonts.fredoka(
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the favorites provider
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final bool isFavorite = favoritesProvider.isFavorite(widget.storyId);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        child: SafeArea(
          child: isLoading
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Theme.of(context).primaryColor),
                const SizedBox(height: 20),
                Text(
                  'Loading story...',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          )
              : errorMessage.isNotEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Theme.of(context).primaryColor, size: 60),
                const SizedBox(height: 20),
                Text(
                  errorMessage,
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom AppBar
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Back button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Theme.of(context).primaryColor,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Back to Stories',
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const Spacer(),
                      // Language toggle
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _toggleLanguage,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Icon(
                              _isEnglish
                                  ? Icons.translate
                                  : Icons.g_translate,
                              color: Theme.of(context).primaryColor,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Story Title with shadow effect
              FadeInDown(
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 500),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Text shadow effect
                        Text(
                          storyTitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 4
                              ..color = Theme.of(context).scaffoldBackgroundColor,
                          ),
                        ),
                        // Main text
                        Text(
                          storyTitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Action buttons row
              FadeInDown(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 500),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Favorite button
                      GestureDetector(
                        onTap: () {
                          // Toggle favorite status
                          favoritesProvider.toggleFavorite(widget.storyId, {
                            'id': widget.storyId,
                            'title': storyTitle,
                            'category': storyData['category'],
                            'image': storyData['image'],
                            'progress': 0.5,
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: Colors.red,
                                size: 22,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isFavorite ? 'Favorited' : 'Favorite',
                                style: GoogleFonts.fredoka(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Quiz button
                      GestureDetector(
                        onTap: () => _showQuizDialog(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.quiz,
                                color: Theme.of(context).colorScheme.secondary,
                                size: 22,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Quiz',
                                style: GoogleFonts.fredoka(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Page flip book container
              Expanded(
                child: FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  duration: const Duration(milliseconds: 600),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).primaryColor, width: 2.5),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: PageFlipWidget(
                        key: ValueKey(_isEnglish),
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                        lastPage: Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/story_complete.png',
                                  height: 120,
                                  width: 120,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.check_circle, size: 100, color: Theme.of(context).colorScheme.secondary),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Hooray! You finished the story',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  height: 50,
                                  width: 180,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Theme.of(context).primaryColor, Theme.of(context).colorScheme.secondary],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    icon: const Icon(
                                        Icons.quiz,
                                        color: Colors.white
                                    ),
                                    label: Text(
                                      'Take Quiz',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    onPressed: () => _showQuizDialog(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        children: storyPages.isEmpty
                            ? [
                          Center(
                            child: Text(
                              'No story content available',
                              style: GoogleFonts.fredoka(
                                fontSize: 18,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        ]
                            : List.generate(
                          storyPages.length,
                              (index) => StoryPage(
                            pageContent: _isEnglish
                                ? storyPages[index]['textEng']!
                                : storyPages[index]['textTag']!,
                            imageUrl: storyPages[index]['image']!,
                            pageNumber: index + 1,
                            totalPages: storyPages.length,
                            primaryColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Page flip instructions
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                duration: const Duration(milliseconds: 500),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swipe_left,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Swipe to turn page',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.swipe_right,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StoryPage extends StatelessWidget {
  final String pageContent;
  final String imageUrl;
  final int pageNumber;
  final int totalPages;
  final Color primaryColor;

  const StoryPage({
    Key? key,
    required this.pageContent,
    required this.imageUrl,
    required this.pageNumber,
    required this.totalPages,
    required this.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image - now from Firebase Storage
        ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: imageUrl.isNotEmpty
              ? Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey.shade200,
                child: Center(
                  child: CircularProgressIndicator(
                    color: primaryColor,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              print('Error loading image: $error');
              return Container(
                color: Colors.grey.shade300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Image not found',
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
              : Container(
            color: Colors.grey.shade300,
            child: Center(
              child: Icon(
                Icons.image_not_supported,
                size: 64,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ),

        // Text container
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.85),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: primaryColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Text(
              pageContent,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ),

        // Page number indicator
        Positioned(
          bottom: 8,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Page $pageNumber/$totalPages',
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}