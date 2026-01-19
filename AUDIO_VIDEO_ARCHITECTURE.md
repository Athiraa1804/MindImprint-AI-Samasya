# Audio & Video Integration - Architecture

## System Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    GAME COMPLETION FLOW                         │
└─────────────────────────────────────────────────────────────────┘

User Completes Assessment (3 Games)
            │
            ▼
    ┌──────────────────┐
    │  Game 3 Finishes │
    │  (Step Builder)  │
    └────────┬─────────┘
             │
             ▼
    ┌──────────────────────────────┐
    │  sendSessionDataToBackend()  │
    │  - Sends all game data       │
    │  - Backend processes via AI  │
    │  - Returns cognitive profile │
    └────────┬─────────────────────┘
             │
             ▼
    ┌──────────────────────────────┐
    │  showFinalReport()           │
    │  (Updated in assessment.dart)│
    └────────┬─────────────────────┘
             │
             ▼
    ┌──────────────────────────────────────────────┐
    │         CompletionScreen() DISPLAYED          │
    ├──────────────────────────────────────────────┤
    │ 1. Celebration Header (🎉)                  │
    │ 2. Audio Section                            │
    │    - Plays automatically                    │
    │    - Replay button available               │
    │ 3. YouTube Video Section                    │
    │    - Embedded player                        │
    │    - Full controls                         │
    │ 4. Cognitive Profile Summary                │
    │    - Score, level, recommendations          │
    │ 5. Back to Home Button                      │
    └────────┬───────────────────────────────────┘
             │
             ▼
    User Clicks "Back to Home"
             │
             ▼
    Navigation to HomeScreen
```

## Component Architecture

```
┌─────────────────────────────────────────────────┐
│            Assessment Flow (State Manager)       │
├─────────────────────────────────────────────────┤
│ - Manages 3 game sequencing                      │
│ - Collects game results                         │
│ - Sends data to backend                         │
│ - Manages cognitive profile state               │
│ - Triggers completion screen navigation         │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────────┐
        │   CompletionScreen         │
        │  (New StatefulWidget)      │
        ├────────────────────────────┤
        │ State Management:          │
        │ - AudioPlayer instance     │
        │ - YoutubePlayerController  │
        │ - isAudioPlaying flag      │
        │                            │
        │ Methods:                   │
        │ - initState()              │
        │ - _playCompletionAudio()   │
        │ - _playYoutubeVideo()      │
        │ - dispose()                │
        │ - build()                  │
        │ - _buildXxxSection()       │
        └────────────────────────────┘
```

## Audio & Video Integration Points

```
┌──────────────────────────────────────────────────────────────┐
│                    CompletionScreen                          │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────┐         ┌─────────────────┐             │
│  │  Audio System   │         │ Video System    │             │
│  ├─────────────────┤         ├─────────────────┤             │
│  │ audioplayers    │         │ youtube_player  │             │
│  │ package v6.1.0  │         │ package v8.1.2  │             │
│  │                 │         │                 │             │
│  │ Features:       │         │ Features:       │             │
│  │ - Play local    │         │ - Embedded      │             │
│  │   asset audio   │         │   player        │             │
│  │ - Replay        │         │ - Full controls │             │
│  │ - Status        │         │ - Fullscreen    │             │
│  │   indicator     │         │ - Captions      │             │
│  │ - Error handle  │         │ - Progress bar  │             │
│  └────────┬────────┘         └────────┬────────┘             │
│           │                          │                       │
│           ▼                          ▼                       │
│  ┌──────────────────────────────────────────────┐             │
│  │       UI Widgets (_buildXxxSection)         │             │
│  │                                              │             │
│  │  _buildAudioSection()                        │             │
│  │  - Container with amber background          │             │
│  │  - Status label                             │             │
│  │  - Replay button                            │             │
│  │                                              │             │
│  │  _buildYoutubeSection()                      │             │
│  │  - Grey container                           │             │
│  │  - Video player widget                      │             │
│  │  - Play button                              │             │
│  └──────────────────────────────────────────────┘             │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

## Data Flow

```
User Completes Game
    │
    ▼
Assessment.dart
├─ onStepGameFinished(result)
│  └─ setState() → currentGameIndex = 3
│     └─ sendSessionDataToBackend()
│        └─ HTTP POST to Flask backend
│           └─ Backend processes
│              └─ Returns cognitive_profile
│
└─ showFinalReport()
   └─ Navigator.push(CompletionScreen)
      │
      ├─ CompletionScreen.initState()
      │  ├─ AudioPlayer initialized
      │  ├─ YoutubePlayerController initialized
      │  └─ _playCompletionAudio() called
      │
      └─ CompletionScreen.build()
         ├─ Display celebration UI
         ├─ Show audio section
         ├─ Show video section
         ├─ Display cognitive profile
         │  (passed via constructor)
         └─ Show navigation button
            └─ On click: Navigator.pop() twice
               └─ Back to HomeScreen
```

## Dependencies Tree

```
pubspec.yaml
├─ flutter: sdk
│
├─ cupertino_icons: ^1.0.8
│
├─ http: ^1.2.0
│  └─ Backend communication
│
├─ audioplayers: ^6.1.0 ◄── NEW
│  └─ Audio playback
│     ├─ Supports MP3, WAV, etc.
│     └─ Handles local & remote files
│
└─ youtube_player_flutter: ^8.1.2 ◄── NEW
   └─ YouTube video embedding
      ├─ WebView backend
      └─ Full player controls
```

## File Organization

```
game_3/
├── lib/
│   ├── main.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── assessment.dart ◄── MODIFIED
│   │   ├── completion_screen.dart ◄── NEW
│   │   └── ...
│   ├── games/
│   │   ├── wait_for_your_turn.dart
│   │   ├── game_4/
│   │   │   └── story_reading.dart
│   │   └── step_builder.dart
│   ├── models/
│   │   └── assessment_models.dart
│   └── utils/
│       └── image_generator.dart
│
├── assets/
│   ├── images/
│   │   ├── step_sequencing.png
│   │   ├── story_reading.png
│   │   └── reaction_time.png
│   └── sounds/ ◄── NEW FOLDER
│       ├── README.md ◄── NEW
│       └── completion_chime.mp3 ◄── USER ADDS
│
├── pubspec.yaml ◄── MODIFIED
├── AUDIO_VIDEO_SETUP.md ◄── NEW
├── AUDIO_VIDEO_IMPLEMENTATION.md ◄── NEW
└── QUICK_AUDIO_VIDEO_GUIDE.md ◄── NEW
```

## State Management Diagram

```
CompletionScreen (StatefulWidget)
    │
    ├─ audioPlayer: AudioPlayer
    │  ├─ play()
    │  ├─ dispose()
    │  └─ onPlayerComplete listener
    │
    ├─ youtubeController: YoutubePlayerController
    │  ├─ play()
    │  ├─ dispose()
    │  └─ flags (autoPlay, mute, etc.)
    │
    └─ isAudioPlaying: bool
       ├─ Initial: false
       ├─ Set to true when playing
       └─ UI updates based on this
```

## Lifecycle Diagram

```
CompletionScreen Created
    │
    ▼
initState()
├─ Create AudioPlayer instance
├─ Create YoutubePlayerController instance
│  └─ Set initialVideoId
│  └─ Configure flags
└─ Call _playCompletionAudio()
   └─ Load asset audio file
      └─ Start playback
         └─ Set isAudioPlaying = true

User Interacts
├─ Can click "Replay Sound"
│  └─ _playCompletionAudio() called again
├─ Can click "Play Celebration Video"
│  └─ youtubeController.play() called
└─ Audio completes
   └─ onPlayerComplete listener fires
      └─ Set isAudioPlaying = false

User Navigates Away
    │
    ▼
dispose()
├─ audioPlayer.dispose()
│  └─ Release audio resources
└─ youtubeController.dispose()
   └─ Release video resources

CompletionScreen Destroyed
    │
    ▼
Back to HomeScreen
```

## Integration Points with Existing Code

```
HomeScreen
    │
    └─ User selects game
       │
       ├─ Navigator.push(AssessmentFlow)
       │
       └─ AssessmentFlow (Stateful)
          ├─ Manages 3 games sequentially
          ├─ Collects results
          └─ On final game complete:
             │
             ├─ sendSessionDataToBackend()
             │  └─ HTTP POST
             │
             └─ showFinalReport() ◄── MODIFIED
                └─ Navigator.push(CompletionScreen) ◄── NEW
                   │
                   └─ CompletionScreen ◄── NEW
                      ├─ Shows celebration
                      ├─ Audio plays
                      ├─ Video available
                      └─ On "Back to Home":
                         └─ Navigator.pop() twice
                            └─ Back to HomeScreen
```

---

This architecture ensures:
- ✅ Smooth integration with existing flow
- ✅ Proper resource management
- ✅ Scalable customization
- ✅ Error handling
- ✅ No breaking changes to existing code
