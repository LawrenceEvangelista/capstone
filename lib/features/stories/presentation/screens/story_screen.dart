import 'package:flutter/material.dart';
import 'package:page_flip/page_flip.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:testapp/features/favorites/provider/favorites_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:testapp/providers/recently_viewed_provider.dart';
import '../../../../providers/localization_provider.dart';

class StoryScreen extends StatefulWidget {
  final String storyId;

  const StoryScreen({Key? key, required this.storyId}) : super(key: key);

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool isLoading = true;
  bool _isEnglish = true;
  String storyTitle = '';
  List<Map<String, String>> storyPages = [];
  String errorMessage = '';
  Map<String, dynamic> storyData = {};

  // Cartoonish colors - matching signup screen
  final Color _backgroundColor = const Color(0xFFFFF176); // Light yellow
  final Color _primaryColor = const Color(0xFFFF6D00); // Orange
  final Color _accentColor = const Color(0xFF8E24AA); // Purple
  final Color _buttonColor = const Color(0xFFFF9800); // Orange

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
    final localization = Provider.of<LocalizationProvider>(context, listen: false);

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
              localization.translate('comingSoon'),
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
          localization.translate('quizComingSoon'),
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
              localization.translate('ok'),
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
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
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
                  localization.translate('loadingStory'),
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
                  localization.translate('oopsError'),
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    color: Colors.red,
                  ),
                ),
                if (errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
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
                        '${localization.translate('back')} ${localization.translate('stories')}',
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: Colors.red,
                                size: 22,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isFavorite ? localization.translate('favorited') : localization.translate('favorite'),
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
                                localization.translate('quiz'),
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
                        key: ValueKey(_isEnglish),
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
                                  localization.translate('storyComplete'),
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
                                      localization.translate('startQuiz'),
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
                              localization.translate('noStoryContentAvailable'),
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
                            localization.translate('swipeToTurnPage'),
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
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    // Calculate if text is long
    final bool isLongText = pageContent.length > 120;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Column(
          children: [
            // Image section - adaptive height
            Expanded(
              flex: isLongText ? 48 : 55,
              child: Stack(
                children: [
                  // Main image
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
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
                        return Container(
                          color: Colors.grey.shade300,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  localization.translate('imageNotFound'),
                                  style: GoogleFonts.fredoka(
                                    fontSize: 12,
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
                          size: 48,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),

                  // Page number - top right corner on image
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '$pageNumber/$totalPages',
                        style: GoogleFonts.fredoka(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Thin decorative separator
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.3),
                    primaryColor,
                    primaryColor.withOpacity(0.3),
                  ],
                ),
              ),
            ),

            // Text section - compact and scrollable
            Expanded(
              flex: isLongText ? 52 : 45,
              child: Container(
                width: double.infinity,
                color: Colors.white,
                child: Stack(
                  children: [
                    // Decorative corner patterns
                    Positioned(
                      top: 0,
                      left: 0,
                      child: CustomPaint(
                        size: const Size(40, 40),
                        painter: CornerDecoration(primaryColor),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Transform.flip(
                        flipX: true,
                        child: CustomPaint(
                          size: const Size(40, 40),
                          painter: CornerDecoration(primaryColor),
                        ),
                      ),
                    ),

                    // Scrollable text with proper padding
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              // Subtle scroll indicator at top
                              if (isLongText)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  width: 40,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),

                              Text(
                                pageContent,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.fredoka(
                                  fontSize: isLongText ? 15 : 17,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                  letterSpacing: 0.2,
                                ),
                              ),

                              // Bottom padding for scroll space
                              if (isLongText) const SizedBox(height: 8),
                            ],
                          ),
                        ),
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
  }
}
// Custom painter for decorative corners
class CornerDecoration extends CustomPainter {
  final Color color;

  CornerDecoration(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..quadraticBezierTo(0, 0, 0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}