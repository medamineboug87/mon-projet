package com.example.project_backend.Repository;

import com.example.project_backend.Entity.TrainingSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface TrainingSessionRepository extends JpaRepository<TrainingSession,Long> {
    List<TrainingSession> findByMemberId(Long memberId);
    void deleteByMemberId(Long memberId);
    @Query("SELECT s FROM TrainingSession s WHERE s.member.id = :memberId AND s.date >= :since")
    List<TrainingSession> findByMemberIdSince(@Param("memberId") Long memberId,
                                              @Param("since") java.time.LocalDate since);
}
