// lib/features/stories/data/models/story_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String id;
  final String title;
  final String category;
  final double progress;

  StoryModel({
    required this.id,
    required this.title,
    required this.category,
    required this.progress,
  });

  /// Create a StoryModel from Firestore DocumentSnapshot
  factory StoryModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StoryModel(
      id: doc.id,
      title: data['title'] ?? 'Untitled Story',
      category: data['category'] ?? 'Uncategorized',
      progress: (data['progress'] ?? 0).toDouble(),
    );
  }

  /// Create a StoryModel from JSON (for local use or API)
  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      progress: (json['progress'] ?? 0).toDouble(),
    );
  }

  /// Convert the model to JSON for Firestore or API storage
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'progress': progress,
    };
  }

  /// Create a copy with new data (for updating progress, etc.)
  StoryModel copyWith({
    String? id,
    String? title,
    String? category,
    double? progress,
  }) {
    return StoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      progress: progress ?? this.progress,
    );
  }
}
