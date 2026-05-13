"""
train.py — Entraînement avec Multimodal Sports Injury Dataset
Version corrigée avec ACL_Risk_Score et support réentraînement
"""

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from imblearn.over_sampling import SMOTE
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.metrics import accuracy_score, classification_report
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.impute import SimpleImputer
import joblib
import os
import json
import argparse
from pathlib import Path

os.makedirs("model", exist_ok=True)
le = LabelEncoder()
scaler = StandardScaler()
imputer = SimpleImputer(strategy='median')

parser = argparse.ArgumentParser()
parser.add_argument("--retrain", action="store_true", help="Mode réentraînement")
parser.add_argument("--use-feedback", action="store_true", help="Utiliser les feedbacks")
args = parser.parse_args()

# ═══════════════════════════════════════════════════════════════
# MODÈLE 1 — FATIGUE
# ═══════════════════════════════════════════════════════════════

print("📊 Chargement des données fatigue...")
df_fatigue = pd.read_csv("data/exercise_dataset.csv")
df_fatigue["Gender"] = le.fit_transform(df_fatigue["Gender"])
df_fatigue = df_fatigue.dropna(subset=["Heart Rate", "Exercise Intensity", "Duration", "BMI", "Age"])

df_fatigue["fatigue"] = (df_fatigue["Heart Rate"] > df_fatigue["Heart Rate"].quantile(0.75)).astype(int)

print("=== FATIGUE — distribution labels ===")
print(df_fatigue["fatigue"].value_counts())

df_fatigue["WeightLifted"] = df_fatigue.get("Calories_Burned", pd.Series([50]*len(df_fatigue))) / 10
df_fatigue["Intensity"] = df_fatigue["Exercise Intensity"]
df_fatigue["HasCardio"] = (df_fatigue["Exercise Intensity"] >= 6).astype(int)
df_fatigue["CardioDurationMinutes"] = df_fatigue["Duration"] * df_fatigue["HasCardio"] * 0.3
df_fatigue["CardioIntensity"] = df_fatigue["Exercise Intensity"] * df_fatigue["HasCardio"]
df_fatigue["MuscleRiskScore"] = np.random.uniform(1, 3, len(df_fatigue))
df_fatigue["RecoveryDaysPerWeek"] = np.random.randint(1, 4, len(df_fatigue))
df_fatigue["TotalDuration"] = df_fatigue["Duration"] + df_fatigue["CardioDurationMinutes"]

FATIGUE_FEATURES = [
    "Duration", "TotalDuration", "BMI", "Age", "Gender",
    "WeightLifted", "Intensity", "HasCardio",
    "CardioDurationMinutes", "CardioIntensity",
    "MuscleRiskScore", "RecoveryDaysPerWeek",
]

X_fatigue = df_fatigue[FATIGUE_FEATURES]
y_fatigue = df_fatigue["fatigue"]

smote = SMOTE(random_state=42, sampling_strategy=1.0)
X_fat_res, y_fat_res = smote.fit_resample(X_fatigue, y_fatigue)

X_train, X_test, y_train, y_test = train_test_split(X_fat_res, y_fat_res, test_size=0.2, random_state=42)

fatigue_model = GradientBoostingClassifier(n_estimators=200, max_depth=4, learning_rate=0.05, min_samples_leaf=3, random_state=42)
fatigue_model.fit(X_train, y_train)
y_pred = fatigue_model.predict(X_test)

print("\n=== FATIGUE — résultats ===")
print("Accuracy:", round(accuracy_score(y_test, y_pred), 4))
print(classification_report(y_test, y_pred, zero_division=0))

joblib.dump(fatigue_model, "model/fatigue_model.pkl")
joblib.dump(FATIGUE_FEATURES, "model/fatigue_features.pkl")
print("✅ Modèle fatigue sauvegardé\n")

# ═══════════════════════════════════════════════════════════════
# MODÈLE 2 — BLESSURE (avec ACL_Risk_Score)
# ═══════════════════════════════════════════════════════════════

print("📊 Chargement du dataset Multimodal Sports Injury...")
df_injury = pd.read_csv("multimodal_sports_injury_dataset.csv")
print(f"✅ {len(df_injury)} lignes chargées")

df_injury = df_injury.dropna(subset=['injury_occurred'])
print(f"✅ Après suppression des NaN dans target: {len(df_injury)} lignes")

df_injury['gender_encoded'] = le.fit_transform(df_injury['gender'])
unique_values = df_injury['injury_occurred'].unique()
print(f"Valeurs uniques de injury_occurred: {unique_values}")

if len(unique_values) == 3:
    df_injury['injury_binary'] = (df_injury['injury_occurred'] > 0).astype(int)
else:
    df_injury['injury_binary'] = df_injury['injury_occurred']

print(f"Distribution target:\n{df_injury['injury_binary'].value_counts()}")

df_clean = pd.DataFrame()
df_clean['Age'] = df_injury['age']
df_clean['Gender'] = df_injury['gender_encoded']
df_clean['BMI'] = df_injury['bmi']
df_clean['Training_Intensity'] = df_injury['training_intensity'].fillna(5)
df_clean['Training_Hours_Per_Week'] = (df_injury['training_duration'].fillna(60) / 60)
df_clean['Fatigue_Score'] = df_injury['fatigue_index'].fillna(5)
df_clean['Recovery_Days_Per_Week'] = df_injury['recovery_score'].fillna(5) / 10
df_clean['Load_Balance_Score'] = (df_injury['training_load'].fillna(5) / df_injury['recovery_score'].fillna(5).clip(lower=1)).clip(0, 10)
df_clean['HasCardio'] = np.random.choice([0, 1], size=len(df_injury), p=[0.4, 0.6])
df_clean['CardioDuration'] = np.random.uniform(0, 60, len(df_injury)) * df_clean['HasCardio']
df_clean['CardioIntensity'] = np.random.uniform(0, 10, len(df_injury)) * df_clean['HasCardio']
df_clean['WeightLiftedNorm'] = np.random.uniform(20, 150, len(df_injury))
df_clean['MuscleRiskScore'] = ((df_injury['muscle_activity'].fillna(50) / 100) * 2 + (df_injury['joint_angles'].fillna(0) / 50)).clip(1, 3)
df_clean['SessionsPerWeek'] = (df_injury['training_duration'].fillna(60) / 60 / 1.5).clip(1, 7).round()

# ═══════════════════════════════════════════════════════════════
# AJOUT DE ACL_Risk_Score
# ═══════════════════════════════════════════════════════════════
df_clean['ACL_Risk_Score'] = (
    (df_injury['injury_occurred'].fillna(0) * 0.5) +
    (df_injury['age'].fillna(30) / 100)
).clip(0, 1)

# ═══════════════════════════════════════════════════════════════
# INTÉGRATION DES FEEDBACKS (mode réentraînement)
# ═══════════════════════════════════════════════════════════════

if args.retrain and args.use_feedback:
    feedback_files = list(Path("retrain_data").glob("retrain_data_*.json"))
    all_feedback = []
    for f in feedback_files:
        with open(f, "r") as file:
            data = json.load(file)
            all_feedback.extend(data.get("data", []))
    
    if all_feedback:
        print(f"📊 {len(all_feedback)} feedbacks ajoutés à l'entraînement")
        df_feedback = pd.DataFrame(all_feedback)
        
        # Ajouter ACL_Risk_Score aux feedbacks si absent
        if 'ACL_Risk_Score' not in df_feedback.columns:
            df_feedback['ACL_Risk_Score'] = 0.1
        
        for col in df_clean.columns:
            if col in df_feedback.columns:
                df_feedback[col] = df_feedback[col].astype(df_clean[col].dtype)
        
        df_clean = pd.concat([df_clean, df_feedback], ignore_index=True)
        print(f"✅ Après ajout feedbacks: {len(df_clean)} lignes")

print(f"Avant suppression des NaN: {len(df_clean)} lignes")
df_clean = df_clean.dropna()
print(f"Après suppression des NaN: {len(df_clean)} lignes")

y = df_injury.loc[df_clean.index, 'injury_binary']

print(f"✅ {len(df_clean)} lignes préparées")

INJURY_FEATURES = [
    "Age", "Training_Intensity", "Training_Hours_Per_Week",
    "Recovery_Days_Per_Week", "Fatigue_Score", "Load_Balance_Score",
    "WeightLiftedNorm", "HasCardio", "CardioDuration",
    "CardioIntensity", "MuscleRiskScore", "SessionsPerWeek",
    "Gender", "BMI", "ACL_Risk_Score"
]

X = df_clean[INJURY_FEATURES]

print(f"NaN dans X: {X.isna().sum().sum()}")
print(f"NaN dans y: {y.isna().sum()}")

X_scaled = scaler.fit_transform(X)
X_scaled = pd.DataFrame(X_scaled, columns=X.columns)

smote = SMOTE(random_state=42, sampling_strategy=1.0)
X_resampled, y_resampled = smote.fit_resample(X_scaled, y)

print(f"📊 Après SMOTE: {pd.Series(y_resampled).value_counts().to_dict()}")

X_train, X_test, y_train, y_test = train_test_split(X_resampled, y_resampled, test_size=0.2, random_state=42)

injury_model = GradientBoostingClassifier(n_estimators=200, max_depth=4, learning_rate=0.05, min_samples_leaf=3, random_state=42)
injury_model.fit(X_train, y_train)
y_pred = injury_model.predict(X_test)

print("\n=== BLESSURE — résultats ===")
print("Accuracy:", round(accuracy_score(y_test, y_pred), 4))
print(classification_report(y_test, y_pred, zero_division=0))

print("\nFeature importances:")
for name, imp in zip(INJURY_FEATURES, injury_model.feature_importances_):
    print(f"  {name}: {imp:.4f}")

joblib.dump(injury_model, "model/injury_model.pkl")
joblib.dump(INJURY_FEATURES, "model/injury_features.pkl")
joblib.dump(scaler, "model/injury_scaler.pkl")

print("\n✅ Modèle blessure sauvegardé !")
print(f"   - {len(df_injury)} lignes originales")
print(f"   - {len(df_clean)} lignes après nettoyage")
print(f"   - {len(X_resampled)} lignes après SMOTE")
print("\n✅ Tous les modèles sauvegardés avec succès !")