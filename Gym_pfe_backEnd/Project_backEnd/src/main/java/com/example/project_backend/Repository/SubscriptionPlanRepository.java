package com.example.project_backend.Repository;

import com.example.project_backend.Entity.SubscriptionPlan;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SubscriptionPlanRepository extends JpaRepository<SubscriptionPlan, Long> {
    List<SubscriptionPlan> findByActiveTrue();
    Optional<SubscriptionPlan> findByName(String name);
    boolean existsByName(String name);
}