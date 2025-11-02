import 'package:flutter/material.dart';
import 'package:page_flip/page_flip.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:testapp/screens/favorites/favorites_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class StoryScreen extends StatefulWidget {
  final String storyId;
  // This field is essential for passing the category from the list view
  final Map<String, dynamic>? initialStoryData;

  const StoryScreen({
    Key? key,
    required this.storyId,
    this.initialStoryData,
  }) : super(key: key);

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  // We keep the controller to support the initial 'goToPage' functionality.
  final _controller = GlobalKey<PageFlipWidgetState>();
  bool isLoading = true;
  bool _isEnglish = true;
  String storyTitle = '';
  List<Map<String, String>> storyPages = [];
  String errorMessage = '';
  Map<String, dynamic> storyData = {}; // This map holds the data for saving

  // 1. STATE FOR TRACKING PROGRESS (Logic disabled as package version lacks callback)
  int _currentPage = 0;

  // Cartoonish colors - matching signup screen
  final Color _backgroundColor = const Color(0xFFFFF176); // Light yellow
  final Color _primaryColor = const Color(0xFFFF6D00); // Orange
  final Color _accentColor = const Color(0xFF8E24AA); // Purple
  final Color _buttonColor = const Color(0xFFFF9800); // Orange

  @override
  void initState() {
    super.initState();
    if (widget.initialStoryData != null) {
      storyData = Map.from(widget.initialStoryData!);
    }
    _fetchStoryData();
  }

  // 2. METHOD TO UPDATE PROGRESS IN FIREBASE (Now only called when the last page is reached, if logic is added)
  // NOTE: This function's real-time use is now limited because PageFlipWidget (v0.2.5+1) lacks an onPageFlip/onFlip callback.
  Future<void> _updateStoryProgress(int pageIndex) async {
    // pageIndex is 0-based.
    final totalPages = storyPages.length;
    if (totalPages == 0) return;

    // Calculate progress as a fraction (0.0 to 1.0)
    final newProgress = (pageIndex + 1) / totalPages;
    double clampedProgress = newProgress.clamp(0.0, 1.0);

    // If the story is fully read, update the isRead flag
    bool isRead = clampedProgress == 1.0;

    // Update the local storyData map
    storyData['progress'] = clampedProgress;
    storyData['isRead'] = isRead;

    try {
      final DatabaseReference storyRef = FirebaseDatabase.instance
          .ref()
          .child('stories')
          .child(widget.storyId);

      // Save the progress and read status back to Firebase
      await storyRef.update({
        'progress': clampedProgress,
        'isRead': isRead,
      });

    } catch (e) {
      // Log error but don't disrupt the user experience
      print('Error updating story progress: $e');
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

        // Check all known keys for the category in the database
        final String? categoryFromDB = data['typeEng'] ?? data['type'] ?? data['category'];

        // Fetch existing progress from the database
        final double? dbProgress = (data['progress'] is int)
            ? (data['progress'] as int).toDouble()
            : data['progress'] as double?;

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

          for (String pageKey in sortedPageKeys) {
            if (pagesData[pageKey] is Map) {
              Map<dynamic, dynamic> pageContent = pagesData[pageKey] as Map;
              combinedPages.add({
                'textEng': pageContent['textEng'] ?? '',
                'textTag': pageContent['textTag'] ?? '',
                'image': 'assets/pic${(combinedPages.length % 5) + 1}.png',
              });
            }
          }
        }

        // Re-build storyData, ensuring the 'category' is the most reliable one.
        String finalCategory = categoryFromDB ?? storyData['category'] ?? 'Uncategorized';

        // Use DB progress if available, otherwise use progress from initial data, otherwise default
        final double finalProgress = dbProgress ?? storyData['progress'] ?? 0.0;

        storyData = {
          'id': widget.storyId,
          'titleEng': titleEng,
          'titleTag': titleTag,
          'category': finalCategory,
          'title': _isEnglish ? (titleEng ?? 'No Title') : (titleTag ?? 'Walang Pamagat'),
          'image': storyData['imageUrl'] ?? (combinedPages.isNotEmpty ? combinedPages[0]['image'] : 'assets/pic1.png'),
          'progress': finalProgress,
        };

        // Calculate initial page index based on progress
        // We use floor() to get the index of the last *fully* read page.
        final int initialPage = (finalProgress * combinedPages.length).floor().clamp(0, combinedPages.length - 1);

        setState(() {
          storyTitle = _isEnglish ? (titleEng ?? 'No Title') : (titleTag ?? 'Walang Pamagat');
          storyPages = combinedPages;
          isLoading = false;
          // Set the initial current page based on loaded progress
          _currentPage = initialPage;
        });

        // After state update, jump to the correct page if not at the start
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (storyPages.isNotEmpty && _currentPage > 0) {
            // The goToPage method expects the page number (1-based), so we jump to page _currentPage + 1.
            _controller.currentState?.goToPage(_currentPage + 1);
          }
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
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.quiz, color: _primaryColor, size: 28),
            const SizedBox(width: 10),
            Text(
              'Coming Soon!',
              style: GoogleFonts.fredoka(
                textStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
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
              backgroundColor: _accentColor,
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
      backgroundColor: _backgroundColor,
      body: Container(
        child: SafeArea(
          child: isLoading
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: _primaryColor),
                const SizedBox(height: 20),
                Text(
                  'Loading story...',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    color: _primaryColor,
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
                Icon(Icons.error_outline, color: _primaryColor, size: 60),
                const SizedBox(height: 20),
                Text(
                  errorMessage,
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    color: Colors.red,
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
                    color: const Color(0xFFFFD93D),
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
                              color: _primaryColor,
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
                          color: _primaryColor,
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
                              color: _primaryColor,
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
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.2),
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
                              ..color = Colors.white,
                          ),
                        ),
                        // Main text
                        Text(
                          storyTitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
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
                          // The storyData map now holds the consolidated and correct category
                          favoritesProvider.toggleFavorite(widget.storyId, {
                            'id': storyData['id'],
                            'title': storyTitle,
                            'category': storyData['category'], // Using the consolidated category
                            'image': storyData['image'],
                            'progress': storyData['progress'] ?? 0.5,
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              // CORRECTED: Fixed the typo from BoxBoxShadow to BoxShadow
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
                                  color: Colors.black87,
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
                            color: Colors.white,
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
                                color: _accentColor,
                                size: 22,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Quiz',
                                style: GoogleFonts.fredoka(
                                  fontSize: 14,
                                  color: Colors.black87,
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
                        border: Border.all(color: _primaryColor, width: 2.5),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: PageFlipWidget(
                        key: ValueKey(_isEnglish), // Add this key to force rebuild
                        // COMPILATION FIX: Removed the 'onPageChange' parameter entirely
                        // as this specific version (0.2.5+1) does not support it,
                        // causing the persistent "No named parameter" error.

                        backgroundColor: Colors.white,
                        lastPage: Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
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
                                      Icon(Icons.check_circle, size: 100, color: _accentColor),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Hooray! You finished the story',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  height: 50,
                                  width: 180,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [_buttonColor, _accentColor],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _accentColor.withOpacity(0.3),
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
                                color: Colors.black54,
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
                            primaryColor: _primaryColor,
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
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swipe_left,
                            color: _accentColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Swipe to turn page',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.swipe_right,
                            color: _accentColor,
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
        // Background image
        ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Image.asset(
            imageUrl,
            fit: BoxFit.cover,
          ),
        ),

        // Text container
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
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
                color: Colors.black,
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
