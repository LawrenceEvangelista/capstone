// lib/features/stories/presentation/screens/stories_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../../providers/localization_provider.dart';
import '../../presentation/screens/story_screen.dart'; // adjust if your import path differs

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

  final ScrollController _scrollController = ScrollController();

  // Firebase refs
  final DatabaseReference _databaseReference = FirebaseDatabase.instance
      .ref()
      .child('stories');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<String> readStatuses = ['All Status', 'Read', 'Unread'];
  List<String> allCategories = ['Folktale', 'Legend', 'Fable'];

  List<Map<String, dynamic>> allStories = [];
  final Map<String, String> imageUrlCache = {}; // Cache for image URLs

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    fetchStories(); // initial load
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMoreStories) {
      return;
    }

    final thresholdPixels =
        200.0; // when there's 200px left to bottom -> load more
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;

    if (maxScroll - current <= thresholdPixels) {
      fetchStories();
    }
  }

  Future<String> _getImageUrl(String storyKey) async {
    if (imageUrlCache.containsKey(storyKey)) return imageUrlCache[storyKey]!;

    String imageUrl = '';
    try {
      imageUrl = await _storage.ref('images/$storyKey.png').getDownloadURL();
    } catch (_) {
      try {
        imageUrl = await _storage.ref('images/$storyKey.jpg').getDownloadURL();
      } catch (_) {
        imageUrl = '';
      }
    }
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
      // get snapshot once
      final DatabaseEvent event = await _databaseReference.once();
      final DataSnapshot snapshot = event.snapshot;

      if (snapshot.value == null || snapshot.value is! Map) {
        // nothing to load
        if (mounted) {
          setState(() {
            isLoading = false;
            _isLoadingMore = false;
            _hasMoreStories = false;
          });
        }
        return;
      }

      final Map<dynamic, dynamic> data = snapshot.value as Map;
      final List<String> storyKeys = data.keys.cast<String>().toList();

      // pagination variables
      const int pageSize = 10;
      final int startIndex = _currentPage * pageSize;
      final int endIndex = (startIndex + pageSize).clamp(0, storyKeys.length);

      if (startIndex >= storyKeys.length) {
        if (mounted) {
          setState(() {
            _hasMoreStories = false;
            _isLoadingMore = false;
            isLoading = false;
          });
        }
        return;
      }

      final List<String> pageKeys = storyKeys.sublist(startIndex, endIndex);

      // gather categories for dropdown
      final Set<String> categoriesFound = {};
      final List<Map<String, dynamic>> fetchedStories = [];

      await Future.wait(
        pageKeys.map((key) async {
          final value = data[key];
          if (value is Map) {
            final imageUrl = await _getImageUrl(key);

            final title =
                (value['titleEng'] ?? value['titleTag'] ?? 'No Title')
                    .toString();

            // Normalise category
            String rawCategory =
                (value['typeEng'] ?? value['typeTag'] ?? '').toString();
            String normalizedCategory = 'Uncategorized';
            if (rawCategory.isNotEmpty) {
              final lc = rawCategory.toLowerCase();
              if (lc.contains('folktale') || lc.contains('folktales')) {
                normalizedCategory = 'Folktale';
              } else if (lc.contains('legend') || lc.contains('legends'))
                normalizedCategory = 'Legend';
              else if (lc.contains('fable') || lc.contains('fables'))
                normalizedCategory = 'Fable';
              else if (rawCategory.split(' ').length <= 3 &&
                  !rawCategory.contains('The'))
                normalizedCategory = rawCategory;
            }

            if (normalizedCategory != 'Uncategorized') {
              categoriesFound.add(normalizedCategory);
            }

            final bool isRead = value['isRead'] == true;
            final double progress =
                (value['progress'] is num)
                    ? (value['progress'] as num).toDouble()
                    : 0.0;

            fetchedStories.add({
              'id': key,
              'title': title,
              'imageUrl': imageUrl,
              'category': normalizedCategory,
              'isRead': isRead,
              'progress': progress,
            });
          }
        }),
      );

      // update dropdown categories only on first page to avoid flicker
      if (_currentPage == 0) {
        final validCategories =
            <String>{...allCategories, ...categoriesFound}.toList()..sort();
        // keep 'All Categories' as default first item when building dropdown
        allCategories = validCategories;
      }

      if (!mounted) return;
      setState(() {
        allStories.addAll(fetchedStories);
        _currentPage++;
        _hasMoreStories = endIndex < storyKeys.length;
        isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e, st) {
      // print for debugging; don't crash UI
      // ignore: avoid_print
      print('Error fetching stories: $e\n$st');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        _isLoadingMore = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(
      context,
      listen: false,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD93D),
        title: Consumer<LocalizationProvider>(
          builder:
              (context, localization, _) =>
                  Text(
                    localization.translate('stories'),
                    style: GoogleFonts.fredoka(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SEARCH BAR
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
                  _searchTimer?.cancel();
                  _searchTimer = Timer(const Duration(milliseconds: 500), () {
                    // reset pagination & reload with search filter
                    setState(() {
                      searchQuery = value.trim();
                      _currentPage = 0;
                      _hasMoreStories = true;
                      allStories.clear();
                    });
                    fetchStories();
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
                                _currentPage = 0;
                                _hasMoreStories = true;
                                allStories.clear();
                              });
                              fetchStories();
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

          // FILTERS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Consumer<LocalizationProvider>(
                    builder:
                        (context, localization, _) => Text(
                          '${localization.translate('filterByCategory')} ',
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: selectedCategory,
                    onChanged: (newCategory) {
                      if (newCategory == null) return;
                      setState(() {
                        selectedCategory = newCategory;
                        // reset list and fetch
                        _currentPage = 0;
                        _hasMoreStories = true;
                        allStories.clear();
                      });
                      fetchStories();
                    },
                    items:
                        ['All Categories', ...allCategories]
                            .map(
                              (String value) => DropdownMenuItem<String>(
                                value: value,
                                child: SizedBox(
                                  width: 150,
                                  child: Text(
                                    _localizedLabel(value, localization),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(width: 16),
                  Consumer<LocalizationProvider>(
                    builder:
                        (context, localization, _) => Text(
                          '${localization.translate('filterByReadStatus')} ',
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: selectedReadStatus,
                    onChanged: (newStatus) {
                      if (newStatus == null) return;
                      setState(() {
                        selectedReadStatus = newStatus;
                        _currentPage = 0;
                        _hasMoreStories = true;
                        allStories.clear();
                      });
                      fetchStories();
                    },
                    items:
                        readStatuses
                            .map(
                              (String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  _localizedLabel(value, localization),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
          ),

          // STORIES LIST
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildStoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryList() {
    final localization = Provider.of<LocalizationProvider>(
      context,
      listen: false,
    );

    final List<Map<String, dynamic>> filteredStories =
        allStories.where((story) {
          final matchesCategory =
              selectedCategory == 'All Categories' ||
              story['category'] == selectedCategory;
          final matchesReadStatus =
              selectedReadStatus == 'All Status' ||
              (selectedReadStatus == 'Read' && story['isRead'] == true) ||
              (selectedReadStatus == 'Unread' && story['isRead'] == false);
          final matchesSearchQuery = (story['title'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase());
          return matchesCategory && matchesReadStatus && matchesSearchQuery;
        }).toList();

    if (filteredStories.isEmpty) {
      return Center(
        child: Text(
          localization.translate('noStoriesMatching'),
          style: GoogleFonts.fredoka(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _currentPage = 0;
        _hasMoreStories = true;
        allStories.clear();
        await fetchStories(refresh: true);
      },
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: filteredStories.length + (_hasMoreStories ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index == filteredStories.length) {
            // show bottom loader
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final story = filteredStories[index];
          return GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoryScreen(storyId: story['id']),
                ),
              );
              // refresh on return to update read status
              _currentPage = 0;
              _hasMoreStories = true;
              allStories.clear();
              fetchStories();
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
                  Container(
                    width: 120,
                    height: 150,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child:
                        (story['imageUrl'] ?? '').toString().isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: story['imageUrl'],
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
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
                              errorWidget:
                                  (context, url, error) => Container(
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
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            story['title'] ?? 'No Title',
                            style: GoogleFonts.fredoka(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${localization.translate('categories')}: ${_localizedLabel(story['category'], localization)}',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                story['isRead']
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                size: 16,
                                color:
                                    story['isRead']
                                        ? Colors.green
                                        : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                story['isRead']
                                    ? localization.translate('read')
                                    : localization.translate('unread'),
                                style: GoogleFonts.fredoka(
                                  fontSize: 14,
                                  color:
                                      story['isRead']
                                          ? Colors.green
                                          : Colors.grey,
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
                                style: GoogleFonts.fredoka(
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
