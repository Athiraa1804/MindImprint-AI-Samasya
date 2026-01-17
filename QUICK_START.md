# 🚀 QUICK START GUIDE

## **Prerequisites**
- ✅ Flutter installed
- ✅ Python 3.8+ installed
- ✅ Visual Studio Code or similar editor

---

## **STEP 1: Start Flask Backend**

```bash
# Navigate to backend
cd c:\flutter_projects\ADHD-AI-Samasya\neuro_backend

# Install dependencies (first time only)
pip install -r requirements.txt

# Run Flask server
python app.py
```

**Expected Output:**
```
 * Running on http://127.0.0.1:5000
 * Debug mode: on
```

✅ **Backend is ready!**

---

## **STEP 2: Run Flutter App**

```bash
# Navigate to Flutter project
cd c:\flutter_projects\ADHD-AI-Samasya\game_3

# Get dependencies (first time only)
flutter pub get

# Run the app
flutter run
```

✅ **App should launch!**

---

## **STEP 3: Test the Flow**

1. **Home Screen** appears
   - Click age selector (e.g., 7-9)
   - Click "Start Exploration"

2. **Wait For Your Turn Game** starts (2 minutes)
   - Practice round: First 30 sec (countdown always 3)
   - Main game: Next 90 sec (random 2-15 sec countdowns)
   - **Action:** Tap screen when you see "GO!"

3. **Story Reading Game** starts (5 minutes)
   - Read the story pages
   - Click "NEXT" to advance or "SKIP" to skip
   - **Timer shows remaining time**

4. **Final Report** appears
   - Shows all metrics from both games
   - Shows ✅ confirmation that data was saved

5. **Data is stored** in Flask database!

---

## **STEP 4: Verify Data Was Saved**

```bash
# Open terminal in backend directory
cd c:\flutter_projects\ADHD-AI-Samasya\neuro_backend

# Check database (requires sqlite3 CLI)
sqlite3 assessment_sessions.db
> SELECT session_id, age_group, created_at FROM sessions;
```

**Or use Flask endpoints:**

```bash
# Get all sessions
curl http://127.0.0.1:5000/get_sessions

# Get specific session (replace SESSION_ID)
curl http://127.0.0.1:5000/get_session/SESSION_ID
```

---

## **TROUBLESHOOTING**

### **"Connection Error" in Flutter app**
- ✅ Make sure Flask server is running (`python app.py`)
- ✅ Check server is on `http://127.0.0.1:5000`
- ✅ Try: `curl http://127.0.0.1:5000/` in terminal

### **"ModuleNotFoundError: flask" in Python**
- ✅ Run: `pip install -r requirements.txt`
- ✅ Make sure you're in the right directory

### **Flutter compilation errors**
- ✅ Run: `flutter pub get`
- ✅ Run: `flutter clean && flutter pub get`

### **Database not found**
- ✅ First run of Flask creates it automatically
- ✅ Check: `c:\flutter_projects\ADHD-AI-Samasya\neuro_backend\assessment_sessions.db`

---

## **📊 SAMPLE DATA OUTPUT**

**Final Report shows:**
```
🧠 Assessment Complete!

⏳ Impulse Control (Wait For Your Turn)
  Total Correct Taps:     12
  Premature Taps:         3
  Avg Reaction Time:      285 ms
  Reaction Variability:   42 ms
  Total Trials:           15

📖 Reading Attention (Story Reading)
  Pages Read:             2
  Pages Skipped:          1
  Avg Read Time:          2684 ms
  Skip Rate:              33.3%

✅ All data has been saved to the backend successfully!
```

---

## **🎮 GAME MECHANICS**

### **Wait For Your Turn (2 min total)**
- **Practice** (30 sec): Countdown always shows 3
- **Main** (90 sec): Random countdown 2-15 seconds
- **Action:** Tap ONLY after "GO!" appears
- **Scoring:** 
  - ✅ Correct = tap recorded
  - ❌ Premature = tap before countdown ends
  - ⏳ Reaction time = milliseconds after "GO!"

### **Story Reading (5 min total)**
- **Read** pages at your own pace
- **NEXT** = advance to next page, record time
- **SKIP** = skip page, record as skip
- **Timer** = auto-finish at 5 minutes
- **Scoring:**
  - Pages read/skipped count
  - Time per page tracked
  - Skip rate calculated

---

## **📂 KEY FILES MODIFIED**

```
c:\flutter_projects\ADHD-AI-Samasya\
├── game_3/
│   ├── lib/
│   │   ├── main.dart                         (no changes)
│   │   ├── models/
│   │   │   └── assessment_models.dart        ✅ UPDATED (added full metrics)
│   │   ├── screens/
│   │   │   ├── home_screen.dart             ✅ NO CHANGES (already good)
│   │   │   └── assessment.dart              ✅ UPDATED (batch data, backend)
│   │   └── games/
│   │       ├── wait_for_your_turn.dart      ✅ UPDATED (2 min, random timers)
│   │       └── game_4/
│   │           └── story_reading.dart       ✅ UPDATED (5 min timer)
│   └── pubspec.yaml                         ✅ NO CHANGES (deps already there)
│
└── neuro_backend/
    ├── app.py                                ✅ UPDATED (added /save_session endpoint)
    └── requirements.txt                      ✅ UPDATED (Flask, CORS)

IMPLEMENTATION_SUMMARY.md                     ✅ CREATED (comprehensive docs)
```

---

## **🎯 YOU'RE ALL SET!**

Everything is ready to go. The system is:
- ✅ Fully implemented
- ✅ Data collection complete
- ✅ Backend persistence working
- ✅ Professional UI/UX
- ✅ Ready for deployment

**Start with:** Backend first, then Flutter app! 🚀
