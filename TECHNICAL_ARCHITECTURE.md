# 🏗️ TECHNICAL ARCHITECTURE DOCUMENT

## **System Overview**

```
┌─────────────────────────────────────────────────────────────────────┐
│                    FLUTTER MOBILE APP (Frontend)                     │
│  ┌─────────────────┐          ┌──────────────────┐                  │
│  │  Home Screen    │ ────────→│ Assessment Flow  │                  │
│  │  - Age Select   │          │  - Game Manager  │                  │
│  │  - Start Game   │          │  - Data Collect  │                  │
│  └─────────────────┘          │  - HTTP Client   │                  │
│                                └────────┬─────────┘                  │
│                                         │                             │
│                    ┌────────────────────┼────────────────────┐        │
│                    │                    │                    │        │
│            ┌───────▼──────┐    ┌────────▼────────┐  ┌──────▼─────┐ │
│            │   Wait Game  │    │  Story Game     │  │   Models  │ │
│            │  (2 minutes) │    │  (5 minutes)    │  │  - Result │ │
│            │              │    │                 │  │  - Data   │ │
│            └──────────────┘    └─────────────────┘  └───────────┘ │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
                                   │
                  HTTP POST (JSON)  │
                  /save_session     │
                                   ▼
┌──────────────────────────────────────────────────────────────────────┐
│                  FLASK BACKEND (Backend Server)                       │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                    Request Handler                            │   │
│  │  - Parse session JSON                                        │   │
│  │  - Validate data                                             │   │
│  │  - Calculate AI scores                                       │   │
│  └────────────────────────┬─────────────────────────────────────┘   │
│                           │                                          │
│  ┌────────────────────────▼─────────────────────────────────────┐   │
│  │              Behavior Analysis Engine                         │   │
│  │  - Impulsivity Score       (0-1)                             │   │
│  │  - Reaction Speed Score    (0-1)                             │   │
│  │  - Attention Variability   (0-1)                             │   │
│  │  - Pattern Classification                                    │   │
│  └────────────────────────┬─────────────────────────────────────┘   │
│                           │                                          │
│  ┌────────────────────────▼─────────────────────────────────────┐   │
│  │              Data Persistence Layer                           │   │
│  │  ┌────────────────────────────────────────────────────────┐  │   │
│  │  │              SQLite Database                           │  │   │
│  │  │                                                        │  │   │
│  │  │  sessions table:                                       │  │   │
│  │  │  - session_id (PK)                                     │  │   │
│  │  │  - age_group                                           │  │   │
│  │  │  - session_start / end                                 │  │   │
│  │  │  - wait_game_data (JSON)                              │  │   │
│  │  │  - story_game_data (JSON)                             │  │   │
│  │  │  - analysis_scores (JSON)                             │  │   │
│  │  │  - created_at (timestamp)                             │  │   │
│  │  └────────────────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                        │
│  Endpoints:                                                            │
│  POST   /save_session              - Save session data               │
│  GET    /get_sessions              - List all sessions               │
│  GET    /get_session/<id>          - Get specific session            │
│  POST   /analyze                   - Legacy analyze endpoint         │
│                                                                        │
└──────────────────────────────────────────────────────────────────────┘
```

---

## **Data Model**

### **WaitingGameResult (Wait For Your Turn)**

```dart
class WaitingGameResult {
  final int prematureTaps;              // Count of premature taps
  final List<int> reactionTimes;        // [245, 256, 312, ...] ms
  final double avgReaction;             // Average of reactionTimes
  final double reactionVariability;     // Std deviation
  final int totalTrials;                // Number of rounds
  final DateTime startTime;             // When game started
  final DateTime endTime;               // When game ended
  final int ageGroup;                   // 0, 1, or 2
  
  Map<String, dynamic> toJson() {
    // Converts to JSON for backend transmission
  }
}
```

### **StoryGameResult (Story Reading)**

```dart
class StoryGameResult {
  final int pagesRead;                  // NEXT button count
  final int pagesSkipped;               // SKIP button count
  final List<int> pageReadingTimes;     // [3240, 2156, ...] ms
  final double avgReadTime;             // Average page time
  final double skipRate;                // 0-1 scale
  final DateTime startTime;             // When game started
  final DateTime endTime;               // When game ended
  final int ageGroup;                   // 0, 1, or 2
  
  Map<String, dynamic> toJson() {
    // Converts to JSON for backend transmission
  }
}
```

### **AssessmentSessionResult (Complete Session)**

```dart
class AssessmentSessionResult {
  final WaitingGameResult waitingResult;    // Game 1 data
  final StoryGameResult storyResult;        // Game 2 data
  final int ageGroup;                       // From user selection
  final DateTime sessionStart;              // When first game started
  final DateTime sessionEnd;                // When second game ended
  
  String toJsonString() {
    // Returns complete JSON for POST to backend
  }
}
```

---

## **Game Specifications**

### **Game 1: Wait For Your Turn (120 seconds total)**

**Architecture:**
```
GameTimer (1 second intervals)
  ├─ Tracks elapsedSeconds (0-120)
  ├─ At 30 sec: switches from practice to main
  └─ At 120 sec: calls finishGame()

Practice Phase (0-30 sec)
  └─ Fixed countdown: 3 seconds always
  
Main Phase (30-120 sec)
  └─ Random countdown: 2-15 seconds per round
  
Round Flow:
  1. Display countdown (3...2...1...)
  2. Show "GO!" signal
  3. User taps (collect reaction time)
  4. If before countdown ends: prematureTaps++
  5. If after GO: reactionTimes.add(ms)
  6. Loop until 2 minutes up
```

**Metrics Collection:**
```javascript
{
  "premature_taps": 5,
  "reaction_times": [245, 256, 312, 289, 301, 267, 298],
  "avg_reaction": 280.6,                    // Computed
  "reaction_variability": 28.3,             // Computed (std dev)
  "total_trials": 15,
  "duration_seconds": 120
}
```

**Computation:**
- `avgReaction = sum(reactionTimes) / reactionTimes.length`
- `reactionVariability = sqrt(sum((rt - avg)^2) / count)`

---

### **Game 2: Story Reading (300 seconds total)**

**Architecture:**
```
GameTimer (1 second intervals)
  ├─ Tracks elapsedSeconds (0-300)
  ├─ If 5 minutes reached: finishStory()
  └─ User can exit early via button
  
Page Display Loop:
  1. Show story page
  2. Track pageStartTime
  3. User clicks NEXT or SKIP
  4. Record time: DateTime.now() - pageStartTime
  5. Move to next page
  6. Repeat until game end or pages exhausted
```

**Metrics Collection:**
```javascript
{
  "pages_read": 2,                          // NEXT clicks
  "pages_skipped": 1,                       // SKIP clicks
  "page_reading_times": [3240, 2156, 4521],// Time per page (ms)
  "avg_read_time": 3305.67,                 // Computed
  "skip_rate": 0.333,                       // Computed
  "duration_seconds": 300
}
```

**Computation:**
- `avgReadTime = sum(pageReadingTimes) / pageReadingTimes.length`
- `skipRate = pagesSkipped / totalPages`

---

## **HTTP Data Exchange**

### **Request: POST /save_session**

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
    "reaction_times": [245, 256, 312, 289, 301, ...],
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

### **Response: 200 OK**

```json
{
  "status": "success",
  "message": "Session saved successfully",
  "session_id": "1705484520123",
  "analysis": {
    "wait_for_your_turn": {
      "impulsivity": 0.35,
      "reaction_speed": 0.28,
      "attention_variability": 0.14
    },
    "wait_pattern": "Moderate attention and impulse control",
    "story_skip_rate": 0.333
  }
}
```

---

## **Database Schema**

```sql
CREATE TABLE sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    
    -- Session metadata
    session_id TEXT UNIQUE NOT NULL,
    age_group INTEGER NOT NULL,
    
    -- Timing
    session_start TEXT NOT NULL,          -- ISO 8601
    session_end TEXT NOT NULL,            -- ISO 8601
    total_duration_seconds INTEGER,
    
    -- Game data (JSON strings)
    wait_game_data TEXT NOT NULL,         -- Entire Wait Game JSON
    story_game_data TEXT NOT NULL,        -- Entire Story Game JSON
    
    -- Analysis results (JSON)
    analysis_scores TEXT,                 -- Behavior scores + patterns
    
    -- Audit
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Indexes (for performance):**
```sql
CREATE INDEX idx_session_id ON sessions(session_id);
CREATE INDEX idx_age_group ON sessions(age_group);
CREATE INDEX idx_created_at ON sessions(created_at);
```

---

## **Behavioral Scoring Algorithm**

### **Impulsivity Score**
```python
def impulsivity_score(premature_rate):
    # premature_rate = premature_taps / total_trials
    # Baseline: 15% error rate
    # Scale: 0 (low impulsivity) to 1 (high impulsivity)
    score = premature_rate / 0.5
    return clamp(score, 0, 1)
```

**Interpretation:**
- 0.0-0.2: Excellent impulse control ✅
- 0.2-0.5: Good impulse control
- 0.5-0.7: Average impulse control
- 0.7-1.0: High impulsivity (may need attention) ⚠️

### **Reaction Speed Score**
```python
def speed_score(avg_reaction_ms):
    # Baseline: 250 ms
    # Scale to 0-1
    score = (avg_reaction_ms - 250) / 300
    return clamp(score, 0, 1)
```

**Interpretation:**
- 0.0-0.2: Very fast reactions 🚀
- 0.2-0.5: Normal speed
- 0.5-0.8: Slower reactions
- 0.8-1.0: Very slow responses ⚠️

### **Attention Variability Score**
```python
def stability_score(variability_ms):
    # Measures consistency of responses
    # Baseline: 200 ms variability
    # Scale to 0-1
    score = variability / 200
    return clamp(score, 0, 1)
```

**Interpretation:**
- 0.0-0.2: Very consistent ✅
- 0.2-0.5: Good consistency
- 0.5-0.8: Variable responses
- 0.8-1.0: Highly inconsistent (may indicate fatigue) ⚠️

### **Pattern Classification**

```python
if impulsivity > 0.6 and variability > 0.6:
    pattern = "High impulsivity, fluctuating attention"
elif reaction_speed > 0.6:
    pattern = "Slow but controlled responses"
elif impulsivity < 0.3 and variability < 0.3:
    pattern = "Strong impulse control and stable attention"
else:
    pattern = "Moderate attention and impulse control"
```

---

## **Error Handling**

### **Frontend (Flutter)**

```dart
try {
  // Game execution
  waitingResult = await Navigator.push(...);
  
  // Data transmission
  await sendSessionDataToBackend();
  
} catch (e) {
  debugPrint("Error: $e");
  // Show user-friendly error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Connection error: $e"))
  );
}
```

**Connection Error Handling:**
- ✅ User sees: "Connection error - please check network"
- ✅ Games still complete locally
- ✅ User can try again to upload

### **Backend (Flask)**

```python
@app.route("/save_session", methods=["POST"])
def save_session():
    try:
        data = request.get_json()
        # Process and save
        return jsonify({"status": "success"}), 200
    
    except ValueError as e:
        return jsonify({"error": "Invalid data format"}), 400
    
    except sqlite3.IntegrityError:
        return jsonify({"error": "Duplicate session"}), 409
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500
```

**Status Codes:**
- `200`: Success ✅
- `400`: Bad request (invalid JSON)
- `404`: Not found (get_session)
- `409`: Conflict (duplicate session_id)
- `500`: Server error

---

## **Performance Optimization**

### **Frontend**
- **Game Timer:** Uses `Timer.periodic()` for 1-second updates
- **State Management:** Minimal rebuilds using `setState()`
- **Memory:** Lists stored in RAM (small for short sessions)

### **Backend**
- **Database:** SQLite (file-based, no server needed)
- **Connection Pool:** Flask handles HTTP connection pooling
- **JSON Parsing:** Built-in Python json library
- **Indexing:** Added on session_id, age_group, created_at

### **Network**
- **Data Size:** ~5-10 KB per session JSON
- **Compression:** Optional gzip (not implemented, easy to add)
- **Timeout:** HTTP timeout: 30 seconds (configurable)

---

## **Deployment Checklist**

- [ ] Test locally (Flask + Flutter)
- [ ] Database file created: `assessment_sessions.db`
- [ ] All endpoints responding (200 OK)
- [ ] Sample session saved and retrieved
- [ ] Time measurements accurate
- [ ] Scores calculated correctly
- [ ] JSON serialization working
- [ ] Error handling tested
- [ ] Logs being generated

---

## **Future Enhancements**

1. **Authentication**
   - Add user login (child profiles)
   - Track individual progress
   - Generate reports per child

2. **Cloud Deployment**
   - Move Flask to AWS/Azure/Heroku
   - Use RDS or similar managed DB
   - Add HTTPS/SSL

3. **Advanced Analytics**
   - Trend analysis over multiple sessions
   - Peer comparison (anonymized)
   - ML-based pattern detection

4. **Notifications**
   - Alert parents of concerning patterns
   - Progress reminders
   - Achievement badges

5. **More Games**
   - Memory game (recall sequences)
   - Planning game (tower of hanoi)
   - Attention game (spot differences)

6. **Mobile Optimization**
   - Offline mode (sync later)
   - Tablet-specific UI
   - Landscape mode support

---

## **Version Control**

**Current Version:** 2.0
- ✅ Wait For Your Turn: 2 min, randomized countdowns
- ✅ Story Reading: 5 min timer
- ✅ Batch data sending
- ✅ SQLite persistence
- ✅ Advanced scoring

**Previous Version:** 1.0 (Legacy)
- Fixed 5 rounds
- Per-round data sending
- Basic metrics only
