package com.example.project_backend.Controller;

import com.example.project_backend.Entity.Subscription;
import com.example.project_backend.Entity.SubscriptionPlan;
import com.example.project_backend.Repository.SubscriptionPlanRepository;
import com.example.project_backend.Repository.SubscriptionRepository;
import com.example.project_backend.Service.SubscriptionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/admin/subscriptions")
@CrossOrigin(origins = "*")
public class AdminSubscriptionController {

    private final SubscriptionRepository subscriptionRepository;
    private final SubscriptionService subscriptionService;
    private final SubscriptionPlanRepository planRepository;

    public AdminSubscriptionController(SubscriptionRepository subscriptionRepository,
                                       SubscriptionService subscriptionService,
                                       SubscriptionPlanRepository planRepository) {
        this.subscriptionRepository = subscriptionRepository;
        this.subscriptionService = subscriptionService;
        this.planRepository = planRepository;
    }

    // ── GET ALL ──
    @GetMapping
    public ResponseEntity<List<Subscription>> getAllSubscriptions() {
        return ResponseEntity.ok(subscriptionRepository.findAll());
    }

    // ── GET BY ID ──
    @GetMapping("/{id}")
    public ResponseEntity<?> getSubscriptionById(@PathVariable Long id) {
        return subscriptionRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ── GET BY MEMBER ──
    @GetMapping("/member/{memberId}")
    public ResponseEntity<List<Subscription>> getByMember(@PathVariable Long memberId) {
        return ResponseEntity.ok(subscriptionRepository.findByMemberId(memberId));
    }

    // ── GET BY STATUS ──
    @GetMapping("/status/{status}")
    public ResponseEntity<List<Subscription>> getByStatus(@PathVariable String status) {
        return ResponseEntity.ok(subscriptionRepository.findByStatus(status));
    }

    // ── STATS ──
    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getStats() {
        List<Subscription> all = subscriptionRepository.findAll();
        Map<String, Object> stats = new HashMap<>();
        stats.put("total", all.size());
        stats.put("active", all.stream().filter(s -> "ACTIVE".equals(s.getStatus())).count());
        stats.put("pending", all.stream().filter(s -> "PENDING".equals(s.getStatus())).count());
        stats.put("suspended", all.stream().filter(s -> "SUSPENDED".equals(s.getStatus())).count());
        stats.put("cancelled", all.stream().filter(s -> "CANCELLED".equals(s.getStatus())).count());

        double revenue = all.stream()
                .filter(s -> "ACTIVE".equals(s.getStatus()))
                .mapToDouble(Subscription::getPrice)
                .sum();
        stats.put("totalRevenue", revenue);

        // Compter par type (incluant les plans custom)
        Map<String, Long> byType = new HashMap<>();
        all.forEach(s -> {
            String type = s.getType() != null ? s.getType() : "UNKNOWN";
            byType.merge(type, 1L, Long::sum);
        });
        stats.put("byType", byType);

        // Rétrocompatibilité avec les types standard
        stats.put("basicCount", byType.getOrDefault("BASIC", 0L));
        stats.put("standardCount", byType.getOrDefault("STANDARD", 0L));
        stats.put("premiumCount", byType.getOrDefault("PREMIUM", 0L));
        stats.put("annualCount", byType.getOrDefault("ANNUAL", 0L));

        return ResponseEntity.ok(stats);
    }

    // ── CREATE ──
    @PostMapping("/member/{memberId}")
    public ResponseEntity<?> createSubscription(@PathVariable Long memberId,
                                                @RequestBody Map<String, Object> request) {
        try {
            Subscription sub = new Subscription();
            sub.setType((String) request.get("type"));
            sub.setStatus((String) request.getOrDefault("status", "ACTIVE"));
            sub.setAutoRenew((Boolean) request.getOrDefault("autoRenew", true));
            sub.setCreatedAt(LocalDateTime.now());
            sub.setUpdatedAt(LocalDateTime.now());

            if (request.get("startDate") != null)
                sub.setStartDate(LocalDate.parse((String) request.get("startDate")));
            else
                sub.setStartDate(LocalDate.now());

            // Appliquer les defaults du plan (standard ou custom)
            setTypeDefaults(sub, sub.getType());

            // Prix custom (remise)
            if (request.get("customPrice") != null) {
                sub.setPrice(Double.parseDouble(request.get("customPrice").toString()));
            }

            if ("ACTIVE".equals(sub.getStatus()) && sub.getEndDate() == null)
                sub.setEndDate(sub.getStartDate().plusMonths(sub.getDuration()));

            return ResponseEntity.ok(subscriptionService.createSubscription(memberId, sub));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── UPDATE ──
    @PutMapping("/{id}")
    public ResponseEntity<?> updateSubscription(@PathVariable Long id,
                                                @RequestBody Map<String, Object> request) {
        try {
            Subscription sub = subscriptionRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Abonnement introuvable"));

            if (request.get("type") != null) {
                sub.setType((String) request.get("type"));
                setTypeDefaults(sub, sub.getType());
            }
            if (request.get("status") != null) sub.setStatus((String) request.get("status"));
            if (request.get("startDate") != null)
                sub.setStartDate(LocalDate.parse((String) request.get("startDate")));
            if (request.get("endDate") != null)
                sub.setEndDate(LocalDate.parse((String) request.get("endDate")));
            if (request.get("autoRenew") != null)
                sub.setAutoRenew((Boolean) request.get("autoRenew"));
            if (request.get("price") != null)
                sub.setPrice(Double.parseDouble(request.get("price").toString()));
            if (request.get("duration") != null)
                sub.setDuration(Integer.parseInt(request.get("duration").toString()));

            sub.setUpdatedAt(LocalDateTime.now());
            return ResponseEntity.ok(subscriptionRepository.save(sub));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── DELETE ──
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteSubscription(@PathVariable Long id) {
        try {
            subscriptionRepository.deleteById(id);
            return ResponseEntity.ok(Map.of("message", "Abonnement supprimé"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── ACTIVATE ──
    @PostMapping("/{id}/activate")
    public ResponseEntity<?> activateSubscription(@PathVariable Long id) {
        try {
            Subscription sub = subscriptionRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Abonnement introuvable"));
            sub.setStatus("ACTIVE");
            sub.setStartDate(LocalDate.now());
            sub.setEndDate(LocalDate.now().plusMonths(sub.getDuration()));
            sub.setUpdatedAt(LocalDateTime.now());
            return ResponseEntity.ok(subscriptionRepository.save(sub));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── SUSPEND ──
    @PostMapping("/{id}/suspend")
    public ResponseEntity<?> suspendSubscription(@PathVariable Long id) {
        try {
            Subscription sub = subscriptionRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Abonnement introuvable"));
            sub.setStatus("SUSPENDED");
            sub.setUpdatedAt(LocalDateTime.now());
            return ResponseEntity.ok(subscriptionRepository.save(sub));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── CANCEL ──
    @PostMapping("/{id}/cancel")
    public ResponseEntity<?> cancelSubscription(@PathVariable Long id) {
        try {
            Subscription sub = subscriptionRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Abonnement introuvable"));
            sub.setStatus("CANCELLED");
            sub.setUpdatedAt(LocalDateTime.now());
            return ResponseEntity.ok(subscriptionRepository.save(sub));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── APPLY DISCOUNT ──
    @PostMapping("/{id}/discount")
    public ResponseEntity<?> applyDiscount(@PathVariable Long id,
                                           @RequestBody Map<String, Object> request) {
        try {
            Subscription sub = subscriptionRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Abonnement introuvable"));

            String discountType = (String) request.getOrDefault("discountType", "PERCENTAGE");
            double discountValue = Double.parseDouble(request.get("discountValue").toString());

            double originalPrice = sub.getPrice();
            double newPrice;

            if ("PERCENTAGE".equals(discountType)) {
                if (discountValue < 0 || discountValue > 100)
                    return ResponseEntity.badRequest().body(Map.of("error", "Pourcentage invalide (0-100)"));
                newPrice = originalPrice * (1 - discountValue / 100.0);
            } else {
                newPrice = Math.max(0, originalPrice - discountValue);
            }

            newPrice = Math.round(newPrice * 100.0) / 100.0;
            sub.setPrice(newPrice);
            sub.setUpdatedAt(LocalDateTime.now());
            Subscription saved = subscriptionRepository.save(sub);

            return ResponseEntity.ok(Map.of(
                    "message", "Réduction appliquée avec succès",
                    "originalPrice", originalPrice,
                    "newPrice", newPrice,
                    "discount", discountValue,
                    "discountType", discountType,
                    "subscription", saved
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── EXTEND ──
    @PostMapping("/{id}/extend")
    public ResponseEntity<?> extendSubscription(@PathVariable Long id,
                                                @RequestBody Map<String, Object> request) {
        try {
            Subscription sub = subscriptionRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Abonnement introuvable"));

            int extraMonths = Integer.parseInt(request.getOrDefault("months", 1).toString());
            if (extraMonths <= 0)
                return ResponseEntity.badRequest().body(Map.of("error", "Durée invalide"));

            LocalDate currentEnd = sub.getEndDate() != null ? sub.getEndDate() : LocalDate.now();
            sub.setEndDate(currentEnd.plusMonths(extraMonths));
            sub.setDuration(sub.getDuration() + extraMonths);
            sub.setUpdatedAt(LocalDateTime.now());

            return ResponseEntity.ok(Map.of(
                    "message", "Abonnement prolongé de " + extraMonths + " mois",
                    "newEndDate", sub.getEndDate().toString(),
                    "subscription", subscriptionRepository.save(sub)
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── RENEW ──
    @PostMapping("/{id}/renew")
    public ResponseEntity<?> renewSubscription(@PathVariable Long id) {
        try {
            Subscription sub = subscriptionRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Abonnement introuvable"));
            sub.renew();
            sub.setUpdatedAt(LocalDateTime.now());
            return ResponseEntity.ok(subscriptionRepository.save(sub));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── BULK DISCOUNT ──
    @PostMapping("/bulk-discount")
    public ResponseEntity<?> bulkDiscount(@RequestBody Map<String, Object> request) {
        try {
            String subscriptionType = (String) request.get("type");
            String discountType = (String) request.getOrDefault("discountType", "PERCENTAGE");
            double discountValue = Double.parseDouble(request.get("discountValue").toString());

            List<Subscription> targets = subscriptionType != null
                    ? subscriptionRepository.findAll().stream()
                    .filter(s -> "ACTIVE".equals(s.getStatus()) && subscriptionType.equals(s.getType()))
                    .toList()
                    : subscriptionRepository.findByStatus("ACTIVE");

            int count = 0;
            for (Subscription sub : targets) {
                double newPrice = "PERCENTAGE".equals(discountType)
                        ? sub.getPrice() * (1 - discountValue / 100.0)
                        : Math.max(0, sub.getPrice() - discountValue);
                sub.setPrice(Math.round(newPrice * 100.0) / 100.0);
                sub.setUpdatedAt(LocalDateTime.now());
                subscriptionRepository.save(sub);
                count++;
            }

            return ResponseEntity.ok(Map.of(
                    "message", "Réduction appliquée à " + count + " abonnement(s)",
                    "count", count
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── RESET PRICE ──
    @PostMapping("/{id}/reset-price")
    public ResponseEntity<?> resetPrice(@PathVariable Long id) {
        try {
            Subscription sub = subscriptionRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Abonnement introuvable"));
            setTypeDefaults(sub, sub.getType());
            sub.setUpdatedAt(LocalDateTime.now());
            return ResponseEntity.ok(Map.of(
                    "message", "Prix remis au tarif standard",
                    "newPrice", sub.getPrice(),
                    "subscription", subscriptionRepository.save(sub)
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── CHANGE TYPE ──
    @PostMapping("/{id}/change-type")
    public ResponseEntity<?> changeType(@PathVariable Long id,
                                        @RequestBody Map<String, Object> request) {
        try {
            Subscription sub = subscriptionRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Abonnement introuvable"));
            String newType = (String) request.get("type");
            boolean keepPrice = Boolean.TRUE.equals(request.get("keepPrice"));

            sub.setType(newType);
            if (!keepPrice) setTypeDefaults(sub, newType);

            sub.setStartDate(LocalDate.now());
            sub.setEndDate(LocalDate.now().plusMonths(sub.getDuration()));
            sub.setUpdatedAt(LocalDateTime.now());

            return ResponseEntity.ok(subscriptionRepository.save(sub));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ──────────────────────────────────────────────
    // HELPER : applique prix/durée selon le type
    // Cherche d'abord dans les plans custom, puis fallback sur les types hardcodés
    // ──────────────────────────────────────────────
    private void setTypeDefaults(Subscription sub, String type) {
        if (type == null) return;

        // 1. Chercher dans les plans custom en BDD
        planRepository.findByName(type.toUpperCase()).ifPresentOrElse(
                plan -> {
                    sub.setPrice(plan.getPrice());
                    sub.setDuration(plan.getDuration());
                },
                // 2. Fallback sur les types standard hardcodés
                () -> {
                    switch (type.toUpperCase()) {
                        case "BASIC"    -> { sub.setPrice(60);  sub.setDuration(1);  }
                        case "STANDARD" -> { sub.setPrice(150); sub.setDuration(3);  }
                        case "PREMIUM"  -> { sub.setPrice(300); sub.setDuration(6);  }
                        case "ANNUAL"   -> { sub.setPrice(490); sub.setDuration(12); }
                        // Type inconnu : ne rien modifier (admin a peut-être déjà mis prix/durée manuellement)
                    }
                }
        );
    }
}