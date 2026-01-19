"""
🎲 Synthetic Data Generator for MindImprint ML Model Training
Generates realistic behavioral profiles for ML training
"""

import numpy as np
import pandas as pd
import json
from datetime import datetime

class SyntheticProfileGenerator:
    """Generate synthetic ADHD assessment profiles with realistic correlations"""
    
    def __init__(self, random_seed=42):
        np.random.seed(random_seed)
        
    def generate_normal_profile(self):
        """Generate a normal child profile (40% of population)"""
        # Normal children: LOW scores on problem indicators
        return {
            'impulsivity': np.random.normal(0.20, 0.12),           # Low
            'attention': np.random.normal(0.15, 0.10),             # Good
            'memory_org': np.random.normal(0.18, 0.10),            # Good
            'reaction_speed': np.random.normal(350, 40),           # Normal
            'reaction_variability': np.random.normal(70, 20),      # Stable
            'skip_rate': np.random.normal(0.1, 0.08),              # Minimal skipping
            'task_completion_rate': np.random.normal(0.95, 0.05),  # Usually completes
            'avg_accuracy': np.random.normal(0.88, 0.08),          # Good accuracy
            'profile': 'Normal',
            'severity': 'Low'
        }
    
    def generate_adhd_profile(self):
        """Generate ADHD-like profile (30% of population)"""
        # ADHD: HIGH impulsivity, LOW attention, LOW organization
        impulsivity_score = np.random.normal(0.72, 0.12)
        attention_score = np.random.normal(0.68, 0.12)
        org_score = np.random.normal(0.65, 0.12)
        
        return {
            'impulsivity': impulsivity_score,                       # HIGH
            'attention': attention_score,                           # POOR
            'memory_org': org_score,                                # POOR
            'reaction_speed': np.random.normal(280, 80),           # Fast & inconsistent
            'reaction_variability': np.random.normal(140, 30),     # Highly variable
            'skip_rate': np.random.normal(0.50, 0.15),             # Often rushes
            'task_completion_rate': np.random.normal(0.55, 0.20),  # Often incomplete
            'avg_accuracy': np.random.normal(0.62, 0.15),          # More errors
            'profile': 'ADHD-Like',
            'severity': 'High'
        }
    
    def generate_learning_disabled_profile(self):
        """Generate learning/processing disability profile (15% of population)"""
        # Low reaction speed but normal impulse control
        return {
            'impulsivity': np.random.normal(0.30, 0.12),           # Normal
            'attention': np.random.normal(0.58, 0.12),             # Challenged
            'memory_org': np.random.normal(0.35, 0.12),            # Some issues
            'reaction_speed': np.random.normal(450, 50),           # Slow processing
            'reaction_variability': np.random.normal(95, 25),      # Moderate variability
            'skip_rate': np.random.normal(0.35, 0.12),             # Some skipping
            'task_completion_rate': np.random.normal(0.72, 0.18),  # Partially complete
            'avg_accuracy': np.random.normal(0.65, 0.15),          # Lower accuracy
            'profile': 'Learning-Disability',
            'severity': 'Moderate'
        }
    
    def generate_gifted_profile(self):
        """Generate gifted/high-performing profile (15% of population)"""
        # Can have high impulsivity (creativity, energy) but excellent attention & org
        return {
            'impulsivity': np.random.normal(0.55, 0.12),           # Moderate-High (active)
            'attention': np.random.normal(0.12, 0.08),             # EXCELLENT
            'memory_org': np.random.normal(0.08, 0.06),            # EXCELLENT
            'reaction_speed': np.random.normal(240, 30),           # Very fast
            'reaction_variability': np.random.normal(45, 15),      # Very consistent
            'skip_rate': np.random.normal(0.05, 0.06),             # Rarely skips
            'task_completion_rate': np.random.normal(0.98, 0.02),  # Always completes
            'avg_accuracy': np.random.normal(0.94, 0.04),          # Excellent accuracy
            'profile': 'Gifted',
            'severity': 'Low'
        }
    
    def generate_mixed_profile(self):
        """Generate mixed/atypical profile (variable percentage)"""
        # High attention but also high impulsivity - possible giftedness + ADHD
        return {
            'impulsivity': np.random.normal(0.65, 0.12),           # High (active)
            'attention': np.random.normal(0.25, 0.12),             # Good (not gifted)
            'memory_org': np.random.normal(0.40, 0.12),            # Moderate
            'reaction_speed': np.random.normal(300, 60),           # Normal
            'reaction_variability': np.random.normal(80, 25),      # Moderate variability
            'skip_rate': np.random.normal(0.25, 0.15),             # Sometimes rushes
            'task_completion_rate': np.random.normal(0.75, 0.20),  # Variable completion
            'avg_accuracy': np.random.normal(0.72, 0.12),          # Mixed accuracy
            'profile': 'Mixed-Profile',
            'severity': 'Moderate'
        }
    
    def generate_dataset(self, n_samples=10000):
        """Generate full synthetic dataset with realistic distribution"""
        profiles = []
        
        # Distribution percentages
        normal_count = int(n_samples * 0.40)
        adhd_count = int(n_samples * 0.30)
        learning_count = int(n_samples * 0.15)
        gifted_count = int(n_samples * 0.10)
        mixed_count = int(n_samples * 0.05)
        
        print(f"🎲 Generating {n_samples} synthetic profiles...")
        print(f"   Normal: {normal_count} (40%)")
        print(f"   ADHD-Like: {adhd_count} (30%)")
        print(f"   Learning Disabled: {learning_count} (15%)")
        print(f"   Gifted: {gifted_count} (10%)")
        print(f"   Mixed: {mixed_count} (5%)")
        
        # Generate each profile type
        for _ in range(normal_count):
            profiles.append(self.generate_normal_profile())
        
        for _ in range(adhd_count):
            profiles.append(self.generate_adhd_profile())
        
        for _ in range(learning_count):
            profiles.append(self.generate_learning_disabled_profile())
        
        for _ in range(gifted_count):
            profiles.append(self.generate_gifted_profile())
        
        for _ in range(mixed_count):
            profiles.append(self.generate_mixed_profile())
        
        # Shuffle
        np.random.shuffle(profiles)
        
        # Clamp values to valid ranges
        for profile in profiles:
            for key in ['impulsivity', 'attention', 'memory_org', 'skip_rate', 
                       'task_completion_rate', 'avg_accuracy']:
                profile[key] = max(0.0, min(1.0, profile[key]))
        
        print(f"✅ Generated {len(profiles)} profiles successfully\n")
        
        return profiles

def save_dataset(profiles, filename='synthetic_data.json'):
    """Save dataset to JSON file"""
    with open(filename, 'w') as f:
        json.dump(profiles, f, indent=2)
    print(f"💾 Dataset saved to {filename}")

def load_dataset(filename='synthetic_data.json'):
    """Load dataset from JSON file"""
    with open(filename, 'r') as f:
        return json.load(f)

if __name__ == "__main__":
    # Generate and save dataset
    generator = SyntheticProfileGenerator()
    profiles = generator.generate_dataset(n_samples=10000)
    save_dataset(profiles)
    
    # Display sample profiles
    print("📊 Sample Profiles:\n")
    for i, profile in enumerate(profiles[:5]):
        print(f"{i+1}. {profile['profile']} (Severity: {profile['severity']})")
        print(f"   Impulsivity: {profile['impulsivity']:.3f}")
        print(f"   Attention: {profile['attention']:.3f}")
        print(f"   Memory/Org: {profile['memory_org']:.3f}")
        print()
