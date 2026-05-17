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
@CrossOrigin(origins = "*")
public class TrainingSessionController {

    private final TrainingSessionService sessionService;
    private final UserRepository userRepository;

    public TrainingSessionController(TrainingSessionService sessionService,
                                     UserRepository userRepository) {
        this.sessionService = sessionService;
        this.userRepository = userRepository;
    }

    // ── Créer une séance ──
    @PostMapping("/member/{memberId}")
    public ResponseEntity<?> createSession(
            @PathVariable Long memberId,
            @RequestBody TrainingSession session,
            Authentication authentication) {
        try {
            // ✅ FIX #2 : vérifier que le membre peut créer une séance pour lui-même
            User currentUser = resolveUser(authentication);
            boolean isOwner      = currentUser.getMember() != null
                    && currentUser.getMember().getId().equals(memberId);
            boolean isAdminOrCoach = isAdminOrCoach(currentUser);

            if (!isOwner && !isAdminOrCoach) {
                return ResponseEntity.status(403).body(Map.of("error", "Accès refusé"));
            }

            return ResponseEntity.ok(sessionService.createSession(memberId, session));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── Toutes les séances ──
    @GetMapping
    public ResponseEntity<List<TrainingSession>> getAllSessions() {
        return ResponseEntity.ok(sessionService.getAllSessions());
    }

    // ── Séances d'un membre ──
    @GetMapping("/member/{memberId}")
    public ResponseEntity<?> getSessionsByMember(
            @PathVariable Long memberId,
            Authentication authentication) {
        try {
            User currentUser = resolveUser(authentication);

            boolean isOwner      = currentUser.getMember() != null
                    && currentUser.getMember().getId().equals(memberId);
            boolean isAdminOrCoach = isAdminOrCoach(currentUser);

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
            @RequestBody TrainingSession session,
            Authentication authentication) {
        try {
            // ✅ FIX #2 : vérifier que l'utilisateur est propriétaire ou admin/coach
            User currentUser   = resolveUser(authentication);
            TrainingSession existing = sessionService.getById(sessionId);

            boolean isOwner      = currentUser.getMember() != null
                    && existing.getMember() != null
                    && currentUser.getMember().getId().equals(existing.getMember().getId());
            boolean isAdminOrCoach = isAdminOrCoach(currentUser);

            if (!isOwner && !isAdminOrCoach) {
                return ResponseEntity.status(403).body(Map.of("error", "Accès refusé"));
            }

            return ResponseEntity.ok(sessionService.updateSession(sessionId, session));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── Supprimer une séance ──
    @DeleteMapping("/{sessionId}")
    public ResponseEntity<?> deleteSession(
            @PathVariable Long sessionId,
            Authentication authentication) {
        try {
            // ✅ FIX #2 : vérifier la propriété avant suppression
            User currentUser   = resolveUser(authentication);
            TrainingSession existing = sessionService.getById(sessionId);

            boolean isOwner      = currentUser.getMember() != null
                    && existing.getMember() != null
                    && currentUser.getMember().getId().equals(existing.getMember().getId());
            boolean isAdminOrCoach = isAdminOrCoach(currentUser);

            if (!isOwner && !isAdminOrCoach) {
                return ResponseEntity.status(403).body(Map.of("error", "Accès refusé"));
            }

            sessionService.deleteSession(sessionId);
            return ResponseEntity.ok(Map.of("message", "Séance supprimée"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── Helpers privés ──
    private User resolveUser(Authentication authentication) {
        String username = authentication.getName();
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    private boolean isAdminOrCoach(User user) {
        return user.getRole() == Role.ADMIN || user.getRole() == Role.COACH;
    }
}