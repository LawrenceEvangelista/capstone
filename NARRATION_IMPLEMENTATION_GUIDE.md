# Next Steps: Complete Narration Playback Implementation

## Quick Start Guide

### Phase 1: Add Audio Package (30 minutes)

#### Step 1.1: Install `just_audio` Package

```bash
cd c:\Users\Lance\AndroidStudioProjects\testapp
flutter pub add just_audio
```

This adds the following to `pubspec.yaml`:
```yaml
dependencies:
  just_audio: ^0.9.35
```

#### Step 1.2: Update Platform Files (if needed)

For iOS (if building for iOS):
- No additional configuration needed for just_audio

For Android (already configured via Firebase):
- Just_audio works with existing Android setup

---

### Phase 2: Extend NarrationPlayer Widget (1-2 hours)

#### Step 2.1: Update Imports in `narration_player.dart`

Add after existing imports:
```dart
import 'package:just_audio/just_audio.dart';
```

#### Step 2.2: Update _NarrationPlayerState Class

Replace the class declaration:
```dart
class _NarrationPlayerState extends State<NarrationPlayer> {
  final NarrationService _narrationService = NarrationService();
  late AudioPlayer _audioPlayer;  // ADD THIS
  bool _isAvailable = false;
  bool _isLoading = false;
  bool _isPlaying = false;
  String? _currentNarrationUrl;
  double _currentPosition = 0;
  double _duration = 0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();  // ADD THIS
    _checkNarrationAvailability();
    _setupAudioListeners();  // ADD THIS
  }

  // ADD THIS NEW METHOD
  void _setupAudioListeners() {
    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration?.inMilliseconds.toDouble() ?? 0;
        });
      }
    });

    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position.inMilliseconds.toDouble();
        });
      }
    });

    _audioPlayer.playerStateStream.listen((playerState) {
      if (mounted && playerState.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
          _currentPosition = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();  // ADD THIS
    super.dispose();
  }

  // UPDATE EXISTING METHOD
  Future<void> _checkNarrationAvailability() async {
    setState(() {
      _isLoading = true;
    });

    final isAvailable = await _narrationService.isNarrationAvailable(
      widget.storyId,
      widget.currentPage,
      widget.language,
    );

    if (isAvailable) {
      final url = await _narrationService.fetchNarrationUrl(
        widget.storyId,
        widget.currentPage,
        widget.language,
      );

      if (mounted) {
        setState(() {
          _isAvailable = true;
          _currentNarrationUrl = url;
          _isLoading = false;
        });

        // INITIALIZE AUDIO WITH NEW URL
        if (url != null) {
          try {
            await _audioPlayer.setUrl(url);
          } catch (e) {
            print('Error loading audio: $e');
            if (mounted) {
              setState(() {
                _isAvailable = false;
              });
            }
          }
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isAvailable = false;
          _currentNarrationUrl = null;
          _isLoading = false;
        });
      }
    }
  }

  // UPDATE THIS METHOD
  void _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
      if (mounted) {
        setState(() {
          _isPlaying = !_isPlaying;
        });
      }
    } catch (e) {
      print('Error toggling playback: $e');
    }
  }

  // UPDATE THE SLIDER ONCHANGED HANDLER
  // In the SliderTheme onChanged, add:
  void _seekToPosition(double value) async {
    try {
      await _audioPlayer.seek(Duration(milliseconds: value.toInt()));
    } catch (e) {
      print('Error seeking: $e');
    }
  }
}
```

#### Step 2.3: Update Slider onChanged in build()

In the `build()` method, find the Slider widget and update:

```dart
SliderTheme(
  data: SliderThemeData(
    trackHeight: 4,
    thumbShape: const RoundSliderThumbShape(
      enabledThumbRadius: 6,
    ),
    overlayShape: const RoundSliderOverlayShape(
      overlayRadius: 12,
    ),
  ),
  child: Slider(
    value: _currentPosition,
    max: _duration > 0 ? _duration : 1,
    onChanged: _seekToPosition,  // CHANGE THIS LINE
    activeColor: widget.primaryColor,
    inactiveColor: Colors.grey[300],
  ),
)
```

---

### Phase 3: Test Implementation (30 minutes)

#### Step 3.1: Create Test MP3 Files

Upload test MP3 files to Firebase Storage:

```
gs://kwento-pinoy.appspot.com/
└── narration/
    ├── en/
    │   └── story1/
    │       ├── page1.mp3  ← Upload test file
    │       ├── page2.mp3  ← Upload test file
    │       └── page3.mp3  ← Upload test file
    └── fil/
        └── story1/
            ├── page1.mp3  ← Upload test file
            ├── page2.mp3  ← Upload test file
            └── page3.mp3  ← Upload test file
```

**Recommended test audio:**
- Use free MP3 samples (e.g., from royalty-free sites)
- Or record simple test narrations
- Keep files small for faster upload

#### Step 3.2: Firebase Storage Setup

1. Go to Firebase Console: https://console.firebase.google.com
2. Select "kwento-pinoy" project
3. Navigate to Storage
4. Create the folder structure above
5. Upload your test MP3 files

#### Step 3.3: Test on Device

```bash
# Clean build
flutter clean

# Run app
flutter run

# Test scenarios:
# 1. Open a story with narration files
#    → Narration player should appear
#    → Play button should be clickable
#    → Audio should play when clicked
#
# 2. Switch language
#    → Narration should update (if files exist in both languages)
#    → Audio should stop and reset
#
# 3. Try story without narration
#    → Narration player should NOT appear
#    → Story should display normally
```

---

### Phase 4: Advanced Features (2-4 hours)

#### Feature 4.1: Playback Speed Control

```dart
// Add to _NarrationPlayerState
double _playbackSpeed = 1.0;

Future<void> _setPlaybackSpeed(double speed) async {
  await _audioPlayer.setSpeed(speed);
  setState(() {
    _playbackSpeed = speed;
  });
}

// Add button to player UI:
PopupMenuButton<double>(
  initialValue: _playbackSpeed,
  onSelected: _setPlaybackSpeed,
  itemBuilder: (context) => [
    PopupMenuItem(value: 0.75, child: Text('0.75x')),
    PopupMenuItem(value: 1.0, child: Text('1.0x')),
    PopupMenuItem(value: 1.25, child: Text('1.25x')),
    PopupMenuItem(value: 1.5, child: Text('1.5x')),
  ],
  icon: Icon(Icons.speed),
)
```

#### Feature 4.2: Skip Buttons (10 seconds)

```dart
Future<void> _skipForward() async {
  final currentPos = _audioPlayer.position;
  await _audioPlayer.seek(currentPos + Duration(seconds: 10));
}

Future<void> _skipBackward() async {
  final currentPos = _audioPlayer.position;
  await _audioPlayer.seek(currentPos - Duration(seconds: 10));
}

// Add buttons to player UI next to play button
```

#### Feature 4.3: Offline Caching

```dart
// In NarrationService
import 'package:path_provider/path_provider.dart';

Future<void> downloadForOffline(
  String storyId,
  int pageNumber,
  String language,
) async {
  final url = await fetchNarrationUrl(storyId, pageNumber, language);
  if (url == null) return;

  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/narration/${language}_${storyId}_p${pageNumber}.mp3');
    
    await file.parent.create(recursive: true);
    final response = await http.get(Uri.parse(url));
    await file.writeAsBytes(response.bodyBytes);
  } catch (e) {
    print('Error downloading: $e');
  }
}

// In NarrationPlayer
// Try loading from cache first before network
```

#### Feature 4.4: Story Card Narration Badge

```dart
// In story card widget (explore_screen.dart or similar)
FutureBuilder<bool>(
  future: NarrationService().hasNarrationForStory(
    storyData['id'],
    _currentLanguage,
  ),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.done && 
        snapshot.data == true) {
      return Positioned(
        top: 8,
        right: 8,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.headphones, size: 12, color: Colors.white),
              SizedBox(width: 3),
              Text(
                'Audio',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SizedBox.shrink();
  },
)
```

---

## Implementation Checklist

### Core Implementation
- [ ] Install `just_audio` package
- [ ] Add AudioPlayer to _NarrationPlayerState
- [ ] Implement _setupAudioListeners()
- [ ] Update _togglePlayPause() with actual playback
- [ ] Add seek functionality to slider
- [ ] Implement dispose() for cleanup
- [ ] Test basic play/pause
- [ ] Test language switching
- [ ] Test page navigation

### Testing & Validation
- [ ] Upload test MP3 files to Firebase Storage
- [ ] Test on Android device
- [ ] Test on iOS device (if applicable)
- [ ] Verify audio plays correctly
- [ ] Check file loading errors handled gracefully
- [ ] Test with no narration available
- [ ] Test with poor network connection

### Polish & Features
- [ ] Add playback speed selector
- [ ] Add skip forward/backward buttons
- [ ] Improve error messages
- [ ] Add accessibility labels
- [ ] Test on multiple screen sizes
- [ ] Optimize audio file sizes
- [ ] Add narration badges to story cards

### Documentation
- [ ] Update README with narration feature
- [ ] Document Firebase Storage setup
- [ ] Add narration upload guidelines
- [ ] Create user guide

---

## Common Issues & Solutions

### Issue 1: "just_audio" package not found

**Solution:**
```bash
flutter clean
flutter pub get
flutter pub add just_audio
```

### Issue 2: Audio doesn't play

**Check:**
1. MP3 files exist in Firebase Storage at correct paths
2. Firebase Storage permissions allow reading
3. Network connection is active
4. Audio player initialization doesn't have errors
5. Check console logs for specific errors

### Issue 3: App crashes when disposing

**Solution:**
```dart
@override
void dispose() {
  _audioPlayer.dispose();  // Must dispose before super
  super.dispose();
}
```

### Issue 4: Player shows but no controls work

**Check:**
1. _audioPlayer is properly initialized
2. URL loaded successfully (check logs)
3. _togglePlayPause() and _seekToPosition() methods exist
4. No exceptions in callbacks

### Issue 5: Memory leak warning

**Solution:**
Ensure proper cleanup in dispose() and handle stream subscriptions:
```dart
_audioPlayer.playerStateStream.listen(
  (state) { ... },
).onError((error) {
  print('Stream error: $error');
});
```

---

## Performance Tips

1. **Lazy Load:** Don't load audio until user taps play
2. **Cache URLs:** Store fetched URLs to reduce Firebase calls
3. **Stream Optimization:** Only update UI for relevant state changes
4. **Memory Management:** Dispose AudioPlayer properly
5. **Network:** Use WiFi for testing large files

---

## Estimated Timeline

| Phase | Task | Time | Status |
|-------|------|------|--------|
| 1 | Add just_audio package | 30min | ⏳ Pending |
| 2 | Extend NarrationPlayer | 1-2hr | ⏳ Pending |
| 3 | Test & Upload samples | 30min | ⏳ Pending |
| 4 | Advanced features | 2-4hr | ⏳ Optional |
| | **Total** | **4-8 hrs** | |

---

## Support Resources

- **Just Audio Docs:** https://pub.dev/packages/just_audio
- **Firebase Storage:** https://firebase.google.com/docs/storage
- **Flutter Audio:** https://flutter.dev/docs/cookbook/media/audio-playback
- **App Modernization:** See NARRATION_FEATURE.md

---

## Questions?

Refer to:
1. `NARRATION_FEATURE.md` - Complete feature documentation
2. `NARRATION_TECHNICAL_REFERENCE.md` - Architecture & design details
3. Code comments in narration_player.dart and narration_service.dart
