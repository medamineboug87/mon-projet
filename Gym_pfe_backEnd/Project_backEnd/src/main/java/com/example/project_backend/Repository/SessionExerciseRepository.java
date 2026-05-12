package com.example.project_backend.Repository;

import com.example.project_backend.Entity.SessionExercise;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface SessionExerciseRepository extends JpaRepository<SessionExercise, Long> {

    List<SessionExercise> findBySessionIdOrderByExerciseOrderAsc(Long sessionId);

    void deleteBySessionId(Long sessionId);

    @Query("SELECT se FROM SessionExercise se WHERE se.session.member.id = :memberId AND se.exerciseName = :exerciseName ORDER BY se.session.date DESC")
    List<SessionExercise> findByMemberIdAndExerciseName(@Param("memberId") Long memberId,
                                                        @Param("exerciseName") String exerciseName);

    @Query("SELECT MAX(se.weightKg) FROM SessionExercise se WHERE se.session.member.id = :memberId AND se.exerciseName = :exerciseName")
    Double findMaxWeightByMemberAndExercise(@Param("memberId") Long memberId,
                                            @Param("exerciseName") String exerciseName);

    // ✅ CORRIGÉ : utilise un paramètre LocalDate au lieu de CURRENT_DATE - 7
    @Query("SELECT se.muscleName, SUM(se.weightKg * se.setsCompleted * CAST(SUBSTRING(se.repsCompleted, 1, LOCATE('-', se.repsCompleted) - 1) AS int)) " +
            "FROM SessionExercise se " +
            "WHERE se.session.member.id = :memberId " +
            "AND se.session.date >= :sevenDaysAgo " +
            "GROUP BY se.muscleName")
    List<Object[]> findWeeklyVolumeByMuscle(@Param("memberId") Long memberId,
                                            @Param("sevenDaysAgo") LocalDate sevenDaysAgo);

    // ════════════════════════════════════════════════════════════════════
    // LIMITE 8 — Surveillance de la progression des charges par exercice
    // ════════════════════════════════════════════════════════════════════

    /**
     * Récupère les N dernières occurrences d'un exercice pour un membre,
     * ordonnées du plus récent au plus ancien.
     * Utilisé pour calculer la progression des charges exercice par exercice.
     */
    @Query("""
        SELECT se FROM SessionExercise se
        WHERE se.session.member.id = :memberId
          AND LOWER(se.exerciseName) = LOWER(:exerciseName)
        ORDER BY se.session.date DESC
        """)
    List<SessionExercise> findLastOccurrencesByExercise(
            @Param("memberId") Long memberId,
            @Param("exerciseName") String exerciseName);

    /**
     * Récupère tous les exercices d'une séance en cours (par sessionId)
     * pour les comparer aux occurrences précédentes du même exercice.
     */
    @Query("""
        SELECT se FROM SessionExercise se
        WHERE se.session.id = :sessionId
        ORDER BY se.exerciseOrder ASC
        """)
    List<SessionExercise> findCurrentSessionExercises(@Param("sessionId") Long sessionId);

    /**
     * Cherche la dernière occurrence d'un exercice pour un membre
     * AVANT une date donnée (excluant la séance courante).
     * Retourne au max les 4 dernières séances précédentes.
     */
    @Query("""
        SELECT se FROM SessionExercise se
        WHERE se.session.member.id = :memberId
          AND LOWER(se.exerciseName) = LOWER(:exerciseName)
          AND se.session.date < :beforeDate
        ORDER BY se.session.date DESC
        """)
    List<SessionExercise> findPreviousOccurrencesByExercise(
            @Param("memberId") Long memberId,
            @Param("exerciseName") String exerciseName,
            @Param("beforeDate") LocalDate beforeDate);
}