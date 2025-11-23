import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavoritesProvider extends ChangeNotifier {
  // Set to store favorite story IDs
  final Set<String> _favoriteIds = {};

  // Map to store story details for favorites
  final Map<String, Map<String, dynamic>> _favoriteStories = {};

  // Storage key for SharedPreferences
  static const String _storageKey = 'kwentopinoy_favorites';

  FavoritesProvider() {
    _loadFavoritesFromStorage();
  }

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

  // Load favorites from SharedPreferences on app startup
  Future<void> _loadFavoritesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString(_storageKey);

      if (favoritesJson != null) {
        final Map<String, dynamic> decoded = json.decode(favoritesJson);
        
        _favoriteIds.clear();
        _favoriteStories.clear();

        decoded.forEach((id, storyData) {
          _favoriteIds.add(id);
          _favoriteStories[id] = Map<String, dynamic>.from(storyData);
        });

        debugPrint('✅ Loaded ${_favoriteIds.length} favorites from storage');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Error loading favorites from storage: $e');
    }
  }

  // Save favorites to SharedPreferences
  Future<void> _saveFavoritesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> favoritesMap = {};

      for (String id in _favoriteIds) {
        if (_favoriteStories.containsKey(id)) {
          favoritesMap[id] = _favoriteStories[id];
        }
      }

      await prefs.setString(_storageKey, json.encode(favoritesMap));
      debugPrint('💾 Saved ${_favoriteIds.length} favorites to storage');
    } catch (e) {
      debugPrint('⚠️ Error saving favorites to storage: $e');
    }
  }

  // Check if a story is a favorite
  bool isFavorite(String storyId) {
    return _favoriteIds.contains(storyId);
  }

  // Add a story to favorites
  void addFavorite(String storyId, Map<String, dynamic> storyData) {
    if (!_favoriteIds.contains(storyId)) {
      _favoriteIds.add(storyId);
      _favoriteStories[storyId] = storyData;
      _saveFavoritesToStorage(); // Persist to storage
      notifyListeners();
      debugPrint('❤️ Added $storyId to favorites');
    }
  }

  // Remove a story from favorites
  void removeFavorite(String storyId) {
    if (_favoriteIds.remove(storyId)) {
      _favoriteStories.remove(storyId);
      _saveFavoritesToStorage(); // Persist to storage
      notifyListeners();
      debugPrint('💔 Removed $storyId from favorites');
    }
  }

  // Toggle favorite status
  void toggleFavorite(String storyId, Map<String, dynamic> storyData) {
    if (isFavorite(storyId)) {
      removeFavorite(storyId);
    } else {
      addFavorite(storyId, storyData);
    }
  }

  // Clear all favorites
  Future<void> clearAllFavorites() async {
    _favoriteIds.clear();
    _favoriteStories.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
    debugPrint('🗑️ Cleared all favorites');
  }
}
