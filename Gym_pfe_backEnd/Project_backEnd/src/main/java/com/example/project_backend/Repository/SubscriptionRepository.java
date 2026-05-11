package com.example.project_backend.Repository;

import com.example.project_backend.Entity.Subscription;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SubscriptionRepository extends JpaRepository<Subscription, Long> {
    List<Subscription> findByMemberId(Long memberId);
    List<Subscription> findByMemberIdAndStatus(Long memberId, String status);
    List<Subscription> findByStatus(String status);
    void deleteByMemberId(Long memberId);
}