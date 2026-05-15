package com.example.project_backend.Controller;

import com.example.project_backend.Entity.Role;
import com.example.project_backend.Entity.TrainingSession;
import com.example.project_backend.Entity.User;
import com.example.project_backend.Service.TrainingSessionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;
import com.example.project_backend.Repository.UserRepository;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/sessions")
@CrossOrigin
public class TrainingSessionController {

    private final TrainingSessionService sessionService;
    private final UserRepository userRepository;  // ← AJOUTER CETTE LIGNE


    public TrainingSessionController(TrainingSessionService sessionService,
                                     UserRepository userRepository) {
        this.sessionService = sessionService;
        this.userRepository = userRepository;  

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
    public ResponseEntity<?> getSessionsByMember(
            @PathVariable Long memberId,
            Authentication authentication) {
        try {
            String username = authentication.getName();
            User currentUser = userRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("User not found"));

            // Vérifier que l'utilisateur est le membre lui-même, son coach, ou un admin
            boolean isOwner = currentUser.getMember() != null
                    && currentUser.getMember().getId().equals(memberId);
            boolean isAdminOrCoach = currentUser.getRole() == Role.ADMIN
                    || currentUser.getRole() == Role.COACH;

            if (!isOwner && !isAdminOrCoach) {
                return ResponseEntity.status(403).body(Map.of("error", "Accès refusé"));
            }

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