# 🧠 MindImprint AI - Behavioral Analysis & Detection System

## Overview
MindImprint uses a **multi-game assessment approach** combined with **AI-powered cognitive profiling** to detect ADHD-related behavioral patterns in children. The system measures three core cognitive domains and generates personalized, parent-friendly insights.

---

## 📊 Part 1: Parameters Collected from Each Game

### **Game 1: Wait For Your Turn (Impulse Control Assessment)**
**Duration:** 2 minutes (120 seconds)  
**Purpose:** Measures impulse control and reaction consistency

| Parameter | What It Measures | How It's Collected |
|-----------|-----------------|-------------------|
| **Premature Taps** | Impulsivity level | Count of button presses before the green light appears |
| **Reaction Times** | Response speed | Time (ms) from green light to user's tap |
| **Avg Reaction** | Average response speed | Mean of all reaction times |
| **Reaction Variability** | Attention consistency | Standard deviation of reaction times (ms) |
| **Total Trials** | Completeness | Number of complete wait cycles |

**Example Data:**
```
Premature Taps: 2 (out of 20 trials)
Reaction Times: [345ms, 380ms, 320ms, ...] 
Avg Reaction: 350ms
Reaction Variability: 85ms
```

---

### **Game 2: Story Reading (Attention & Reading Comprehension)**
**Duration:** 5 minutes  
**Purpose:** Measures sustained attention and reading focus

| Parameter | What It Measures | How It's Collected |
|-----------|-----------------|-------------------|
| **Pages Read** | Task completion | Number of pages read (out of 3) |
| **Pages Skipped** | Attention lapses | Number of pages skipped/rushed |
| **Page Reading Times** | Reading pace | Time (ms) spent on each page |
| **Avg Read Time** | Average reading speed | Mean time per page |
| **Skip Rate** | Focus consistency | % of pages skipped = skipped_pages / total_pages |

**Example Data:**
```
Pages Read: 2/3
Pages Skipped: 1
Page Reading Times: [3500ms, 2200ms, 1800ms]
Avg Read Time: 2500ms
Skip Rate: 33% (rushed through 1 of 3 pages)
```

**Key Insight:** If a page is read in <2000ms, it's flagged as "RUSHED"

---

### **Game 3: Step Builder (Memory & Organization)**
**Duration:** 2 minutes (120 seconds)  
**Purpose:** Measures ability to remember sequences and follow procedures

| Parameter | What It Measures | How It's Collected |
|-----------|-----------------|-------------------|
| **Steps Skipped** | Memory lapses | Number of steps not placed in sequence |
| **Order Errors** | Organization | Number of steps placed in wrong order |
| **Task Completed** | Success indicator | Boolean - all steps placed correctly |
| **Step Placement Times** | Speed of processing | Time (ms) to place each step |
| **Avg Placement Time** | Average decision speed | Mean time per step placement |

**Example Data:**
```
Steps Skipped: 0
Order Errors: 1 (placed one step wrong)
Task Completed: False (incomplete sequence)
Step Placement Times: [2100ms, 1950ms, 2300ms, ...]
Avg Placement Time: 2150ms
```

---

### **Game 4: Find The Star (Visual Attention & Impulsivity)**
**Duration:** 1 minute (60 seconds) ⭐ [NEW]  
**Purpose:** Measures visual attention and discriminative accuracy

| Parameter | What It Measures | How It's Collected |
|-----------|-----------------|-------------------|
| **Stars Found** | Accuracy & focus | Count of correct star clicks |
| **Total Misclicks** | Impulsivity/errors | Count of wrong shape clicks |
| **Times Per Star** | Reaction speed per target | Array of times (ms) to find each star |
| **Avg Time Per Star** | Average target acquisition | Mean time to find each star |

**Example Data:**
```
Stars Found: 8
Total Misclicks: 2
Times Per Star: [2345ms, 1890ms, 3200ms, ...]
Avg Time Per Star: 2400ms
```

---

## 🤖 Part 2: How AI Uses Parameters to Detect Behavioral Patterns

### **Important Distinction: RULE-BASED vs AI-POWERED**

⚠️ **The core scoring calculations are RULE-BASED (deterministic, mathematical)**  
✅ **Only the narrative conclusions are AI-POWERED (Ollama LLM)**

---

### **Three Core Cognitive Domains**

The backend uses a **weighted scoring system** (rule-based) that converts game metrics into three key domains:

---

## 📈 **Domain 1: IMPULSIVITY** (Acting Without Thinking)

### ⚙️ **RULE-BASED Calculation:**
```
Impulsivity = (Wait Game Score × 70%) + (Step Game Score × 30%)

Wait Game Score = Premature Taps / Total Trials / 0.5 (normalized)
Step Game Score = Order Errors / 4 (normalized)
```

### What It Measures:
- **Does the child act before thinking?**
- **Do they rush through tasks?**
- **Do they make careless errors?**

### Scoring Scale:
| Score | Level | Meaning |
|-------|-------|---------|
| 0.0-0.25 | **Low** | Excellent impulse control ✅ |
| 0.25-0.50 | **Moderate** | Normal for age 📊 |
| 0.50-0.75 | **High** | Needs practice 🔸 |
| 0.75-1.0 | **Very High** | Significant challenges 🔴 |

### Example Analysis:
```
Child taps button prematurely 5 times out of 20 trials = 25% premature rate
25% / 0.5 = 0.5 (normalized to Impulsivity score)
→ "Very High Impulsivity" 🔴 "Tends to act quickly without thinking"
```

---

## 📈 **Domain 2: ATTENTION** (Focus & Consistency)

### ⚙️ **RULE-BASED Calculation:**
```
Attention = (Reaction Variability Score × 50%) + (Skip Rate × 50%)

Reaction Variability Score = Reaction Variability in ms / 200
Skip Rate = Pages Skipped / Total Pages
```

### What It Measures:
- **Is the child's focus consistent?**
- **Do they get distracted during tasks?**
- **Do they maintain concentration?**

### Scoring Scale:
| Score | Level | Meaning |
|-------|-------|---------|
| 0.0-0.25 | **Low** | Strong focused attention ✅ |
| 0.25-0.50 | **Moderate** | Normal distractibility 📊 |
| 0.50-0.75 | **High** | Struggles to maintain focus 🔸 |
| 0.75-1.0 | **Very High** | Major attention challenges 🔴 |

### Example Analysis:
```
Reaction Variability: 150ms (high = poor consistency)
150 / 200 = 0.75 (indicates attention problems)
Skip Rate: 33% (rushed through 1 of 3 pages)
0.33 / 1.0 = 0.33

Attention Score = (0.75 × 0.5) + (0.33 × 0.5) = 0.54
→ "High Attention Issues" 🔸 "Struggles to focus; recommend breaks"
```

---

## 📈 **Domain 3: MEMORY & ORGANIZATION** (Task Planning & Execution)

### ⚙️ **RULE-BASED Calculation:**
```
Memory/Organization = (Task Completion Score × 70%) + (Pages Read Score × 30%)

Task Completion Score = 0.1 if completed, else Steps Skipped / 3 (normalized)
Pages Read Score = 1 - (Pages Read / 3)
```

### What It Measures:
- **Can the child remember multi-step sequences?**
- **Do they plan and organize their approach?**
- **Do they complete structured tasks?**

### Scoring Scale:
| Score | Level | Meaning |
|-------|-------|---------|
| 0.0-0.25 | **Low** | Excellent organization ✅ |
| 0.25-0.50 | **Moderate** | Developing skills 📊 |
| 0.50-0.75 | **High** | Needs structured support 🔸 |
| 0.75-1.0 | **Very High** | Significant organization challenges 🔴 |

### Example Analysis:
```
Task Completed: False (couldn't place all steps)
Steps Skipped: 2
Org Score = 2 / 3 = 0.67

Pages Read: 2/3
Pages Score = 1 - (2/3) = 0.33

Final Score = (0.67 × 0.7) + (0.33 × 0.3) = 0.57
→ "High Memory/Organization Issues" 🔸 "Struggles with multi-step tasks"
```

---

## 🎯 Part 3: AI-Powered Insights & Recommendations

### **Step 1: Generate Severity Assessment**
Each domain gets classified into a severity level:
- **Low** (0.0-0.25) = Strength/No concerns
- **Moderate** (0.25-0.50) = Typical development
- **High** (0.50-0.75) = Needs intervention
- **Very High** (0.75-1.0) = Significant challenges

### **Step 2: Generate AI Narratives (Using Ollama Mistral)**

The backend uses **Ollama LLM (Mistral model)** to generate personalized, parent-friendly conclusions:

```python
# AI Prompt Example for Impulsivity
"""
Child's impulse control score: 75% (High impulsivity)
Quick button presses: 8 times out of 20 trials
Total trials: 20

Write ONE sentence about needing practice with impulse control.
Frame as growth opportunity with support.
"""

# AI Response (Example)
"Your child tends to act quickly, and with targeted practice and support, 
they can build stronger impulse control."
```

### **Evidence Collection**
Each conclusion includes **supporting evidence**:

```json
{
  "Impulsivity": {
    "score": 0.75,
    "level": "High",
    "conclusion": "Your child tends to act quickly...",
    "evidence": [
      "Premature taps in Wait game: 8",
      "Order errors in Step Builder: 2"
    ]
  },
  "Attention": {
    "score": 0.54,
    "level": "High",
    "conclusion": "Your child struggled with focus...",
    "evidence": [
      "Reaction variability: 150ms",
      "Story skip rate: 33%"
    ]
  },
  "Memory/Organization": {
    "score": 0.57,
    "level": "High",
    "conclusion": "Your child found it challenging...",
    "evidence": [
      "Step Builder completed: ❌ No",
      "Steps skipped: 2",
      "Pages read: 2/3"
    ]
  }
}
```

### **Step 3: Generate Recommendations**

The AI analyzes all three domains and recommends interventions:

```python
Recommendations Generated:
✓ High impulsivity (0.75) → "impulse control strategies, stop-and-think exercises"
✓ Attention issues (0.54) → "focus training and minimal distractions"  
✓ Organization issues (0.57) → "structured task breakdowns and visual aids"

Final Output:
"Organization difficulties detected - recommend structured task breakdowns 
and visual aids | Impulse control needed - recommend stop-and-think strategies"
```

---

## 🔬 Part 4: Behavioral Pattern Detection

### **Pattern Recognition Algorithm**

The system identifies **cross-domain patterns**:

```python
Pattern 1: "High impulsivity + High attention issues"
→ ADHD-like profile with focus and control challenges

Pattern 2: "High organization issues + Normal impulsivity"
→ Executive function deficit (planning/memory weak)

Pattern 3: "Low across all domains"
→ Strong cognitive performance, no concerns

Pattern 4: "High impulsivity + Low organization"
→ Acts without planning; needs structure
```

### **Real-World Example:**

```
Child Profile:
- Premature Taps: 12/20 (60% rate) → Impulsivity: 0.60 [HIGH]
- Reaction Variability: 180ms → Attention component: 0.90 [VERY HIGH]
- Skip Rate: 67% (skipped 2/3 pages) → Attention component: 0.67 [HIGH]
- Task Not Completed, 3 steps skipped → Organization: 0.70 [HIGH]

AI Analysis:
"This child shows significant difficulties across all three domains:
- Acts impulsively (60% premature tap rate)
- Struggles to maintain focus (high reaction inconsistency, skips pages)
- Cannot organize complex tasks (doesn't complete sequences)

This profile suggests ADHD-like symptoms or significant attention regulation issues.
Recommend professional evaluation + behavioral strategies."

Recommendations:
1. Structured environment with clear routines
2. Short, focused tasks with frequent breaks
3. Visual aids and step-by-step instructions
4. Professional evaluation for possible ADHD assessment
```

---

## 🏗️ Part 5: System Architecture

### **Data Flow:**

```
Flutter App (Games) 
    ↓ [Collects all game metrics]
    ↓ SendSessionData
    ↓
Flask Backend (app.py)
    ↓ [calculate_impulsivity()]
    ↓ [calculate_attention()]
    ↓ [calculate_memory_organization()]
    ↓
Ollama LLM (Mistral)
    ↓ [generate_narrative_conclusion()]
    ↓ [Cache results for speed]
    ↓
Cognitive Profile JSON
    ↓
Flutter Completion Screen
    ↓ [Display scores + conclusions + recommendations]
    ↓
Parent-Friendly Report
```

### **Key Technologies:**

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Frontend** | Flutter + Dart | Interactive games, metrics collection |
| **Backend** | Flask + Python | Scoring & analysis logic |
| **LLM** | Ollama Mistral | Generate personalized narratives |
| **Database** | SQLite | Store session data & history |
| **Caching** | In-memory cache | Speed up repeated narrative generation |

---

## 📋 Part 6: Sample API Request/Response

### **Request (from Flutter):**
```json
POST /save_session
{
  "session_id": "1768632083673",
  "age_group": 8,
  "wait_game_data": {
    "premature_taps": 2,
    "reaction_times": [345, 380, 320, ...],
    "avg_reaction": 350,
    "reaction_variability": 85,
    "total_trials": 20
  },
  "story_game_data": {
    "pages_read": 2,
    "pages_skipped": 1,
    "page_reading_times": [3500, 2200, 1800],
    "skip_rate": 0.333
  },
  "step_game_data": {
    "steps_skipped": 0,
    "order_errors": 1,
    "task_completed": false,
    "step_placement_times": [2100, 1950, 2300]
  },
  "find_star_game_data": {
    "stars_found": 8,
    "total_misclicks": 2,
    "times_per_star": [2345, 1890, 3200, ...],
    "avg_time_per_star": 2400
  }
}
```

### **Response (from Backend):**
```json
{
  "status": "success",
  "message": "Session saved successfully with cognitive analysis",
  "session_id": "1768632083673",
  "cognitive_profile": {
    "impulsivity": {
      "score": 0.3,
      "level": "Moderate",
      "conclusion": "Your child showed good impulse control with occasional quick reactions.",
      "evidence": ["Premature taps: 2", "Order errors: 1"]
    },
    "attention": {
      "score": 0.54,
      "level": "High",
      "conclusion": "Your child struggled with focus...",
      "evidence": ["Reaction variability: 85ms", "Story skip rate: 33%"]
    },
    "memory_organization": {
      "score": 0.3,
      "level": "Moderate",
      "conclusion": "Your child followed most steps correctly...",
      "evidence": ["Task completed: ❌ No", "Steps skipped: 0", "Pages read: 2/3"]
    },
    "overall_score": 0.38,
    "overall_level": "Moderate",
    "recommendation": "Organization difficulties detected - recommend structured task breakdowns"
  }
}
```

---

## 🎯 Part 7: Advantages of This Approach

✅ **Multi-faceted assessment** - Measures 3 dimensions, not just one  
✅ **Objective metrics** - Game data is quantifiable and measurable  
✅ **AI-powered narratives** - Personalized conclusions, not generic templates  
✅ **Parent-friendly language** - No clinical jargon, supportive tone  
✅ **Evidence-based** - Each conclusion backed by specific metrics  
✅ **Scalable** - Can assess many children with consistent methodology  
✅ **Fast feedback** - Results generated immediately after session  
✅ **Caching optimization** - LLM responses cached for speed  

---

## 🔮 Future Enhancements

1. **Longitudinal tracking** - Compare scores over time to track progress
2. **Age-normalized baselines** - Adjust expectations by child's age
3. **Additional games** - Add more assessment modalities (working memory, executive function)
4. **Professional integration** - Export reports for clinical use
5. **Parent coaching** - AI-generated strategies specific to child's profile
6. **Machine learning** - Train models on larger population to improve accuracy

---

**System Version:** 1.0  
**Last Updated:** January 2026  
**Status:** ✅ Production Ready
