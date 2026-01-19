from flask import Flask, request, jsonify
from flask_cors import CORS
import math
import json
from datetime import datetime
import sqlite3
import os
import requests
import hashlib
from threading import Thread
import pickle
import numpy as np

app = Flask(__name__)
CORS(app)

# ════════════════════════════════════════════════════════════════
# 🤖 LOAD ML MODEL (Behavioral Profile Classifier)
# ════════════════════════════════════════════════════════════════
ML_MODEL = None
ML_SCALER = None
ML_FEATURE_NAMES = [
    'impulsivity', 'attention', 'memory_org',
    'reaction_speed_normalized', 'reaction_variability_normalized',
    'skip_rate', 'task_completion_rate', 'avg_accuracy'
]
ML_PROFILE_CLASSES = ['Normal', 'ADHD-Like', 'Learning-Disability', 'Gifted', 'Mixed-Profile']

def load_ml_model():
    """Load pre-trained ML model and scaler"""
    global ML_MODEL, ML_SCALER
    try:
        model_path = os.path.join(os.path.dirname(__file__), 'behavioral_model.pkl')
        scaler_path = os.path.join(os.path.dirname(__file__), 'feature_scaler.pkl')
        
        if os.path.exists(model_path) and os.path.exists(scaler_path):
            with open(model_path, 'rb') as f:
                ML_MODEL = pickle.load(f)
            with open(scaler_path, 'rb') as f:
                ML_SCALER = pickle.load(f)
            debugPrint(f"✅ ML Model loaded successfully")
            return True
        else:
            debugPrint(f"⚠️ ML Model files not found. Run ml_model_trainer.py first")
            return False
    except Exception as e:
        debugPrint(f"❌ Error loading ML model: {e}")
        return False

# ────────────────────── NARRATIVE CACHE (Speed Optimization) ──────────────────────
NARRATIVE_CACHE = {}  # Cache generated narratives to avoid regenerating

def cache_key(domain_name, score, level):
    """Generate cache key for narrative"""
    return f"{domain_name}_{level}_{int(score*100)}"

def get_cached_narrative(domain_name, score, level):
    """Get cached narrative or None"""
    key = cache_key(domain_name, score, level)
    return NARRATIVE_CACHE.get(key)

# ────────────────────── DATABASE SETUP ──────────────────────
DATABASE = "assessment_sessions.db"

def init_db():
    """Initialize SQLite database"""
    if not os.path.exists(DATABASE):
        conn = sqlite3.connect(DATABASE)
        c = conn.cursor()
        c.execute('''
            CREATE TABLE sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT UNIQUE,
                age_group INTEGER,
                session_start TEXT,
                session_end TEXT,
                total_duration_seconds INTEGER,
                wait_game_data TEXT,
                story_game_data TEXT,
                analysis_scores TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        conn.commit()
        conn.close()
        print("✅ Database initialized")

init_db()

# ────────────────────── BASELINE (Synthetic Reference) ──────────────────────
BASELINE = {
    "premature_rate": 0.15,        # typical impulsive error rate
    "avg_reaction": 350,           # ms
    "reaction_variability": 90     # ms
}

# ════════════════════════════════════════════════════════════════
# � OLLAMA LLM INTEGRATION FOR PERSONALIZED NARRATIVES
# ════════════════════════════════════════════════════════════════

OLLAMA_API_URL = "http://localhost:11434/api/generate"

def generate_narrative_conclusion(domain_name, score, level, metrics):
    """
    Generate personalized narrative conclusion using Ollama Mistral
    Parent-friendly, encouraging, non-clinical language
    Balanced: reflects performance but not too negative
    
    Args:
        domain_name: "Impulsivity", "Attention", or "Memory/Organization"
        score: 0-1 score (HIGH = PROBLEM for all domains)
        level: "Low", "Moderate", "High", "Very High"
        metrics: dict with relevant game data
    """
    try:
        # Create parent-friendly prompts based on level
        if domain_name == "Impulsivity":
            if level == "Low":
                context = f"""
Child's impulse control score: {score*100:.0f}% (EXCELLENT - very few issues)
Quick button presses: {metrics.get('premature_taps', 0)} times
Total trials: {metrics.get('trials', 0)}

Write ONE sentence celebrating their excellent impulse control. Keep it simple and genuine.
Example: "Your child showed excellent patience and really thought through before acting!"
"""
            elif level == "Moderate":
                context = f"""
Child's impulse control score: {score*100:.0f}% (GOOD - normal for their age)
Quick button presses: {metrics.get('premature_taps', 0)} times
Total trials: {metrics.get('trials', 0)}

Write ONE sentence about their solid impulse control with a small observation. Keep it encouraging.
Example: "Your child shows good patience, with just occasional quick reactions as they're still learning."
"""
            elif level == "High":
                context = f"""
Child's impulse control score: {score*100:.0f}% (NEEDS PRACTICE - some challenges)
Quick button presses: {metrics.get('premature_taps', 0)} times
Total trials: {metrics.get('trials', 0)}

Write ONE sentence about needing more practice with impulse control, but keep it constructive and hopeful.
Example: "Your child is still learning to pause before acting, which is normal—with practice they'll improve!"
"""
            else:  # Very High
                context = f"""
Child's impulse control score: {score*100:.0f}% (SIGNIFICANT - needs focused work)
Quick button presses: {metrics.get('premature_taps', 0)} times
Total trials: {metrics.get('trials', 0)}

Write ONE sentence about needing significant practice, but frame it as a growth opportunity with support.
Example: "Your child tends to act quickly, and with targeted practice and support, they can build stronger impulse control."
"""
                
        elif domain_name == "Attention":
            if level == "Low":
                context = f"""
Child's attention score: {score*100:.0f}% (EXCELLENT - very focused)
Reaction consistency: {metrics.get('reaction_variability', 0):.0f}ms variability
Story focus: {(1 - metrics.get('skip_rate', 0))*100:.0f}%

Write ONE sentence celebrating their excellent focus. Keep it specific and genuine.
Example: "Your child maintained wonderful focus throughout, showing strong concentration skills!"
"""
            elif level == "Moderate":
                context = f"""
Child's attention score: {score*100:.0f}% (GOOD - generally focused)
Reaction consistency: {metrics.get('reaction_variability', 0):.0f}ms variability
Story focus: {(1 - metrics.get('skip_rate', 0))*100:.0f}%

Write ONE sentence about their good focus with a small tip for improvement. Keep it encouraging.
Example: "Your child generally stays focused, with occasional moments of distraction—totally age-appropriate!"
"""
            elif level == "High":
                context = f"""
Child's attention score: {score*100:.0f}% (NEEDS PRACTICE - some focus challenges)
Reaction consistency: {metrics.get('reaction_variability', 0):.0f}ms variability
Story focus: {(1 - metrics.get('skip_rate', 0))*100:.0f}%

Write ONE sentence about their attention needing practice, but frame it constructively.
Example: "Your child had some trouble staying focused, which is common—short activities and breaks can help build this skill."
"""
            else:  # Very High
                context = f"""
Child's attention score: {score*100:.0f}% (SIGNIFICANT - major focus challenges)
Reaction consistency: {metrics.get('reaction_variability', 0):.0f}ms variability
Story focus: {(1 - metrics.get('skip_rate', 0))*100:.0f}%

Write ONE sentence about attention challenges, but emphasize support and strategies to help.
Example: "Your child struggled to maintain focus during this activity; with structured support and breaks, focus can improve."
"""
                
        else:  # Memory/Organization
            if level == "Low":
                context = f"""
Child's organization score: {score*100:.0f}% (EXCELLENT - very organized)
Task completed: {'Yes' if metrics.get('task_completed') else 'No'}
Steps skipped: {metrics.get('steps_skipped', 0)}
Pages read: {metrics.get('pages_read', 0)}/3

Write ONE sentence celebrating their excellent planning and memory. Keep it genuine.
Example: "Your child remembered and followed all the steps perfectly—excellent organization skills!"
"""
            elif level == "Moderate":
                context = f"""
Child's organization score: {score*100:.0f}% (GOOD - generally organized)
Task completed: {'Yes' if metrics.get('task_completed') else 'No'}
Steps skipped: {metrics.get('steps_skipped', 0)}
Pages read: {metrics.get('pages_read', 0)}/3

Write ONE sentence about their good planning with room to grow. Keep it encouraging.
Example: "Your child followed most steps correctly and is building strong organizational skills."
"""
            elif level == "High":
                context = f"""
Child's organization score: {score*100:.0f}% (NEEDS PRACTICE - some organization challenges)
Task completed: {'Yes' if metrics.get('task_completed') else 'No'}
Steps skipped: {metrics.get('steps_skipped', 0)}
Pages read: {metrics.get('pages_read', 0)}/3

Write ONE sentence about organization needing practice, but frame it as learnable.
Example: "Your child had trouble remembering all the steps, which is normal—breaking tasks into smaller chunks can really help."
"""
            else:  # Very High
                context = f"""
Child's organization score: {score*100:.0f}% (SIGNIFICANT - major organization challenges)
Task completed: {'Yes' if metrics.get('task_completed') else 'No'}
Steps skipped: {metrics.get('steps_skipped', 0)}
Pages read: {metrics.get('pages_read', 0)}/3

Write ONE sentence about organization challenges, but emphasize how structure and support help.
Example: "Your child found it challenging to organize and complete multiple steps; structured checklists and visual guides can provide real support."
"""

        prompt = f"""You are writing to parents about their child's performance. Keep it POSITIVE and ENCOURAGING.
Match the performance level but never sound scary or negative. Focus on what they're learning.

{context}

Comment (exactly ONE sentence):"""

        # ✅ CHECK CACHE FIRST (Speed optimization)
        cached = get_cached_narrative(domain_name, score, level)
        if cached:
            debugPrint(f"⚡ CACHED {domain_name} ({level}): {cached[:60]}...")
            return cached

        # Call Ollama with reduced timeout for speed
        try:
            response = requests.post(
                OLLAMA_API_URL,
                json={
                    "model": "mistral",
                    "prompt": prompt,
                    "stream": False,
                    "temperature": 0.3,
                },
                timeout=45  # Reduced from 60
            )

            if response.status_code == 200:
                result = response.json()
                narrative = result.get("response", "").strip()
                
                # Clean up response
                if narrative.startswith("Comment:"):
                    narrative = narrative.replace("Comment:", "").strip()
                narrative = narrative.lstrip("- ").strip()
                
                # ✅ CACHE THE RESULT
                NARRATIVE_CACHE[cache_key(domain_name, score, level)] = narrative
                
                debugPrint(f"✅ Generated {domain_name} ({level}): {narrative[:60]}...")
                return narrative
            else:
                debugPrint(f"⚠️ Ollama error: {response.status_code}, using template fallback")
                return _fallback_narrative(domain_name, level)
        except requests.exceptions.Timeout:
            debugPrint(f"⚠️ Ollama timeout, using template fallback for {domain_name}")
            return _fallback_narrative(domain_name, level)
            
    except Exception as e:
        debugPrint(f"❌ Narrative generation failed: {e}, using template fallback")
        return _fallback_narrative(domain_name, level)

def _fallback_narrative(domain_name, level):
    """Quick template-based fallback if Ollama is slow"""
    templates = {
        ("Impulsivity", "Low"): "Your child showed excellent patience and really thought through their actions!",
        ("Impulsivity", "Moderate"): "Your child shows good impulse control, with just occasional quick reactions as they're learning.",
        ("Impulsivity", "High"): "Your child is still learning to pause before acting, which is normal—with practice they'll improve!",
        ("Impulsivity", "Very High"): "Your child tends to act quickly; with targeted practice and support, they can build stronger impulse control.",
        
        ("Attention", "Low"): "Your child maintained wonderful focus throughout, showing strong concentration skills!",
        ("Attention", "Moderate"): "Your child generally stays focused, with occasional moments of distraction—totally age-appropriate!",
        ("Attention", "High"): "Your child had some trouble staying focused; short activities and breaks can help build this skill.",
        ("Attention", "Very High"): "Your child struggled with focus; with structured support and breaks, attention can improve significantly.",
        
        ("Memory/Organization", "Low"): "Your child remembered and followed all the steps perfectly—excellent organization skills!",
        ("Memory/Organization", "Moderate"): "Your child followed most steps correctly and is building strong organizational skills.",
        ("Memory/Organization", "High"): "Your child had some trouble remembering steps; breaking tasks into smaller chunks really helps.",
        ("Memory/Organization", "Very High"): "Your child struggled organizing multiple steps; visual checklists and support will make a big difference.",
    }
    return templates.get((domain_name, level), "Your child participated in the assessment!")

def debugPrint(msg):
    """Print debug message (compatibility with Flask logging)"""
    print(f"[AI] {msg}")

# ════════════════════════════════════════════════════════════════
# 🤖 ML PREDICTION FUNCTION
# ════════════════════════════════════════════════════════════════

def predict_ml_profile(impulsivity, attention, memory_org, reaction_speed, 
                       reaction_variability, skip_rate, task_completion_rate, avg_accuracy):
    """
    Use ML model to predict behavioral profile
    
    Returns:
        {
            'profile': 'ADHD-Like',
            'confidence': 0.92,
            'probabilities': {...},
            'risk_level': 'High'
        }
    """
    if ML_MODEL is None or ML_SCALER is None:
        return None
    
    try:
        # Normalize reaction times
        reaction_speed_norm = max(0.0, min(1.0, (reaction_speed - 200) / 300))
        reaction_var_norm = max(0.0, min(1.0, reaction_variability / 200))
        
        # Create feature vector
        features = np.array([[
            impulsivity,
            attention,
            memory_org,
            reaction_speed_norm,
            reaction_var_norm,
            skip_rate,
            task_completion_rate,
            avg_accuracy
        ]])
        
        # Scale
        features_scaled = ML_SCALER.transform(features)
        
        # Predict
        profile = ML_MODEL.predict(features_scaled)[0]
        probabilities = ML_MODEL.predict_proba(features_scaled)[0]
        confidence = probabilities.max()
        
        # Get probability distribution
        prob_dict = {
            profile_class: float(prob)
            for profile_class, prob in zip(ML_PROFILE_CLASSES, probabilities)
        }
        
        # Get risk level
        risk_levels = {
            'Normal': 'Low',
            'Gifted': 'Low',
            'Mixed-Profile': 'Moderate',
            'Learning-Disability': 'Moderate',
            'ADHD-Like': 'High'
        }
        risk_level = risk_levels.get(profile, 'Unknown')
        
        debugPrint(f"🤖 ML Prediction: {profile} (Confidence: {confidence:.1%})")
        
        return {
            'profile': profile,
            'confidence': float(confidence),
            'probabilities': prob_dict,
            'risk_level': risk_level
        }
    
    except Exception as e:
        debugPrint(f"⚠️ ML prediction error: {e}")
        return None

# ════════════════════════════════════════════════════════════════
# �🧠 ENHANCED AI: COGNITIVE PROFILE ANALYSIS
# Maps game metrics to attention, impulsivity, and memory/organization
# ════════════════════════════════════════════════════════════════

def clamp(value, min_val=0, max_val=1):
    return max(min(value, max_val), min_val)

def get_severity_level(score):
    """Convert 0-1 score to severity level"""
    if score < 0.25:
        return "Low"
    elif score < 0.5:
        return "Moderate"
    elif score < 0.75:
        return "High"
    else:
        return "Very High"

# ────────────────────── DOMAIN 1: IMPULSIVITY ──────────────────────
def calculate_impulsivity(wait_game_data, step_game_data):
    """
    Impulsivity from:
    - Game 1: premature_taps (acting without thinking)
    - Game 3: order_errors (rushing through without planning)
    """
    wait_trials = max(wait_game_data.get("total_trials", 1), 1)
    wait_premature_rate = wait_game_data.get("premature_taps", 0) / wait_trials
    
    # Normalize to 0-1 scale
    wait_impulsivity = clamp(wait_premature_rate / 0.5)
    
    # Step game impulsivity: more errors = rushed/impulsive
    step_errors = step_game_data.get("order_errors", 0)
    step_impulsivity = clamp(step_errors / 4)  # 4+ errors = very impulsive
    
    # Weighted average (wait game is more direct measure)
    impulsivity_score = (wait_impulsivity * 0.7) + (step_impulsivity * 0.3)
    
    return clamp(impulsivity_score)

# ────────────────────── DOMAIN 2: ATTENTION ──────────────────────
def calculate_attention(wait_game_data, story_game_data):
    """
    Attention from:
    - Game 1: attention_variability (consistency of focus)
    - Game 2: skip_rate (focused reading vs skipping)
    
    NOTE: Returns score where HIGH = POOR attention (consistent with Impulsivity scale)
    """
    # Game 1: Higher variability = poor attention
    reaction_variability = wait_game_data.get("reaction_variability", 0)
    attention_problems_1 = clamp(reaction_variability / 200)
    
    # Game 2: High skip rate = poor attention
    skip_rate = story_game_data.get("skip_rate", 0)
    attention_problems_2 = clamp(skip_rate)
    
    # Weighted average (HIGH SCORE = PROBLEM)
    attention_score = (attention_problems_1 * 0.5) + (attention_problems_2 * 0.5)
    
    return clamp(attention_score)

# ────────────────────── DOMAIN 3: MEMORY & ORGANIZATION ──────────────────────
def calculate_memory_organization(step_game_data, story_game_data):
    """
    Memory/Organization from:
    - Game 3: task_completed (can remember sequence), steps_skipped
    - Game 2: pages_read (task completion)
    
    NOTE: Returns score where HIGH = POOR organization (consistent with Impulsivity scale)
    """
    # Game 3: Task completion is key indicator
    task_completed = step_game_data.get("task_completed", False)
    steps_skipped = step_game_data.get("steps_skipped", 0)
    
    # Convert to score: completed=low problem, skipped=high problem
    if task_completed:
        org_problem = 0.1  # Successfully completed = low problem score
    else:
        org_problem = clamp(steps_skipped / 3)  # More steps skipped = more problems
    
    # Game 2: Reading completion as secondary indicator
    pages_read = story_game_data.get("pages_read", 0)
    pages_problem = clamp(1 - (pages_read / 3))  # Fewer pages = more problem
    
    # Weighted average (HIGH SCORE = PROBLEM)
    memory_org_score = (org_problem * 0.7) + (pages_problem * 0.3)
    
    return clamp(memory_org_score)

# ────────────────────── COGNITIVE PROFILE GENERATOR ──────────────────────
def generate_cognitive_profile(wait_game_data, story_game_data, step_game_data):
    """
    Generate comprehensive cognitive profile with conclusions
    """
    # Calculate scores for each domain
    impulsivity = calculate_impulsivity(wait_game_data, step_game_data)
    attention = calculate_attention(wait_game_data, story_game_data)
    memory_org = calculate_memory_organization(step_game_data, story_game_data)
    
    # Get severity levels
    impulsivity_level = get_severity_level(impulsivity)
    attention_level = get_severity_level(attention)
    memory_level = get_severity_level(memory_org)
    
    # Generate AI-powered conclusions using Ollama
    impulsivity_conclusion = generate_narrative_conclusion(
        "Impulsivity",
        impulsivity,
        impulsivity_level,
        {
            "premature_taps": wait_game_data.get('premature_taps', 0),
            "order_errors": step_game_data.get('order_errors', 0),
            "trials": wait_game_data.get('total_trials', 1),
        }
    )
    
    attention_conclusion = generate_narrative_conclusion(
        "Attention",
        attention,
        attention_level,
        {
            "reaction_variability": wait_game_data.get('reaction_variability', 0),
            "skip_rate": story_game_data.get('skip_rate', 0),
            "pages_read": story_game_data.get('pages_read', 0),
        }
    )
    
    memory_org_conclusion = generate_narrative_conclusion(
        "Memory/Organization",
        memory_org,
        memory_level,
        {
            "task_completed": step_game_data.get('task_completed', False),
            "steps_skipped": step_game_data.get('steps_skipped', 0),
            "order_errors": step_game_data.get('order_errors', 0),
            "pages_read": story_game_data.get('pages_read', 0),
        }
    )
    
    # Fallback to template if Ollama fails
    if not impulsivity_conclusion:
        impulsivity_conclusion = _conclude_impulsivity(impulsivity, impulsivity_level)
    if not attention_conclusion:
        attention_conclusion = _conclude_attention(attention, attention_level)
    if not memory_org_conclusion:
        memory_org_conclusion = _conclude_memory_org(memory_org, memory_level, step_game_data)
    
    # Generate conclusions based on patterns
    conclusions = {
        "impulsivity": {
            "score": round(impulsivity, 3),
            "level": impulsivity_level,
            "conclusion": impulsivity_conclusion,
            "evidence": [
                f"Premature taps in Wait game: {wait_game_data.get('premature_taps', 0)}",
                f"Order errors in Step Builder: {step_game_data.get('order_errors', 0)}"
            ]
        },
        "attention": {
            "score": round(attention, 3),
            "level": attention_level,
            "conclusion": attention_conclusion,
            "evidence": [
                f"Reaction variability: {wait_game_data.get('reaction_variability', 0):.0f}ms",
                f"Story skip rate: {story_game_data.get('skip_rate', 0):.1%}"
            ]
        },
        "memory_organization": {
            "score": round(memory_org, 3),
            "level": memory_level,
            "conclusion": memory_org_conclusion,
            "evidence": [
                f"Step Builder completed: {'✅ Yes' if step_game_data.get('task_completed') else '❌ No'}",
                f"Steps skipped: {step_game_data.get('steps_skipped', 0)}",
                f"Pages read: {story_game_data.get('pages_read', 0)}/3"
            ]
        }
    }
    
    # Overall assessment
    overall_score = (impulsivity + attention + memory_org) / 3
    
    return {
        "cognitive_profile": conclusions,
        "overall_score": round(overall_score, 3),
        "overall_level": get_severity_level(overall_score),
        "recommendation": _generate_recommendation(impulsivity, attention, memory_org)
    }

# ────────────────────── CONCLUSION GENERATORS ──────────────────────
def _conclude_impulsivity(score, level):
    """Generate conclusion about impulsivity"""
    if level == "Very High":
        return "User shows very high impulsivity - acts without thinking, makes quick errors without considering consequences"
    elif level == "High":
        return "User shows high impulsivity - tends to act quickly, may skip planning steps"
    elif level == "Moderate":
        return "User shows moderate impulsivity - generally controlled but occasional hasty decisions"
    else:
        return "User shows low impulsivity - demonstrates strong impulse control and deliberate decision-making"

def _conclude_attention(score, level):
    """Generate conclusion about attention"""
    if level == "Very High":
        return "User has very poor attention - highly inconsistent focus, frequently distracted"
    elif level == "High":
        return "User has poor attention - struggles to maintain focus, skips significant portions of tasks"
    elif level == "Moderate":
        return "User has moderate attention - can focus but occasional lapses in concentration"
    else:
        return "User has strong attention - maintains consistent focus, completes tasks thoroughly"

def _conclude_memory_org(score, level, step_data):
    """Generate conclusion about memory and organization"""
    if level == "Very High":
        return "User has excellent memory and organization - can recall sequences and complete complex tasks systematically"
    elif level == "High":
        return "User has good memory and organization - generally remembers instructions and follows procedures"
    elif level == "Moderate":
        return "User has moderate memory and organization - can follow some procedures but may miss steps"
    else:
        return "User has poor memory and organization - struggles to remember sequences or complete structured tasks"

def _generate_recommendation(impulsivity, attention, memory_org):
    """Generate personalized recommendations"""
    issues = []
    
    if impulsivity > 0.6:
        issues.append("High impulsivity detected - recommend impulse control strategies (e.g., stop-and-think exercises)")
    
    if attention < 0.4:
        issues.append("Attention challenges detected - recommend focus training and minimal distractions")
    
    if memory_org < 0.4:
        issues.append("Organization difficulties detected - recommend structured task breakdowns and visual aids")
    
    if not issues:
        return "User shows strong cognitive performance across all domains"
    
    return " | ".join(issues)

# ────────────────────── OLD BEHAVIOR ANALYSIS (kept for compatibility) ──────────────────────
def analyze_behavior(data):
    trials = max(data.get("trials", 1), 1)
    premature_rate = data.get("premature_taps", 0) / trials

    scores = {
        "impulsivity": clamp(premature_rate / 0.5),
        "reaction_speed": clamp((data.get("avg_reaction", 0) - 250) / 300),
        "attention_variability": clamp(data.get("reaction_variability", 0) / 200)
    }

    # Pattern classification
    if scores["impulsivity"] > 0.6 and scores["attention_variability"] > 0.6:
        pattern = "High impulsivity, fluctuating attention"
    elif scores["reaction_speed"] > 0.6:
        pattern = "Slow but controlled responses"
    elif scores["impulsivity"] < 0.3 and scores["attention_variability"] < 0.3:
        pattern = "Strong impulse control and stable attention"
    else:
        pattern = "Moderate attention and impulse control"

    return scores, pattern

# ────────────────────── API ENDPOINT: ANALYZE (Legacy) ──────────────────────
@app.route("/analyze", methods=["POST"])
def analyze():
    data = request.get_json()
    scores, pattern = analyze_behavior(data)

    response = {
        "status": "success",
        "behavior_scores": scores,
        "pattern_summary": pattern
    }

    print("🧠 AI Analysis:", response)
    return jsonify(response)

# ════════════════════════════════════════════════════════════════
# NEW: SAVE COMPLETE SESSION DATA
# ════════════════════════════════════════════════════════════════
@app.route("/save_session", methods=["POST"])
def save_session():
    """Save complete assessment session data with enhanced cognitive profiling"""
    try:
        data = request.get_json()
        
        session_id = data.get("session_id")
        age_group = data.get("age_group")
        session_start = data.get("session_start")
        session_end = data.get("session_end")
        total_duration = data.get("total_duration_seconds")

        wait_game = data.get("wait_for_your_turn", {})
        story_game = data.get("story_reading", {})
        step_game = data.get("step_builder", {})

        # ──── Generate Enhanced Cognitive Profile (Rule-Based) ────
        cognitive_profile = generate_cognitive_profile(wait_game, story_game, step_game)
        
        # ──── ML PREDICTION (AI-Based) ────
        ml_prediction = None
        if ML_MODEL is not None:
            ml_prediction = predict_ml_profile(
                impulsivity=cognitive_profile["cognitive_profile"]["impulsivity"]["score"],
                attention=cognitive_profile["cognitive_profile"]["attention"]["score"],
                memory_org=cognitive_profile["cognitive_profile"]["memory_organization"]["score"],
                reaction_speed=wait_game.get("avg_reaction", 350),
                reaction_variability=wait_game.get("reaction_variability", 0),
                skip_rate=story_game.get("skip_rate", 0),
                task_completion_rate=1.0 if step_game.get("task_completed", False) else 0.5,
                avg_accuracy=1.0 - cognitive_profile["cognitive_profile"]["memory_organization"]["score"]
            )
            
            # Add ML prediction to cognitive profile
            if ml_prediction:
                cognitive_profile["ml_prediction"] = ml_prediction

        # ──── Create Analysis Summary ────
        analysis_scores = {
            "cognitive_profile": cognitive_profile["cognitive_profile"],
            "overall_score": cognitive_profile["overall_score"],
            "overall_level": cognitive_profile["overall_level"],
            "recommendation": cognitive_profile["recommendation"],
        }
        
        if ml_prediction:
            analysis_scores["ml_profile"] = ml_prediction

        # ──── Save to Database ────
        conn = sqlite3.connect(DATABASE)
        c = conn.cursor()

        c.execute('''
            INSERT INTO sessions 
            (session_id, age_group, session_start, session_end, total_duration_seconds, 
             wait_game_data, story_game_data, analysis_scores)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            session_id,
            age_group,
            session_start,
            session_end,
            total_duration,
            json.dumps(wait_game),
            json.dumps(story_game),
            json.dumps(analysis_scores),
        ))

        conn.commit()
        conn.close()

        response = {
            "status": "success",
            "message": "Session saved successfully with cognitive analysis",
            "session_id": session_id,
            "cognitive_profile": cognitive_profile,
        }

        print(f"✅ Session saved: {session_id}")
        print(f"🧠 Cognitive Profile (Rule-Based):")
        print(f"   Impulsivity: {cognitive_profile['cognitive_profile']['impulsivity']['level']}")
        print(f"   Attention: {cognitive_profile['cognitive_profile']['attention']['level']}")
        print(f"   Memory/Org: {cognitive_profile['cognitive_profile']['memory_organization']['level']}")
        print(f"   Overall: {cognitive_profile['overall_level']}")
        
        if ml_prediction:
            print(f"\n🤖 ML Prediction (AI-Based):")
            print(f"   Profile: {ml_prediction['profile']}")
            print(f"   Confidence: {ml_prediction['confidence']:.1%}")
            print(f"   Risk Level: {ml_prediction['risk_level']}")
            print(f"   Top Probability: {max(ml_prediction['probabilities'].values()):.1%}")


        return jsonify(response), 200

    except Exception as e:
        print(f"❌ Error saving session: {e}")
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

# ════════════════════════════════════════════════════════════════
# GET ALL SESSIONS (FOR ADMIN/REVIEW)
# ════════════════════════════════════════════════════════════════
@app.route("/get_sessions", methods=["GET"])
def get_sessions():
    """Retrieve all saved sessions"""
    try:
        conn = sqlite3.connect(DATABASE)
        c = conn.cursor()

        c.execute('''
            SELECT session_id, age_group, session_start, session_end, 
                   total_duration_seconds, created_at 
            FROM sessions 
            ORDER BY created_at DESC
        ''')

        sessions = []
        for row in c.fetchall():
            sessions.append({
                "session_id": row[0],
                "age_group": row[1],
                "start": row[2],
                "end": row[3],
                "duration_seconds": row[4],
                "saved_at": row[5],
            })

        conn.close()

        return jsonify({
            "status": "success",
            "total_sessions": len(sessions),
            "sessions": sessions
        }), 200

    except Exception as e:
        print(f"❌ Error retrieving sessions: {e}")
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

# ════════════════════════════════════════════════════════════════
# GET SINGLE SESSION DETAILS
# ════════════════════════════════════════════════════════════════
@app.route("/get_session/<session_id>", methods=["GET"])
def get_session(session_id):
    """Retrieve specific session data"""
    try:
        conn = sqlite3.connect(DATABASE)
        c = conn.cursor()

        c.execute('''
            SELECT session_id, age_group, session_start, session_end,
                   total_duration_seconds, wait_game_data, story_game_data, 
                   analysis_scores, created_at
            FROM sessions 
            WHERE session_id = ?
        ''', (session_id,))

        row = c.fetchone()
        conn.close()

        if not row:
            return jsonify({
                "status": "error",
                "message": "Session not found"
            }), 404

        return jsonify({
            "status": "success",
            "session": {
                "session_id": row[0],
                "age_group": row[1],
                "start": row[2],
                "end": row[3],
                "duration_seconds": row[4],
                "wait_game": json.loads(row[5]),
                "story_game": json.loads(row[6]),
                "analysis": json.loads(row[7]),
                "saved_at": row[8],
            }
        }), 200

    except Exception as e:
        print(f"❌ Error retrieving session: {e}")
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

@app.route("/")
def home():
    model_status = "✅ Loaded" if ML_MODEL else "⚠️ Not loaded"
    return jsonify({
        "status": "running",
        "version": "2.0",
        "ml_status": model_status,
        "features": [
            "/analyze - Legacy endpoint",
            "/save_session - Save complete session with ML prediction",
            "/get_sessions - Get all sessions",
            "/get_session/<id> - Get session details",
        ]
    })

if __name__ == "__main__":
    # Load ML model on startup
    print("="*60)
    print("🚀 Starting MindImprint Backend")
    print("="*60)
    load_ml_model()
    print()
    app.run(debug=True)

