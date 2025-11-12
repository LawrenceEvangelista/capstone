// lib/models/story_model.dart

class StoryModel {
  final String id;
  final String title;
  final String category;
  final double progress;
  // You might add a 'description' or 'imageUrl' later.

  StoryModel({
    required this.id,
    required this.title,
    required this.category,
    required this.progress,
  });
}