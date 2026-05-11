package com.example.project_backend.Repository;

import com.example.project_backend.Entity.AIFeedback;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AIFeedbackRepository extends JpaRepository<AIFeedback, Long> {

    // ── Feedbacks par membre ──
    List<AIFeedback> findByMemberIdOrderByCreatedAtDesc(Long memberId);

    // ── Feedbacks par coach ──
    List<AIFeedback> findByCoachIdOrderByCreatedAtDesc(Long coachId);

    // ── Feedback par séance (un seul par session) ──
    Optional<AIFeedback> findBySessionId(Long sessionId);

    // ── Feedbacks non utilisés pour le réentraînement ──
    List<AIFeedback> findByUsedForRetrainingFalse();

    // ── Feedbacks avec correction (prédiction marquée incorrecte) ──
    @Query("""
        SELECT f FROM AIFeedback f
        WHERE f.fatiguePredictionCorrect = false
           OR f.injuryPredictionCorrect  = false
           OR f.overloadPredictionCorrect = false
        ORDER BY f.createdAt DESC
        """)
    List<AIFeedback> findAllWithCorrections();

    // ── Taux de précision global (feedbacks validés / total feedbacks évalués) ──
    @Query("""
        SELECT COUNT(f) FROM AIFeedback f
        WHERE f.fatiguePredictionCorrect = true
        """)
    long countCorrectFatiguePredictions();

    @Query("""
        SELECT COUNT(f) FROM AIFeedback f
        WHERE f.fatiguePredictionCorrect IS NOT NULL
        """)
    long countEvaluatedFatiguePredictions();

    @Query("""
        SELECT COUNT(f) FROM AIFeedback f
        WHERE f.injuryPredictionCorrect = true
        """)
    long countCorrectInjuryPredictions();

    @Query("""
        SELECT COUNT(f) FROM AIFeedback f
        WHERE f.injuryPredictionCorrect IS NOT NULL
        """)
    long countEvaluatedInjuryPredictions();

    // ── Feedbacks par membre et coach ──
    List<AIFeedback> findByMemberIdAndCoachIdOrderByCreatedAtDesc(Long memberId, Long coachId);

    // ── Nombre de feedbacks d'un coach ──
    long countByCoachId(Long coachId);

    // ── Suppression par membre (cascade) ──
    void deleteByMemberId(Long memberId);

    // ── Suppression par session ──
    void deleteBySessionId(Long sessionId);
}
