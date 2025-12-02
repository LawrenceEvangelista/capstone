import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class RecentlyViewedProvider with ChangeNotifier {
  List<Map<String, dynamic>> _recentlyViewed = [];
  String? _currentUserId;
  bool _isLoaded = false; // Track if data has been loaded from preferences

  List<Map<String, dynamic>> get recentlyViewed => _recentlyViewed;
  bool get isLoaded => _isLoaded; // Expose load status

  // Get recently viewed stories filtered by date (e.g., last 7 days, last 30 days)
  List<Map<String, dynamic>> getRecentlyViewedByDate({int days = 7}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _recentlyViewed.where((story) {
      final viewedAt = DateTime.tryParse(story['viewedAt'] ?? '');
      return viewedAt != null && viewedAt.isAfter(cutoffDate);
    }).toList();
  }

  // Get stories viewed today
  List<Map<String, dynamic>> get getTodayStories {
    final today = DateTime.now();
    return _recentlyViewed.where((story) {
      final viewedAt = DateTime.tryParse(story['viewedAt'] ?? '');
      return viewedAt != null && 
             viewedAt.year == today.year && 
             viewedAt.month == today.month && 
             viewedAt.day == today.day;
    }).toList();
  }

  // Get stories from this week
  List<Map<String, dynamic>> get getThisWeekStories {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    
    return _recentlyViewed.where((story) {
      final viewedAt = DateTime.tryParse(story['viewedAt'] ?? '');
      return viewedAt != null && viewedAt.isAfter(weekStartDate);
    }).toList();
  }
  void setCurrentUserId(String? userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      // When the user changes, clear in-memory list first to avoid showing stale data
      _recentlyViewed = [];
      _isLoaded = false; // Reset load flag
      notifyListeners();
      // If switching to a logged-in user, proactively remove guest data to
      // prevent carrying over guest entries into the new account during races.
      if (_currentUserId != null && _currentUserId != 'guest') {
        SharedPreferences.getInstance().then((prefs) async {
          try {
            await prefs.remove('recently_viewed_guest');
            print('✅ Cleared guest recently viewed data immediately for new user: $_currentUserId');
          } catch (e) {
            print('⚠️ Error clearing guest data on user switch: $e');
          }
        });
      }

      // Then reload from preferences for the new user
      loadRecentlyViewed();
    }
  }

  String _getPrefsKey() {
    // If no user is logged in, use a generic key or 'guest' key.
    // To ensure data is separate, use the user ID.
    // The key format will be: 'recently_viewed_<USER_ID>'
    return 'recently_viewed_${_currentUserId ?? 'guest'}';
  }

  Future<void> loadRecentlyViewed() async {
    final String prefsKey = _getPrefsKey();
    final prefs = await SharedPreferences.getInstance();
    final String? recentlyViewedJson = prefs.getString(prefsKey);

    // Load data FIRST, then assign to prevent race condition
    final List<Map<String, dynamic>> loadedList = [];

    if (recentlyViewedJson != null) {
      try {
        final List<dynamic> decoded = json.decode(recentlyViewedJson);
        loadedList.addAll(decoded.map((item) => Map<String, dynamic>.from(item)));
      } catch (e) {
        print('⚠️ Error decoding recently viewed data: $e');
        // If decode fails, start fresh
      }
    }

    // Always clear old guest data when loading for a new user
    // This prevents carryover from previous sessions
    if (_currentUserId != null && _currentUserId != 'guest') {
      try {
        // Clear the guest key if we're switching to a logged-in user
        await prefs.remove('recently_viewed_guest');
        print('✅ Cleared guest recently viewed data for new user: $_currentUserId');
      } catch (e) {
        print('⚠️ Error clearing guest data: $e');
      }
    }

    _recentlyViewed = loadedList;
    _isLoaded = true; // Mark as loaded
    notifyListeners();
    // Validate and refresh loaded entries in background to avoid displaying
    // stale or deleted stories and to refresh image URLs.
    _validateAndRefreshEntries();
  }

  /// Validate each locally stored recently-viewed entry against the
  /// authoritative Realtime Database and Storage. Removes entries for
  /// deleted stories and updates titles/image URLs when possible.
  Future<void> _validateAndRefreshEntries() async {
    if (_recentlyViewed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final String prefsKey = _getPrefsKey();

    bool changed = false;

    final storage = FirebaseStorage.instance;
    final db = FirebaseDatabase.instance;

    // Iterate backwards so removals don't affect indices
    for (int i = _recentlyViewed.length - 1; i >= 0; i--) {
      final item = _recentlyViewed[i];
      final id = item['id']?.toString();
      if (id == null || id.isEmpty) {
        _recentlyViewed.removeAt(i);
        changed = true;
        continue;
      }

      try {
        final snap = await db.ref('stories/$id').get();
        if (!snap.exists || snap.value == null) {
          // Story was removed from DB — drop it
          _recentlyViewed.removeAt(i);
          changed = true;
          continue;
        }

        final Map<dynamic, dynamic>? data = snap.value as Map<dynamic, dynamic>?;
        if (data != null) {
          // Update titles if available
          final titleEng = data['titleEng'];
          final titleTag = data['titleTag'];
          if (titleEng != null) item['titleEng'] = titleEng;
          if (titleTag != null) item['titleTag'] = titleTag;

          // Update progress if present
          if (data['progress'] != null) {
            try {
              item['progress'] = (data['progress'] is double)
                  ? data['progress']
                  : (double.tryParse(data['progress'].toString()) ?? item['progress'] ?? 0.0);
            } catch (_) {}
          }
        }

        // If imageUrl is empty/missing try to fetch a current one from Storage
        String? currentImage = item['imageUrl']?.toString();
        if (currentImage == null || currentImage.isEmpty) {
          String newUrl = '';
          try {
            newUrl = await storage.ref('images/$id.png').getDownloadURL();
          } catch (_) {
            try {
              newUrl = await storage.ref('images/$id.jpg').getDownloadURL();
            } catch (_) {}
          }

          if (newUrl.isNotEmpty) {
            item['imageUrl'] = newUrl;
            changed = true;
          }
        }
      } catch (e) {
        print('⚠️ Error validating recently viewed entry $id: $e');
        // Skip problematic entries but continue validating others
      }
    }

    if (changed) {
      await prefs.setString(prefsKey, json.encode(_recentlyViewed));
      notifyListeners();
    }
  }

  Future<void> addRecentlyViewed(Map<String, dynamic> story) async {
    // Use provider's user id if available; otherwise fall back to FirebaseAuth
    // currentUser to avoid writing into the 'guest' key after an auth change.
    final effectiveUserId = _currentUserId ?? fb_auth.FirebaseAuth.instance.currentUser?.uid;
    final String prefsKey = 'recently_viewed_${effectiveUserId ?? 'guest'}';

    _recentlyViewed.removeWhere((item) => item['id'] == story['id']);

    _recentlyViewed.insert(0, {
      'id': story['id'],
      'title': story['title'],
      'titleTag': story['titleTag'],
      'titleEng': story['titleEng'],
      'imageUrl': story['imageUrl'],
      'progress': story['progress'] ?? 0.0,
      'viewedAt': DateTime.now().toIso8601String(),
    });

    if (_recentlyViewed.length > 10) {
      _recentlyViewed = _recentlyViewed.sublist(0, 10);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, json.encode(_recentlyViewed));

    notifyListeners();
  }

  Future<void> clearRecentlyViewed() async {
    _recentlyViewed.clear();
    _isLoaded = true; // Mark as cleared (empty state is loaded)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getPrefsKey());
    notifyListeners();
  }

  /// Update fields for an existing recently-viewed entry without changing its position.
  Future<void> updateEntry(String id, Map<String, dynamic> updates) async {
    final int index = _recentlyViewed.indexWhere((item) => item['id'] == id);
    if (index == -1) return;

    final item = _recentlyViewed[index];
    updates.forEach((key, value) {
      item[key] = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getPrefsKey(), json.encode(_recentlyViewed));
    notifyListeners();
  }
}
