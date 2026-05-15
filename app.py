"""
app.py — Service IA pour Smart Gym
Version 4.0 - Corrections de cohérence avec AIService.java

Changements vs v3.5 :
  - painLevel ajouté dans FatigueInput (envoyé par Java, maintenant documenté)
  - totalDuration : calculé côté Java ET Python pour robustesse
  - fitnessLevel / avgSleepHours / stressLevel : documentés comme
    multiplicateurs post-modèle (ne font PAS partie des FEATURES ML)
  - source ajouté dans les réponses (MODEL / HEURISTIC)
  - Scaler absent → réponse structurée cohérente avec le fallback Java
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
import joblib
import numpy as np
import pandas as pd
import os
import logging
import json
import yaml
import subprocess
import sys
from datetime import datetime
from pathlib import Path

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ai-api")

app = FastAPI(title="Smart Gym AI API", version="4.0")

RETRAIN_DATA_DIR = Path("retrain_data")
RETRAIN_DATA_DIR.mkdir(exist_ok=True)

# ══════════════════════════════════════════════════════════════
# CHARGEMENT DE LA CONFIGURATION PARTAGÉE (multipliers.yml)
# ══════════════════════════════════════════════════════════════

CONFIG_PATH = Path("config/multipliers.yml")
DEFAULT_CONFIG = {
    "fatigue_level_multiplier": {
        "BEGINNER": 1.4,
        "INTERMEDIATE": 1.15,
        "ADVANCED": 1.0,
        "ATHLETE": 0.85
    },
    "injury_level_multiplier": {
        "BEGINNER": 1.5,
        "INTERMEDIATE": 1.2,
        "ADVANCED": 1.0,
        "ATHLETE": 0.9
    },
    "sleep_multiplier": {
        "poor": 1.3,      # < 6 heures
        "moderate": 1.15, # 6-7 heures
        "good": 1.0       # >= 7 heures
    },
    "stress_multiplier": {
        "high": 1.25,     # >= 7/10
        "moderate": 1.1,  # 5-6/10
        "low": 1.0        # <= 4/10
    }
}

try:
    with open(CONFIG_PATH, "r") as f:
        config = yaml.safe_load(f)
        FATIGUE_LEVEL_MULTIPLIER = config.get("fatigue_level_multiplier", DEFAULT_CONFIG["fatigue_level_multiplier"])
        INJURY_LEVEL_MULTIPLIER  = config.get("injury_level_multiplier",  DEFAULT_CONFIG["injury_level_multiplier"])
        SLEEP_MULTIPLIER         = config.get("sleep_multiplier",         DEFAULT_CONFIG["sleep_multiplier"])
        STRESS_MULTIPLIER        = config.get("stress_multiplier",        DEFAULT_CONFIG["stress_multiplier"])
        logger.info("✅ Configuration chargée depuis config/multipliers.yml")
except Exception as e:
    logger.warning(f"⚠️ Impossible de charger multipliers.yml, valeurs par défaut: {e}")
    FATIGUE_LEVEL_MULTIPLIER = DEFAULT_CONFIG["fatigue_level_multiplier"]
    INJURY_LEVEL_MULTIPLIER  = DEFAULT_CONFIG["injury_level_multiplier"]
    SLEEP_MULTIPLIER         = DEFAULT_CONFIG["sleep_multiplier"]
    STRESS_MULTIPLIER        = DEFAULT_CONFIG["stress_multiplier"]

# ══════════════════════════════════════════════════════════════
# CHARGEMENT DES MODÈLES
# ══════════════════════════════════════════════════════════════

INJURY_SCALER_MISSING = False

try:
    fatigue_model = joblib.load("model/fatigue_model.pkl")
    logger.info("✅ Modèle fatigue chargé")
except Exception as e:
    fatigue_model = None
    logger.error(f"❌ Erreur chargement modèle fatigue: {e}")

try:
    injury_model = joblib.load("model/injury_model.pkl")
    logger.info("✅ Modèle blessure chargé")
except Exception as e:
    injury_model = None
    logger.error(f"❌ Erreur chargement modèle blessure: {e}")

try:
    injury_scaler = joblib.load("model/injury_scaler.pkl")
    logger.info("✅ Scaler blessure chargé")
except Exception as e:
    injury_scaler = None
    INJURY_SCALER_MISSING = True
    logger.warning(f"⚠️ Scaler blessure non trouvé: {e}")

# ══════════════════════════════════════════════════════════════
# FEATURES DES MODÈLES ML
#
# ⚠️ IMPORTANT — séparation claire des responsabilités :
#
# FATIGUE_FEATURES / INJURY_FEATURES = entrées du modèle scikit-learn
#   → doivent correspondre exactement à ce qui a été utilisé dans train.py
#
# Champs de personnalisation (fitnessLevel, avgSleepHours, stressLevel,
# painLevel) = multiplicateurs appliqués APRÈS la prédiction du modèle
#   → ils affinent le score final mais ne font PAS partie du ML
#   → cohérent avec AIService.java (heuristique et appel Python)
# ══════════════════════════════════════════════════════════════

FATIGUE_FEATURES = [
    "Duration",
    "TotalDuration",       # FIX: maintenant toujours calculé (Java + Python)
    "BMI",
    "Age",
    "Gender",
    "WeightLifted",
    "Intensity",
    "HasCardio",
    "CardioDurationMinutes",
    "CardioIntensity",
    "MuscleRiskScore",
    "RecoveryDaysPerWeek",
]

INJURY_FEATURES = [
    "Age",
    "Training_Intensity",
    "Training_Hours_Per_Week",
    "Recovery_Days_Per_Week",
    "Fatigue_Score",
    "Load_Balance_Score",
    "WeightLiftedNorm",
    "HasCardio",
    "CardioDuration",
    "CardioIntensity",
    "MuscleRiskScore",
    "SessionsPerWeek",
    "Gender",
    "BMI",
    "ACL_Risk_Score",
]

# ══════════════════════════════════════════════════════════════
# SCHÉMAS D'ENTRÉE PYDANTIC
# ══════════════════════════════════════════════════════════════

class FatigueInput(BaseModel):
    # ── Champs du modèle ML (FATIGUE_FEATURES) ──
    age: int
    bmi: float
    gender: int
    duration: float
    weightLifted: float
    intensity: Optional[float] = 5.0
    recoveryDaysPerWeek: Optional[int] = 2
    hasCardio: Optional[int] = 0
    cardioDurationMinutes: Optional[float] = 0.0
    cardioIntensity: Optional[float] = 0.0
    muscleRiskScore: Optional[float] = 1.0

    # FIX: totalDuration optionnel mais maintenant envoyé par Java
    # Si absent → recalculé ici pour robustesse
    totalDuration: Optional[float] = None

    # ── Champs de personnalisation (multiplicateurs post-modèle) ──
    # Ces champs ne font PAS partie du modèle ML — ils ajustent le score final
    fitnessLevel: Optional[str] = "BEGINNER"
    avgSleepHours: Optional[float] = 7.0
    stressLevel: Optional[int] = 5
    # FIX: painLevel documenté — utilisé comme multiplicateur post-modèle
    # (cohérent avec l'heuristique Java : 1.0 + painLevel/20 si painLevel > 3)
    painLevel: Optional[int] = Field(0, ge=0, le=10,
        description="Niveau de douleur 0-10. Multiplicateur post-modèle, pas dans FATIGUE_FEATURES ML.")


class InjuryInput(BaseModel):
    # ── Champs du modèle ML (INJURY_FEATURES) ──
    Age: int
    Training_Intensity: float
    Training_Hours_Per_Week: float
    Recovery_Days_Per_Week: float
    Fatigue_Score: float
    Load_Balance_Score: float
    ACL_Risk_Score: float
    WeightLiftedNorm: Optional[float] = 50.0
    SessionsPerWeek: Optional[float] = 3.0
    HasCardio: Optional[int] = 0
    CardioDuration: Optional[float] = 0.0
    CardioIntensity: Optional[float] = 0.0
    MuscleRiskScore: Optional[float] = 1.0
    Gender: Optional[int] = 1
    BMI: Optional[float] = 22.5

    # ── Champs de personnalisation (multiplicateurs post-modèle) ──
    fitnessLevel: Optional[str] = "BEGINNER"
    avgSleepHours: Optional[float] = 7.0
    stressLevel: Optional[int] = 5


class RetrainData(BaseModel):
    totalSamples: int
    readyToRetrain: bool
    minimumRequired: int
    data: List[Dict[str, Any]]
    message: str

# ══════════════════════════════════════════════════════════════
# FONCTIONS UTILITAIRES — MULTIPLICATEURS
# ══════════════════════════════════════════════════════════════

def get_sleep_multiplier(sleep_hours: float) -> float:
    """Cohérent avec AIService.java predictFatigueHeuristic."""
    if sleep_hours < 6.0:
        return SLEEP_MULTIPLIER["poor"]
    elif sleep_hours < 7.0:
        return SLEEP_MULTIPLIER["moderate"]
    return SLEEP_MULTIPLIER["good"]


def get_stress_multiplier(stress_level: int) -> float:
    """Cohérent avec AIService.java predictFatigueHeuristic."""
    if stress_level >= 7:
        return STRESS_MULTIPLIER["high"]
    elif stress_level >= 5:
        return STRESS_MULTIPLIER["moderate"]
    return STRESS_MULTIPLIER["low"]


def get_fatigue_level_multiplier(level: str) -> float:
    return FATIGUE_LEVEL_MULTIPLIER.get(level.upper(), 1.0)


def get_injury_level_multiplier(level: str) -> float:
    return INJURY_LEVEL_MULTIPLIER.get(level.upper(), 1.0)


def get_pain_multiplier(pain_level: int) -> float:
    """
    FIX: aligné avec AIService.java predictFatigueHeuristic.
    Java : painMultiplier = painLevel > 3 ? 1.0 + (painLevel / 20.0) : 1.0
    """
    if pain_level > 3:
        return 1.0 + (pain_level / 20.0)
    return 1.0


# ══════════════════════════════════════════════════════════════
# RÉENTRAÎNEMENT EN ARRIÈRE-PLAN
# ══════════════════════════════════════════════════════════════

def _retrain_models():
    """Exécute train.py pour réentraîner les modèles avec les nouveaux feedbacks."""
    logger.info("🔄 Démarrage du réentraînement réel...")
    try:
        result = subprocess.run(
            [sys.executable, "train.py", "--retrain", "--use-feedback"],
            capture_output=True,
            text=True,
            timeout=300
        )
        if result.returncode == 0:
            logger.info("✅ Réentraînement terminé avec succès")
            global fatigue_model, injury_model, injury_scaler, INJURY_SCALER_MISSING
            try:
                fatigue_model  = joblib.load("model/fatigue_model.pkl")
                injury_model   = joblib.load("model/injury_model.pkl")
                injury_scaler  = joblib.load("model/injury_scaler.pkl")
                INJURY_SCALER_MISSING = False
                logger.info("✅ Modèles rechargés après réentraînement")
            except Exception as e:
                logger.error(f"❌ Erreur rechargement modèles: {e}")
        else:
            logger.error(f"❌ Échec réentraînement: {result.stderr}")
    except subprocess.TimeoutExpired:
        logger.error("❌ Réentraînement trop long (timeout 5 min)")
    except Exception as e:
        logger.error(f"❌ Erreur lors du réentraînement: {e}")

# ══════════════════════════════════════════════════════════════
# ENDPOINTS
# ══════════════════════════════════════════════════════════════

@app.get("/health")
def health():
    return {
        "status": "ok",
        "version": "4.0",
        "models": {
            "fatigue": fatigue_model is not None,
            "injury":  injury_model  is not None,
        },
        "scaler_available": not INJURY_SCALER_MISSING,
        "features": {
            "fatigue": FATIGUE_FEATURES,
            "injury":  INJURY_FEATURES,
        },
        "multipliers": {
            "fatigue_level": FATIGUE_LEVEL_MULTIPLIER,
            "injury_level":  INJURY_LEVEL_MULTIPLIER,
            "sleep":         SLEEP_MULTIPLIER,
            "stress":        STRESS_MULTIPLIER,
        },
        "post_model_adjustments": [
            "fitnessLevel → level_multiplier",
            "avgSleepHours → sleep_multiplier",
            "stressLevel → stress_multiplier",
            "painLevel → pain_multiplier (fatigue uniquement)",
        ],
        "timestamp": datetime.now().isoformat(),
    }


@app.post("/predict_fatigue")
def predict_fatigue(data: FatigueInput):
    if fatigue_model is None:
        raise HTTPException(status_code=503, detail="Modèle fatigue non disponible")

    logger.info(
        f"📥 Fatigue — level={data.fitnessLevel} | sleep={data.avgSleepHours}h "
        f"| stress={data.stressLevel}/10 | pain={data.painLevel}/10"
    )

    try:
        # FIX: totalDuration robuste — utilise la valeur Java si présente,
        # sinon recalcule localement (fallback de sécurité)
        total_duration = (
            data.totalDuration
            if data.totalDuration is not None
            else data.duration + (data.cardioDurationMinutes or 0.0)
        )

        features = pd.DataFrame([{
            "Duration":             data.duration,
            "TotalDuration":        total_duration,
            "BMI":                  data.bmi,
            "Age":                  data.age,
            "Gender":               data.gender,
            "WeightLifted":         data.weightLifted,
            "Intensity":            data.intensity,
            "HasCardio":            data.hasCardio,
            "CardioDurationMinutes": data.cardioDurationMinutes,
            "CardioIntensity":      data.cardioIntensity,
            "MuscleRiskScore":      data.muscleRiskScore,
            "RecoveryDaysPerWeek":  data.recoveryDaysPerWeek,
        }])

        features = features[FATIGUE_FEATURES]

        prediction     = fatigue_model.predict(features)
        proba          = fatigue_model.predict_proba(features)
        base_confidence = float(proba.max())
        base_fatigue_score = float(proba[0][1]) if proba.shape[1] > 1 else base_confidence

        # ── Multiplicateurs post-modèle (cohérents avec AIService.java) ──
        level_multi  = get_fatigue_level_multiplier(data.fitnessLevel)
        sleep_multi  = get_sleep_multiplier(data.avgSleepHours)
        stress_multi = get_stress_multiplier(data.stressLevel)
        pain_multi   = get_pain_multiplier(data.painLevel)   # FIX: aligné Java

        adjusted_score = (
            base_fatigue_score
            * level_multi
            * sleep_multi
            * stress_multi
            * pain_multi
        )
        adjusted_score = min(1.0, max(0.0, adjusted_score))
        is_fatigued    = adjusted_score > 0.6

        return {
            "fatigue":       1 if is_fatigued else 0,
            "label":         "fatigué" if is_fatigued else "normal",
            "confidence":    round(base_confidence, 2),
            "proba_fatigued": round(adjusted_score, 2),
            "fatigueScore":  round(adjusted_score * 10, 1),   # échelle 0-10 pour cohérence avec heuristique
            "source":        "MODEL",
            "totalDurationUsed": round(total_duration, 1),
            "multipliers_applied": {
                "level":       level_multi,
                "sleep":       sleep_multi,
                "stress":      stress_multi,
                "pain":        pain_multi,
                "final_score": round(adjusted_score, 3),
            },
        }

    except Exception as e:
        logger.error(f"❌ Erreur fatigue: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Fatigue prediction error: {str(e)}")


@app.post("/predict_injury")
def predict_injury(data: InjuryInput):
    if injury_model is None:
        raise HTTPException(status_code=503, detail="Modèle blessure non disponible")

    logger.info(
        f"📥 Injury — level={data.fitnessLevel} | sleep={data.avgSleepHours}h "
        f"| stress={data.stressLevel}/10 | ACL={data.ACL_Risk_Score}"
    )

    if INJURY_SCALER_MISSING:
        logger.warning("⚠️ Scaler absent — prédiction blessure désactivée")
        return {
            "injury_risk":   0,
            "label":         "non disponible",
            "risk_level":    "NON_DISPONIBLE",
            "riskLevel":     "NON_DISPONIBLE",
            "confidence":    0.0,
            "proba_injured": 0.0,
            "source":        "MODEL_UNAVAILABLE",
            "scaler_missing": True,
            "warning": (
                "⚠️ Scaler absent. Relancez train.py pour calibrer le modèle. "
                "Le fallback heuristique Java est utilisé."
            ),
        }

    try:
        features = pd.DataFrame([{
            "Age":                     data.Age,
            "Training_Intensity":      data.Training_Intensity,
            "Training_Hours_Per_Week": data.Training_Hours_Per_Week,
            "Recovery_Days_Per_Week":  data.Recovery_Days_Per_Week,
            "Fatigue_Score":           data.Fatigue_Score,
            "Load_Balance_Score":      data.Load_Balance_Score,
            "ACL_Risk_Score":          data.ACL_Risk_Score,
            "WeightLiftedNorm":        data.WeightLiftedNorm,
            "HasCardio":               data.HasCardio,
            "CardioDuration":          data.CardioDuration,
            "CardioIntensity":         data.CardioIntensity,
            "MuscleRiskScore":         data.MuscleRiskScore,
            "SessionsPerWeek":         data.SessionsPerWeek,
            "Gender":                  data.Gender,
            "BMI":                     data.BMI,
        }])

        features        = features[INJURY_FEATURES]
        features_scaled = pd.DataFrame(
            injury_scaler.transform(features), columns=features.columns
        )

        prediction      = injury_model.predict(features_scaled)
        proba           = injury_model.predict_proba(features_scaled)
        base_confidence = float(proba.max())
        base_risk_score = float(proba[0][1]) if proba.shape[1] > 1 else base_confidence

        # ── Multiplicateurs post-modèle ──
        level_multi  = get_injury_level_multiplier(data.fitnessLevel)
        sleep_multi  = get_sleep_multiplier(data.avgSleepHours)
        stress_multi = get_stress_multiplier(data.stressLevel)

        adjusted_score = base_risk_score * level_multi * sleep_multi * stress_multi
        adjusted_score = min(1.0, max(0.0, adjusted_score))

        # 3 niveaux cohérents avec l'heuristique Java
        if adjusted_score > 0.7:
            risk_level   = "ÉLEVÉ"
            label        = "risque élevé"
            injury_risk  = 1
        elif adjusted_score > 0.4:
            risk_level   = "MODÉRÉ"
            label        = "risque modéré"
            injury_risk  = 0
        else:
            risk_level   = "FAIBLE"
            label        = "risque faible"
            injury_risk  = 0

        return {
            "injury_risk":   injury_risk,
            "label":         label,
            "risk_level":    risk_level,
            "riskLevel":     risk_level,       # double clé pour compatibilité Java
            "confidence":    round(base_confidence, 2),
            "proba_injured": round(adjusted_score, 2),
            "injuryRisk":    round(adjusted_score, 2),  # double clé pour compatibilité Java
            "source":        "MODEL",
            "multipliers_applied": {
                "level":       level_multi,
                "sleep":       sleep_multi,
                "stress":      stress_multi,
                "final_score": round(adjusted_score, 3),
            },
        }

    except Exception as e:
        logger.error(f"❌ Erreur injury: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Injury prediction error: {str(e)}")


@app.post("/retrain")
def retrain(data: RetrainData, background_tasks: BackgroundTasks):
    logger.info(f"🔁 Réentraînement demandé — {data.totalSamples} samples")

    if not data.readyToRetrain:
        return {
            "success": False,
            "message": f"Données insuffisantes : {data.totalSamples}/{data.minimumRequired} requis.",
        }

    # Vérification que les données sont bien numériques (pas de texte ML)
    text_fields_detected = []
    for sample in data.data:
        for key, val in sample.items():
            if isinstance(val, str) and key not in ("fatigue_label", "injury_label"):
                text_fields_detected.append(key)
    if text_fields_detected:
        unique_text = list(set(text_fields_detected))
        logger.warning(f"⚠️ Champs texte détectés (ignorés par le ML): {unique_text}")

    try:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename  = RETRAIN_DATA_DIR / f"retrain_data_{timestamp}.json"

        with open(filename, "w", encoding="utf-8") as f:
            json.dump({
                "timestamp":    timestamp,
                "totalSamples": data.totalSamples,
                "data":         data.data,
            }, f, indent=2, ensure_ascii=False)

        background_tasks.add_task(_retrain_models)

        return {
            "success":         True,
            "modelVersion":    f"v4.0.{timestamp}",
            "samplesReceived": data.totalSamples,
            "savedFile":       str(filename),
            "fatigueAccuracy": "N/A (calcul après réentraînement)",
            "injuryAccuracy":  "N/A (calcul après réentraînement)",
            "message":         f"Réentraînement déclenché — {data.totalSamples} feedbacks en cours de traitement.",
        }

    except Exception as e:
        logger.error(f"❌ Erreur retrain: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Retrain error: {str(e)}")


@app.get("/stats")
def get_stats():
    retrain_files = list(RETRAIN_DATA_DIR.glob("retrain_data_*.json"))
    return {
        "version":        "4.0",
        "models_loaded":  {"fatigue": fatigue_model is not None, "injury": injury_model is not None},
        "scaler_available": not INJURY_SCALER_MISSING,
        "retrain_data_files": len(retrain_files),
        "features": {
            "fatigue_ml":     FATIGUE_FEATURES,
            "injury_ml":      INJURY_FEATURES,
            "post_model_adjustments": [
                "fitnessLevel", "avgSleepHours", "stressLevel", "painLevel (fatigue)"
            ],
        },
        "multipliers": {
            "fatigue_level": FATIGUE_LEVEL_MULTIPLIER,
            "injury_level":  INJURY_LEVEL_MULTIPLIER,
            "sleep":         SLEEP_MULTIPLIER,
            "stress":        STRESS_MULTIPLIER,
        },
        "uptime": datetime.now().isoformat(),
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5001, reload=True)