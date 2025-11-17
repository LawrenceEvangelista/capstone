import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RecentlyViewedProvider with ChangeNotifier {
  List<Map<String, dynamic>> _recentlyViewed = [];
  String? _currentUserId;

  List<Map<String, dynamic>> get recentlyViewed => _recentlyViewed;

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
      // When the user changes, reload the list for the new user (or clear if logged out)
      loadRecentlyViewed();
    }
  }

  String _getPrefsKey() {
    // If no user is logged in, use a generic key or 'guest' key.
    // To ensure data is separate, use the user ID.
    // The key format will be: 'recently_viewed_<USER_ID>'
    return 'recently_viewed_${_currentUserId ?? 'guest'}';
  }

  Future<void>loadRecentlyViewed() async {
    final String prefsKey = _getPrefsKey();
    final prefs = await SharedPreferences.getInstance();
    final String? recentlyViewedJson = prefs.getString(prefsKey);

    _recentlyViewed = [];

    if (recentlyViewedJson != null) {
      final List<dynamic> decoded = json.decode(recentlyViewedJson);
      _recentlyViewed = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      notifyListeners();
    }
  }

  Future<void> addRecentlyViewed(Map<String, dynamic> story) async {
    final String prefsKey = _getPrefsKey();

    _recentlyViewed.removeWhere((item) => item['id'] == story['id']);

    _recentlyViewed.insert(0, {
      'id': story['id'],
      'title': story['title'],
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getPrefsKey());
    notifyListeners();
  }
}
