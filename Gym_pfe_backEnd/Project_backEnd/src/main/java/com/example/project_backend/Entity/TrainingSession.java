package com.example.project_backend.Entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "training_sessions")
public class TrainingSession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private LocalDate date;
    private int duration;
    private int intensity;
    private double weightLifted;
    private Double fatigueScore;
    private Double loadBalanceScore;
    private Double aclRiskScore;
    private Integer recoveryDaysPerWeek;
    private String targetMuscles;

    // ── Cardio ──
    private Boolean hasCardio            = false;
    private Integer cardioDurationMinutes = 0;
    private String  cardioType           = "";
    private Integer cardioIntensity      = 0;

    // ── Problème #5 : Douleur ressentie post-séance ──
    // 0 = aucune, 1-3 = légère, 4-6 = modérée, 7-10 = intense
    private Integer painLevel;

    // ── Problème #7 : Échauffement effectué ──
    private Boolean warmupDone;

    // ── NOUVEAU Problème #3 : Exercices individuels avec charge réelle ──
    // Cascade ALL : quand la séance est supprimée, ses exercices le sont aussi
    @OneToMany(mappedBy = "session", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonIgnore  // évite la boucle infinie JSON (session → exercises → session...)
    private List<SessionExercise> exercises = new ArrayList<>();

    @ManyToOne
    @JoinColumn(name = "member_id")
    private Member member;

    // ===== Getters =====

    public Long getId()                     { return id; }
    public LocalDate getDate()              { return date; }
    public int getDuration()                { return duration; }
    public int getIntensity()               { return intensity; }
    public double getWeightLifted()         { return weightLifted; }
    public Member getMember()               { return member; }
    public Double getFatigueScore()         { return fatigueScore; }
    public Double getLoadBalanceScore()     { return loadBalanceScore; }
    public Double getAclRiskScore()         { return aclRiskScore; }
    public Integer getRecoveryDaysPerWeek() { return recoveryDaysPerWeek; }
    public String getTargetMuscles()        { return targetMuscles; }

    // Cardio
    public Boolean getHasCardio()              { return hasCardio != null && hasCardio; }
    public Integer getCardioDurationMinutes()  { return cardioDurationMinutes != null ? cardioDurationMinutes : 0; }
    public String getCardioType()              { return cardioType != null ? cardioType : ""; }
    public Integer getCardioIntensity()        { return cardioIntensity != null ? cardioIntensity : 0; }

    // Nouveaux champs Niveau 2
    public Integer getPainLevel()          { return painLevel; }
    public Boolean getWarmupDone()         { return warmupDone; }

    // ── Exercises (Niveau 3 — charge réelle par exercice) ──
    public List<SessionExercise> getExercises() { return exercises; }

    /**
     * Retourne le poids effectif à envoyer à l'IA :
     * - Si des exercices détaillés existent → poids max utilisé parmi eux
     * - Sinon → valeur globale saisie manuellement (weightLifted)
     */
    public double getEffectiveWeightLifted() {
        if (exercises == null || exercises.isEmpty()) return weightLifted;
        double maxWeight = exercises.stream()
                .mapToDouble(e -> e.getWeightKg() != null ? e.getWeightKg() : 0.0)
                .max()
                .orElse(0.0);
        return maxWeight > 0 ? maxWeight : weightLifted;
    }

    /**
     * Volume total réel calculé depuis les exercices :
     *   Volume = Σ (poids × séries × reps) pour chaque exercice
     * Utilisé par AIService pour un calcul de surcharge plus précis.
     */
    public double getTotalVolume() {
        if (exercises == null || exercises.isEmpty()) {
            // Fallback : estimation depuis durée × poids global
            return weightLifted * (duration / 60.0);
        }
        return exercises.stream()
                .mapToDouble(e -> e.getTotalVolume() != null ? e.getTotalVolume() : 0.0)
                .sum();
    }

    /**
     * Score de risque musculaire calculé depuis les exercices réels :
     * prend en compte la charge relative pour chaque muscle.
     * Retourne null si aucun exercice détaillé → l'AIService utilisera
     * le calcul basé sur targetMuscles.
     */
    public Double getExerciseBasedMuscleRiskScore() {
        if (exercises == null || exercises.isEmpty()) return null;
        double totalWeightedRisk = 0.0;
        double totalWeight = 0.0;
        for (SessionExercise ex : exercises) {
            if (ex.getWeightKg() != null && ex.getWeightKg() > 0) {
                totalWeightedRisk += ex.getWeightKg();
                totalWeight += ex.getWeightKg();
            }
        }
        if (totalWeight == 0) return null;
        double avgWeight = totalWeightedRisk / exercises.size();
        if (avgWeight < 20)  return 1.0;
        if (avgWeight < 40)  return 1.5;
        if (avgWeight < 60)  return 2.0;
        if (avgWeight < 100) return 2.5;
        return 3.0;
    }

    // ═══════════════════════════════════════════════════════════════════
    // NOUVELLES MÉTHODES POUR AIService (Limite 8)
    // ═══════════════════════════════════════════════════════════════════

    /**
     * Retourne le poids moyen de la séance.
     * Si des exercices existent → moyenne des poids des exercices
     * Sinon → retourne weightLifted (valeur globale)
     */
    public double getAverageWeight() {
        if (exercises == null || exercises.isEmpty()) {
            return weightLifted;
        }
        return exercises.stream()
                .filter(ex -> ex.getWeightKg() != null && ex.getWeightKg() > 0)
                .mapToDouble(SessionExercise::getWeightKg)
                .average()
                .orElse(weightLifted);
    }

    // ===== Setters =====

    public void setId(Long id)                                      { this.id = id; }
    public void setDate(LocalDate date)                             { this.date = date; }
    public void setDuration(int duration)                           { this.duration = duration; }
    public void setIntensity(int intensity)                         { this.intensity = intensity; }
    public void setWeightLifted(double weightLifted)                { this.weightLifted = weightLifted; }
    public void setMember(Member member)                            { this.member = member; }
    public void setFatigueScore(Double fatigueScore)                { this.fatigueScore = fatigueScore; }
    public void setLoadBalanceScore(Double v)                       { this.loadBalanceScore = v; }
    public void setAclRiskScore(Double v)                           { this.aclRiskScore = v; }
    public void setRecoveryDaysPerWeek(Integer v)                   { this.recoveryDaysPerWeek = v; }
    public void setTargetMuscles(String v)                          { this.targetMuscles = v; }
    public void setHasCardio(Boolean hasCardio)                     { this.hasCardio = hasCardio; }
    public void setCardioDurationMinutes(Integer v)                 { this.cardioDurationMinutes = v; }
    public void setCardioType(String cardioType)                    { this.cardioType = cardioType; }
    public void setCardioIntensity(Integer cardioIntensity)         { this.cardioIntensity = cardioIntensity; }
    public void setPainLevel(Integer painLevel)                     { this.painLevel = painLevel; }
    public void setWarmupDone(Boolean warmupDone)                   { this.warmupDone = warmupDone; }
    public void setExercises(List<SessionExercise> exercises)       { this.exercises = exercises; }
}