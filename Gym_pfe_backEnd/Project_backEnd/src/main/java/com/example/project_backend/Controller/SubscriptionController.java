package com.example.project_backend.Controller;

import com.example.project_backend.Entity.Subscription;
import com.example.project_backend.Service.SubscriptionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/subscriptions")
@CrossOrigin
public class SubscriptionController {

    private final SubscriptionService subscriptionService;

    public SubscriptionController(SubscriptionService subscriptionService) {
        this.subscriptionService = subscriptionService;
    }

    // ── Créer un abonnement ──
    @PostMapping("/member/{memberId}")
    public ResponseEntity<Subscription> createSubscription(
            @PathVariable Long memberId,
            @RequestBody Subscription subscription) {
        return ResponseEntity.ok(
                subscriptionService.createSubscription(memberId, subscription));
    }

    // ── Abonnement actif d'un membre ──
    @GetMapping("/member/{memberId}/active")
    public ResponseEntity<Map<String, Object>> getActiveSubscription(
            @PathVariable Long memberId) {

        Subscription subscription = subscriptionService
                .getActiveMemberSubscription(memberId);

        Map<String, Object> response = new HashMap<>();

        if (subscription == null) {
            response.put("hasSubscription", false);
            response.put("message", "Aucun abonnement actif");
            return ResponseEntity.ok(response);
        }

        // ✅ FIX : null-safe — si endDate null on retourne 0 jours et statut ACTIF
        String status = subscriptionService.getSubscriptionStatus(subscription.getId());
        long daysRemaining = subscriptionService.getDaysRemaining(subscription.getId());

        boolean isExpiring = subscription.getEndDate() != null && subscription.isExpiringSoon();
        boolean isExpired  = subscription.getEndDate() != null && subscription.isExpired();

        response.put("hasSubscription", true);
        response.put("subscription", subscription);
        response.put("status", status);
        response.put("daysRemaining", daysRemaining);
        response.put("isExpiring", isExpiring);
        response.put("isExpired", isExpired);

        return ResponseEntity.ok(response);
    }

    // ── Tous les abonnements d'un membre ──
    @GetMapping("/member/{memberId}")
    public ResponseEntity<List<Subscription>> getMemberSubscriptions(
            @PathVariable Long memberId) {
        return ResponseEntity.ok(
                subscriptionService.getMemberSubscriptions(memberId));
    }

    // ── Renouveler ──
    @PostMapping("/{subscriptionId}/renew")
    public ResponseEntity<Map<String, Object>> renewSubscription(
            @PathVariable Long subscriptionId) {

        Subscription renewed = subscriptionService.renewSubscription(subscriptionId);
        String status = subscriptionService.getSubscriptionStatus(subscriptionId);
        long daysRemaining = subscriptionService.getDaysRemaining(subscriptionId);

        return ResponseEntity.ok(Map.of(
                "message", "Abonnement renouvelé avec succès",
                "subscription", renewed,
                "status", status,
                "daysRemaining", daysRemaining
        ));
    }

    // ── Annuler ──
    @PostMapping("/{subscriptionId}/cancel")
    public ResponseEntity<Map<String, Object>> cancelSubscription(
            @PathVariable Long subscriptionId) {

        subscriptionService.cancelSubscription(subscriptionId);
        return ResponseEntity.ok(Map.of(
                "message", "Abonnement annulé",
                "subscriptionId", subscriptionId
        ));
    }

    // ── Statut détaillé ──
    @GetMapping("/{subscriptionId}/status")
    public ResponseEntity<Map<String, Object>> getStatus(
            @PathVariable Long subscriptionId) {

        String status = subscriptionService.getSubscriptionStatus(subscriptionId);
        long daysRemaining = subscriptionService.getDaysRemaining(subscriptionId);

        return ResponseEntity.ok(Map.of(
                "status", status,
                "daysRemaining", daysRemaining
        ));
    }
}