# Narration Player - Visual & Technical Reference

## Visual Layout in Story Screen

### Full Story Screen Flow

```
┌─────────────────────────────────────────────────────────────┐
│  ◀️ Back Stories                          🌐 [Language Toggle] │ ← AppBar (Yellow)
└─────────────────────────────────────────────────────────────┘

              🎬 The Enchanted Forest 🎬                       ← Story Title

          ❤️  Favorite  •  📚 Quiz                            ← Action Buttons

    ┌───────────────────────────────────────────────┐
    │                                               │
    │     📖  [Story Page Image Here]  📖          │
    │                                               │  
    │     "Once upon a time, in a magical          │
    │      forest filled with ancient trees..."    │ ← Page Flip Widget
    │                                               │
    │     Page 1 / 3                                │
    │                                               │
    └───────────────────────────────────────────────┘

    ┌─────────────────────────────────────────────────┐
    │ 🎧 Narration                    Page 1/3       │  ← NARRATION PLAYER
    │                                                 │     (NEW!)
    │ ▶️  ════════●═════════  02:45 / 05:30  🔊      │
    └─────────────────────────────────────────────────┘

    👈  Swipe to turn page  👉                       ← Instructions

```

## Component Structure

### 1. Header Section
```
┌─────────────────────────────────────────────────┐
│ 🎧 Narration                    Page 1/3       │
└─────────────────────────────────────────────────┘
  ↓                                           ↓
Narration Indicator         Page Number Display
(with icon)                 (Current/Total)
```

### 2. Player Control Section
```
┌──────────────────────────────────────────────────────────────┐
│ ▶️  ════════●═════════  02:45 / 05:30  🔊                  │
└──────────────────────────────────────────────────────────────┘
  ↓      ↓                ↓                  ↓
Play   Progress    Time Display         Volume
Button  Slider                          Indicator
```

## State Management Flow

### NarrationPlayer State Lifecycle

```
┌─────────────────────────────┐
│     initState()             │
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────┐
│ Check Narration Available   │
│ _checkNarrationAvailability │
└────────────┬────────────────┘
             │
             ├─── Available ───┐
             │                 │
             ▼                 ▼
        ┌─────────────┐   ┌──────────────┐
        │ Show Player │   │ Hide Player  │
        │ Fetch URL   │   │ (SizedBox)   │
        │             │   │              │
        └─────────────┘   └──────────────┘
             │
             └─────────────────┬────────────────┐
                               │                │
                    Page Changed  Language Changed
                               │                │
                               ▼                ▼
                    Reset _currentPosition
                    Set _isPlaying = false
                    Call _checkNarrationAvailability()
```

## Data Flow: Language Switching

```
User Taps Language Toggle
        │
        ▼
_toggleLanguage() called
        │
        ├─ _isEnglish = !_isEnglish
        ├─ Update storyTitle
        └─ setState()
        │
        ▼
Consumer<LocalizationProvider> rebuilds
        │
        ▼
NarrationPlayer receives new language prop
        │
        ├─ language changed (didUpdateWidget)
        ├─ Call _checkNarrationAvailability()
        │
        ▼
NarrationService.fetchNarrationUrl()
        │
        ├─ Construct path: narration/{en|fil}/{storyId}/page{N}.mp3
        ├─ Query Firebase Storage
        └─ Return URL or null
        │
        ▼
Display updated narration or hide player
```

## Firebase Storage Query Pattern

### URL Generation Logic

```
Language: en (English)
Story: story1
Page: 1

Path Construction:
┌──────────────────────────────────────────────────────┐
│ narration / {language} / {storyId} / page{N}.mp3    │
│ narration / en        / story1     / page1.mp3      │
└──────────────────────────────────────────────────────┘
        │          │           │           │
        │          │           │           └─ File name (1-indexed)
        │          │           └─ Story identifier
        │          └─ Language folder (en, fil)
        └─ Root directory

Example URLs Generated:
• English, Story 1, Page 1: narration/en/story1/page1.mp3
• Tagalog, Story 1, Page 1: narration/fil/story1/page1.mp3
• English, Story 2, Page 3: narration/en/story2/page3.mp3
```

### Firebase Storage Method Calls

```dart
// Step 1: Get reference
final ref = FirebaseStorage.instance.ref('narration/en/story1/page1.mp3');

// Step 2: Check metadata (file exists)
try {
  await ref.getMetadata();  // Throws if not found
} catch (e) {
  return null;  // File doesn't exist
}

// Step 3: Get download URL
final url = await ref.getDownloadURL();
// Returns: https://firebasestorage.googleapis.com/b/.../...
```

## Widget Tree Integration

### Complete UI Hierarchy

```
Scaffold
├─ SafeArea
│  └─ Column (main story layout)
│     ├─ FadeInDown
│     │  └─ AppBar Container (Custom)
│     │     ├─ Back Button
│     │     ├─ "Back Stories" Text
│     │     └─ Language Toggle Button
│     │
│     ├─ SizedBox (16px)
│     │
│     ├─ FadeInDown
│     │  └─ Story Title (centered, shadow)
│     │
│     ├─ SizedBox (12px)
│     │
│     ├─ FadeInDown
│     │  └─ Action Buttons Row
│     │     ├─ Favorite Button
│     │     └─ Quiz Button
│     │
│     ├─ Expanded
│     │  └─ FadeInUp
│     │     └─ Page Flip Widget
│     │        └─ StoryPage (children)
│     │           ├─ Image
│     │           ├─ Content Text
│     │           └─ Page Number
│     │
│     ├─ Consumer<LocalizationProvider>  ← NEW
│     │  └─ NarrationPlayer  ← NEW
│     │     ├─ Header (Icon + Title + Page)
│     │     └─ Controls (Play + Slider + Volume)
│     │
│     └─ FadeInUp
│        └─ Swipe Instructions
```

## Color Scheme

### Used Colors

```dart
_primaryColor = Color(0xFFFF6D00)      // Orange (#FF6D00)
_accentColor = Color(0xFF8E24AA)       // Purple (#8E24AA)
_backgroundColor = Color(0xFFFFF176)   // Light Yellow (#FFF176)
_buttonColor = Color(0xFFFF9800)       // Orange (#FF9800)

// Narration Player Specific
Player Background:         Colors.white
Player Border:             _primaryColor with 0.3 opacity
Player Shadow:             Colors.grey with 0.2 opacity
Play/Pause Button:         _primaryColor background
Icons:                     _primaryColor (play, volume)
Text (Primary):            _primaryColor
Text (Secondary):          Colors.grey[600]
Progress Bar (Active):     _primaryColor
Progress Bar (Inactive):   Colors.grey[300]
```

## Animation Timings

### NarrationPlayer Animations

```dart
// Initial appearance
FadeIn(
  duration: Duration(milliseconds: 400),  // 400ms fade-in
  child: NarrationPlayer(...)
)

// Result:
Timeline:
0ms ─────────────────────────────── 400ms
│                                   │
Opacity: 0%                    Opacity: 100%
```

## Responsive Design

### Different Screen Sizes

```
Mobile (360px width)
┌────────────────────┐
│ 🎧 Narration  1/3  │
│ ▶️ ══●═ 02:45 🔊   │
└────────────────────┘

Tablet (600px width)
┌──────────────────────────────────────┐
│ 🎧 Narration                   1/3   │
│ ▶️  ════════●════════ 02:45 / 05:30 🔊 │
└──────────────────────────────────────┘

Large Tablet (900px width)
┌──────────────────────────────────────────────────┐
│ 🎧 Narration                          Page 1/3   │
│ ▶️  ════════════●════════════ 02:45 / 05:30  🔊  │
└──────────────────────────────────────────────────┘
```

## Performance Considerations

### Optimization Strategy

```
1. Lazy Loading
   - NarrationPlayer only fetches when mounted
   - Firebase Storage query happens on widget creation
   - Silent failure if narration unavailable (no error UI)

2. Caching (Ready for implementation)
   - Service singleton prevents duplicate queries
   - URL caching possible in service
   - Future: Download caching for offline

3. State Updates
   - Only setState() when necessary
   - didUpdateWidget() for prop changes
   - Disposes resources on widget removal

4. Memory Management
   - AudioPlayer disposal in future implementation
   - Large files handled by Firebase (chunked download)
   - Unused variables tracked and cleaned
```

## Error Handling

### Failure Scenarios

```
Scenario 1: File Not Found
┌──────────────────────────────────┐
│ Firebase Storage                 │
└────────────────┬─────────────────┘
                 │
        File not found exception
                 │
                 ▼
┌──────────────────────────────────┐
│ Catch & Return null             │
└────────────────┬─────────────────┘
                 │
                 ▼
┌──────────────────────────────────┐
│ _isAvailable = false            │
│ Return SizedBox.shrink() (hide)  │
└──────────────────────────────────┘

Scenario 2: Firebase Error (Network, Auth, etc.)
┌──────────────────────────────────┐
│ Firebase Exception thrown         │
└────────────────┬─────────────────┘
                 │
        Caught in try-catch
                 │
                 ▼
┌──────────────────────────────────┐
│ Print error to console           │
│ Return null/false gracefully    │
└────────────────┬─────────────────┘
                 │
                 ▼
┌──────────────────────────────────┐
│ Story display continues          │
│ Narration player hides           │
│ No app crash                     │
└──────────────────────────────────┘

Scenario 3: Empty Story (No Pages)
┌──────────────────────────────────┐
│ storyPages.length = 0            │
│ totalPages = 0                   │
└────────────────┬─────────────────┘
                 │
                 ▼
┌──────────────────────────────────┐
│ NarrationPlayer still attempts   │
│ to fetch page 1 (edge case)      │
│ Returns null → Player hides      │
└──────────────────────────────────┘
```

## Future Enhancement Hooks

### Built-in Extension Points

```dart
// 1. In NarrationService:
// - Add caching with shared_preferences
// - Add download manager for offline mode
// - Support multiple narrators

Future<String?> downloadNarrationForOffline(...)
Future<List<String>> getAvailableNarrators(...)
Future<void> preloadNarration(...)

// 2. In NarrationPlayer:
// - Add playback speed selector
// - Add auto-play option
// - Add narration subtitles/transcripts
// - Add skip forward/backward buttons

Widget _buildPlaybackSpeedSelector()
Widget _buildAutoPlayToggle()
Widget _buildSubtitleToggle()

// 3. In story_screen.dart:
// - Track which pages have been listened
// - Show listening progress in UI
// - Add narration-specific achievements

Future<void> _trackNarrationProgress(...)
```

## Testing Scenarios

### Unit Test Cases

```dart
// NarrationService Tests
test('fetchNarrationUrl returns correct path format')
test('isNarrationAvailable returns true for existing file')
test('isNarrationAvailable returns false for missing file')
test('hasNarrationForStory returns false for empty language folder')
test('getNarrationPages returns sorted list of page numbers')
test('Error handling: graceful failure on Firebase error')

// NarrationPlayer Tests
test('Widget hides when no narration available')
test('Widget shows when narration available')
test('Language change triggers _checkNarrationAvailability')
test('Page change resets play state')
test('Play button toggles _isPlaying state')
test('Slider position updates correctly')
```

### Integration Test Cases

```dart
// Full flow tests
test('User opens story → Narration player shows if available')
test('User switches language → Narration player updates URL')
test('User turns page → Narration player resets and updates')
test('Story with no narration → Player hides, story displays normally')
test('Firebase Storage unavailable → Story displays without player')
test('Language set to English → Fetches narration/en/ files')
test('Language set to Tagalog → Fetches narration/fil/ files')
```

## Conclusion

This narration player system provides a clean, production-ready foundation for audio features. The modular design separates concerns (service for data, widget for UI) and gracefully handles edge cases. Integration with a real audio player package is straightforward due to the clear architecture, and future enhancements can be added without disrupting core functionality.
