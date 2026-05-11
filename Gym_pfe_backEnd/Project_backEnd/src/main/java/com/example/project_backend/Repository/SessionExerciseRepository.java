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
}