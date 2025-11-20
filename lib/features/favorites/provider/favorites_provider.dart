import 'package:flutter/foundation.dart';

class FavoritesProvider extends ChangeNotifier {
  // Set to store favorite story IDs
  final Set<String> _favoriteIds = {};

  // Map to store story details for favorites
  final Map<String, Map<String, dynamic>> _favoriteStories = {};

  // Getters
  Set<String> get favoriteIds => _favoriteIds;
  Map<String, Map<String, dynamic>> get favoriteStories => _favoriteStories;

  // Get list of all favorite stories as a list
  List<Map<String, dynamic>> get favorites {
    return _favoriteIds
        .map((id) => _favoriteStories[id] ?? {})
        .where((story) => story.isNotEmpty)
        .toList();
  }

  // Check if a story is a favorite
  bool isFavorite(String storyId) {
    return _favoriteIds.contains(storyId);
  }

  // Add a story to favorites
  void addFavorite(String storyId, Map<String, dynamic> storyData) {
    _favoriteIds.add(storyId);
    _favoriteStories[storyId] = storyData;
    notifyListeners();
  }

  // Remove a story from favorites
  void removeFavorite(String storyId) {
    _favoriteIds.remove(storyId);
    _favoriteStories.remove(storyId);
    notifyListeners();
  }

  // Toggle favorite status
  void toggleFavorite(String storyId, Map<String, dynamic> storyData) {
    if (isFavorite(storyId)) {
      removeFavorite(storyId);
    } else {
      addFavorite(storyId, storyData);
    }
  }
}
