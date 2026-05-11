package com.example.project_backend.Controller;

import com.example.project_backend.Entity.SubscriptionPlan;
import com.example.project_backend.Repository.SubscriptionPlanRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/admin/plans")
@CrossOrigin
public class SubscriptionPlanController {

    private final SubscriptionPlanRepository planRepository;

    public SubscriptionPlanController(SubscriptionPlanRepository planRepository) {
        this.planRepository = planRepository;
    }

    // ── GET ALL (actifs + inactifs) ──
    @GetMapping
    public ResponseEntity<List<SubscriptionPlan>> getAllPlans() {
        return ResponseEntity.ok(planRepository.findAll());
    }

    // ── GET ACTIFS SEULEMENT (pour les membres) ──
    @GetMapping("/active")
    public ResponseEntity<List<SubscriptionPlan>> getActivePlans() {
        return ResponseEntity.ok(planRepository.findByActiveTrue());
    }

    // ── GET BY ID ──
    @GetMapping("/{id}")
    public ResponseEntity<?> getPlanById(@PathVariable Long id) {
        return planRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ── CREATE ──
    @PostMapping
    public ResponseEntity<?> createPlan(@RequestBody Map<String, Object> request) {
        try {
            String name = (String) request.get("name");
            if (name == null || name.isBlank())
                return ResponseEntity.badRequest().body(Map.of("error", "Le nom est obligatoire"));

            String normalizedName = name.toUpperCase().replace(" ", "_");

            if (planRepository.existsByName(normalizedName))
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "Un plan avec ce nom existe déjà : " + normalizedName));

            SubscriptionPlan plan = new SubscriptionPlan();
            plan.setName(normalizedName);
            plan.setDisplayName((String) request.getOrDefault("displayName", name));
            plan.setDescription((String) request.get("description"));
            plan.setPrice(Double.parseDouble(request.get("price").toString()));
            plan.setDuration(Integer.parseInt(request.get("duration").toString()));
            plan.setActive(true);
            plan.setColor((String) request.getOrDefault("color", "#00E676"));
            plan.setEmoji((String) request.getOrDefault("emoji", "⭐"));

            SubscriptionPlan saved = planRepository.save(plan);
            return ResponseEntity.ok(saved);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── UPDATE ──
    @PutMapping("/{id}")
    public ResponseEntity<?> updatePlan(@PathVariable Long id,
                                        @RequestBody Map<String, Object> request) {
        try {
            SubscriptionPlan plan = planRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Plan introuvable"));

            if (request.get("displayName") != null)
                plan.setDisplayName((String) request.get("displayName"));
            if (request.get("description") != null)
                plan.setDescription((String) request.get("description"));
            if (request.get("price") != null)
                plan.setPrice(Double.parseDouble(request.get("price").toString()));
            if (request.get("duration") != null)
                plan.setDuration(Integer.parseInt(request.get("duration").toString()));
            if (request.get("color") != null)
                plan.setColor((String) request.get("color"));
            if (request.get("emoji") != null)
                plan.setEmoji((String) request.get("emoji"));
            if (request.get("active") != null)
                plan.setActive((Boolean) request.get("active"));

            return ResponseEntity.ok(planRepository.save(plan));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── TOGGLE ACTIVE ──
    @PostMapping("/{id}/toggle")
    public ResponseEntity<?> toggleActive(@PathVariable Long id) {
        try {
            SubscriptionPlan plan = planRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Plan introuvable"));
            plan.setActive(!plan.isActive());
            planRepository.save(plan);
            return ResponseEntity.ok(Map.of(
                    "message", plan.isActive() ? "Plan activé" : "Plan désactivé",
                    "active", plan.isActive()
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── DELETE ──
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deletePlan(@PathVariable Long id) {
        try {
            SubscriptionPlan plan = planRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Plan introuvable"));

            // Désactiver plutôt que supprimer si des abonnements existent avec ce type
            plan.setActive(false);
            planRepository.save(plan);

            return ResponseEntity.ok(Map.of("message", "Plan désactivé (conservé pour l'historique)"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── DELETE FORCÉ (irréversible) ──
    @DeleteMapping("/{id}/force")
    public ResponseEntity<?> forceDeletePlan(@PathVariable Long id) {
        try {
            planRepository.deleteById(id);
            return ResponseEntity.ok(Map.of("message", "Plan supprimé définitivement"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}