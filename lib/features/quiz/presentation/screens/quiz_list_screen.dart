// testapp/lib/features/quiz/presentation/screens/quiz_list_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:testapp/core/services/voice_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:testapp/features/quiz/data/models/question_model.dart';
import 'package:testapp/features/stories/presentation/widgets/story_card.dart';
import 'package:testapp/features/quiz/presentation/widgets/quiz_filters_bottom_sheet.dart';

import '../../../../providers/localization_provider.dart';
import '../screens/quiz_qa.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  final DatabaseReference _storiesRef = FirebaseDatabase.instance.ref().child(
    'stories',
  );
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController searchController = TextEditingController();
  final VoiceService voice = VoiceService();

  bool _isLoading = true;
  Timer? _searchTimer;

  String searchQuery = '';
  String selectedCategory = 'All Categories';
  String selectedQuizStatus = 'All';

  List<String> allCategories = ['Folktale', 'Legend', 'Fable', 'Fiction'];
  List<String> quizStatuses = ['All', 'Completed', 'Incomplete'];

  List<Map<String, dynamic>> _storiesWithQuiz = [];
  Map<String, String> _imageUrlCache = {};

  @override
  void initState() {
    super.initState();
    _loadStoriesWithQuiz();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<String> _getImageUrl(String storyId) async {
    if (_imageUrlCache.containsKey(storyId)) return _imageUrlCache[storyId]!;
    String url = '';
    try {
      url = await _storage.ref('images/$storyId.png').getDownloadURL();
    } catch (e) {
      try {
        url = await _storage.ref('images/$storyId.jpg').getDownloadURL();
      } catch (e) {
        url = ''; // fallback to placeholder
      }
    }
    _imageUrlCache[storyId] = url;
    return url;
  }

  /// Loads all stories but keeps only those that have a `quiz` child.
  Future<void> _loadStoriesWithQuiz() async {
    setState(() => _isLoading = true);
    try {
      DatabaseEvent event = await _storiesRef.once();
      final snapshot = event.snapshot;
      if (snapshot.value != null && snapshot.value is Map) {
        final Map<dynamic, dynamic> data = snapshot.value as Map;
        final List<Map<String, dynamic>> fetched = [];

        // concurrently fetch image URLs for stories that contain 'quiz'
        await Future.wait(
          data.keys.map((key) async {
            final value = data[key];
            if (value is Map && value.containsKey('quiz')) {
              final title =
                  value['titleEng'] ?? value['titleTag'] ?? 'No Title';
              final category =
                  (value['typeEng'] ?? value['typeTag'] ?? 'Uncategorized')
                      .toString();
              final progress =
                  (value['progress'] ?? 0.0) is double
                      ? value['progress'] ?? 0.0
                      : double.tryParse(
                            (value['progress'] ?? '0.0').toString(),
                          ) ??
                          0.0;
              final isRead = value['isRead'] ?? false;

              final imageUrl = await _getImageUrl(key);

              fetched.add({
                'id': key,
                'title': title,
                'category': category,
                'progress': progress,
                'isRead': isRead,
                'imageUrl': imageUrl,
              });
            }
          }).toList(),
        );

        // compute categories dynamically (merge defaults)
        final Set<String> categoriesSet = {...allCategories};
        for (var s in fetched) {
          final c = s['category']?.toString() ?? '';
          if (c.isNotEmpty) categoriesSet.add(_normalizeCategory(c));
        }
        allCategories = categoriesSet.toList()..sort();

        setState(() {
          _storiesWithQuiz = fetched;
          _isLoading = false;
        });
      } else {
        setState(() {
          _storiesWithQuiz = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading quizzes: $e');
      setState(() {
        _storiesWithQuiz = [];
        _isLoading = false;
      });
    }
  }

  // normalize simple categories to your UI names
  String _normalizeCategory(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('folk')) return 'Folktale';
    if (s.contains('legend')) return 'Legend';
    if (s.contains('fable')) return 'Fable';
    if (s.contains('fiction')) return 'Fiction';
    return raw;
  }

  String _localizedLabel(String value, LocalizationProvider localization) {
    String mappedKey = value.toLowerCase();

    if (value == 'All Categories' || value == 'All') {
      mappedKey = 'allStories';
    } else if (value == 'Fables') {
      mappedKey = 'fable';
    } else if (value == 'Folktale') {
      mappedKey = 'folktale';
    } else if (value == 'Legend') {
      mappedKey = 'legend';
    } else if (value == 'Fiction') {
      mappedKey = 'fiction';
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
        title: Text(
          localization.translate('storyQuizzes'),
          style: GoogleFonts.sniglet(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
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
                controller: searchController,
                onChanged: (value) {
                  _searchTimer?.cancel();
                  _searchTimer = Timer(
                    const Duration(milliseconds: 350),
                    () => setState(() => searchQuery = value),
                  );
                },
                decoration: InputDecoration(
                  hintText: localization.translate('searchStories'),

                  // 🔥 Move mic to the LEFT
                  prefixIcon: IconButton(
                    icon: Icon(
                      voice.isListening ? Icons.mic : Icons.mic_none,
                      color: voice.isListening ? Colors.red : Colors.black,
                    ),
                    onPressed: () async {
                      if (voice.isListening) {
                        await voice.stopListening();
                        setState(() {});
                      } else {
                        await voice.startListening((text) {
                          setState(() {
                            searchController.text = text;
                            searchQuery = text;
                          });
                        });
                        setState(() {});
                      }
                    },
                  ),

                  // wigets/quiz_filters_bottom_sheet.dart
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      QuizFiltersBottomSheet.show(
                        context: context,
                        localization: localization,
                        selectedCategory: selectedCategory,
                        selectedQuizStatus: selectedQuizStatus,
                        allCategories: allCategories,
                        quizStatuses: quizStatuses,
                        onCategoryChanged:
                            (v) => setState(() => selectedCategory = v),
                        onStatusChanged:
                            (v) => setState(() => selectedQuizStatus = v),
                      );
                    },
                  ),

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

          // Content
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildListView(localization),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(LocalizationProvider localization) {
    final filtered =
        _storiesWithQuiz.where((s) {
          final title = (s['title'] ?? '').toString().toLowerCase();
          final category = (s['category'] ?? 'Uncategorized').toString();
          final progress = (s['progress'] ?? 0.0) as double;

          final matchesSearch = title.contains(searchQuery.toLowerCase());
          final matchesCategory =
              selectedCategory == 'All Categories' ||
              category == selectedCategory;
          final matchesStatus =
              selectedQuizStatus == 'All' ||
              (selectedQuizStatus == 'Completed' && progress >= 1.0) ||
              (selectedQuizStatus == 'Incomplete' && progress < 1.0);

          return matchesSearch && matchesCategory && matchesStatus;
        }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          localization.translate('noStoriesMatching'),
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final story = filtered[index];

        return StoryCard(
          storyId: story['id'] ?? '',
          title: story['title'] ?? 'No Title',

          // prevent null or weird category
          category: _localizedLabel(
            (story['category'] ?? 'Uncategorized').toString(),
            localization,
          ),

          // Safe image
          imageUrl: story['imageUrl'] ?? '',

          // prevent crash if progress is string/null/not-double
          progress:
              (story['progress'] is double)
                  ? story['progress']
                  : double.tryParse(story['progress']?.toString() ?? '0') ??
                      0.0,

          isRead: story['isRead'] ?? false,

          onTap: () async {
            final quizRoot = FirebaseDatabase.instance.ref(
              "stories/${story['id']}/quiz",
            );

            // 🔥 Step 1: detect the quiz node name (owl_legend, doc1, etc.)
            final quizNodeSnap = await quizRoot.get();

            if (quizNodeSnap.value == null || quizNodeSnap.value is! Map) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("No quiz available for this story"),
                ),
              );
              return;
            }

            // The first child under "quiz" is the quiz root
            final firstQuizKey = (quizNodeSnap.value as Map).keys.first;

            // 🔥 Step 2: load questions
            final questionsSnap =
                await quizRoot.child("$firstQuizKey/questions").get();

            if (questionsSnap.value == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("No questions found.")),
              );
              return;
            }

            final raw = questionsSnap.value as Map;

            // 🔥 Step 3: convert map to QuestionModel list
            List<QuestionModel> allQuestions =
                raw.values.map((q) => QuestionModel.fromMap(q)).toList();

            allQuestions.shuffle();

            final selectedQuestions = allQuestions.take(10).toList();

            // 🔥 Step 4: navigate to quiz screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => QuizQa(
                      storyId: story['id'],
                      storyTitle: story['title'],
                      questions: selectedQuestions,
                    ),
              ),
            );
          },
        );
      },
    );
  }
}
