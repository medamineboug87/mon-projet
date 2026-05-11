package com.example.project_backend.Entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Feedback du coach sur une prédiction IA.
 * Permet au coach de valider, corriger ou annoter les prédictions.
 * Ces données servent aussi au réentraînement futur des modèles.
 */
@Entity
@Table(name = "ai_feedbacks")
public class AIFeedback {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // ── Lien vers le membre concerné ──
    @ManyToOne
    @JoinColumn(name = "member_id", nullable = false)
    private Member member;

    // ── Lien vers le coach qui donne le feedback ──
    @ManyToOne
    @JoinColumn(name = "coach_id", nullable = false)
    private Coach coach;

    // ── Lien vers la séance analysée ──
    @ManyToOne
    @JoinColumn(name = "session_id")
    private TrainingSession session;

    // ─────────────────────────────────────────────
    // PRÉDICTIONS ORIGINALES (ce que l'IA a prédit)
    // ─────────────────────────────────────────────

    // Prédiction fatigue originale : "normal" | "fatigué"
    @Column(length = 50)
    private String originalFatigueLabel;

    // Confiance fatigue originale (0.0 - 1.0)
    private Double originalFatigueConfidence;

    // Prédiction blessure originale : "risque faible" | "risque élevé"
    @Column(length = 50)
    private String originalInjuryLabel;

    // Confiance blessure originale (0.0 - 1.0)
    private Double originalInjuryConfidence;

    // Niveau de surcharge original : "NORMAL" | "MODÉRÉ" | "ÉLEVÉ" | "CRITIQUE"
    @Column(length = 20)
    private String originalOverloadLevel;

    // ─────────────────────────────────────────────
    // CORRECTIONS DU COACH
    // ─────────────────────────────────────────────

    /**
     * Le coach valide-t-il la prédiction fatigue ?
     * true  = correct (IA avait raison)
     * false = incorrect (IA s'est trompée)
     * null  = non évalué par le coach
     */
    private Boolean fatiguePredictionCorrect;

    /**
     * Le coach valide-t-il la prédiction blessure ?
     */
    private Boolean injuryPredictionCorrect;

    /**
     * Le coach valide-t-il le niveau de surcharge ?
     */
    private Boolean overloadPredictionCorrect;

    // Correction fatigue selon le coach : "normal" | "fatigué"
    @Column(length = 50)
    private String correctedFatigueLabel;

    // Correction blessure selon le coach : "risque faible" | "risque élevé"
    @Column(length = 50)
    private String correctedInjuryLabel;

    // Correction surcharge selon le coach : "NORMAL" | "MODÉRÉ" | "ÉLEVÉ" | "CRITIQUE"
    @Column(length = 20)
    private String correctedOverloadLevel;

    // ─────────────────────────────────────────────
    // NOTE GLOBALE DU COACH (1-5 étoiles)
    // 1 = très mauvaise prédiction, 5 = parfaite
    // ─────────────────────────────────────────────
    private Integer coachRating; // 1-5

    // Commentaire libre du coach
    @Column(length = 1000)
    private String coachComment;

    // ─────────────────────────────────────────────
    // OBSERVATIONS DU COACH SUR L'ÉTAT DU MEMBRE
    // ─────────────────────────────────────────────

    /**
     * Niveau de fatigue observé réellement par le coach (1-10).
     * null = non renseigné.
     */
    private Integer observedFatigueLevel;

    /**
     * Le membre présentait-il des signes de blessure visibles ?
     */
    private Boolean injurySignsObserved;

    /**
     * Description des signes observés (douleur localisée, boiterie, etc.)
     */
    @Column(length = 500)
    private String injuryObservationDetail;

    /**
     * Charge recommandée par le coach pour la prochaine séance.
     * Peut différer de ce que l'IA suggère.
     * null = pas de recommandation spécifique.
     */
    private Double recommendedNextSessionLoad;

    /**
     * Repos recommandé par le coach (en jours).
     * null = pas de repos particulier recommandé.
     */
    private Integer recommendedRestDays;

    // ─────────────────────────────────────────────
    // MÉTADONNÉES
    // ─────────────────────────────────────────────

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    /**
     * Ce feedback a-t-il déjà été utilisé pour le réentraînement ?
     */
    private Boolean usedForRetraining = false;

    @PrePersist
    public void prePersist() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    // ─────────────────────────────────────────────
    // GETTERS & SETTERS
    // ─────────────────────────────────────────────

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Member getMember() { return member; }
    public void setMember(Member member) { this.member = member; }

    public Coach getCoach() { return coach; }
    public void setCoach(Coach coach) { this.coach = coach; }

    public TrainingSession getSession() { return session; }
    public void setSession(TrainingSession session) { this.session = session; }

    public String getOriginalFatigueLabel() { return originalFatigueLabel; }
    public void setOriginalFatigueLabel(String v) { this.originalFatigueLabel = v; }

    public Double getOriginalFatigueConfidence() { return originalFatigueConfidence; }
    public void setOriginalFatigueConfidence(Double v) { this.originalFatigueConfidence = v; }

    public String getOriginalInjuryLabel() { return originalInjuryLabel; }
    public void setOriginalInjuryLabel(String v) { this.originalInjuryLabel = v; }

    public Double getOriginalInjuryConfidence() { return originalInjuryConfidence; }
    public void setOriginalInjuryConfidence(Double v) { this.originalInjuryConfidence = v; }

    public String getOriginalOverloadLevel() { return originalOverloadLevel; }
    public void setOriginalOverloadLevel(String v) { this.originalOverloadLevel = v; }

    public Boolean getFatiguePredictionCorrect() { return fatiguePredictionCorrect; }
    public void setFatiguePredictionCorrect(Boolean v) { this.fatiguePredictionCorrect = v; }

    public Boolean getInjuryPredictionCorrect() { return injuryPredictionCorrect; }
    public void setInjuryPredictionCorrect(Boolean v) { this.injuryPredictionCorrect = v; }

    public Boolean getOverloadPredictionCorrect() { return overloadPredictionCorrect; }
    public void setOverloadPredictionCorrect(Boolean v) { this.overloadPredictionCorrect = v; }

    public String getCorrectedFatigueLabel() { return correctedFatigueLabel; }
    public void setCorrectedFatigueLabel(String v) { this.correctedFatigueLabel = v; }

    public String getCorrectedInjuryLabel() { return correctedInjuryLabel; }
    public void setCorrectedInjuryLabel(String v) { this.correctedInjuryLabel = v; }

    public String getCorrectedOverloadLevel() { return correctedOverloadLevel; }
    public void setCorrectedOverloadLevel(String v) { this.correctedOverloadLevel = v; }

    public Integer getCoachRating() { return coachRating; }
    public void setCoachRating(Integer v) { this.coachRating = v; }

    public String getCoachComment() { return coachComment; }
    public void setCoachComment(String v) { this.coachComment = v; }

    public Integer getObservedFatigueLevel() { return observedFatigueLevel; }
    public void setObservedFatigueLevel(Integer v) { this.observedFatigueLevel = v; }

    public Boolean getInjurySignsObserved() { return injurySignsObserved; }
    public void setInjurySignsObserved(Boolean v) { this.injurySignsObserved = v; }

    public String getInjuryObservationDetail() { return injuryObservationDetail; }
    public void setInjuryObservationDetail(String v) { this.injuryObservationDetail = v; }

    public Double getRecommendedNextSessionLoad() { return recommendedNextSessionLoad; }
    public void setRecommendedNextSessionLoad(Double v) { this.recommendedNextSessionLoad = v; }

    public Integer getRecommendedRestDays() { return recommendedRestDays; }
    public void setRecommendedRestDays(Integer v) { this.recommendedRestDays = v; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime v) { this.createdAt = v; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime v) { this.updatedAt = v; }

    public Boolean getUsedForRetraining() { return usedForRetraining; }
    public void setUsedForRetraining(Boolean v) { this.usedForRetraining = v; }
}
