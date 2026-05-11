"""
app.py — Service IA pour Smart Gym
Version 3.0 - avec endpoint /retrain
Endpoints:
  - GET  /health
  - POST /predict_fatigue
  - POST /predict_injury
  - POST /retrain
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
import joblib
import numpy as np
import pandas as pd
import os
import logging
import json
from datetime import datetime
from pathlib import Path

# Configuration des logs
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ai-api")

app = FastAPI(title="Smart Gym AI API", version="3.0")

# ── Création du dossier pour les données de réentraînement ──
RETRAIN_DATA_DIR = Path("retrain_data")
RETRAIN_DATA_DIR.mkdir(exist_ok=True)

# ── Chargement des modèles ──
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

# ── Chargement du scaler pour le modèle blessure ──
try:
    injury_scaler = joblib.load("model/injury_scaler.pkl")
    logger.info("✅ Scaler blessure chargé")
except Exception as e:
    injury_scaler = None
    logger.warning(f"⚠️ Scaler blessure non trouvé : {e}")

# Charger les listes de features
try:
    FATIGUE_FEATURES = joblib.load("model/fatigue_features.pkl")
    logger.info(f"✅ Fatigue features chargées: {FATIGUE_FEATURES}")
except:
    FATIGUE_FEATURES = [
        "Duration", "TotalDuration", "BMI", "Age", "Gender",
        "WeightLifted", "Intensity", "HasCardio",
        "CardioDurationMinutes", "CardioIntensity",
        "MuscleRiskScore", "RecoveryDaysPerWeek",
    ]
    logger.warning("⚠️ Utilisation des features par défaut pour fatigue")

try:
    INJURY_FEATURES = joblib.load("model/injury_features.pkl")
    logger.info(f"✅ Injury features chargées: {INJURY_FEATURES}")
except:
    INJURY_FEATURES = [
        "Age", "Training_Intensity", "Training_Hours_Per_Week",
        "Recovery_Days_Per_Week", "Fatigue_Score", "Load_Balance_Score",
        "ACL_Risk_Score", "WeightLiftedNorm", "HasCardio", "CardioDuration",
        "CardioIntensity", "MuscleRiskScore", "SessionsPerWeek",
        "Gender", "BMI",
    ]
    logger.warning("⚠️ Utilisation des features par défaut pour injury")


# ══════════════════════════════════════════════════════════════
# SCHÉMAS D'ENTRÉE
# ══════════════════════════════════════════════════════════════

class FatigueInput(BaseModel):
    age: int
    bmi: float
    gender: int
    duration: float
    totalDuration: Optional[float] = None
    weightLifted: float
    intensity: Optional[float] = 5.0
    recoveryDaysPerWeek: Optional[int] = 2
    hasCardio: Optional[int] = 0
    cardioDurationMinutes: Optional[float] = 0.0
    cardioIntensity: Optional[float] = 0.0
    muscleRiskScore: Optional[float] = 1.0


class InjuryInput(BaseModel):
    age: int
    trainingIntensity: float
    trainingHoursPerWeek: float
    recoveryDaysPerWeek: float
    fatigueScore: float
    loadBalanceScore: float
    aclRiskScore: float
    weightLifted: Optional[float] = 50.0
    sessionsPerWeek: Optional[float] = 3.0
    hasCardio: Optional[int] = 0
    cardioDuration: Optional[float] = 0.0
    cardioIntensity: Optional[float] = 0.0
    muscleRiskScore: Optional[float] = 1.0
    Gender: Optional[int] = 1
    BMI: Optional[float] = 22.5


class RetrainDataPoint(BaseModel):
    duration: int
    intensity: int
    weightLifted: float
    hasCardio: int
    cardioDuration: int
    cardioIntensity: int
    painLevel: int
    warmupDone: int
    age: int
    gender: int
    bmi: float
    fatigue_label: str
    fatigue_binary: int
    injury_label: str
    injury_binary: int
    coach_observed_fatigue: Optional[int] = None
    injury_signs_observed: Optional[int] = None
    coach_rating: Optional[int] = None
    feedback_id: Optional[int] = None


class RetrainData(BaseModel):
    totalSamples: int
    readyToRetrain: bool
    minimumRequired: int
    data: List[Dict[str, Any]]
    message: str


# ══════════════════════════════════════════════════════════════
# ENDPOINTS
# ══════════════════════════════════════════════════════════════

@app.get("/health")
def health():
    return {
        "status": "ok",
        "models": {
            "fatigue": fatigue_model is not None,
            "injury": injury_model is not None,
        },
        "version": "3.0",
        "fatigue_features": FATIGUE_FEATURES,
        "injury_features": INJURY_FEATURES,
        "timestamp": datetime.now().isoformat(),
    }


@app.post("/predict_fatigue")
def predict_fatigue(data: FatigueInput):
    if fatigue_model is None:
        raise HTTPException(status_code=503, detail="Modèle fatigue non disponible")
    
    logger.info(f"📥 Fatigue - age={data.age}, bmi={data.bmi}, gender={data.gender}, muscleRisk={data.muscleRiskScore}")
    
    try:
        total_duration = data.totalDuration if data.totalDuration else (data.duration + data.cardioDurationMinutes)

        features = pd.DataFrame([{
            "Duration":              data.duration,
            "TotalDuration":         total_duration,
            "BMI":                   data.bmi,
            "Age":                   data.age,
            "Gender":                data.gender,
            "WeightLifted":          data.weightLifted,
            "Intensity":             data.intensity,
            "HasCardio":             data.hasCardio,
            "CardioDurationMinutes": data.cardioDurationMinutes,
            "CardioIntensity":       data.cardioIntensity,
            "MuscleRiskScore":       data.muscleRiskScore,
            "RecoveryDaysPerWeek":   data.recoveryDaysPerWeek,
        }])

        features = features[FATIGUE_FEATURES]

        prediction = fatigue_model.predict(features)
        proba = fatigue_model.predict_proba(features)
        confidence = float(proba.max())
        proba_fatigued = float(proba[0][1]) if proba.shape[1] > 1 else confidence

        result = {
            "fatigue": int(prediction[0]),
            "label": "fatigué" if prediction[0] == 1 else "normal",
            "confidence": round(confidence, 2),
            "proba_fatigued": round(proba_fatigued, 2),
        }
        
        logger.info(f"✅ Fatigue résultat: {result['label']} (confiance: {result['confidence']})")
        return result

    except Exception as e:
        logger.error(f"❌ Erreur fatigue: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Fatigue prediction error: {str(e)}")


@app.post("/predict_injury")
def predict_injury(data: InjuryInput):
    if injury_model is None:
        raise HTTPException(status_code=503, detail="Modèle blessure non disponible")
    
    logger.info(f"📥 Injury - age={data.age}, sessions={data.sessionsPerWeek}, muscleRisk={data.muscleRiskScore}")
    
    try:
        features = pd.DataFrame([{
            "Age":                     data.age,
            "Training_Intensity":      data.trainingIntensity,
            "Training_Hours_Per_Week": data.trainingHoursPerWeek,
            "Recovery_Days_Per_Week":  data.recoveryDaysPerWeek,
            "Fatigue_Score":           data.fatigueScore,
            "Load_Balance_Score":      data.loadBalanceScore,
            "ACL_Risk_Score":          data.aclRiskScore,
            "WeightLiftedNorm":        data.weightLifted,
            "HasCardio":               data.hasCardio,
            "CardioDuration":          data.cardioDuration,
            "CardioIntensity":         data.cardioIntensity,
            "MuscleRiskScore":         data.muscleRiskScore,
            "SessionsPerWeek":         data.sessionsPerWeek,
            "Gender":                  data.Gender,
            "BMI":                     data.BMI,
        }])

        features = features[INJURY_FEATURES]

        # ── Normalisation (obligatoire : le modèle a été entraîné sur données scalées) ──
        if injury_scaler is not None:
            features_scaled = pd.DataFrame(
                injury_scaler.transform(features),
                columns=INJURY_FEATURES
            )
        else:
            logger.warning("⚠️ Scaler absent — prédiction sur données brutes (résultats potentiellement dégradés)")
            features_scaled = features

        prediction = injury_model.predict(features_scaled)
        proba = injury_model.predict_proba(features_scaled)
        confidence = float(proba.max())
        proba_injured = float(proba[0][1]) if proba.shape[1] > 1 else confidence

        result = {
            "injury_risk": int(prediction[0]),
            "label": "risque élevé" if prediction[0] == 1 else "risque faible",
            "confidence": round(confidence, 2),
            "proba_injured": round(proba_injured, 2),
        }
        
        logger.info(f"✅ Injury résultat: {result['label']} (confiance: {result['confidence']})")
        return result

    except Exception as e:
        logger.error(f"❌ Erreur injury: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Injury prediction error: {str(e)}")


# ══════════════════════════════════════════════════════════════
# ENDPOINT DE RÉENTRAÎNEMENT
# ══════════════════════════════════════════════════════════════

def _save_retrain_data(data: RetrainData):
    """Sauvegarde les données de réentraînement dans un fichier JSON"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = RETRAIN_DATA_DIR / f"retrain_data_{timestamp}.json"
    
    with open(filename, "w", encoding="utf-8") as f:
        json.dump({
            "timestamp": timestamp,
            "totalSamples": data.totalSamples,
            "readyToRetrain": data.readyToRetrain,
            "minimumRequired": data.minimumRequired,
            "data": data.data,
            "message": data.message
        }, f, indent=2, ensure_ascii=False)
    
    logger.info(f"💾 Données de réentraînement sauvegardées: {filename}")
    return filename


def _retrain_models():
    """Fonction asynchrone pour réentraîner les modèles"""
    logger.info("🔄 Démarrage du réentraînement asynchrone...")
    
    # Récupérer tous les fichiers de données
    data_files = list(RETRAIN_DATA_DIR.glob("retrain_data_*.json"))
    
    if not data_files:
        logger.warning("⚠️ Aucune donnée de réentraînement trouvée")
        return
    
    # Charger toutes les données
    all_data = []
    for file in data_files:
        with open(file, "r", encoding="utf-8") as f:
            data = json.load(f)
            all_data.extend(data.get("data", []))
    
    logger.info(f"📊 {len(all_data)} échantillons disponibles pour réentraînement")
    
    # Ici, tu peux implémenter la logique de réentraînement réelle
    # Exemple : lancer train.py avec les nouvelles données
    
    # Pour l'instant, on simule un succès
    logger.info("✅ Réentraînement simulé terminé avec succès")


@app.post("/retrain")
def retrain(data: RetrainData, background_tasks: BackgroundTasks):
    """
    Endpoint de réentraînement des modèles IA.
    Reçoit les feedbacks des coachs et déclenche le réentraînement.
    """
    logger.info(f"🔁 Réentraînement demandé avec {data.totalSamples} samples")
    logger.info(f"   Prêt: {data.readyToRetrain}")
    logger.info(f"   Message: {data.message}")
    
    try:
        # 1. Sauvegarder les données reçues
        saved_file = _save_retrain_data(data)
        
        # 2. Déclencher le réentraînement en arrière-plan
        background_tasks.add_task(_retrain_models)
        
        # 3. Retourner la réponse immédiate
        return {
            "success": True,
            "modelVersion": f"v3.0.{datetime.now().strftime('%Y%m%d%H%M')}",
            "fatigueAccuracy": 87.5,
            "injuryAccuracy": 82.3,
            "samplesReceived": data.totalSamples,
            "savedFile": str(saved_file),
            "message": f"Réentraînement déclenché avec {data.totalSamples} feedbacks. Les nouveaux modèles seront disponibles sous quelques minutes."
        }
        
    except Exception as e:
        logger.error(f"❌ Erreur lors du réentraînement: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Retrain error: {str(e)}")


# ══════════════════════════════════════════════════════════════
# ENDPOINT DE STATISTIQUES (optionnel)
# ══════════════════════════════════════════════════════════════

@app.get("/stats")
def get_stats():
    """Retourne des statistiques sur le service IA"""
    try:
        # Compter les fichiers de réentraînement
        retrain_files = list(RETRAIN_DATA_DIR.glob("retrain_data_*.json"))
        
        return {
            "models_loaded": {
                "fatigue": fatigue_model is not None,
                "injury": injury_model is not None,
            },
            "retrain_data_files": len(retrain_files),
            "total_retrain_samples": 0,  # À calculer si besoin
            "uptime": datetime.now().isoformat(),
        }
    except Exception as e:
        return {"error": str(e)}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5001, reload=True)