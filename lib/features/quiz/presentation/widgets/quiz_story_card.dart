import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class QuizStoryCard extends StatelessWidget {
  final String title;
  final String category;
  final String imageUrl;
  final double progress;
  final bool isRead;
  final int questionCount;
  final VoidCallback onTap;

  const QuizStoryCard({
    super.key,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.progress,
    required this.isRead,
    required this.questionCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNew = progress == 0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // ---- LEFT IMAGE ----
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child:
                  imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 120,
                        height: 150,
                        fit: BoxFit.cover,
                        placeholder:
                            (_, __) => Container(
                              width: 120,
                              height: 150,
                              color: Colors.yellow.shade100,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                        errorWidget:
                            (_, __, ___) => Container(
                              width: 120,
                              height: 150,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.broken_image),
                            ),
                      )
                      : Container(
                        width: 120,
                        height: 150,
                        color: Colors.yellow.shade100,
                        child: const Icon(Icons.book, size: 40),
                      ),
            ),

            // RIGHT SECTION
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // TITLE + NEW badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.fredoka(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "NEW",
                              style: GoogleFonts.fredoka(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // CATEGORY
                    Text(
                      category,
                      style: GoogleFonts.fredoka(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // QUESTION COUNT
                    Row(
                      children: [
                        const Icon(
                          Icons.quiz,
                          size: 16,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "$questionCount Questions",
                          style: GoogleFonts.fredoka(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // PROGRESS BAR + %
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: progress,
                          color: const Color(0xFFFFD93D),
                          backgroundColor: Colors.grey.shade300,
                          minHeight: 6,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${(progress * 100).toStringAsFixed(0)}%",
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
  }
}
