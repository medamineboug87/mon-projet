import pandas as pd

df = pd.read_csv("collegiate_athlete_injury_dataset.csv")
print(df.columns)
print(df.head())
print(df.shape)
df = pd.read_csv("exercise_dataset.csv")
print(df.columns)
print(df.head())
print(df.shape)

