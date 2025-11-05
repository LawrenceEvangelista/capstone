import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:testapp/screens/auth/profile_screen.dart';
import 'package:testapp/screens/story_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:testapp/providers/recently_viewed_provider.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const Placeholder(),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_rounded),
            label: 'Bookmarks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
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

  @override
  void initState() {
    super.initState();
    fetchUsername();
    fetchStories();
    initializeRecentlyViewedUser();
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

              fetchedStories.add({
                'id': key,
                'title': title,
                'text': text,
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
            'Oops! Something went wrong',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Failed to load content',
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
              'Try Again',
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading stories...',
            style: GoogleFonts.fredoka(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentlyViewedProvider = Provider.of<RecentlyViewedProvider>(context);
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
                      _buildSectionTitle('Explore Categories'),
                      const SizedBox(height: 16),
                      _buildCategoriesRow(),
                      const SizedBox(height: 36),

                      // Continue Reading (only if there are stories in progress)
                      if (continueReadingStories.isNotEmpty) ...[
                        _buildSectionTitle('Continue Reading'),
                        const SizedBox(height: 16),
                        _buildStoryList(continueReadingStories),
                        const SizedBox(height: 36),
                      ],

                      // New Stories
                      if (newStories.isNotEmpty) ...[
                        _buildSectionTitle('New Stories'),
                        const SizedBox(height: 16),
                        _buildStoryList(newStories),
                        const SizedBox(height: 36),
                      ],

                      // Recently Viewed
                      if (recentlyViewedStories.isNotEmpty) ...[
                        _buildSectionTitle('Recently Viewed'),
                        const SizedBox(height: 16),
                        _buildStoryList(recentlyViewedStories),
                        const SizedBox(height: 36),
                      ],

                      // Recommended For You
                      _buildSectionTitle('Recommended For You'),
                      const SizedBox(height: 16),
                      _buildStoryList(stories),
                      const SizedBox(height: 36),

                      // Completed Stories
                      if (completedStories.isNotEmpty) ...[
                        _buildSectionTitle('Completed Stories'),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Challenge',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Read 1 story today! 🎯',
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
                  challengeCompleted ? '🎉 Challenge Complete!' : 'Daily Challenge',
                  textAlign: TextAlign.center,
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
                      ? 'Great job! You read a story today! 🌟'
                      : 'Read 1 story to complete today\'s challenge!',
                  textAlign: TextAlign.center,
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
                            'Stories Read Today',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          Text(
                            '$storiesReadToday / 1',
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
                'Welcome back,',
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
        decoration: InputDecoration(
          hintText: 'Search a story',
          hintStyle: GoogleFonts.fredoka(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            size: 24,
          ),
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
      ),
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
          _buildCategory(Icons.pets_rounded, 'Animals'),
          _buildDivider(),
          _buildCategory(Icons.flag_rounded, 'Filipino\nCulture'),
          _buildDivider(),
          _buildCategory(Icons.auto_stories_rounded, 'Folklore'),
          _buildDivider(),
          _buildCategory(Icons.volunteer_activism_rounded, 'Values'),
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

  Widget _buildCategory(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        // Category tap action
      },
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
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
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
                'See all',
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