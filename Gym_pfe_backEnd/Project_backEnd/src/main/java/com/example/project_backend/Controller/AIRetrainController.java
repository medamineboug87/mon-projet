package com.example.project_backend.Controller;

import com.example.project_backend.Service.AIFeedbackService;
import com.example.project_backend.Service.AIRetrainService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Endpoints dédiés au réentraînement des modèles IA
 * à partir des feedbacks validés par les coachs.
 *
 * Base URL : /api/ai/retrain
 */
@RestController
@RequestMapping("/api/ai/retrain")
@CrossOrigin(origins = "*")
public class AIRetrainController {

    private static final Logger log = LoggerFactory.getLogger(AIRetrainController.class);

    private final AIRetrainService retrainService;
    private final AIFeedbackService feedbackService;

    public AIRetrainController(AIRetrainService retrainService,
                               AIFeedbackService feedbackService) {
        this.retrainService  = retrainService;
        this.feedbackService = feedbackService;
    }

    // ── GET statut du réentraînement ──
    // Indique si le seuil minimum de feedbacks est atteint
    @GetMapping("/status")
    public ResponseEntity<?> getRetrainStatus() {
        try {
            Map<String, Object> status = retrainService.getRetrainStatus();
            return ResponseEntity.ok(status);
        } catch (Exception e) {
            log.error("Erreur statut réentraînement: {}", e.getMessage());
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", e.getMessage()));
        }
    }

    // ── GET données pour réentraînement (export pour le script Python) ──
    @GetMapping("/data")
    public ResponseEntity<?> getRetrainingData() {
        try {
            Map<String, Object> data = feedbackService.getRetrainingData();
            return ResponseEntity.ok(data);
        } catch (Exception e) {
            log.error("Erreur récupération données: {}", e.getMessage());
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", e.getMessage()));
        }
    }

    // ── POST déclencher le réentraînement ──
    // Envoie les feedbacks au service Python IA et lance le réentraînement
    @PostMapping("/trigger")
    public ResponseEntity<?> triggerRetrain() {
        log.info("🔁 Déclenchement réentraînement IA demandé");
        try {
            Map<String, Object> result = retrainService.triggerRetrain();
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            log.error("Erreur déclenchement réentraînement: {}", e.getMessage());
            return ResponseEntity.internalServerError()
                    .body(Map.of(
                            "success", false,
                            "error",   e.getMessage()
                    ));
        }
    }

    // ── POST marquer les feedbacks comme utilisés après un réentraînement ──
    @PostMapping("/mark-used")
    public ResponseEntity<?> markFeedbacksAsUsed(@RequestBody Map<String, Object> body) {
        try {
            @SuppressWarnings("unchecked")
            List<Long> ids = ((List<?>) body.get("feedbackIds"))
                    .stream().map(o -> Long.valueOf(o.toString())).toList();

            int count = feedbackService.markFeedbacksAsUsed(ids);
            return ResponseEntity.ok(Map.of(
                    "marked", count,
                    "message", count + " feedback(s) marqué(s) comme utilisés"
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── GET statistiques de précision globales ──
    @GetMapping("/accuracy")
    public ResponseEntity<?> getAccuracyStats() {
        try {
            return ResponseEntity.ok(feedbackService.getAccuracyStats());
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", e.getMessage()));
        }
    }

    // ── GET historique des réentraînements ──
    @GetMapping("/history")
    public ResponseEntity<?> getRetrainHistory() {
        try {
            return ResponseEntity.ok(retrainService.getRetrainHistory());
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", e.getMessage()));
        }
    }
}
