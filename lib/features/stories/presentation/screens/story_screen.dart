// lib/features/stories/presentation/screens/story_screen.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:testapp/features/stories/presentation/widgets/story_flipbook_container.dart';
import 'package:testapp/features/favorites/provider/favorites_provider.dart';
import 'package:testapp/providers/recently_viewed_provider.dart';
import 'package:testapp/providers/localization_provider.dart';
import 'package:testapp/features/quiz/data/models/question_model.dart';
import 'package:testapp/features/quiz/presentation/screens/quiz_qa.dart';
import 'package:testapp/providers/recently_viewed_provider.dart';
import '../../../../providers/localization_provider.dart';
import '../../../../core/widgets/narration_player.dart';
import '../../../../core/widgets/fullscreen_image_viewer.dart';
import '../../../../core/services/text_sync_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StoryScreen extends StatefulWidget {
  final String storyId;

  const StoryScreen({super.key, required this.storyId});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool isLoading = true;
  bool _isEnglish = true;
  String storyTitle = '';
  List<Map<String, dynamic>> storyPages = [];
  String errorMessage = '';
  Map<String, dynamic> storyData = {};
  int _currentPageIndex = 0;

  // Theme colors
  final Color _backgroundColor = const Color(0xFFFFF176);
  final Color _primaryColor = const Color(0xFFFF6D00);
  final Color _accentColor = const Color(0xFF8E24AA);
  final Color _buttonColor = const Color(0xFFFF9800);

  // Narration defaults
  double _speakingRate = 0.9;
  double _pitch = 1.0;
  String _voiceEn = 'en-US-Studio-O';
  String _voiceTag = 'fil-PH-Wavenet-C';

  final List<String> _enVoices = [
    'en-US-Studio-O',
    'en-US-Neural2-D',
    'en-US-Neural2-F',
  ];
  final List<String> _tagVoices = [
    'fil-PH-Wavenet-C',
    'fil-PH-Wavenet-A',
    'fil-PH-Wavenet-B',
  ];

  @override
  void initState() {
    super.initState();
    _fetchStoryData();
    _trackStoryView();
  }

  // --------------------------
  // RECENTLY VIEWED
  // --------------------------
  Future<void> _trackStoryView() async {
    try {
      final snapshot =
          await FirebaseDatabase.instance
              .ref('stories/${widget.storyId}')
              .once();

      if (snapshot.snapshot.value != null && snapshot.snapshot.value is Map) {
        final data = snapshot.snapshot.value as Map;

        String imageUrl = '';
        try {
          imageUrl =
              await _storage
                  .ref('images/${widget.storyId}.png')
                  .getDownloadURL();
        } catch (_) {
          try {
            imageUrl =
                await _storage
                    .ref('images/${widget.storyId}.jpg')
                    .getDownloadURL();
          } catch (_) {}
        }

        final viewData = {
          'id': widget.storyId,
          'title': data['titleEng'] ?? data['titleTag'] ?? 'No Title',
          'titleTag': data['titleTag'],
          'titleEng': data['titleEng'],
          'imageUrl': imageUrl,
          'progress': data['progress'] ?? 0.0,
        };

        if (mounted) {
          Provider.of<RecentlyViewedProvider>(
            context,
            listen: false,
          ).addRecentlyViewed(viewData);
        }
      }
    } catch (_) {}
  }

  // --------------------------
  // LOAD STORY DATA
  // --------------------------
  Future<String> _loadPageImage(int pageNumber) async {
    final tryPaths = [
      'storypages/${widget.storyId}/PAGE $pageNumber.png',
      'storypages/${widget.storyId}/page$pageNumber.png',
      'storypages/${widget.storyId}/PAGE $pageNumber.jpg',
      'storypages/${widget.storyId}/page$pageNumber.jpg',
    ];

    for (final path in tryPaths) {
      try {
        return await _storage.ref(path).getDownloadURL();
      } catch (_) {}
    }
    return '';
  }

  Future<void> _fetchStoryData() async {
    setState(() => isLoading = true);

        // Store story data for favorites and recently viewed
        storyData = {
          'id': widget.storyId,
          'titleEng': titleEng,
          'titleTag': titleTag,
          'category': category,
          'title':
              _isEnglish
                  ? (titleEng ?? 'No Title')
                  : (titleTag ?? 'Walang Pamagat'),
          'image':
              coverImageUrl.isNotEmpty
                  ? coverImageUrl
                  : (combinedPages.isNotEmpty ? combinedPages[0]['image'] : ''),
          // NOTE: 'progress' is initially set in _trackStoryView or fetched in the main list.
          // We default it here but the tracking logic will update it.
          'progress': data['progress'] ?? 0.0,
        };

      if (snap.snapshot.value == null || snap.snapshot.value is! Map) {
        setState(() {
          isLoading = false;
          errorMessage = 'Story not found';
        });
        return;
      }

      final data = snap.snapshot.value as Map;
      final titleEng = data['titleEng'] ?? '';
      final titleTag = data['titleTag'] ?? '';

      final List<Map<String, dynamic>> pages = [];

      if (data['pages'] is Map) {
        final pageMap = data['pages'] as Map;

        final keys = pageMap.keys.map((e) => e.toString()).toList();
        keys.sort((a, b) {
          final ai = int.tryParse(a.replaceAll(RegExp(r'\D'), '')) ?? 0;
          final bi = int.tryParse(b.replaceAll(RegExp(r'\D'), '')) ?? 0;
          return ai.compareTo(bi);
        });

        for (int i = 0; i < keys.length; i++) {
          final pageObj = pageMap[keys[i]];
          if (pageObj is Map) {
            final imageUrl = await _loadPageImage(i + 1);

            List<Map<String, String>>? segments;
            final rawSeg = pageObj['segments'];
            if (rawSeg is List) {
              try {
                segments =
                    rawSeg
                        .where((e) => e != null)
                        .map<Map<String, String>>(
                          (e) => Map<String, String>.from(e as Map),
                        )
                        .toList();
              } catch (_) {}
            }

            pages.add({
              'textEng': pageObj['textEng'] ?? '',
              'textTag': pageObj['textTag'] ?? '',
              'image': imageUrl,
              'segments': segments,
            });
          }
        }
      }

      storyData = {
        'titleEng': titleEng,
        'titleTag': titleTag,
        'category': data['category'] ?? '',
        'image': '',
      };

      setState(() {
        storyTitle = _isEnglish ? titleEng : titleTag;
        storyPages = pages;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading story: $e';
      });
    }
  }

  // 🔥 FIX: Function to calculate and save story progress
  Future<void> _updateStoryProgress(int newPageIndex) async {
    // Only update if pages exist and index is valid
    if (storyPages.isEmpty) return;

    if (newPageIndex >= 0 && newPageIndex < storyPages.length) {
      final double totalPages = storyPages.length.toDouble();
      // Progress calculation: (Current Page Index + 1) / Total Pages
      // Clamp to ensure it doesn't exceed 1.0
      final double newProgress =
          ((newPageIndex + 1).toDouble() / totalPages).clamp(0.0, 1.0);

      try {
        // 1. Persist the new progress to Firebase Realtime Database
        await FirebaseDatabase.instance.ref()
          .child('stories/${widget.storyId}')
          .update({'progress': newProgress});

        // 2. Update the Recently Viewed provider (for immediate display on other screens)
        final storyDataToUpdate = {
          'id': widget.storyId,
          // Use current title, as it might be localized
          'title': storyTitle,
          'titleTag': storyData['titleTag'],
          'titleEng': storyData['titleEng'],
          'imageUrl': storyData['image'],
          'progress': newProgress, // Use the new progress
        };

        if (mounted) {
          Provider.of<RecentlyViewedProvider>(
            context,
            listen: false,
          ).addRecentlyViewed(storyDataToUpdate);
        }

        print('✅ Progress updated for ${widget.storyId}: $newProgress');
      } catch (e) {
        print('❌ Error saving story progress: $e');
      }
    }
  }

  void _toggleLanguage() {
    setState(() {
      _isEnglish = !_isEnglish;
      // Update the story title based on the current language
      if (storyData['titleEng'] != null && storyData['titleTag'] != null) {
        storyTitle = _isEnglish ? storyData['titleEng'] : storyData['titleTag'];
      }
      // Preserve the current page index when language changes
      // The narration will restart from the new page when player reloads
    });
  }

  /// Builds the list of story page widgets with the current language
  List<Widget> _buildStoryPages() {
    if (storyPages.isEmpty) {
      final localization = Provider.of<LocalizationProvider>(context, listen: false);
      return [
        Center(
          child: Text(
            localization.translate('noStoryContentAvailable'),
            style: GoogleFonts.fredoka(
              fontSize: 18,
              color: Colors.black54,
            ),
          ),
        ),
      ];
    }

    return List.generate(
      storyPages.length,
      (index) => StoryPage(
        pageContent:
            _isEnglish
                ? storyPages[index]['textEng']!
                : storyPages[index]['textTag']!,
        imageUrl: storyPages[index]['image']!,
        pageNumber: index + 1,
        totalPages: storyPages.length,
        primaryColor: _primaryColor,
        onPageViewed: (pageNum) {
          setState(() {
            _currentPageIndex = pageNum - 1;
          });
          // 🔥 FIX APPLIED HERE
          _updateStoryProgress(pageNum - 1);
        },
        narrationPosition: _narrationPosition,
        narrationDuration: _narrationDuration,
      ),
    );
  }

  Future<void> _openQuiz() async {
    try {
      final quizRoot = FirebaseDatabase.instance.ref(
        "stories/${widget.storyId}/quiz",
      );
      final quizSnap = await quizRoot.get();

      // 🔥 Step 1: detect any quiz folder name
      final quizNodeSnap = await quizRoot.get();

      if (quizNodeSnap.value == null || quizNodeSnap.value is! Map) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "No quiz available for this story",
              style: GoogleFonts.fredoka(),
            ),
          ),
        );
        return;
      }

      final firstKey = (quizSnap.value as Map).keys.first;
      final qsSnap = await quizRoot.child("$firstKey/questions").get();

      if (qsSnap.value == null || qsSnap.value is! Map) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              "No questions found.",
              style: GoogleFonts.fredoka(),
            ),
          ),
        );
        return;
      }

      final rawMap = qsSnap.value as Map;
      final allQuestions =
          rawMap.entries.map((e) {
            final m = Map<String, dynamic>.from(e.value);
            m['id'] = e.key;
            return QuestionModel.fromMap(m);
          }).toList();

      allQuestions.shuffle();
      final selected = allQuestions.take(10).toList();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => QuizQa(
                storyId: widget.storyId,
                storyTitle: storyTitle,
                questions: selected,
                languagePref: _isEnglish ? 'en' : 'fil',
              ),
        ),
      );
    } catch (e) {
      print("❌ Error opening quiz: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            "Error loading quiz",
            style: GoogleFonts.fredoka(),
          ),
        ),
      );
    }
  }

  // --------------------------
  // SETTINGS SHEET (with download button)
  // --------------------------
  void _openSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            String localEn = _voiceEn;
            String localTag = _voiceTag;
            double localRate = _speakingRate;
            double localPitch = _pitch;

            return Padding(
              padding: MediaQuery.of(ctx).viewInsets,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  children: [
                    Center(
                      child: Container(
                        width: 60,
                        height: 6,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),

                    Text(
                      "Narration Settings",
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Custom AppBar
                      FadeInDown(
                        duration: const Duration(milliseconds: 400),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD93D),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
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
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
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
                              Tooltip(
                                message: _isEnglish
                                    ? 'Switch to Tagalog'
                                    : 'Switch to English',
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _toggleLanguage,
                                    borderRadius: BorderRadius.circular(30),
                                    splashColor: _primaryColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.15,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _isEnglish
                                                ? Icons.translate
                                                : Icons.g_translate,
                                            color: _primaryColor,
                                            size: 28,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _isEnglish ? 'ENG' : 'FIL',
                                            style: GoogleFonts.fredoka(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: _primaryColor,
                                            ),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _startOfflineDownload();
                      },
                    ),

                    const SizedBox(height: 8),

                      // Page flip book container
                      Expanded(
                        child: FadeInUp(
                          delay: const Duration(milliseconds: 400),
                          duration: const Duration(milliseconds: 600),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _primaryColor,
                                  width: 2.5,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryColor.withValues(alpha: 0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: PageFlipWidget(
                                key: ValueKey('${widget.storyId}_$_isEnglish'),
                                backgroundColor: Colors.white,
                                lastPage: Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/story_complete.png',
                                          height: 120,
                                          width: 120,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                                    Icons.check_circle,
                                                    size: 100,
                                                    color: _accentColor,
                                                  ),
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          localization.translate(
                                            'storyComplete',
                                          ),
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
                                              colors: [
                                                _buttonColor,
                                                _accentColor,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              25,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _accentColor.withValues(
                                                  alpha: 0.3,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton.icon(
                                            icon: const Icon(
                                              Icons.quiz,
                                              color: Colors.white,
                                            ),
                                            label: Text(
                                              localization.translate(
                                                'startQuiz',
                                              ),
                                              style: GoogleFonts.fredoka(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            onPressed: _openQuiz,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                children: _buildStoryPages(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      child: Text("Close", style: GoogleFonts.fredoka()),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ========================= PART 2 (CONTINUATION) =========================

  // --------------------------
  // START FULL-SCREEN DOWNLOAD MODAL
  // --------------------------
  void _startOfflineDownload() {
    final audio = Provider.of<AudioProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // Begin download after dialog loads
        Future.microtask(() {
          audio.preloadStoryNarration(
            fullPages: storyPages,
            isEnglish: _isEnglish,
            voiceEn: _voiceEn,
            voiceTag: _voiceTag,
            speakingRate: _speakingRate,
            pitch: _pitch,
          );
        });

        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return Consumer<AudioProvider>(
              builder: (context, audio, _) {
                // Auto-close when done
                if (!audio.isSynthesizing && audio.synthProgress == 1.0) {
                  Future.delayed(const Duration(milliseconds: 400), () {
                    if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Narration Downloaded!")),
                    );
                  });
                }

                return WillPopScope(
                  onWillPop: () async => false,
                  child: Material(
                    color: Colors.black.withOpacity(0.75),
                    child: Center(
                      child: Container(
                        width: 320,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Downloading Narration...",
                              style: GoogleFonts.fredoka(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: audio.synthProgress,
                              backgroundColor: Colors.grey.shade300,
                              color: _primaryColor,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 160,
                              child: ListView.builder(
                                itemCount: audio.synthLog.length,
                                itemBuilder: (ctx, i) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      audio.synthLog[i],
                                      style: GoogleFonts.fredoka(fontSize: 14),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // --------------------------
  // LANGUAGE TOGGLE
  // --------------------------
  void _toggleLanguage() {
    setState(() {
      _isEnglish = !_isEnglish;
      storyTitle = _isEnglish ? storyData['titleEng'] : storyData['titleTag'];
      _currentPageIndex = 0;
    });

  @override
  void didUpdateWidget(StoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rebuild when narration position or duration changes, or when page content changes (language switch)
    if (oldWidget.narrationPosition != widget.narrationPosition ||
        oldWidget.narrationDuration != widget.narrationDuration ||
        oldWidget.pageContent != widget.pageContent) {
      setState(() {});
    }
  }

    if (storyPages.isNotEmpty) {
      final page = storyPages[0];
      final text = _isEnglish ? page['textEng'] : page['textTag'];
      final languageCode = _isEnglish ? 'en-US' : 'fil-PH';
      final voice = _isEnglish ? _voiceEn : _voiceTag;

      List<Map<String, String>>? segments;
      final rawSeg = page['segments'];
      if (rawSeg is List) {
        try {
          segments =
              rawSeg
                  .where((e) => e != null)
                  .map<Map<String, String>>(
                    (e) => Map<String, String>.from(e as Map),
                  )
                  .toList();
        } catch (_) {}
      }

      audio.loadPageFromTts(
        pageText: text,
        languageCode: languageCode,
        voiceName: voice,
        speakingRate: _speakingRate,
        pitch: _pitch,
        ssmlSegments: segments,
      );
    }
  }

  // --------------------------
  // BUILD METHOD
  // --------------------------
  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(
      context,
      listen: false,
    );
    final favorites = Provider.of<FavoritesProvider>(context);
    final isFavorite = favorites.isFavorite(widget.storyId);

    return ChangeNotifierProvider(
      create: (_) => AudioProvider(),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: SafeArea(
          child:
              isLoading
                  ? Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  )
                  : errorMessage.isNotEmpty
                  ? Center(
                    child: Text(
                      errorMessage,
                      style: GoogleFonts.fredoka(fontSize: 16),
                    ),
                  )
                  : _buildContent(localization, favorites, isFavorite),
        ),
      ),
    );
  }

  // --------------------------
  // MAIN CONTENT UI
  // --------------------------
  Widget _buildContent(
    LocalizationProvider localization,
    FavoritesProvider favoritesProvider,
    bool isFavorite,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopBar(),
        const SizedBox(height: 12),

        // Story Title
        Center(
          child: Text(
            storyTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Favorite + Quiz
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Favorite
              GestureDetector(
                onTap: () {
                  favoritesProvider.toggleFavorite(widget.storyId, {
                    'id': widget.storyId,
                    'title': storyTitle,
                    'category': storyData['category'],
                    'image': storyData['image'],
                    'progress': 0.0,
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.22),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                      child:
                          widget.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                imageUrl: widget.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey.shade200,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: widget.primaryColor,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  return Container(
                                    color: Colors.grey.shade300,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image,
                                            size: 48,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            localization.translate(
                                              'imageNotFound',
                                            ),
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
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isFavorite
                            ? localization.translate('favorited')
                            : localization.translate('favorite'),
                        style: GoogleFonts.fredoka(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Quiz Button
              GestureDetector(
                onTap: _openQuiz,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.22),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.quiz, color: _accentColor),
                      const SizedBox(width: 6),
                      Text(
                        localization.translate('quiz'),
                        style: GoogleFonts.fredoka(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Flipbook
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StoryFlipbookContainer(
              // Convert dynamic pages → String-only maps for Flipbook
              storyPages:
                  storyPages.map((page) {
                    return {
                      'textEng': page['textEng'] ?? '',
                      'textTag': page['textTag'] ?? '',
                      'image': page['image'] ?? '',
                    };
                  }).toList(),

              isEnglish: _isEnglish,
              primaryColor: _primaryColor,
              accentColor: _accentColor,
              buttonColor: _buttonColor,
              lastPage: _buildLastPage(localization),

              onPageViewed: (pageNum) {
                setState(() => _currentPageIndex = pageNum - 1);
                _saveBookmark(pageNum);
              },
            ),
          ),
        ),

        // Swipe hint
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swipe_left, color: _accentColor),
                  const SizedBox(width: 8),
                  Text(
                    localization.translate('swipeToTurnPage'),
                    style: GoogleFonts.fredoka(),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.swipe_right, color: _accentColor),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------
  // TOP BAR
  // --------------------------
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD93D),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
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
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "Back Stories",
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: _toggleLanguage,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                _isEnglish ? Icons.translate : Icons.g_translate,
                color: _primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _openSettingsSheet,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(Icons.settings, color: _primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------
  // LAST PAGE: STORY COMPLETE
  // --------------------------
  Widget _buildLastPage(LocalizationProvider localization) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/story_complete.png',
            height: 120,
            errorBuilder:
                (_, __, ___) =>
                    Icon(Icons.check_circle, size: 100, color: _accentColor),
          ),
          const SizedBox(height: 20),
          Text(
            localization.translate('storyComplete'),
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _openQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: _buttonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              localization.translate('startQuiz'),
              style: GoogleFonts.fredoka(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------
  // BOOKMARK SAVE
  // --------------------------
  Future<void> _saveBookmark(int pageNum) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt("bookmark_${widget.storyId}", pageNum);
    } catch (_) {}
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
