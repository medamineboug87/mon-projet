package com.example.project_backend.Controller;

import com.example.project_backend.Entity.Coach;
import com.example.project_backend.Repository.CoachRepository;
import com.example.project_backend.Repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/coaches")
@CrossOrigin(origins = "*")
public class CoachController {

    private final CoachRepository coachRepository;
    private final UserRepository  userRepository;

    public CoachController(CoachRepository coachRepository,
                           UserRepository userRepository) {
        this.coachRepository = coachRepository;
        this.userRepository  = userRepository;
    }

    // ── Profil du coach ──
    @GetMapping("/profile/{coachId}")
    public ResponseEntity<?> getCoachProfile(@PathVariable Long coachId) {
        // ✅ FIX : 404 quand coach introuvable, pas 400
        Coach coach = coachRepository.findById(coachId).orElse(null);
        if (coach == null) return ResponseEntity.notFound().build();

        Map<String, Object> profile = new HashMap<>();
        profile.put("id",         coach.getId());
        profile.put("fullName",   coach.getFullName());
        profile.put("email",      coach.getEmail());
        profile.put("phone",      coach.getPhone());
        profile.put("experience", coach.getExperience());

        if (coach.getUser() != null) {
            profile.put("username", coach.getUser().getUsername());
        }

        return ResponseEntity.ok(List.of());
    }

    // ── Modifier le profil ──
    @PutMapping("/profile/{coachId}")
    public ResponseEntity<?> updateCoachProfile(
            @PathVariable Long coachId,
            @RequestBody Map<String, String> request) {

        Coach coach = coachRepository.findById(coachId).orElse(null);
        // ✅ FIX : 404 quand coach introuvable
        if (coach == null) return ResponseEntity.notFound().build();

        if (request.containsKey("fullName")) coach.setFullName(request.get("fullName"));
        if (request.containsKey("email"))    coach.setEmail(request.get("email"));
        if (request.containsKey("phone"))    coach.setPhone(request.get("phone"));

        coachRepository.save(coach);
        return ResponseEntity.ok(Map.of("message", "Profil mis à jour avec succès"));
    }

    // ── Membres d'un coach (stub) ──
    @GetMapping("/{coachId}/members")
    public ResponseEntity<?> getCoachMembers(@PathVariable Long coachId) {
        return ResponseEntity.ok(Map.of("message", "À implémenter"));
    }
}