"""
🤖 ML Model Trainer for MindImprint
Trains Random Forest on synthetic data and saves the model
"""

import numpy as np
import pandas as pd
import pickle
import json
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from synthetic_data_generator import SyntheticProfileGenerator

class BehavioralProfileClassifier:
    """ML-based classifier for behavioral profiles"""
    
    def __init__(self):
        self.model = None
        self.scaler = None
        self.feature_names = [
            'impulsivity',
            'attention',
            'memory_org',
            'reaction_speed_normalized',
            'reaction_variability_normalized',
            'skip_rate',
            'task_completion_rate',
            'avg_accuracy'
        ]
        self.profile_classes = ['Normal', 'ADHD-Like', 'Learning-Disability', 'Gifted', 'Mixed-Profile']
    
    def prepare_data(self, profiles):
        """Convert profiles to feature matrix and labels"""
        X = []
        y = []
        
        for profile in profiles:
            # Normalize reaction_speed (350ms is baseline)
            reaction_speed_norm = max(0.0, min(1.0, (profile['reaction_speed'] - 200) / 300))
            # Normalize reaction_variability (100ms is baseline)
            reaction_var_norm = max(0.0, min(1.0, profile['reaction_variability'] / 200))
            
            features = [
                profile['impulsivity'],
                profile['attention'],
                profile['memory_org'],
                reaction_speed_norm,
                reaction_var_norm,
                profile['skip_rate'],
                profile['task_completion_rate'],
                profile['avg_accuracy']
            ]
            
            X.append(features)
            y.append(profile['profile'])
        
        return np.array(X), np.array(y)
    
    def train(self, profiles, test_size=0.2, random_state=42):
        """Train Random Forest classifier"""
        print("🎯 Training Behavioral Profile Classifier...\n")
        
        # Prepare data
        X, y = self.prepare_data(profiles)
        print(f"📊 Dataset: {X.shape[0]} samples, {X.shape[1]} features")
        print(f"   Profile distribution: {np.unique(y, return_counts=True)}")
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=test_size, random_state=random_state, stratify=y
        )
        
        # Scale features
        self.scaler = StandardScaler()
        X_train_scaled = self.scaler.fit_transform(X_train)
        X_test_scaled = self.scaler.transform(X_test)
        
        # Train Random Forest
        print("\n🌲 Training Random Forest...")
        self.model = RandomForestClassifier(
            n_estimators=200,
            max_depth=15,
            min_samples_split=10,
            min_samples_leaf=5,
            random_state=random_state,
            n_jobs=-1,
            class_weight='balanced'
        )
        
        self.model.fit(X_train_scaled, y_train)
        
        # Evaluate
        print("📈 Evaluating model...")
        y_pred = self.model.predict(X_test_scaled)
        accuracy = accuracy_score(y_test, y_pred)
        
        print(f"\n✅ Model Accuracy: {accuracy:.1%}")
        print("\nClassification Report:")
        print(classification_report(y_test, y_pred))
        
        print("\nConfusion Matrix:")
        cm = confusion_matrix(y_test, y_pred)
        print(cm)
        
        # Feature importance
        self._print_feature_importance()
        
        return accuracy
    
    def _print_feature_importance(self):
        """Print feature importance"""
        print("\n🎯 Feature Importance:")
        importances = self.model.feature_importances_
        sorted_idx = np.argsort(importances)[::-1]
        
        for idx in sorted_idx:
            feature = self.feature_names[idx]
            importance = importances[idx]
            bar = "█" * int(importance * 50)
            print(f"   {feature:30s} {importance:.3f} {bar}")
    
    def predict(self, features_dict):
        """
        Predict profile for a child
        
        Args:
            features_dict: {
                'impulsivity': 0.45,
                'attention': 0.62,
                'memory_org': 0.35,
                'reaction_speed': 380,
                'reaction_variability': 85,
                'skip_rate': 0.33,
                'task_completion_rate': 0.75,
                'avg_accuracy': 0.72
            }
        
        Returns:
            {
                'profile': 'ADHD-Like',
                'confidence': 0.92,
                'probabilities': {...},
                'interpretation': '...'
            }
        """
        if self.model is None:
            raise ValueError("Model not trained yet. Call train() first.")
        
        # Normalize reaction times
        reaction_speed_norm = max(0.0, min(1.0, (features_dict['reaction_speed'] - 200) / 300))
        reaction_var_norm = max(0.0, min(1.0, features_dict['reaction_variability'] / 200))
        
        features = np.array([[
            features_dict['impulsivity'],
            features_dict['attention'],
            features_dict['memory_org'],
            reaction_speed_norm,
            reaction_var_norm,
            features_dict['skip_rate'],
            features_dict['task_completion_rate'],
            features_dict['avg_accuracy']
        ]])
        
        # Scale
        features_scaled = self.scaler.transform(features)
        
        # Predict
        profile = self.model.predict(features_scaled)[0]
        probabilities = self.model.predict_proba(features_scaled)[0]
        confidence = probabilities.max()
        
        # Get probability distribution
        prob_dict = {
            profile_class: float(prob)
            for profile_class, prob in zip(self.profile_classes, probabilities)
        }
        
        # Generate interpretation
        interpretation = self._generate_interpretation(profile, prob_dict, features_dict)
        
        return {
            'profile': profile,
            'confidence': float(confidence),
            'probabilities': prob_dict,
            'interpretation': interpretation,
            'risk_level': self._get_risk_level(profile)
        }
    
    def _generate_interpretation(self, profile, probabilities, features):
        """Generate human-readable interpretation"""
        impulsivity = features['impulsivity']
        attention = features['attention']
        memory_org = features['memory_org']
        
        if profile == 'ADHD-Like':
            return "High impulsivity and attention challenges detected. Recommend structured support and professional evaluation."
        elif profile == 'Gifted':
            return "Strong focus and organization with high energy levels. Child shows excellent performance across metrics."
        elif profile == 'Learning-Disability':
            return "Processing speed concerns detected. Child may benefit from extended time and visual supports."
        elif profile == 'Normal':
            return "Profile shows typical development across all cognitive domains. Continue monitoring."
        elif profile == 'Mixed-Profile':
            return "Mixed profile detected. Further assessment recommended to clarify strengths and challenges."
        else:
            return f"Profile: {profile}"
    
    def _get_risk_level(self, profile):
        """Get risk level for intervention"""
        risk_levels = {
            'Normal': 'Low',
            'Gifted': 'Low',
            'Mixed-Profile': 'Moderate',
            'Learning-Disability': 'Moderate',
            'ADHD-Like': 'High'
        }
        return risk_levels.get(profile, 'Unknown')
    
    def save(self, model_path='behavioral_model.pkl', scaler_path='feature_scaler.pkl'):
        """Save trained model and scaler"""
        if self.model is None:
            raise ValueError("No model to save. Train first.")
        
        with open(model_path, 'wb') as f:
            pickle.dump(self.model, f)
        print(f"💾 Model saved to {model_path}")
        
        with open(scaler_path, 'wb') as f:
            pickle.dump(self.scaler, f)
        print(f"💾 Scaler saved to {scaler_path}")
    
    @staticmethod
    def load(model_path='behavioral_model.pkl', scaler_path='feature_scaler.pkl'):
        """Load trained model and scaler"""
        classifier = BehavioralProfileClassifier()
        
        with open(model_path, 'rb') as f:
            classifier.model = pickle.load(f)
        
        with open(scaler_path, 'rb') as f:
            classifier.scaler = pickle.load(f)
        
        print(f"✅ Model loaded from {model_path}")
        return classifier

def train_and_save_model():
    """Generate data, train model, and save it"""
    
    # Generate synthetic data
    generator = SyntheticProfileGenerator()
    profiles = generator.generate_dataset(n_samples=10000)
    
    # Train classifier
    classifier = BehavioralProfileClassifier()
    accuracy = classifier.train(profiles)
    
    # Save model
    classifier.save()
    
    return classifier, accuracy

if __name__ == "__main__":
    print("="*60)
    print("🤖 MindImprint ML Model Training")
    print("="*60 + "\n")
    
    classifier, accuracy = train_and_save_model()
    
    print("\n" + "="*60)
    print("✅ Training Complete!")
    print("="*60)
    print(f"Model Accuracy: {accuracy:.1%}")
    print("Files saved:")
    print("  - behavioral_model.pkl")
    print("  - feature_scaler.pkl")
    print("  - synthetic_data.json")
