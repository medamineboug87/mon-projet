"""
explore_dataset.py - Pour comprendre la structure du nouveau dataset
"""

import pandas as pd
import os

# À MODIFIER selon le vrai nom du fichier
file_path = "d:\gym-ai\multimodal_sports_injury_dataset.csv"

# Si le fichier est en Excel ou autre format, ajustez
if file_path.endswith('.csv'):
    df = pd.read_csv(file_path)
elif file_path.endswith('.xlsx'):
    df = pd.read_excel(file_path)
else:
    # Chercher tous les fichiers
    for f in os.listdir("data/multimodal/"):
        if f.endswith(('.csv', '.xlsx', '.xls')):
            print(f"📄 Fichier trouvé: {f}")
            if f.endswith('.csv'):
                df = pd.read_csv(f"data/multimodal/{f}")
            else:
                df = pd.read_excel(f"data/multimodal/{f}")
            break

print("=" * 60)
print("📊 STRUCTURE DU DATASET")
print("=" * 60)
print(f"Nombre de lignes: {len(df)}")
print(f"Nombre de colonnes: {len(df.columns)}")
print(f"\n📋 NOMS DES COLONNES:")
for i, col in enumerate(df.columns):
    print(f"  {i+1}. {col}")

print(f"\n🎯 TYPES DE DONNÉES:")
print(df.dtypes)

print(f"\n📊 APERÇU (5 premières lignes):")
print(df.head())

print(f"\n🔍 VALEURS UNIQUES PAR COLONNE CATÉGORIELLE:")
for col in df.columns:
    if df[col].dtype == 'object' and df[col].nunique() < 20:
        print(f"  {col}: {df[col].unique().tolist()}")

print(f"\n📈 STATISTIQUES NUMÉRIQUES:")
print(df.describe())

# Vérifier la colonne cible (blessure)
target_columns = [col for col in df.columns if any(word in col.lower() for word in ['injury', 'risk', 'label', 'target'])]
print(f"\n🎯 COLONNES CANDIDATES POUR LA TARGET: {target_columns}")