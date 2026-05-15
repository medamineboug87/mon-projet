package com.example.project_backend.Controller;

import com.example.project_backend.Entity.Member;
import com.example.project_backend.Entity.Subscription;
import com.example.project_backend.Repository.MemberRepository;
import com.example.project_backend.Repository.SubscriptionPlanRepository;
import com.example.project_backend.Repository.SubscriptionRepository;
import com.example.project_backend.Service.PaymentService;
import com.example.project_backend.Service.SubscriptionService;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/payments")
@CrossOrigin(origins = "*")
public class PaymentController {

    private final PaymentService paymentService;
    private final SubscriptionService subscriptionService;
    private final SubscriptionRepository subscriptionRepository;
    private final MemberRepository memberRepository;
    private final SubscriptionPlanRepository planRepository;


    public PaymentController(
            PaymentService paymentService,
            SubscriptionService subscriptionService,
            SubscriptionRepository subscriptionRepository,
            MemberRepository memberRepository,
            SubscriptionPlanRepository planRepository) {
        this.paymentService = paymentService;
        this.subscriptionService = subscriptionService;
        this.subscriptionRepository = subscriptionRepository;
        this.memberRepository = memberRepository;
        this.planRepository=planRepository;
    }

    // ──────────────────────────────────────────────────
    // 💳 Paiement simulé (carte bancaire — ONLINE)
    // Crée un abonnement ACTIVE directement
    // ──────────────────────────────────────────────────
    @PostMapping("/simulate")
    public ResponseEntity<?> simulatePayment(@RequestBody Map<String, Object> request) {
        try {
            Long memberId = Long.valueOf(request.get("memberId").toString());
            String subscriptionType = (String) request.get("subscriptionType");
            double amount = Double.parseDouble(request.get("amount").toString());

            // Invalider tout abonnement PENDING existant avant d'en créer un nouveau ACTIVE
            List<Subscription> pending = subscriptionRepository
                    .findByMemberIdAndStatus(memberId, "PENDING");
            for (Subscription s : pending) {
                s.setStatus("CANCELLED");
                subscriptionRepository.save(s);
            }

            Map<String, Object> result = paymentService.simulateOnlinePayment(memberId, subscriptionType, amount);

            Subscription subscription = new Subscription();
            subscription.setType(subscriptionType);
            subscription.setStartDate(LocalDate.now());
            subscription.setStatus("ACTIVE");
            subscription.setAutoRenew(true);
            setSubscriptionPriceAndDuration(subscription, subscriptionType);
            subscriptionService.createSubscription(memberId, subscription);

            result.put("subscriptionCreated", true);
            return ResponseEntity.ok(result);

        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ──────────────────────────────────────────────────
    // 💵 Paiement CASH — crée un abonnement PENDING
    // Évite les doublons : annule le PENDING existant avant d'en créer un nouveau
    // ──────────────────────────────────────────────────
    @PostMapping("/cash")
    public ResponseEntity<?> cashPayment(@RequestBody Map<String, Object> request) {
        try {
            Long memberId = Long.valueOf(request.get("memberId").toString());
            String subscriptionType = (String) request.get("subscriptionType");

            // FIX : annuler tout PENDING existant pour éviter les doublons
            List<Subscription> existingPending = subscriptionRepository
                    .findByMemberIdAndStatus(memberId, "PENDING");
            for (Subscription s : existingPending) {
                s.setStatus("CANCELLED");
                subscriptionRepository.save(s);
            }

            Subscription subscription = new Subscription();
            subscription.setType(subscriptionType);
            subscription.setStartDate(LocalDate.now());
            subscription.setStatus("PENDING");
            subscription.setAutoRenew(false);
            setSubscriptionPriceAndDuration(subscription, subscriptionType);
            subscriptionService.createSubscriptionPending(memberId, subscription);

            return ResponseEntity.ok(Map.of(
                    "message", "Présentez-vous à la réception pour payer",
                    "status", "PENDING"
            ));

        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ──────────────────────────────────────────────────
    // ✅ Confirmer un paiement cash → activer l'abonnement
    // Appelé par l'admin depuis AdminDashboard
    // ──────────────────────────────────────────────────
    @PostMapping("/cash/confirm/{subscriptionId}")
    @Transactional
    public ResponseEntity<?> confirmCashPayment(@PathVariable Long subscriptionId) {
        try {
            Subscription subscription = subscriptionRepository.findById(subscriptionId)
                    .orElseThrow(() -> new RuntimeException("Abonnement introuvable"));

            if (!"PENDING".equals(subscription.getStatus())) {
                return ResponseEntity.badRequest().body(
                        Map.of("error", "Cet abonnement n'est pas en attente"));
            }

            subscription.setStatus("ACTIVE");
            subscription.setStartDate(LocalDate.now());
            subscription.setEndDate(
                    LocalDate.now().plusMonths(subscription.getDuration()));
            subscriptionRepository.save(subscription);

            return ResponseEntity.ok(Map.of(
                    "message", "Abonnement activé avec succès",
                    "subscriptionId", subscriptionId
            ));

        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ──────────────────────────────────────────────────
    // ❌ Rejeter un paiement cash → supprime le membre
    // Appelé par l'admin depuis AdminDashboard
    // ──────────────────────────────────────────────────
    @DeleteMapping("/cash/reject/{subscriptionId}")
    @Transactional
    public ResponseEntity<?> rejectCashPayment(@PathVariable Long subscriptionId) {
        try {
            Subscription subscription = subscriptionRepository.findById(subscriptionId)
                    .orElseThrow(() -> new RuntimeException("Abonnement introuvable"));

            if (!"PENDING".equals(subscription.getStatus())) {
                return ResponseEntity.badRequest().body(
                        Map.of("error", "Cet abonnement n'est pas en attente"));
            }

            Member member = subscription.getMember();
            if (member == null) {
                return ResponseEntity.badRequest().body(Map.of("error", "Membre introuvable"));
            }

            // La suppression cascade du membre est gérée par AdminController.deleteMember
            // On délègue simplement en retournant l'ID pour que le front appelle deleteMember
            subscriptionRepository.deleteById(subscriptionId);

            return ResponseEntity.ok(Map.of(
                    "message", "Abonnement rejeté",
                    "memberId", member.getId()
            ));

        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ──────────────────────────────────────────────────
    // 📋 Récupérer tous les abonnements PENDING
    // Appelé par l'admin pour la liste des paiements en attente
    // ──────────────────────────────────────────────────
    @GetMapping("/cash/pending")
    public ResponseEntity<?> getPendingPayments() {
        try {
            List<Subscription> pending = subscriptionRepository.findByStatus("PENDING");
            return ResponseEntity.ok(pending);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── Helper ──
    private void setSubscriptionPriceAndDuration(Subscription sub, String type) {
        if (type == null) return;
        // 1. Chercher dans les plans custom BDD
        planRepository.findByName(type.toUpperCase()).ifPresentOrElse(
                plan -> {
                    sub.setPrice(plan.getPrice());
                    sub.setDuration(plan.getDuration());
                },
                () -> {
                    switch (type.toUpperCase()) {
                        case "BASIC"    -> { sub.setPrice(60);  sub.setDuration(1);  }
                        case "STANDARD" -> { sub.setPrice(150); sub.setDuration(3);  }
                        case "PREMIUM"  -> { sub.setPrice(300); sub.setDuration(6);  }
                        case "ANNUAL"   -> { sub.setPrice(490); sub.setDuration(12); }
                        default -> throw new IllegalArgumentException(
                                "Type d'abonnement inconnu: " + type);
                    }
                }
        );
    }
}