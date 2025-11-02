// lib/widgets/quiz_story_card.dart

import 'package:flutter/material.dart';
import '../models/story_model.dart';

class QuizStoryCard extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onTap;

  const QuizStoryCard({
    super.key,
    required this.story,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            // Image Placeholder (Design Preserved)
            Container(
              width: 120,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                border: Border.all(color: Colors.grey, width: 2),
                color: Colors.white,
              ),
              child: const Center(
                child: Icon(Icons.image, color: Colors.grey, size: 40),
              ),
            ),

            // Story Details (Design Preserved)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Placeholder for description/category
                    Text(
                      'Category: ${story.category}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const Spacer(),
                    // Progress Indicator (Design Preserved)
                    LinearProgressIndicator(
                      value: story.progress,
                      backgroundColor: Colors.white,
                      color: Colors.blueAccent,
                      minHeight: 6,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      story.progress == 0.0
                          ? 'Not taken yet'
                          : '${(story.progress * 100).toInt()}% quiz taken',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
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