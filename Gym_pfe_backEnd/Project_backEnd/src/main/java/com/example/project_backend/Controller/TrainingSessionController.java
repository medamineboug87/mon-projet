package com.example.project_backend.Controller;

import com.example.project_backend.Entity.TrainingSession;
import com.example.project_backend.Service.TrainingSessionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/sessions")
@CrossOrigin
public class TrainingSessionController {

    private final TrainingSessionService sessionService;

    public TrainingSessionController(TrainingSessionService sessionService) {
        this.sessionService = sessionService;
    }

    // ── Créer une séance ──
    @PostMapping("/member/{memberId}")
    public ResponseEntity<?> createSession(
            @PathVariable Long memberId,
            @RequestBody TrainingSession session) {
        try {
            return ResponseEntity.ok(sessionService.createSession(memberId, session));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── Toutes les séances ──
    // ✅ FIX : ResponseEntity au lieu de List brute
    @GetMapping
    public ResponseEntity<List<TrainingSession>> getAllSessions() {
        return ResponseEntity.ok(sessionService.getAllSessions());
    }

    // ── Séances d'un membre ──
    // ✅ FIX : ResponseEntity + gestion erreur si membre inexistant
    @GetMapping("/member/{memberId}")
    public ResponseEntity<?> getSessionsByMember(@PathVariable Long memberId) {
        try {
            return ResponseEntity.ok(sessionService.getSessionsByMember(memberId));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── Mettre à jour une séance ──
    @PutMapping("/{sessionId}")
    public ResponseEntity<?> updateSession(
            @PathVariable Long sessionId,
            @RequestBody TrainingSession session) {
        try {
            return ResponseEntity.ok(sessionService.updateSession(sessionId, session));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── Supprimer une séance ──
    // ✅ FIX : retourner message au lieu de Void
    @DeleteMapping("/{sessionId}")
    public ResponseEntity<?> deleteSession(@PathVariable Long sessionId) {
        try {
            sessionService.deleteSession(sessionId);
            return ResponseEntity.ok(Map.of("message", "Séance supprimée"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}