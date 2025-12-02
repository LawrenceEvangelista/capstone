class TextSyncService {
  /// Calculates the current highlight progress for text based on audio duration and position
  /// Returns a value between 0.0 and 1.0 representing how much of the text should be highlighted
  static double calculateHighlightProgress(double currentPosition, double totalDuration) {
    if (totalDuration <= 0) return 0.0;
    final progress = currentPosition / totalDuration;
    return progress.clamp(0.0, 1.0);
  }

  /// Splits text into words for word-by-word highlighting
  static List<String> splitIntoWords(String text) {
    // Split by spaces while preserving punctuation
    return text.split(RegExp(r'(\s+)')).where((word) => word.isNotEmpty).toList();
  }

  /// Calculates how many words should be highlighted based on progress
  static int calculateHighlightedWordCount(String text, double progress) {
    final words = splitIntoWords(text);
    final highlightedCount = (words.length * progress).floor();
    return highlightedCount.clamp(0, words.length);
  }

  /// Gets the substring to highlight based on progress
  static String getHighlightedText(String text, double progress) {
    if (progress <= 0) return '';
    if (progress >= 1.0) return text;

    final highlightedCount = calculateHighlightedWordCount(text, progress);

    if (highlightedCount == 0) return '';

    final targetCharIndex = getHighlightCharIndex(text, progress);
    return text.substring(0, targetCharIndex).trimRight();
  }

  /// Get percentage of text that should be highlighted (0-100)
  static int getHighlightPercentage(String text, double progress) {
    return (progress * 100).floor();
  }

  /// Calculate character index to highlight up to
  static int getHighlightCharIndex(String text, double progress) {
    if (progress <= 0) return 0;
    if (progress >= 1.0) return text.length;

    final targetChars = (text.length * progress).floor();
    return targetChars.clamp(0, text.length);
  }
}
