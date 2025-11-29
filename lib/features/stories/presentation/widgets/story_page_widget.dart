// lib/features/stories/presentation/widgets/story_page_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:testapp/core/widgets/fullscreen_image_viewer.dart';
import 'package:testapp/core/services/text_sync_service.dart';

class StoryPageWidget extends StatefulWidget {
  final String pageContent;
  final String imageUrl;
  final int pageNumber;
  final int totalPages;
  final Color primaryColor;

  final Function(int)? onPageViewed;

  final double narrationPosition; // ms
  final double narrationDuration; // ms

  const StoryPageWidget({
    super.key,
    required this.pageContent,
    required this.imageUrl,
    required this.pageNumber,
    required this.totalPages,
    required this.primaryColor,
    this.onPageViewed,
    this.narrationPosition = 0,
    this.narrationDuration = 0,
  });

  @override
  State<StoryPageWidget> createState() => _StoryPageWidgetState();
}

class _StoryPageWidgetState extends State<StoryPageWidget> {
  @override
  void initState() {
    super.initState();
    // notify StoryScreen this page is viewed
    Future.microtask(() {
      widget.onPageViewed?.call(widget.pageNumber);
    });
  }

  @override
  void didUpdateWidget(covariant StoryPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Text highlight sync updates when narration moves
    if (oldWidget.narrationPosition != widget.narrationPosition ||
        oldWidget.narrationDuration != widget.narrationDuration) {
      setState(() {});
    }
  }

  /// ------------------------------------------------------------
  /// TEXT HIGHLIGHT LOGIC
  /// ------------------------------------------------------------
  Widget _buildHighlightedText() {
    final text = widget.pageContent;

    final progress = TextSyncService.calculateHighlightProgress(
      widget.narrationPosition,
      widget.narrationDuration,
    );

    final highlightIndex = TextSyncService.getHighlightCharIndex(
      text,
      progress,
    ).clamp(0, text.length);

    final highlighted = text.substring(0, highlightIndex);
    final remaining = text.substring(highlightIndex);

    final isLong = text.length > 130;

    final baseStyle = GoogleFonts.fredoka(
      fontSize: isLong ? 15 : 17,
      height: 1.45,
      color: Colors.black87,
    );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: highlighted,
            style: baseStyle.copyWith(
              color: widget.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: remaining, style: baseStyle),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  /// ------------------------------------------------------------
  /// IMAGE VIEW
  /// ------------------------------------------------------------
  Widget _buildImage() {
    if (widget.imageUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.broken_image, size: 50),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => FullscreenImageViewer(
                  imageUrl: widget.imageUrl,
                  heroTag: "page-${widget.pageNumber}",
                ),
          ),
        );
      },
      child: Hero(
        tag: "page-${widget.pageNumber}",
        child: Image.network(
          widget.imageUrl,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, loading) {
            if (loading == null) return child;
            return Center(
              child: CircularProgressIndicator(color: widget.primaryColor),
            );
          },
        ),
      ),
    );
  }

  /// ------------------------------------------------------------
  /// BUILD PAGE UI
  /// ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isLong = widget.pageContent.length > 130;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            Expanded(
              flex: isLong ? 50 : 60,
              child: Stack(
                children: [
                  _buildImage(),

                  /// Page badge (e.g. 2/12)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${widget.pageNumber}/${widget.totalPages}",
                        style: GoogleFonts.fredoka(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  /// Tap-to-expand hint
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.fullscreen,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Tap to expand",
                            style: GoogleFonts.fredoka(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// Divider
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.primaryColor.withOpacity(0.2),
                    widget.primaryColor,
                    widget.primaryColor.withOpacity(0.2),
                  ],
                ),
              ),
            ),

            /// TEXT
            Expanded(
              flex: isLong ? 50 : 40,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                child: _buildHighlightedText(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
