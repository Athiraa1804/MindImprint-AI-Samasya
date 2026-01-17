# 📈 GAME FLOW DIAGRAMS

## **Complete Assessment Session Flow**

```
START
  ↓
┌─────────────────────────────────────────┐
│         HOME SCREEN                      │
│  Title: "Discover Your Child's           │
│          Cognitive Superpowers"          │
│                                          │
│  Age Group Selection:                    │
│  [ 4-6  ]  [ 7-9  ]  [ 10-12 ]          │
│                                          │
│  [Start Exploration Button]              │
└────────────┬────────────────────────────┘
             │
             ▼
      Age Group = 1 (7-9)
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│    ASSESSMENT FLOW BEGINS                                     │
│    (AssessmentFlow Widget)                                    │
└────┬─────────────────────────────────────────────────────┬───┘
     │                                                     │
     ▼                                                     ▼
GAME 1: WAIT FOR YOUR TURN                          GAME 2: STORY READING
═════════════════════════════════════════════════════════════════════════

┌──────────────────────────────┐                 ┌──────────────────────────────┐
│  ⏳ 2 MINUTES TOTAL           │                 │  📖 5 MINUTES TOTAL          │
│                              │                 │                              │
│  Phase 1: PRACTICE (30 sec)  │                 │  Read story pages at own     │
│  ├─ Countdown = 3 (fixed)   │                 │  pace                        │
│  ├─ No scoring              │                 │                              │
│  └─ Warm up round           │                 │  BUTTONS:                    │
│                              │                 │  [SKIP Page]  [NEXT Page]   │
│  Phase 2: MAIN (90 sec)      │                 │                              │
│  ├─ Countdown: Random 2-15 s │                 │  TIMER: Shows remaining     │
│  ├─ Full scoring active      │                 │  PAGE COUNTER:              │
│  └─ Continuous rounds        │                 │  Page 1 / 3                 │
│                              │                 │                              │
│  SCREEN CHANGES:             │                 │  AUTO-FINISH at 5 minutes   │
│  Before GO: BLUE background  │                 │                              │
│  After GO:  GREEN background │                 │  TEXT SIZE: 22pt, centered  │
└────────────┬─────────────────┘                 └────────────┬────────────────┘
             │                                               │
             │ Countdown: 3...2...1...                       │ Read Page 1
             │                                               │ Time tracked
             ▼                                               │
        [GO!]                                                ▼
        Show "GO!"                                    [NEXT] → Page 2
        Start accepting taps                         Time tracked
             │                                               │
             │ User taps before GO                           │ [NEXT] → Page 3
             │ ├─ prematureTaps++                            │ Time tracked
             │ └─ Message: "Oops—wait a little 😊"           │
             │                                               ▼
             │ User taps after GO                      [SKIP] → Loop back
             │ ├─ reactionTime recorded (ms)           Or: NEXT → Loop
             │ ├─ reactionTimes.add(ms)                Or: Timer expires
             │ └─ Stats update in real-time                  │
             │                                               │
        [Continue rounds]                          [Game ends]
             │                                               │
             │ Loop until 2 min expires                      │
             │                                               │
             ▼                                               ▼
        [Game ends]                             StoryGameResult created:
                                                ├─ pagesRead: 2
    WaitingGameResult created:                  ├─ pagesSkipped: 1
    ├─ prematureTaps: 5                         ├─ pageReadingTimes: [...]
    ├─ reactionTimes: [245,256,...]             ├─ avgReadTime: 2698
    ├─ avgReaction: 280.6                       ├─ skipRate: 0.333
    ├─ reactionVariability: 28.3                ├─ startTime: ...
    ├─ totalTrials: 15                          ├─ endTime: ...
    ├─ startTime: ...                           └─ ageGroup: 1
    ├─ endTime: ...
    └─ ageGroup: 1                              Return to AssessmentFlow
                                                
    Return to AssessmentFlow
             │
             │ [Game 2 started]
             │
             └─────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│    DATA TRANSMISSION                                          │
│                                                               │
│    AssessmentSessionResult created:                          │
│    ├─ waitingResult: { all metrics from Game 1 }            │
│    ├─ storyResult: { all metrics from Game 2 }              │
│    ├─ ageGroup: 1                                            │
│    ├─ sessionStart: timestamp                                │
│    └─ sessionEnd: timestamp                                  │
│                                                               │
│    HTTP POST /save_session                                   │
│    ├─ URL: http://127.0.0.1:5000/save_session              │
│    ├─ Method: POST                                           │
│    ├─ Body: JSON with all metrics (~8 KB)                   │
│    └─ Headers: Content-Type: application/json               │
└────────────┬─────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│    FLASK BACKEND PROCESSING                                  │
│                                                               │
│    1. Parse JSON request                                     │
│    2. Extract game data:                                     │
│       - Wait game metrics                                    │
│       - Story game metrics                                   │
│       - Timestamps and metadata                              │
│                                                               │
│    3. Calculate behavioral scores:                           │
│       - Impulsivity = premature_taps / 0.5 (0-1)            │
│       - Reaction Speed = (avg_reaction - 250) / 300 (0-1)   │
│       - Variability = reaction_variability / 200 (0-1)      │
│                                                               │
│    4. Classify pattern:                                      │
│       IF impulsivity > 0.6 AND variability > 0.6:           │
│         → "High impulsivity, fluctuating attention"          │
│       ELIF reaction_speed > 0.6:                             │
│         → "Slow but controlled responses"                    │
│       ELIF impulsivity < 0.3 AND variability < 0.3:         │
│         → "Strong impulse control, stable attention"         │
│       ELSE:                                                  │
│         → "Moderate attention and impulse control"           │
│                                                               │
│    5. Store in SQLite:                                       │
│       INSERT INTO sessions VALUES (                          │
│         session_id, age_group, timestamps,                   │
│         wait_game_data (JSON),                               │
│         story_game_data (JSON),                              │
│         analysis_scores (JSON)                               │
│       )                                                       │
│                                                               │
│    6. Return response:                                       │
│       {                                                      │
│         "status": "success",                                 │
│         "analysis": {                                        │
│           "impulsivity": 0.35,                               │
│           "reaction_speed": 0.28,                            │
│           "pattern": "Moderate..."                           │
│         }                                                    │
│       }                                                      │
└────────────┬─────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│    FINAL REPORT SCREEN                                       │
│                                                               │
│    ╔══════════════════════════════════════════════════════╗  │
│    ║  🧠 Assessment Complete!                            ║  │
│    ╠══════════════════════════════════════════════════════╣  │
│    ║                                                      ║  │
│    ║  ⏳ Impulse Control (Wait For Your Turn)             ║  │
│    ║    Total Correct Taps:    12                        ║  │
│    ║    Premature Taps:        3                         ║  │
│    ║    Avg Reaction Time:     285 ms                    ║  │
│    ║    Reaction Variability:  42 ms                     ║  │
│    ║    Total Trials:          15                        ║  │
│    ║                                                      ║  │
│    ║  📖 Reading Attention (Story Reading)               ║  │
│    ║    Pages Read:            2                         ║  │
│    ║    Pages Skipped:         1                         ║  │
│    ║    Avg Read Time:         2684 ms                   ║  │
│    ║    Skip Rate:             33.3%                     ║  │
│    ║                                                      ║  │
│    ║  ✅ All data has been saved to the backend!         ║  │
│    ║                                                      ║  │
│    ║                           [Done]                    ║  │
│    ╚══════════════════════════════════════════════════════╝  │
│                                                               │
└────────────┬─────────────────────────────────────────────────┘
             │
             ▼
        [Done Button]
             │
             ▼
        Return to Home Screen
             │
             ▼
          END
```

---

## **Wait For Your Turn Game - Detailed Flow**

```
GAME START (gameStartTime = now)
│
├─────────────────────────────────────────────────────────────
│ PRACTICE ROUND (0-30 seconds)
├─────────────────────────────────────────────────────────────
│
│  Timer: 0 sec
│  Display: "🏫 Practice Round"
│           "3"           ← Fixed countdown
│           "Wait…"
│
│  Elapse 1 second: Timer = 1 sec
│  Display: "2"
│
│  Elapse 1 second: Timer = 2 sec
│  Display: "1"
│
│  Elapse 1 second: Timer = 3 sec
│  Display: "GO!"           ← Switch to green
│  goTime = now()
│
│  User taps screen (at 200 ms):
│    Since goSignal = TRUE and tap is after GO
│    reactionTime = 200 - 0 = 200 ms
│    reactionTimes.add(200)
│    Display: stats update
│
│  Wait 500 ms, then start next round
│
│  Elapse: 30 seconds total
│
├─────────────────────────────────────────────────────────────
│ MAIN GAME ROUND 1 (30-35 seconds example)
├─────────────────────────────────────────────────────────────
│
│  Timer: 30 sec
│  isPracticeRound = FALSE
│  Display: "🎮 Main Game"
│
│  Random countdown selected: 7 seconds
│  Display: "7"           ← Random for each round!
│           "Wait…"
│
│  Elapse 1 sec: Timer = 31 sec, countdown = 6
│  Elapse 1 sec: Timer = 32 sec, countdown = 5
│  Elapse 1 sec: Timer = 33 sec, countdown = 4
│  Elapse 1 sec: Timer = 34 sec, countdown = 3
│
│  User taps screen (at 33 sec):
│    Since goSignal = FALSE (countdown still running)
│    prematureTaps++           ← Counted as error
│    canTap = FALSE
│    Show message: "⏳ Oops — wait a little 😊"
│    Prevent further taps this round
│
│  Elapse 1 sec: Timer = 35 sec, countdown = 2
│  Elapse 1 sec: Timer = 36 sec, countdown = 1
│  Elapse 1 sec: Timer = 37 sec, countdown = 0
│  Display: "GO!"          ← Now green, accepting taps
│  goTime = now()
│  canTap = TRUE
│  totalTrials++
│
│  No user tap → MISSED (don't penalize, just wait)
│
│  Wait 500 ms, then start next round
│
│  [Repeat for remaining rounds until 120 sec]
│
│  ...
│
├─────────────────────────────────────────────────────────────
│ GAME END (120 seconds)
├─────────────────────────────────────────────────────────────
│
│  Timer reaches 120 seconds
│  finishGame() is called
│  gameTimer.cancel()
│
│  Calculate metrics:
│    avgReaction = sum(reactionTimes) / count
│    variability = sqrt(sum((rt - avg)²) / count)
│
│  Create WaitingGameResult with:
│    - prematureTaps: 5
│    - reactionTimes: [245, 256, 312, 289, 301, ...]
│    - avgReaction: 280.6
│    - reactionVariability: 28.3
│    - totalTrials: 15
│    - startTime: game start timestamp
│    - endTime: game end timestamp
│    - ageGroup: 1
│
│  Navigator.pop(context, result)
│  ↓ Returns to AssessmentFlow
```

---

## **Story Reading Game - Detailed Flow**

```
GAME START (gameStartTime = now)
│
│  Current Page: 0
│  Timer: 0 sec (out of 300)
│  Display: Page 1 text
│           [SKIP Page]  [NEXT Page]
│           "⏱️ 5:00" (timer showing 5 minutes)
│           "Page 1 / 3"
│
│  User reads page 1 for some time...
│
├─────────────────────────────────────────────────────────────
│ USER PRESSES "SKIP"
├─────────────────────────────────────────────────────────────
│
│  timeSpent = DateTime.now() - pageStartTime = 3240 ms
│  pageReadingTimes.add(3240)
│  skipCount++                      ← Count as skip
│
│  currentPage = 1
│  pageStartTime = DateTime.now()   ← Reset timer for next page
│
│  Display: Page 2 text
│           "⏱️ 4:55" (timer updated)
│           "Page 2 / 3"
│
├─────────────────────────────────────────────────────────────
│ USER PRESSES "NEXT"
├─────────────────────────────────────────────────────────────
│
│  timeSpent = DateTime.now() - pageStartTime = 2156 ms
│  pageReadingTimes.add(2156)
│  nextCount++                      ← Count as read
│
│  currentPage = 2
│  pageStartTime = DateTime.now()
│
│  Display: Page 3 text
│           "⏱️ 4:30"
│           "Page 3 / 3"
│
├─────────────────────────────────────────────────────────────
│ TIMER RUNS OUT (300 seconds elapsed)
├─────────────────────────────────────────────────────────────
│
│  elapsedSeconds = 300
│  finishStory() is called
│
│  Calculate metrics:
│    avgReadTime = sum(pageReadingTimes) / count
│    skipRate = skipCount / totalPages
│
│  Example:
│    pageReadingTimes: [3240, 2156, 4521]
│    skipCount: 1
│    nextCount: 2
│    avgReadTime = (3240 + 2156 + 4521) / 3 = 3305.67 ms
│    skipRate = 1 / 3 = 0.333
│
│  Create StoryGameResult with:
│    - pagesRead: 2
│    - pagesSkipped: 1
│    - pageReadingTimes: [3240, 2156, 4521]
│    - avgReadTime: 3305.67
│    - skipRate: 0.333
│    - startTime: game start timestamp
│    - endTime: game end timestamp
│    - ageGroup: 1
│
│  Navigator.pop(context, result)
│  ↓ Returns to AssessmentFlow
```

---

## **Data Structure - JSON**

```json
{
  "session_id": "1705484520123",
  "age_group": 1,
  "session_start": "2025-01-17T10:08:40.123Z",
  "session_end": "2025-01-17T10:15:40.456Z",
  "total_duration_seconds": 420,
  
  "wait_for_your_turn": {
    "game_id": "wait_for_your_turn",
    "age_group": 1,
    "premature_taps": 5,
    "reaction_times": [
      245, 256, 312, 289, 301, 267, 298,
      301, 289, 256, 289, 278, 291, 305, 267
    ],
    "avg_reaction": 280.6,
    "reaction_variability": 28.3,
    "total_trials": 15,
    "start_time": "2025-01-17T10:08:40.123Z",
    "end_time": "2025-01-17T10:10:40.456Z",
    "duration_seconds": 120
  },
  
  "story_reading": {
    "game_id": "story_reading",
    "age_group": 1,
    "pages_read": 2,
    "pages_skipped": 1,
    "page_reading_times": [3240, 2156, 4521],
    "avg_read_time": 3305.67,
    "skip_rate": 0.333,
    "start_time": "2025-01-17T10:10:40.456Z",
    "end_time": "2025-01-17T10:15:40.123Z",
    "duration_seconds": 300
  }
}
```

---

**Diagram Version:** 1.0
**Last Updated:** January 17, 2026
