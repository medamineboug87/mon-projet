package com.example.project_backend.Entity;

import jakarta.persistence.*;

/**
 * Représente un exercice individuel réalisé dans une séance.
 * Résout le Problème #3 : capture la charge réelle par exercice.
 *
 * Chaque séance peut avoir plusieurs SessionExercise (one-to-many).
 * Exemple : Séance du 2025-01-15 → 3 exercices avec leurs poids réels.
 */
@Entity
@Table(name = "session_exercises")
public class SessionExercise {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // ── Lien vers la séance parente ──
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", nullable = false)
    private TrainingSession session;

    // ── Nom de l'exercice (ex: "Développé couché", "Squat") ──
    @Column(nullable = false, length = 100)
    private String exerciseName;

    // ── Muscle ciblé principal (ex: "Pectoraux") ──
    @Column(length = 50)
    private String muscleName;

    // ── Charge réelle utilisée en kg ──
    private Double weightKg = 0.0;

    // ── Nombre de séries réalisées ──
    private Integer setsCompleted = 0;

    // ── Répétitions par série (ex: "10" ou "8-10" ou "10,8,6") ──
    @Column(length = 50)
    private String repsCompleted;

    // ── Répétitions en échec ? (indique si la charge était maximale) ──
    private Boolean failureReached = false;

    // ── Durée de repos entre séries en secondes ──
    private Integer restSeconds = 90;

    // ── Niveau de difficulté ressenti (RPE 1-10) ──
    // RPE = Rate of Perceived Exertion
    private Integer rpe;

    // ── Notes libres du membre sur cet exercice ──
    @Column(length = 300)
    private String notes;

    // ── Ordre de passage dans la séance (1er exercice, 2ème, etc.) ──
    private Integer exerciseOrder = 1;

    // ── Volume total calculé = weightKg × setsCompleted × repsCompleted ──
    // Stocké pour faciliter les calculs IA sans recalculer à chaque fois
    private Double totalVolume = 0.0;

    // ════════════════════════════════════════════════════
// GETTERS & SETTERS
// ════════════════════════════════════════════════════

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public TrainingSession getSession() { return session; }
    public void setSession(TrainingSession session) { this.session = session; }

    public String getExerciseName() { return exerciseName; }
    public void setExerciseName(String exerciseName) { this.exerciseName = exerciseName; }

    public String getMuscleName() { return muscleName; }
    public void setMuscleName(String muscleName) { this.muscleName = muscleName; }

    public Double getWeightKg() { return weightKg; }
    public void setWeightKg(Double weightKg) {
        this.weightKg = weightKg;
        // Plus d'appel ici - recalcul différé
    }

    public Integer getSetsCompleted() { return setsCompleted; }
    public void setSetsCompleted(Integer setsCompleted) {
        this.setsCompleted = setsCompleted;
        // Plus d'appel ici - recalcul différé
    }

    public String getRepsCompleted() { return repsCompleted; }
    public void setRepsCompleted(String repsCompleted) {
        this.repsCompleted = repsCompleted;
        recalculateTotalVolume(); // Déclenchement uniquement quand reps est modifié
    }

    public Boolean getFailureReached() { return failureReached; }
    public void setFailureReached(Boolean failureReached) { this.failureReached = failureReached; }

    public Integer getRestSeconds() { return restSeconds; }
    public void setRestSeconds(Integer restSeconds) { this.restSeconds = restSeconds; }

    public Integer getRpe() { return rpe; }
    public void setRpe(Integer rpe) { this.rpe = rpe; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public Integer getExerciseOrder() { return exerciseOrder; }
    public void setExerciseOrder(Integer exerciseOrder) { this.exerciseOrder = exerciseOrder; }

    public Double getTotalVolume() { return totalVolume; }
    public void setTotalVolume(Double totalVolume) { this.totalVolume = totalVolume; }

    // ── Recalcul automatique du volume total ──
// Volume = Poids × Séries × Répétitions moyennes
    private void recalculateTotalVolume() {
        if (weightKg != null && setsCompleted != null && repsCompleted != null) {
            int repsValue = parseReps(repsCompleted);
            this.totalVolume = weightKg * setsCompleted * repsValue;
        }
    }

    // ── Méthode utilitaire pour forcer le recalcul (utile après chargement depuis DB) ──
    public void refreshTotalVolume() {
        recalculateTotalVolume();
    }

    // ── Helper : extrait un nombre entier depuis une string de reps ──
    private int parseReps(String reps) {
        if (reps == null || reps.isBlank()) return 10;
        try {
            // "10-12" → prendre le premier nombre
            String first = reps.split("[-,]")[0].trim();
            return Integer.parseInt(first);
        } catch (NumberFormatException e) {
            return 10; // valeur par défaut
        }
    }}