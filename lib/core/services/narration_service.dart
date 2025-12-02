import 'package:firebase_storage/firebase_storage.dart';

class NarrationService {
  static final NarrationService _instance = NarrationService._internal();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  NarrationService._internal();

  factory NarrationService() {
    return _instance;
  }

  /// Fetch the download URL for a narration MP3 file
  /// Falls back to other language if specified language not found
  /// 
  /// Parameters:
  /// - storyId: The story identifier
  /// - pageNumber: The page number (1-indexed)
  /// - language: 'en' for English or 'fil' for Tagalog
  /// 
  /// Returns: The download URL of the MP3 file, or null if not found
  Future<String?> fetchNarrationUrl(
    String storyId,
    int pageNumber,
    String language,
  ) async {
    try {
      // Try the requested language first
      final languageFolder = language == 'fil' ? 'Tagalog' : 'English';
      final path = 'narration/$languageFolder/$storyId/page$pageNumber.mp3';
      final ref = _storage.ref(path);

      // Check if file exists
      try {
        await ref.getMetadata();
      } catch (e) {
        // Try fallback language if requested language not available
        print('🔄 Narration not found in requested language, trying fallback...');
        final fallbackLanguageFolder = language == 'fil' ? 'English' : 'Tagalog';
        final fallbackPath = 'narration/$fallbackLanguageFolder/$storyId/page$pageNumber.mp3';
        final fallbackRef = _storage.ref(fallbackPath);
        try {
          await fallbackRef.getMetadata();
          return await fallbackRef.getDownloadURL();
        } catch (e2) {
          // File doesn't exist in either language
          return null;
        }
      }

      // Get download URL
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Error fetching narration URL: $e');
      return null;
    }
  }

  /// Check if narration is available for a specific story page
  /// Falls back to checking other language if specified language not found
  Future<bool> isNarrationAvailable(
    String storyId,
    int pageNumber,
    String language,
  ) async {
    try {
      // Map language codes to Firebase folder names
      final languageFolder = language == 'fil' ? 'Tagalog' : 'English';
      final path = 'narration/$languageFolder/$storyId/page$pageNumber.mp3';
      print('🔍 NarrationService: Checking path = $path');
      final ref = _storage.ref(path);
      await ref.getMetadata();
      print('✅ NarrationService: File exists at $path');
      return true;
    } catch (e) {
      // If requested language not found, try the other language
      try {
        final fallbackLanguageFolder = language == 'fil' ? 'English' : 'Tagalog';
        final fallbackPath = 'narration/$fallbackLanguageFolder/$storyId/page$pageNumber.mp3';
        print('🔄 NarrationService: Requested language not found, trying fallback at $fallbackPath');
        final ref = _storage.ref(fallbackPath);
        await ref.getMetadata();
        print('✅ NarrationService: Fallback file exists at $fallbackPath');
        return true;
      } catch (e2) {
        print('❌ NarrationService: File not found in either language - Error: $e2');
        return false;
      }
    }
  }

  /// Check if any narration exists for a story in a given language
  Future<bool> hasNarrationForStory(String storyId, String language) async {
    try {
      // Map language codes to Firebase folder names
      final languageFolder = language == 'fil' ? 'Tagalog' : 'English';
      final path = 'narration/$languageFolder/$storyId/';
      final ref = _storage.ref(path);
      
      // List files in the directory
      final result = await ref.listAll();
      return result.items.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get all page numbers that have narration for a story
  Future<List<int>> getNarrationPages(String storyId, String language) async {
    try {
      // Map language codes to Firebase folder names
      final languageFolder = language == 'fil' ? 'Tagalog' : 'English';
      final path = 'narration/$languageFolder/$storyId/';
      final ref = _storage.ref(path);
      
      final result = await ref.listAll();
      final pageNumbers = <int>[];
      
      for (var item in result.items) {
        final fileName = item.name;
        if (fileName.startsWith('page') && fileName.endsWith('.mp3')) {
          final pageNum = int.tryParse(
            fileName.replaceAll('page', '').replaceAll('.mp3', ''),
          );
          if (pageNum != null) {
            pageNumbers.add(pageNum);
          }
        }
      }
      
      return pageNumbers..sort();
    } catch (e) {
      print('Error getting narration pages: $e');
      return [];
    }
  }
}
