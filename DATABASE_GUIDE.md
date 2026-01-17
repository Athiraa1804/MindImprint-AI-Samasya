# 📊 DATABASE GUIDE & QUERIES

## **Database Location**
```
c:\flutter_projects\ADHD-AI-Samasya\neuro_backend\assessment_sessions.db
```

---

## **Quick Access**

### **Open Database (SQLite CLI)**
```bash
cd c:\flutter_projects\ADHD-AI-Samasya\neuro_backend
sqlite3 assessment_sessions.db
```

### **View All Sessions**
```sql
SELECT 
    session_id,
    age_group,
    session_start,
    session_end,
    total_duration_seconds,
    created_at
FROM sessions
ORDER BY created_at DESC;
```

### **Count Sessions**
```sql
SELECT COUNT(*) as total_sessions FROM sessions;
```

### **Get Specific Session**
```sql
SELECT * FROM sessions WHERE session_id = 'YOUR_SESSION_ID';
```

---

## **JSON Data Access**

### **Extract Wait Game Data**
```sql
SELECT 
    session_id,
    json_extract(wait_game_data, '$.premature_taps') as premature_taps,
    json_extract(wait_game_data, '$.avg_reaction') as avg_reaction,
    json_extract(wait_game_data, '$.total_trials') as total_trials
FROM sessions
ORDER BY created_at DESC;
```

### **Extract Story Game Data**
```sql
SELECT 
    session_id,
    json_extract(story_game_data, '$.pages_read') as pages_read,
    json_extract(story_game_data, '$.skip_rate') as skip_rate,
    json_extract(story_game_data, '$.avg_read_time') as avg_read_time
FROM sessions
ORDER BY created_at DESC;
```

### **Extract Analysis Scores**
```sql
SELECT 
    session_id,
    json_extract(analysis_scores, '$.wait_for_your_turn.impulsivity') as impulsivity,
    json_extract(analysis_scores, '$.wait_pattern') as pattern
FROM sessions
ORDER BY created_at DESC;
```

---

## **Python Access (Flask)**

### **Using Flask Shell**
```bash
cd c:\flutter_projects\ADHD-AI-Samasya\neuro_backend
python

>>> import sqlite3
>>> import json
>>> conn = sqlite3.connect('assessment_sessions.db')
>>> c = conn.cursor()
>>> c.execute("SELECT * FROM sessions ORDER BY created_at DESC LIMIT 1")
>>> row = c.fetchone()
>>> wait_data = json.loads(row[6])
>>> print(wait_data)
```

---

## **Data Export**

### **Export All Sessions to CSV**
```bash
cd c:\flutter_projects\ADHD-AI-Samasya\neuro_backend
sqlite3 assessment_sessions.db
.mode csv
.output sessions_export.csv
SELECT session_id, age_group, session_start, session_end, total_duration_seconds FROM sessions;
.quit
```

### **Export JSON**
```python
import sqlite3
import json

conn = sqlite3.connect('assessment_sessions.db')
c = conn.cursor()
c.execute("SELECT * FROM sessions")

sessions = []
for row in c.fetchall():
    sessions.append({
        'session_id': row[1],
        'age_group': row[2],
        'wait_game': json.loads(row[6]),
        'story_game': json.loads(row[7]),
        'analysis': json.loads(row[8]),
    })

with open('sessions_export.json', 'w') as f:
    json.dump(sessions, f, indent=2)

conn.close()
```

---

## **Analytics Queries**

### **Average Metrics by Age Group**
```sql
SELECT 
    age_group,
    COUNT(*) as sessions,
    ROUND(AVG(json_extract(wait_game_data, '$.premature_taps')), 1) as avg_premature,
    ROUND(AVG(json_extract(wait_game_data, '$.avg_reaction')), 0) as avg_reaction_ms,
    ROUND(AVG(json_extract(story_game_data, '$.skip_rate')), 3) as avg_skip_rate
FROM sessions
GROUP BY age_group;
```

**Explanation:**
- Shows average metrics grouped by age (0=4-6, 1=7-9, 2=10-12)
- Useful for comparing performance by age

### **Sessions This Week**
```sql
SELECT 
    session_id,
    age_group,
    session_start,
    json_extract(wait_game_data, '$.premature_taps') as premature_taps
FROM sessions
WHERE datetime(created_at) >= datetime('now', '-7 days')
ORDER BY created_at DESC;
```

### **High Impulsivity Sessions**
```sql
SELECT 
    session_id,
    age_group,
    json_extract(analysis_scores, '$.wait_for_your_turn.impulsivity') as impulsivity_score,
    json_extract(analysis_scores, '$.wait_pattern') as pattern
FROM sessions
WHERE json_extract(analysis_scores, '$.wait_for_your_turn.impulsivity') > 0.6
ORDER BY created_at DESC;
```

### **Sessions with Skip Rate > 50%**
```sql
SELECT 
    session_id,
    age_group,
    json_extract(story_game_data, '$.skip_rate') as skip_rate,
    json_extract(story_game_data, '$.pages_read') as pages_read
FROM sessions
WHERE json_extract(story_game_data, '$.skip_rate') > 0.5
ORDER BY created_at DESC;
```

---

## **Database Maintenance**

### **Backup Database**
```bash
# PowerShell
Copy-Item assessment_sessions.db assessment_sessions_backup_$(Get-Date -Format 'yyyyMMdd').db

# Or manual backup
xcopy assessment_sessions.db backup\
```

### **Check Database Integrity**
```sql
PRAGMA integrity_check;
```

**Output should be:**
```
ok
```

### **Optimize Database**
```sql
VACUUM;
ANALYZE;
```

### **Delete Old Sessions** (older than 30 days)
```sql
DELETE FROM sessions 
WHERE datetime(created_at) < datetime('now', '-30 days');
```

⚠️ **WARNING:** This is destructive - backup first!

---

## **Sample Data Structure**

### **Full JSON from wait_game_data**
```json
{
  "game_id": "wait_for_your_turn",
  "age_group": 1,
  "premature_taps": 5,
  "reaction_times": [245, 256, 312, 289, 301, 267, 298],
  "avg_reaction": 280.6,
  "reaction_variability": 28.3,
  "total_trials": 15,
  "start_time": "2025-01-17T10:08:40.123Z",
  "end_time": "2025-01-17T10:10:40.456Z",
  "duration_seconds": 120
}
```

### **Full JSON from story_game_data**
```json
{
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
```

### **Full JSON from analysis_scores**
```json
{
  "wait_for_your_turn": {
    "impulsivity": 0.35,
    "reaction_speed": 0.28,
    "attention_variability": 0.14
  },
  "wait_pattern": "Moderate attention and impulse control",
  "story_skip_rate": 0.333
}
```

---

## **REST API Access (Via Flask)**

### **Get All Sessions**
```bash
curl http://127.0.0.1:5000/get_sessions
```

**Response:**
```json
{
  "status": "success",
  "total_sessions": 5,
  "sessions": [
    {
      "session_id": "1705484520123",
      "age_group": 1,
      "start": "2025-01-17T10:08:40.123Z",
      "end": "2025-01-17T10:15:40.456Z",
      "duration_seconds": 420,
      "saved_at": "2025-01-17 10:16:00"
    }
  ]
}
```

### **Get Specific Session**
```bash
curl http://127.0.0.1:5000/get_session/1705484520123
```

**Response:**
```json
{
  "status": "success",
  "session": {
    "session_id": "1705484520123",
    "age_group": 1,
    "wait_game": { /* full JSON */ },
    "story_game": { /* full JSON */ },
    "analysis": { /* full JSON */ },
    "saved_at": "2025-01-17 10:16:00"
  }
}
```

---

## **Monitoring & Alerts**

### **Check Database Size**
```bash
# PowerShell
(Get-Item assessment_sessions.db).Length / 1MB
```

**Expected:** < 100 MB for 5000+ sessions

### **Monitor Growth Rate**
```sql
SELECT 
    DATE(created_at) as date,
    COUNT(*) as sessions_added
FROM sessions
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

### **Find Slow Sessions** (taking > 10 min)
```sql
SELECT 
    session_id,
    age_group,
    total_duration_seconds / 60.0 as duration_minutes
FROM sessions
WHERE total_duration_seconds > 600
ORDER BY total_duration_seconds DESC;
```

---

## **Troubleshooting**

### **"database is locked"**
```
Cause: Multiple processes accessing DB
Fix: Close Flutter app, wait 5 seconds, try again
```

### **"no such table: sessions"**
```
Cause: Database not initialized
Fix: Run Flask app once: python app.py
     This creates the table automatically
```

### **"disk I/O error"**
```
Cause: File permissions or corruption
Fix: 
  1. Backup database
  2. Run: sqlite3 assessment_sessions.db
  3. Run: PRAGMA integrity_check;
  4. If corrupted, restore from backup
```

### **JSON extraction returns NULL**
```
Cause: Key doesn't exist in JSON
Fix: Check JSON structure with:
  sqlite3 assessment_sessions.db
  SELECT json_extract(wait_game_data, '$') FROM sessions LIMIT 1;
```

---

## **Best Practices**

1. **Regular Backups**
   - Daily automated backup
   - Store offsite
   - Test restore monthly

2. **Data Retention**
   - Keep last 90 days active
   - Archive to CSV/JSON older data
   - Delete after 2 years (or per policy)

3. **Access Control**
   - Limit database write access
   - Read-only for analytics
   - Audit log changes

4. **Performance**
   - Run ANALYZE monthly
   - Monitor query performance
   - Add indexes if needed

5. **Documentation**
   - Keep JSON schema documented
   - Document any custom queries
   - Share with team

---

**Database Version:** 1.0
**Last Updated:** January 17, 2026
**Maintenance Date:** [Schedule quarterly check]
