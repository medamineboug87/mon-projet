// 📁 src/main/java/com/example/project_backend/Repository/AIFeedbackRepository.java

package com.example.project_backend.Repository;

import com.example.project_backend.Entity.AIFeedback;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AIFeedbackRepository extends JpaRepository<AIFeedback, Long> {

    // Find by member
    List<AIFeedback> findByMemberIdOrderByCreatedAtDesc(Long memberId);

    // Find by coach
    List<AIFeedback> findByCoachIdOrderByCreatedAtDesc(Long coachId);

    // Find by session
    Optional<AIFeedback> findBySessionId(Long sessionId);

    // Find not used for retraining
    List<AIFeedback> findByUsedForRetrainingFalse();

    // ═══════════════════════════════════════════════════════════════
    // STATISTIQUES - FATIGUE
    // ═══════════════════════════════════════════════════════════════

    @Query("SELECT COUNT(f) FROM AIFeedback f WHERE f.fatiguePredictionCorrect = true")
    long countCorrectFatiguePredictions();

    @Query("SELECT COUNT(f) FROM AIFeedback f WHERE f.fatiguePredictionCorrect IS NOT NULL")
    long countEvaluatedFatiguePredictions();

    // ═══════════════════════════════════════════════════════════════
    // STATISTIQUES - BLESSURE
    // ═══════════════════════════════════════════════════════════════

    @Query("SELECT COUNT(f) FROM AIFeedback f WHERE f.injuryPredictionCorrect = true")
    long countCorrectInjuryPredictions();

    @Query("SELECT COUNT(f) FROM AIFeedback f WHERE f.injuryPredictionCorrect IS NOT NULL")
    long countEvaluatedInjuryPredictions();

    // ═══════════════════════════════════════════════════════════════
    // FEEDBACKS AVEC CORRECTIONS
    // ═══════════════════════════════════════════════════════════════

    @Query("SELECT f FROM AIFeedback f WHERE f.fatiguePredictionCorrect = false OR f.injuryPredictionCorrect = false ORDER BY f.createdAt DESC")
    List<AIFeedback> findAllWithCorrections();

    @Query("SELECT AVG(f.coachRating) FROM AIFeedback f WHERE f.coachRating IS NOT NULL")
    Double findAverageRating();
}