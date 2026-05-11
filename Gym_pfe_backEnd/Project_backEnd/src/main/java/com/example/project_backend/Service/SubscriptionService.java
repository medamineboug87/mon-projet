package com.example.project_backend.Service;

import com.example.project_backend.Entity.Member;
import com.example.project_backend.Entity.Subscription;
import com.example.project_backend.Repository.MemberRepository;
import com.example.project_backend.Repository.SubscriptionRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
public class SubscriptionService {

    private final SubscriptionRepository subscriptionRepository;
    private final MemberRepository memberRepository;

    public SubscriptionService(SubscriptionRepository subscriptionRepository,
                               MemberRepository memberRepository) {
        this.subscriptionRepository = subscriptionRepository;
        this.memberRepository = memberRepository;
    }

    // ── Créer abonnement ACTIVE (paiement en ligne confirmé) ──
    public Subscription createSubscription(Long memberId, Subscription subscription) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new RuntimeException("Member not found"));

        subscription.setMember(member);
        subscription.setStatus("ACTIVE");
        subscription.setCreatedAt(LocalDateTime.now());
        subscription.setUpdatedAt(LocalDateTime.now());

        if (subscription.getStartDate() == null) {
            subscription.setStartDate(LocalDate.now());
        }
        subscription.setEndDate(
                subscription.getStartDate().plusMonths(subscription.getDuration())
        );

        return subscriptionRepository.save(subscription);
    }

    // ── Créer abonnement PENDING (espèces — pas encore payé) ──
    public Subscription createSubscriptionPending(Long memberId, Subscription subscription) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new RuntimeException("Member not found"));

        subscription.setMember(member);
        if (subscription.getStatus() == null) {
            subscription.setStatus("PENDING");
        }
        subscription.setCreatedAt(LocalDateTime.now());
        subscription.setUpdatedAt(LocalDateTime.now());

        if (subscription.getStartDate() == null) {
            subscription.setStartDate(LocalDate.now());
        }
        // endDate non calculée pour PENDING — sera fixée à l'activation par l'admin

        return subscriptionRepository.save(subscription);
    }

    // ── Récupérer l'abonnement actif d'un membre ──
    // FIX : filtre aussi les abonnements dont endDate est passée
    // (le statut en base peut ne pas avoir été mis à jour automatiquement)
    public Subscription getActiveMemberSubscription(Long memberId) {
        List<Subscription> subscriptions = subscriptionRepository
                .findByMemberIdAndStatus(memberId, "ACTIVE");

        if (subscriptions.isEmpty()) return null;

        // FIX : ignorer les abonnements réellement expirés
        return subscriptions.stream()
                .filter(s -> s.getEndDate() == null || !s.isExpired())
                .reduce((first, second) -> second) // prendre le plus récent
                .orElse(null);
    }

    // ── Récupérer tous les abonnements d'un membre ──
    public List<Subscription> getMemberSubscriptions(Long memberId) {
        return subscriptionRepository.findByMemberId(memberId);
    }

    // ── Renouveler ──
    public Subscription renewSubscription(Long subscriptionId) {
        Subscription subscription = subscriptionRepository.findById(subscriptionId)
                .orElseThrow(() -> new RuntimeException("Subscription not found"));

        subscription.renew();
        subscription.setUpdatedAt(LocalDateTime.now());
        return subscriptionRepository.save(subscription);
    }

    // ── Annuler ──
    public Subscription cancelSubscription(Long subscriptionId) {
        Subscription subscription = subscriptionRepository.findById(subscriptionId)
                .orElseThrow(() -> new RuntimeException("Subscription not found"));

        subscription.setStatus("CANCELLED");
        subscription.setUpdatedAt(LocalDateTime.now());
        return subscriptionRepository.save(subscription);
    }

    // ── Statut lisible ──
    public String getSubscriptionStatus(Long subscriptionId) {
        Subscription sub = subscriptionRepository.findById(subscriptionId)
                .orElseThrow(() -> new RuntimeException("Subscription not found"));

        if (sub.getEndDate() == null) return "ACTIF";
        if (sub.isExpired())          return "EXPIRÉ";
        if (sub.isExpiringSoon())     return "EXPIRE BIENTÔT";
        return "ACTIF";
    }

    // ── Jours restants ──
    public long getDaysRemaining(Long subscriptionId) {
        Subscription sub = subscriptionRepository.findById(subscriptionId)
                .orElseThrow(() -> new RuntimeException("Subscription not found"));

        if (sub.getEndDate() == null) return 0;
        long days = ChronoUnit.DAYS.between(LocalDate.now(), sub.getEndDate());
        return Math.max(0, days);
    }

    public Subscription getSubscriptionById(Long id) {
        return subscriptionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Subscription not found"));
    }

    public Subscription save(Subscription subscription) {
        return subscriptionRepository.save(subscription);
    }

    public List<Subscription> getSubscriptionsByStatus(String status) {
        return subscriptionRepository.findByStatus(status);
    }
}