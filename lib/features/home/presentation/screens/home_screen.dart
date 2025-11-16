import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:testapp/features/auth/presentation/screens/profile_screen.dart';
import 'package:testapp/features/stories/presentation/screens/story_screen.dart';
import 'package:testapp/features/dictionary/presentation/screens/dictionary_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:testapp/providers/recently_viewed_provider.dart';
import 'package:testapp/providers/localization_provider.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const DictionaryScreen(),
    const Placeholder(),
    const Placeholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        elevation: 16,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: Provider.of<LocalizationProvider>(context, listen: false).translate('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.book_rounded),
            label: Provider.of<LocalizationProvider>(context, listen: false).translate('dictionary'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_rounded),
            label: Provider.of<LocalizationProvider>(context, listen: false).translate('history'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_rounded),
            label: Provider.of<LocalizationProvider>(context, listen: false).translate('settings'),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final FirebaseStorage _storage = FirebaseStorage.instance;

class _HomeScreenState extends State<HomeScreen> {
  String username = 'Loading...';
  List<Map<String, dynamic>> stories = [];
  bool _isLoading = true;
  String? _errorMessage;
  final DatabaseReference _databaseReference =
  FirebaseDatabase.instance.ref().child('stories');
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsername();
    fetchStories();
    initializeRecentlyViewedUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void initializeRecentlyViewedUser() {
    firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;
    final recentlyViewedProvider =
    Provider.of<RecentlyViewedProvider>(context, listen: false);
    recentlyViewedProvider.setCurrentUserId(user?.uid);
  }

  Future<void> fetchUsername() async {
    try {
      firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          username = user.displayName ?? 'No Username';
        });
      }
    } catch (e) {
      print('Error fetching username: $e');
      setState(() {
        username = 'Guest User';
      });
    }
  }

  Future<void> fetchStories() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      DatabaseEvent event = await _databaseReference.once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null && snapshot.value is Map) {
        Map<dynamic, dynamic> data = snapshot.value as Map;
        List<Map<String, dynamic>> fetchedStories = [];

        await Future.wait(
          data.entries.map((entry) async {
            final key = entry.key;
            final value = entry.value;

            if (value is Map) {
              String imageUrl = '';

              try {
                imageUrl = await _storage
                    .ref('images/$key.png')
                    .getDownloadURL();
              } catch (e) {
                try {
                  imageUrl = await _storage
                      .ref('images/$key.jpg')
                      .getDownloadURL();
                } catch (e) {
                  print('Error loading image for $key: $e');
                  // Use a placeholder image URL or empty string
                  imageUrl = '';
                }
              }

              final title = value['titleEng'] ?? value['titleTag'] ?? 'No Title';
              final text = value['textEng'] ?? value['textTag'] ?? '';
              final type = value['typeEng'] ?? value['typeTag'] ?? 'Other';

              fetchedStories.add({
                'id': key,
                'title': title,
                'text': text,
                'type': type,
                'imageUrl': imageUrl,
                'progress': value['progress'] ?? 0.0,
              });
            }
          }),
        );

        setState(() {
          stories = fetchedStories;
          _isLoading = false;
        });
      } else {
        setState(() {
          stories = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching stories: $e');
      setState(() {
        _errorMessage = 'Unable to load stories. Please check your connection and try again.';
        _isLoading = false;
        stories = [];
      });
    }
  }

  // Helper methods to filter stories
  List<Map<String, dynamic>> get continueReadingStories {
    return stories.where((story) {
      final progress = (story['progress'] is double) ? story['progress'] : 0.0;
      return progress > 0 && progress < 1.0;
    }).toList();
  }

  List<Map<String, dynamic>> get newStories {
    return stories.where((story) {
      final progress = (story['progress'] is double) ? story['progress'] : 0.0;
      return progress == 0.0;
    }).take(5).toList();
  }

  List<Map<String, dynamic>> get completedStories {
    return stories.where((story) {
      final progress = (story['progress'] is double) ? story['progress'] : 0.0;
      return progress >= 1.0;
    }).toList();
  }

  Widget _buildErrorWidget() {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            localization.translate('errorOccurred'),
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? localization.translate('failedToLoadContent'),
            style: GoogleFonts.fredoka(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              fetchStories();
              fetchUsername();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              localization.translate('tryAgain'),
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            localization.translate('loadingStories'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.fredoka(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryStories(String category) {
    // Filter stories by category (case-insensitive)
    final filteredStories = stories.where((story) {
      final storyType = story['type'] ?? '';
      return storyType.toLowerCase() == category.toLowerCase();
    }).toList();

    final localization = Provider.of<LocalizationProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        category,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.fredoka(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: filteredStories.isEmpty
                    ? Center(
                        child: Text(
                          localization.translate('noStoriesInCategory'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.fredoka(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredStories.length,
                        itemBuilder: (context, index) {
                          final story = filteredStories[index];
                          return ListTile(
                            leading: story['imageUrl'] != null && story['imageUrl']!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      story['imageUrl'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.book, color: Theme.of(context).primaryColor),
                                  ),
                            title: Text(
                              story['title'] ?? 'No Title',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${(story['progress'] * 100).toStringAsFixed(0)}% Completed',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.fredoka(fontSize: 12),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StoryScreen(storyId: story['id']),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAllStories(String sectionTitle) {
    List<Map<String, dynamic>> displayStories = [];
    
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    
    if (sectionTitle == localization.translate('continueReading')) {
      displayStories = continueReadingStories;
    } else if (sectionTitle == localization.translate('newStories')) {
      displayStories = newStories;
    } else if (sectionTitle == localization.translate('completedStories')) {
      displayStories = completedStories;
    } else {
      displayStories = stories;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        sectionTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.fredoka(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: displayStories.isEmpty
                    ? Center(
                        child: Text(
                          localization.translate('noStoriesFound'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.fredoka(),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: displayStories.length,
                        itemBuilder: (context, index) {
                          final story = displayStories[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StoryScreen(storyId: story['id']),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.hardEdge,
                                    child: Stack(
                                      children: [
                                        Image.network(
                                          story['imageUrl'] ?? '',
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Theme.of(context).primaryColor.withOpacity(0.2),
                                              child: Icon(
                                                Icons.book,
                                                color: Theme.of(context).primaryColor,
                                              ),
                                            );
                                          },
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                                colors: [
                                                  Colors.black.withOpacity(0.7),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                            child: Text(
                                              '${((story['progress'] ?? 0) * 100).toStringAsFixed(0)}%',
                                              style: GoogleFonts.fredoka(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Flexible(
                                  child: Text(
                                    story['title'] ?? 'No Title',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.fredoka(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentlyViewedProvider = Provider.of<RecentlyViewedProvider>(context);
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final recentlyViewedStories = recentlyViewedProvider.getRecentlyViewedByDate(days: 7); // Show stories from last 7 days
    
    // Show loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: _buildLoadingWidget(),
      );
    }
    
    // Show error state
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: _buildErrorWidget(),
      );
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildSearchBar(),
                      const SizedBox(height: 32),

                      // Fun Daily Challenge Card
                      _buildDailyChallengeCard(),
                      const SizedBox(height: 32),

                      // Categories
                      _buildSectionTitle(localization.translate('exploreCategories')),
                      const SizedBox(height: 16),
                      _buildCategoriesRow(),
                      const SizedBox(height: 36),

                      // Continue Reading (only if there are stories in progress)
                      if (continueReadingStories.isNotEmpty) ...[
                        _buildSectionTitle(localization.translate('continueReading')),
                        const SizedBox(height: 16),
                        _buildStoryList(continueReadingStories),
                        const SizedBox(height: 36),
                      ],

                      // New Stories
                      if (newStories.isNotEmpty) ...[
                        _buildSectionTitle(localization.translate('newStories')),
                        const SizedBox(height: 16),
                        _buildStoryList(newStories),
                        const SizedBox(height: 36),
                      ],

                      // Recently Viewed
                      if (recentlyViewedStories.isNotEmpty) ...[
                        _buildSectionTitle(localization.translate('recentlyViewed')),
                        const SizedBox(height: 16),
                        _buildStoryList(recentlyViewedStories),
                        const SizedBox(height: 36),
                      ],

                      // Recommended For You
                      _buildSectionTitle(localization.translate('recommendedForYou')),
                      const SizedBox(height: 16),
                      _buildStoryList(stories),
                      const SizedBox(height: 36),

                      // Completed Stories
                      if (completedStories.isNotEmpty) ...[
                        _buildSectionTitle(localization.translate('completedStories')),
                        const SizedBox(height: 16),
                        _buildStoryList(completedStories),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChallengeCard() {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    return GestureDetector(
      onTap: () {
        _showDailyChallengeDialog();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).primaryColor, Theme.of(context).colorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              fit: FlexFit.loose,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localization.translate('dailyChallenge'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${localization.translate('storiesReadToday')}! 🎯',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showDailyChallengeDialog() {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final recentlyViewedProvider = Provider.of<RecentlyViewedProvider>(context, listen: false);
    // Calculate how many stories were read today using proper date filtering
    final todayStories = recentlyViewedProvider.getTodayStories;
    int storiesReadToday = todayStories.length;
    bool challengeCompleted = storiesReadToday >= 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Trophy icon with animation effect
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: challengeCompleted
                          ? [Theme.of(context).primaryColor, Theme.of(context).colorScheme.secondary]
                          : [Colors.grey.shade300, Colors.grey.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: challengeCompleted
                            ? Theme.of(context).primaryColor.withOpacity(0.4)
                            : Colors.grey.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    challengeCompleted ? Icons.emoji_events_rounded : Icons.lock_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  challengeCompleted ? '🎉 ${localization.translate('challengeComplete')}!' : localization.translate('dailyChallenge'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.fredoka(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  challengeCompleted
                      ? '${localization.translate('greatJob')} 🌟'
                      : '${localization.translate('readStoriesToday')} ${localization.translate('to')} ${localization.translate('completeChallenge')}!',
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 24),

                // Progress indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            localization.translate('storiesReadToday'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          Text(
                            '$storiesReadToday / 1',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.fredoka(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: challengeCompleted
                                  ? Colors.green
                                  : Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: storiesReadToday >= 1 ? 1.0 : storiesReadToday / 1,
                          backgroundColor: Colors.grey.shade300,
                          color: challengeCompleted
                              ? Colors.green
                              : Theme.of(context).primaryColor,
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Theme.of(context).textTheme.labelLarge?.color,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      challengeCompleted ? 'Awesome!' : 'Got it!',
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildHeader() {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            offset: Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Theme.of(context).textTheme.bodyLarge?.color, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localization.translate('welcomeBack'),
                style: GoogleFonts.fredoka(
                  textStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              Text(
                username,
                style: GoogleFonts.sniglet(
                  textStyle: TextStyle(
                    fontSize: 22,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            _searchStories(value);
          }
        },
        decoration: InputDecoration(
          hintText: localization.translate('searchStories'),
          hintStyle: GoogleFonts.fredoka(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            size: 24,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Theme.of(context).primaryColor),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
        ),
        style: GoogleFonts.fredoka(
          textStyle: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 16,
          ),
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  void _searchStories(String query) {
    final filtered = stories
        .where((story) =>
            story['title'].toString().toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (filtered.isEmpty) {
      final localization = Provider.of<LocalizationProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localization.translate('noStoriesFoundMatching')} "$query"'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Results for "$query"',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  // limit the modal list height so the Column has a bounded height
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final story = filtered[index];
                    return ListTile(
                      leading: story['imageUrl'] != null &&
                              story['imageUrl']!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                story['imageUrl'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.book,
                                        color: Theme.of(context).primaryColor),
                                  );
                                },
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.book,
                                  color: Theme.of(context).primaryColor),
                            ),
                      title: Text(
                        story['title'] ?? 'No Title',
                        style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${((story['progress'] ?? 0) * 100).toStringAsFixed(0)}% Completed',
                        style: GoogleFonts.fredoka(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                StoryScreen(storyId: story['id']),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoriesRow() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCategory(Icons.auto_stories_rounded, 'Fable', () {
            _showCategoryStories('Fable');
          }),
          _buildDivider(),
          _buildCategory(Icons.book_rounded, 'Folktale', () {
            _showCategoryStories('Folktale');
          }),
          _buildDivider(),
          _buildCategory(Icons.castle_rounded, 'Legend', () {
            _showCategoryStories('Legend');
          }),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 60,
      width: 1,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildCategory(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 32,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.fredoka(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    return GestureDetector(
      onTap: () {
        _showAllStories(title);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(
                  localization.translate('seeAll'),
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryList(List<Map<String, dynamic>> storyList) {
    if (storyList.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: CircularProgressIndicator(
          color: Theme.of(context).primaryColor,
          strokeWidth: 3,
        ),
      );
    }

    return SizedBox(
      height: 210,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: storyList.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final story = storyList[index];
          final imageUrl = story['imageUrl'] ?? '';
          final title = story['title'] ?? 'No Title';
          final progress =
          (story['progress'] is double) ? story['progress'] : 0.0;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoryScreen(storyId: story['id']),
                ),
              );
            },
            child: SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 170,
                    width: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.white.withOpacity(0.3),
                                    color: Theme.of(context).primaryColor,
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}% Completed',
                                  style: GoogleFonts.fredoka(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
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