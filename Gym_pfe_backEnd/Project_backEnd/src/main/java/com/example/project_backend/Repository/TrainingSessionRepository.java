package com.example.project_backend.Repository;

import com.example.project_backend.Entity.TrainingSession;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TrainingSessionRepository extends JpaRepository<TrainingSession,Long> {
    List<TrainingSession> findByMemberId(Long memberId);
    void deleteByMemberId(Long memberId);
}
