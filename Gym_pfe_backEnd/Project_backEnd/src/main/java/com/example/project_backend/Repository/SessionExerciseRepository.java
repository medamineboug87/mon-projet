package com.example.project_backend.Repository;

import com.example.project_backend.Entity.SessionExercise;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Repository
public interface SessionExerciseRepository extends JpaRepository<SessionExercise, Long> {

    // ── Tous les exercices d'une séance (triés par ordre) ──
    List<SessionExercise> findBySessionIdOrderByExerciseOrderAsc(Long sessionId);

    // ── Tous les exercices d'un membre (toutes séances) ──
    @Query("""
        SELECT se FROM SessionExercise se
        WHERE se.session.member.id = :memberId
        ORDER BY se.session.date DESC, se.exerciseOrder ASC
        """)
    List<SessionExercise> findByMemberIdOrderByDateDesc(@Param("memberId") Long memberId);

    // ── Historique d'un exercice spécifique pour un membre ──
    // Permet de calculer la progression des charges
    @Query("""
        SELECT se FROM SessionExercise se
        WHERE se.session.member.id = :memberId
          AND LOWER(se.exerciseName) = LOWER(:exerciseName)
        ORDER BY se.session.date DESC
        """)
    List<SessionExercise> findByMemberIdAndExerciseName(
            @Param("memberId") Long memberId,
            @Param("exerciseName") String exerciseName);

    // ── Exercices d'un muscle spécifique pour un membre (dernière semaine) ──
    @Query("""
        SELECT se FROM SessionExercise se
        WHERE se.session.member.id = :memberId
          AND LOWER(se.muscleName) = LOWER(:muscleName)
          AND se.session.date >= CURRENT_DATE - 7
        ORDER BY se.session.date DESC
        """)
    List<SessionExercise> findRecentByMemberAndMuscle(
            @Param("memberId") Long memberId,
            @Param("muscleName") String muscleName);

    // ── Charge maximale utilisée par exercice pour un membre ──
    @Query("""
        SELECT MAX(se.weightKg) FROM SessionExercise se
        WHERE se.session.member.id = :memberId
          AND LOWER(se.exerciseName) = LOWER(:exerciseName)
        """)
    Double findMaxWeightByMemberAndExercise(
            @Param("memberId") Long memberId,
            @Param("exerciseName") String exerciseName);

    // ── Volume total par muscle sur les 7 derniers jours ──
    @Query("""
        SELECT se.muscleName, SUM(se.totalVolume)
        FROM SessionExercise se
        WHERE se.session.member.id = :memberId
          AND se.session.date >= CURRENT_DATE - 7
        GROUP BY se.muscleName
        """)
    List<Object[]> findWeeklyVolumeByMuscle(@Param("memberId") Long memberId);

    // ── Suppression des exercices d'une séance (utile si séance supprimée) ──
    @Modifying
    @Transactional
    void deleteBySessionId(Long sessionId);

    // ── Suppression de tous les exercices d'un membre (pour suppression cascade) ──
    @Modifying
    @Transactional
    @Query("DELETE FROM SessionExercise se WHERE se.session.member.id = :memberId")
    void deleteByMemberId(@Param("memberId") Long memberId);
}
