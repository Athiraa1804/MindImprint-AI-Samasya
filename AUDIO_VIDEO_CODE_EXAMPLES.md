# Audio & Video - Code Examples

This document provides code snippets for common customizations.

## Example 1: Random Audio Selection

Play a different audio file randomly each time:

```dart
Future<void> _playCompletionAudio() async {
  try {
    final audioFiles = [
      'sounds/chime1.mp3',
      'sounds/chime2.mp3',
      'sounds/fanfare.mp3',
    ];
    
    final random = Random().nextInt(audioFiles.length);
    final selectedFile = audioFiles[random];
    
    await audioPlayer.play(AssetSource(selectedFile));
    setState(() => isAudioPlaying = true);
    
    audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => isAudioPlaying = false);
      }
    });
  } catch (e) {
    debugPrint("Error playing audio: $e");
  }
}

// Don't forget to import Random at top:
import 'dart:math';
```

## Example 2: Different Videos Based on Score

Play different celebration videos based on user performance:

```dart
@override
void initState() {
  super.initState();
  audioPlayer = AudioPlayer();
  
  // Select video based on overall score
  final overallScore = cognitiveProfile['overall_score'] ?? 0;
  String videoId;
  
  if (overallScore >= 0.9) {
    videoId = "dQw4w9WgXcQ"; // Excellent performance
  } else if (overallScore >= 0.7) {
    videoId = "w-w5w8KcSyI"; // Good performance
  } else {
    videoId = "jNQXAC9IVRw"; // Keep trying video
  }
  
  youtubeController = YoutubePlayerController(
    initialVideoId: videoId,
    flags: const YoutubePlayerFlags(
      autoPlay: false,
      mute: false,
      disableDragSeek: false,
      loop: false,
      isLive: false,
      forceHD: false,
      enableCaption: true,
    ),
  );

  _playCompletionAudio();
}
```

## Example 3: Stream Audio from URL

Use online audio instead of local asset:

```dart
Future<void> _playCompletionAudio() async {
  try {
    // Use URL source instead of AssetSource
    await audioPlayer.play(
      UrlSource("https://your-domain.com/sounds/celebration.mp3"),
    );
    setState(() => isAudioPlaying = true);

    audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => isAudioPlaying = false);
      }
    });
  } catch (e) {
    debugPrint("Error playing audio: $e");
  }
}
```

## Example 4: Auto-play Video

Start playing YouTube video automatically:

```dart
youtubeController = YoutubePlayerController(
  initialVideoId: "w-w5w8KcSyI",
  flags: const YoutubePlayerFlags(
    autoPlay: true,  // Changed from false to true
    mute: false,
    disableDragSeek: false,
    loop: false,
    isLive: false,
    forceHD: false,
    enableCaption: true,
  ),
);
```

## Example 5: Loop Audio

Play audio in a loop:

```dart
Future<void> _playCompletionAudio() async {
  try {
    await audioPlayer.play(
      AssetSource("sounds/completion_chime.mp3"),
    );
    
    // Loop every 10 seconds
    audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        _playCompletionAudio(); // Play again
      }
    });
    
    setState(() => isAudioPlaying = true);
  } catch (e) {
    debugPrint("Error playing audio: $e");
  }
}
```

## Example 6: Stop Audio Manually

Add a stop button for audio:

```dart
Widget _buildAudioSection() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.amber.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.amber, width: 2),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '🎵 Completion Sound',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isAudioPlaying ? Colors.green : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isAudioPlaying ? '🔊 Playing' : '⏸ Idle',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isAudioPlaying ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _playCompletionAudio,
                icon: const Icon(Icons.replay_circle_filled),
                label: const Text('Replay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await audioPlayer.stop();
                  setState(() => isAudioPlaying = false);
                },
                icon: const Icon(Icons.stop_circle),
                label: const Text('Stop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade300,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
```

## Example 7: Custom YouTube Player Styling

Customize YouTube player appearance:

```dart
Container(
  color: Colors.black,
  child: YoutubePlayer(
    controller: youtubeController,
    showVideoProgressIndicator: true,
    progressIndicatorColor: Colors.red.shade600,
    progressColors: ProgressColors(
      playedColor: Colors.red,
      handleColor: Colors.redAccent,
    ),
    onReady: () {
      debugPrint("YouTube player is ready");
      // Optional: auto-play
      // youtubeController.play();
    },
    onEnded: (metaData) {
      debugPrint("Video ended");
      // Optional: show message
      _showVideoEndedDialog();
    },
  ),
),
```

## Example 8: Add Confetti Animation

Add celebratory confetti (requires confetti package):

First, add to pubspec.yaml:
```yaml
confetti: ^0.7.0
```

Then use it:

```dart
import 'package:confetti/confetti.dart';

class _CompletionScreenState extends State<CompletionScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiController.play();
    // ... rest of init
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti overlay
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          particleDrag: 0.05,
          emissionFrequency: 0.05,
          numberOfParticles: 50,
          gravity: 0.1,
          shouldLoop: false,
          colors: const [
            Colors.purple,
            Colors.blue,
            Colors.pink,
            Colors.green,
          ],
        ),
        // Rest of completion screen
        SingleChildScrollView(
          // ... existing content
        ),
      ],
    );
  }
}
```

## Example 9: Add Sound Toggle Preference

Let users disable audio:

```dart
class CompletionScreen extends StatefulWidget {
  final Map<String, dynamic> cognitiveProfile;
  final bool enableSound;

  const CompletionScreen({
    super.key,
    required this.cognitiveProfile,
    this.enableSound = true,
  });

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen> {
  bool soundEnabled = true;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    youtubeController = YoutubePlayerController(
      initialVideoId: "w-w5w8KcSyI",
      flags: const YoutubePlayerFlags(autoPlay: false),
    );

    if (widget.enableSound && soundEnabled) {
      _playCompletionAudio();
    }
  }

  Widget _buildAudioSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🎵 Completion Sound'),
              Switch(
                value: soundEnabled,
                onChanged: (value) {
                  setState(() {
                    soundEnabled = value;
                    if (value) {
                      _playCompletionAudio();
                    } else {
                      audioPlayer.stop();
                    }
                  });
                },
              ),
            ],
          ),
          if (soundEnabled)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _playCompletionAudio,
                  icon: const Icon(Icons.replay),
                  label: const Text('Replay'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

## Example 10: Add Video Closed Caption Control

More YouTube player customization:

```dart
YoutubePlayerController(
  initialVideoId: "w-w5w8KcSyI",
  flags: const YoutubePlayerFlags(
    autoPlay: false,
    mute: false,
    disableDragSeek: false,
    loop: false,
    isLive: false,
    forceHD: false,
    enableCaption: true,
    startAt: Duration(seconds: 0),
    desktopLanguage: AvailableLanguageCodes.en,
    interfaceLanguage: AvailableLanguageCodes.en,
  ),
)
```

## Example 11: Performance Monitoring

Log audio/video performance:

```dart
Future<void> _playCompletionAudio() async {
  final startTime = DateTime.now();
  
  try {
    await audioPlayer.play(
      AssetSource("sounds/completion_chime.mp3"),
    );
    
    final loadTime = DateTime.now().difference(startTime);
    debugPrint("🎵 Audio loaded in ${loadTime.inMilliseconds}ms");
    
    setState(() => isAudioPlaying = true);
    
    audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => isAudioPlaying = false);
      }
    });
  } catch (e) {
    debugPrint("❌ Audio error: $e");
  }
}

void _monitorVideoPerformance() {
  youtubeController.addListener(() {
    debugPrint("🎬 Video state: ${youtubeController.value.playerState}");
    debugPrint("🎬 Video duration: ${youtubeController.metadata.duration}");
    debugPrint("🎬 Current position: ${youtubeController.value.position}");
  });
}
```

## Example 12: Error Handling & Retry

Robust audio/video error handling:

```dart
Future<void> _playCompletionAudio({int retryCount = 0}) async {
  try {
    if (retryCount > 3) {
      debugPrint("❌ Audio failed after 3 retries");
      _showErrorSnackbar("Audio playback failed");
      return;
    }

    await audioPlayer.play(
      AssetSource("sounds/completion_chime.mp3"),
    );
    setState(() => isAudioPlaying = true);

    audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => isAudioPlaying = false);
      }
    });
  } catch (e) {
    debugPrint("⚠️ Audio error (attempt ${retryCount + 1}): $e");
    
    // Retry after delay
    Future.delayed(const Duration(seconds: 1), () {
      _playCompletionAudio(retryCount: retryCount + 1);
    });
  }
}

void _showErrorSnackbar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
    ),
  );
}
```

---

These examples show common customizations. Mix and match based on your needs!
