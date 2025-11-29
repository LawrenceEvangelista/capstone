// lib/features/stories/presentation/widgets/story_flipbook_container.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:testapp/core/widgets/fullscreen_image_viewer.dart';
import 'package:testapp/features/stories/presentation/widgets/highlighted_text.dart';
import 'package:testapp/features/stories/presentation/widgets/narration_controls.dart';
import 'package:testapp/features/narration/provider/audio_provider.dart';

/// Simple, reliable flipbook implemented with PageView.
///
/// Accepts the same arguments the StoryScreen expects:
/// - storyPages: List<Map<String,String>> with keys 'textEng','textTag','image'
/// - isEnglish, primaryColor, accentColor, buttonColor
/// - lastPage: Widget shown at the end
/// - onPageViewed: callback(pageNum)
///
/// NOTE: narrationPosition & narrationDuration are kept for backwards compatibility
/// but the new implementation uses AudioProvider for syncing.
class StoryFlipbookContainer extends StatefulWidget {
  final List<Map<String, dynamic>> storyPages;
  final bool isEnglish;
  final Color primaryColor;
  final Color accentColor;
  final Color buttonColor;
  final Widget lastPage;
  final Function(int pageNum)? onPageViewed;
  final double narrationPosition; // kept for compat (unused)
  final double narrationDuration; // kept for compat (unused)

  const StoryFlipbookContainer({
    super.key,
    required this.storyPages,
    required this.isEnglish,
    required this.primaryColor,
    required this.accentColor,
    required this.buttonColor,
    required this.lastPage,
    this.onPageViewed,
    this.narrationPosition = 0,
    this.narrationDuration = 0,
  });

  @override
  State<StoryFlipbookContainer> createState() => _StoryFlipbookContainerState();
}

class _StoryFlipbookContainerState extends State<StoryFlipbookContainer> {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _hasLoadedInitialPage = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // notify initial (page 1) and load first page TTS via provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPageViewed?.call(1);
      _loadPageTtsIfNeeded(0);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int idx) {
    setState(() => _currentIndex = idx);
    // If index is within story pages, call with 1-based page number
    if (idx < widget.storyPages.length) {
      widget.onPageViewed?.call(idx + 1);
      _loadPageTtsIfNeeded(idx);
    } else {
      // last page (complete)
      widget.onPageViewed?.call(widget.storyPages.length + 1);
      // stop audio on last page
      final audio = Provider.of<AudioProvider>(context, listen: false);
      audio.stop();
    }
  }

  Future<void> _loadPageTtsIfNeeded(int index) async {
    // load TTS only when index is a valid page (not lastPage)
    if (index < 0 || index >= widget.storyPages.length) return;

    final audio = Provider.of<AudioProvider>(context, listen: false);

    // Prevent double-loading the same page (simple check)
    // We use provider's duration + timestamps to heuristically decide,
    // but simplest is to reload every time the page becomes visible to ensure sync.
    final page = widget.storyPages[index];
    final text =
        widget.isEnglish ? (page['textEng'] ?? '') : (page['textTag'] ?? '');
    final languageCode = widget.isEnglish ? 'en-US' : 'fil-PH';

    // load and autoplay page audio
    await audio.loadPageFromTts(
      pageText: text,
      languageCode: languageCode,
      voiceName: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.storyPages.length + 1; // +1 for lastPage
    final audio = Provider.of<AudioProvider>(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: total,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  if (index >= widget.storyPages.length) {
                    // show lastPage
                    return widget.lastPage;
                  }

                  final page = widget.storyPages[index];
                  final text =
                      widget.isEnglish
                          ? (page['textEng'] ?? '')
                          : (page['textTag'] ?? '');
                  final imageUrl = page['image'] ?? '';

                  final bool isLongText = text.length > 120;

                  return _buildPage(
                    context,
                    pageNumber: index + 1,
                    totalPages: widget.storyPages.length,
                    imageUrl: imageUrl,
                    text: text,
                    isLongText: isLongText,
                    primaryColor: widget.primaryColor,
                    audio: audio,
                  );
                },
              ),
            ),

            // Page indicator + simple controls row (previous / next)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    onPressed:
                        _currentIndex > 0
                            ? () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 360),
                              curve: Curves.ease,
                            )
                            : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _currentIndex < widget.storyPages.length
                            ? 'Page ${_currentIndex + 1} / ${widget.storyPages.length}'
                            : 'Complete',
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _currentIndex < total - 1
                            ? () => _pageController.nextPage(
                              duration: const Duration(milliseconds: 360),
                              curve: Curves.ease,
                            )
                            : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(
    BuildContext context, {
    required int pageNumber,
    required int totalPages,
    required String imageUrl,
    required String text,
    required bool isLongText,
    required Color primaryColor,
    required AudioProvider audio,
  }) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            flex: isLongText ? 52 : 62,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    if (imageUrl.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => FullscreenImageViewer(
                                imageUrl: imageUrl,
                                heroTag: 'page-$pageNumber',
                              ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child:
                        imageUrl.isNotEmpty
                            ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (c, child, progress) {
                                if (progress == null) return child;
                                final value =
                                    progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                                        : null;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: value,
                                    color: primaryColor,
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => _brokenImage(),
                            )
                            : _brokenImage(),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$pageNumber / $totalPages',
                      style: GoogleFonts.fredoka(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.25),
                  primaryColor,
                  primaryColor.withOpacity(0.25),
                ],
              ),
            ),
          ),

          Expanded(
            flex: isLongText ? 48 : 38,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Highlighted text using provider-driven activeWordIndex
                  HighlightedText(
                    text: text,
                    activeIndex: audio.activeWordIndex,
                    fontSize: 17,
                  ),

                  const SizedBox(height: 18),

                  // Narration controls (play/pause/replay + progress bar)
                  NarrationControls(
                    primaryColor: primaryColor,
                    buttonColor: widget.buttonColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brokenImage() => Center(
    child: Icon(
      Icons.image_not_supported,
      size: 48,
      color: Colors.grey.shade500,
    ),
  );
}
