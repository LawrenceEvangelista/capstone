import 'package:flutter/material.dart';
import 'package:page_flip/page_flip.dart';
import 'story_page_widget.dart';

class StoryFlipBook extends StatefulWidget {
  final List<Map<String, String>> storyPages;
  final bool isEnglish;
  final Color primaryColor;
  final Widget lastPage;
  final Function(int pageNum)? onPageViewed;
  final double narrationPosition;
  final double narrationDuration;

  const StoryFlipBook({
    super.key,
    required this.storyPages,
    required this.isEnglish,
    required this.primaryColor,
    required this.lastPage,
    this.onPageViewed,
    this.narrationPosition = 0,
    this.narrationDuration = 0,
  });

  @override
  State<StoryFlipBook> createState() => _StoryFlipBookState();
}

class _StoryFlipBookState extends State<StoryFlipBook> {
  final _controller = GlobalKey<PageFlipWidgetState>();

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[];

    // --- Build story pages ---
    for (int i = 0; i < widget.storyPages.length; i++) {
      final page = widget.storyPages[i];

      pages.add(
        StoryPageWidget(
          pageContent:
              widget.isEnglish
                  ? (page["textEng"] ?? "")
                  : (page["textTag"] ?? ""),
          imageUrl: page["image"] ?? "",
          pageNumber: i + 1,
          totalPages: widget.storyPages.length,
          primaryColor: widget.primaryColor,

          onPageViewed: (num) {
            if (widget.onPageViewed != null) {
              widget.onPageViewed!(num);
            }
          },

          narrationPosition: widget.narrationPosition,
          narrationDuration: widget.narrationDuration,
        ),
      );
    }

    // --- Last Page (Story Complete) ---
    pages.add(widget.lastPage);

    return PageFlipWidget(
      key: _controller,
      backgroundColor: Colors.transparent,

      onPageTurn: (int pageIndex) {
        if (widget.onPageViewed != null &&
            pageIndex < widget.storyPages.length) {
          widget.onPageViewed!(pageIndex + 1);
        }
      },

      children: pages,
    );
  }
}
