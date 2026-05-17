package com.example.project_backend.Controller;

import com.example.project_backend.Entity.AIFeedback;
import com.example.project_backend.Entity.Coach;
import com.example.project_backend.Entity.User;
import com.example.project_backend.Repository.CoachRepository;
import com.example.project_backend.Repository.UserRepository;
import com.example.project_backend.Service.AIFeedbackService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Endpoints de feedback coach sur les prédictions IA.
 * Base URL : /api/ai/feedback
 */
@RestController
@RequestMapping("/api/ai/feedback")
@CrossOrigin(origins = "*")
public class AIFeedbackController {

    private static final Logger log = LoggerFactory.getLogger(AIFeedbackController.class);

    private final AIFeedbackService feedbackService;
    private final CoachRepository   coachRepository;
    private final UserRepository    userRepository;

    public AIFeedbackController(AIFeedbackService feedbackService,
                                CoachRepository coachRepository,
                                UserRepository userRepository) {
        this.feedbackService = feedbackService;
        this.coachRepository = coachRepository;
        this.userRepository  = userRepository;
    }

    // ═══════════════════════════════════════════════════════════════
    // POST - Soumettre un feedback pour une séance (appelé par Flutter)
    // ═══════════════════════════════════════════════════════════════

    @PostMapping("/member/{memberId}/session/{sessionId}")
    public ResponseEntity<?> submitFeedback(
            @PathVariable Long memberId,
            @PathVariable Long sessionId,
            @RequestBody Map<String, Object> data) {
        try {
            log.info("📝 Soumission feedback - memberId={}, sessionId={}", memberId, sessionId);
            Long coachId = resolveCoachId();
            AIFeedback saved = feedbackService.saveFeedback(memberId, coachId, sessionId, data);
            return ResponseEntity.ok(feedbackService.toMap(saved));
        } catch (IllegalArgumentException e) {
            log.warn("⚠️ Erreur validation feedback: {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            log.error("❌ Erreur soumission feedback: {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // GET - Tous les feedbacks d'un membre
    // ═══════════════════════════════════════════════════════════════

    @GetMapping("/member/{memberId}")
    public ResponseEntity<?> getFeedbacksByMember(@PathVariable Long memberId) {
        try {
            List<AIFeedback> feedbacks = feedbackService.getFeedbacksByMember(memberId);
            return ResponseEntity.ok(feedbacks.stream()
                    .map(feedbackService::toMap)
                    .toList());
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // GET - Tous les feedbacks du coach connecté
    // ═══════════════════════════════════════════════════════════════

    @GetMapping("/my-feedbacks")
    public ResponseEntity<?> getMyFeedbacks() {
        try {
            Long coachId = resolveCoachId();
            List<AIFeedback> feedbacks = feedbackService.getFeedbacksByCoach(coachId);
            return ResponseEntity.ok(feedbacks.stream()
                    .map(feedbackService::toMap)
                    .toList());
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // GET - Feedback pour une séance spécifique
    // ═══════════════════════════════════════════════════════════════

    @GetMapping("/session/{sessionId}")
    public ResponseEntity<?> getFeedbackBySession(@PathVariable Long sessionId) {
        return feedbackService.getFeedbackBySession(sessionId)
                .map(fb -> ResponseEntity.ok(feedbackService.toMap(fb)))
                .orElse(ResponseEntity.notFound().build());
    }

    // ═══════════════════════════════════════════════════════════════
    // GET - Statistiques de précision pour un membre
    // ═══════════════════════════════════════════════════════════════

    @GetMapping("/accuracy/member/{memberId}")
    public ResponseEntity<?> getMemberAccuracy(@PathVariable Long memberId) {
        try {
            Map<String, Object> stats = feedbackService.getMemberAccuracyStats(memberId);
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // GET - Statistiques globales (précision des modèles)
    // ═══════════════════════════════════════════════════════════════

    @GetMapping("/accuracy")
    public ResponseEntity<?> getGlobalAccuracy() {
        try {
            return ResponseEntity.ok(feedbackService.getAccuracyStats());
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", e.getMessage()));
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // GET - Historique des corrections (avec pagination)
    // ═══════════════════════════════════════════════════════════════

    @GetMapping("/corrections")
    public ResponseEntity<?> getCorrections(
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            List<AIFeedback> all = feedbackService.getAllFeedbacksWithCorrections();
            int from  = Math.min(page * size, all.size());
            int to    = Math.min(from + size, all.size());
            List<Map<String, Object>> slice = all.subList(from, to).stream()
                    .map(feedbackService::toMap)
                    .toList();
            return ResponseEntity.ok(Map.of(
                    "data",  slice,
                    "total", all.size(),
                    "page",  page,
                    "size",  size
            ));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", e.getMessage()));
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // HELPER - Récupérer le coachId depuis le JWT
    // ═══════════════════════════════════════════════════════════════

    private Long resolveCoachId() {
        String username = SecurityContextHolder.getContext()
                .getAuthentication().getName();

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found: " + username));

        // Suppression du fallback dangereux — seul un vrai coach peut soumettre
        if (user.getCoach() == null) {
            throw new RuntimeException("Accès réservé aux coachs");
        }
        return user.getCoach().getId();
    }
}