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
        selectedItemColor: const Color(0xFFFFD93D),
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
    firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        username = user.displayName ?? 'No Username';
      });
    }
  }

  Future<void> fetchStories() async {
    try {
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
        });
      }
    } catch (e) {
      print('Error fetching stories: $e');
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

  @override
  Widget build(BuildContext context) {
    final recentlyViewedStories = Provider.of<RecentlyViewedProvider>(context).recentlyViewed;
    return Scaffold(
      backgroundColor: Colors.white,
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
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD93D), Color(0xFFFFA93D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD93D).withOpacity(0.4),
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
    final recentlyViewedStories = Provider.of<RecentlyViewedProvider>(context, listen: false).recentlyViewed;
    // Calculate how many stories were completed today
    int storiesReadToday = recentlyViewedStories.length; // You can modify this logic
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
              color: Colors.white,
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
                          ? [Color(0xFFFFD93D), Color(0xFFFFA93D)]
                          : [Colors.grey.shade300, Colors.grey.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: challengeCompleted
                            ? const Color(0xFFFFD93D).withOpacity(0.4)
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
                    color: const Color(0xFF2D2D2D),
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
                    color: const Color(0xFF515151),
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
                              color: const Color(0xFF515151),
                            ),
                          ),
                          Text(
                            '$storiesReadToday / 1',
                            style: GoogleFonts.fredoka(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: challengeCompleted
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFFD93D),
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
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFFD93D),
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
                      backgroundColor: const Color(0xFFFFD93D),
                      foregroundColor: const Color(0xFF2D2D2D),
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
      decoration: const BoxDecoration(
        color: Color(0xFFFFD93D),
        boxShadow: [
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
              child: const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF515151), size: 28),
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
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF515151),
                  ),
                ),
              ),
              Text(
                username,
                style: GoogleFonts.sniglet(
                  textStyle: const TextStyle(
                    fontSize: 22,
                    color: Color(0xFF2D2D2D),
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
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF515151),
            size: 24,
          ),
          filled: true,
          fillColor: Colors.white,
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
            borderSide: const BorderSide(color: Color(0xFFFFD93D), width: 2),
          ),
        ),
        style: GoogleFonts.fredoka(
          textStyle: const TextStyle(
            color: Color(0xFF2D2D2D),
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
        color: Colors.grey.shade50,
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
              color: Color(0xFFFFD93D).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 32,
              color: const Color(0xFFFFD93D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF515151),
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
            color: const Color(0xFF2D2D2D),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD93D).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Text(
                'See all',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF2D2D2D),
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
        child: const CircularProgressIndicator(
          color: Color(0xFFFFD93D),
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
                                    color: const Color(0xFFFFD93D),
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
                      color: const Color(0xFF2D2D2D),
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