// 📁 src/main/java/com/example/project_backend/Entity/AIFeedback.java

package com.example.project_backend.Entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "ai_feedbacks")
public class AIFeedback {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Relations
    @ManyToOne
    @JoinColumn(name = "member_id", nullable = false)
    private Member member;

    @ManyToOne
    @JoinColumn(name = "coach_id", nullable = false)
    private Coach coach;

    @ManyToOne
    @JoinColumn(name = "session_id")
    private TrainingSession session;

    // ═══════════════════════════════════════════════════════════════
    // PRÉDICTIONS ORIGINALES (stockées pour référence)
    // ═══════════════════════════════════════════════════════════════

    @Column(length = 50)
    private String originalFatigueLabel;

    private Double originalFatigueConfidence;

    @Column(length = 50)
    private String originalInjuryLabel;

    private Double originalInjuryConfidence;

    @Column(length = 20)
    private String originalOverloadLevel;

    // ═══════════════════════════════════════════════════════════════
    // ✅ CORRECTIONS STRUCTURÉES (utilisées par le ML)
    // ═══════════════════════════════════════════════════════════════

    private Boolean fatiguePredictionCorrect;   // true/false/null
    private Boolean injuryPredictionCorrect;
    private Boolean overloadPredictionCorrect;

    @Column(length = 20)
    private String correctedFatigueLabel;       // "normal" ou "fatigué" UNIQUEMENT

    @Column(length = 20)
    private String correctedInjuryLabel;        // "risque faible" ou "risque élevé" UNIQUEMENT

    @Column(length = 20)
    private String correctedOverloadLevel;      // "NORMAL","MODÉRÉ","ÉLEVÉ","CRITIQUE"

    // ═══════════════════════════════════════════════════════════════
    // NOTE ET OBSERVATIONS
    // ═══════════════════════════════════════════════════════════════

    private Integer coachRating;                // 1-5 étoiles

    @Column(length = 1000)
    private String coachComment;                // 📝 TEXTE LIBRE (stocké seulement)

    private Integer observedFatigueLevel;       // 0-10
    private Boolean injurySignsObserved;

    @Column(length = 500)
    private String injuryObservationDetail;

    private Double recommendedNextSessionLoad;
    private Integer recommendedRestDays;

    // ═══════════════════════════════════════════════════════════════
    // MÉTADONNÉES
    // ═══════════════════════════════════════════════════════════════

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
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

    // ═══════════════════════════════════════════════════════════════
    // GETTERS & SETTERS (tous)
    // ═══════════════════════════════════════════════════════════════

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