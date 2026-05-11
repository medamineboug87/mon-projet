package com.example.project_backend.Repository;

import com.example.project_backend.Entity.Coach;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CoachRepository extends JpaRepository<Coach, Long> {
    Optional<Coach> findByUserId(Long userId);
    boolean existsByEmail(String email);
}