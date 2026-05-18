package com.example.project_backend.Controller;

import com.example.project_backend.Entity.Coach;
import com.example.project_backend.Entity.Role;
import com.example.project_backend.Entity.User;
import com.example.project_backend.Repository.CoachRepository;
import com.example.project_backend.Repository.MemberRepository;
import com.example.project_backend.Repository.UserRepository;
import com.example.project_backend.Service.MemberService;
import com.example.project_backend.Service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

@RestController
@RequestMapping("/admin")
@CrossOrigin(origins = "*")
public class AdminController {

    private final UserService userService;
    private final MemberService memberService;
    private final UserRepository userRepository;
    private final MemberRepository memberRepository;
    private final CoachRepository coachRepository;

    // ── In-memory audit log (last 50 entries per coach) ──
    private final Map<Long, List<Map<String, Object>>> coachAuditLog = new ConcurrentHashMap<>();

    public AdminController(UserService userService,
                           MemberService memberService,
                           UserRepository userRepository,
                           MemberRepository memberRepository,
                           CoachRepository coachRepository) {
        this.userService = userService;
        this.memberService = memberService;
        this.userRepository = userRepository;
        this.memberRepository = memberRepository;
        this.coachRepository = coachRepository;
    }

    // ── Créer un coach ──
    @PostMapping("/coaches")
    public ResponseEntity<?> createCoach(
            @RequestBody Map<String, Object> request) {
        try {
            // Validate required fields
            if (request.get("username") == null || request.get("username").toString().isBlank())
                return ResponseEntity.badRequest().body(Map.of("error", "Le nom d'utilisateur est requis"));
            if (request.get("password") == null || request.get("password").toString().isBlank())
                return ResponseEntity.badRequest().body(Map.of("error", "Le mot de passe est requis"));
            if (request.get("fullName") == null || request.get("fullName").toString().isBlank())
                return ResponseEntity.badRequest().body(Map.of("error", "Le nom complet est requis"));
            if (request.get("email") == null || request.get("email").toString().isBlank())
                return ResponseEntity.badRequest().body(Map.of("error", "L'email est requis"));

            // Check email uniqueness
            String email = (String) request.get("email");
            if (userRepository.existsByEmail(email))
                return ResponseEntity.badRequest().body(Map.of("error", "Cet email est déjà utilisé"));
            if (coachRepository.existsByEmail(email))
                return ResponseEntity.badRequest().body(Map.of("error", "Un coach avec cet email existe déjà"));

            User user = new User();
            user.setUsername((String) request.get("username"));
            user.setPassword((String) request.get("password"));
            user.setEmail(email);
            user.setPhone((String) request.get("phone"));
            user.setRole(Role.COACH);
            userService.register(user, null);

            Coach coach = new Coach();
            coach.setFullName((String) request.get("fullName"));
            coach.setPhone((String) request.get("phone"));
            coach.setEmail(email);
            coach.setExperience(Integer.parseInt(
                    request.getOrDefault("experience", "0").toString()));
            coach.setActive(true);
            coach.setUser(user);
            coachRepository.save(coach);

            user.setCoach(coach);
            userRepository.save(user);

            _addAuditEntry(coach.getId(), "CREATION", "Coach créé par l'admin", null);

            return ResponseEntity.ok(Map.of(
                    "message", "Coach créé avec succès",
                    "coachId", coach.getId(),
                    "username", user.getUsername()
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(
                    Map.of("error", e.getMessage()));
        }
    }

    // ── Liste tous les coachs (avec userId + username + active) ──
    @GetMapping("/coaches")
    public ResponseEntity<List<Map<String, Object>>> getAllCoaches() {
        List<Map<String, Object>> result = coachRepository.findAll().stream()
                .map(coach -> {
                    Map<String, Object> map = new HashMap<>();
                    map.put("id", coach.getId());
                    map.put("fullName", coach.getFullName());
                    map.put("email", coach.getEmail());
                    map.put("phone", coach.getPhone());
                    map.put("experience", coach.getExperience());
                    map.put("active", coach.isActive());
                    if (coach.getUser() != null) {
                        map.put("userId", coach.getUser().getId());
                        map.put("username", coach.getUser().getUsername());
                    }
                    return map;
                })
                .toList();
        return ResponseEntity.ok(result);
    }

    // ── Coach par userId ──
    @GetMapping("/coaches/by-user/{userId}")
    public ResponseEntity<?> getCoachByUserId(@PathVariable Long userId) {
        return coachRepository.findByUserId(userId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ── Supprimer un coach ──
    @DeleteMapping("/coaches/{id}")
    public ResponseEntity<?> deleteCoach(@PathVariable Long id) {
        coachRepository.deleteById(id);
        return ResponseEntity.ok(Map.of("message", "Coach supprimé"));
    }

    // ── Récupérer un coach par ID ──
    @GetMapping("/coaches/{id}")
    public ResponseEntity<?> getCoachById(@PathVariable Long id) {
        return coachRepository.findById(id)
                .map(coach -> {
                    Map<String, Object> map = new HashMap<>();
                    map.put("id", coach.getId());
                    map.put("fullName", coach.getFullName());
                    map.put("email", coach.getEmail());
                    map.put("phone", coach.getPhone());
                    map.put("experience", coach.getExperience());
                    map.put("active", coach.isActive());
                    if (coach.getUser() != null) {
                        map.put("userId", coach.getUser().getId());
                        map.put("username", coach.getUser().getUsername());
                    }
                    return ResponseEntity.ok((Object) map);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    // ════════════════════════════════════════════════════════════════
    // ── MODIFIER UN COACH (PUT /admin/coaches/{id}) ──
    // ════════════════════════════════════════════════════════════════
    @PutMapping("/coaches/{id}")
    public ResponseEntity<?> updateCoach(
            @PathVariable Long id,
            @RequestBody Map<String, Object> request) {
        try {
            Coach coach = coachRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Coach introuvable"));

            // Track what changed for audit log
            List<String> changes = new ArrayList<>();

            // ── fullName ──
            if (request.get("fullName") != null && !request.get("fullName").toString().isBlank()) {
                String newName = request.get("fullName").toString().trim();
                if (!newName.equals(coach.getFullName())) {
                    changes.add("Nom: '" + coach.getFullName() + "' → '" + newName + "'");
                    coach.setFullName(newName);
                }
            }

            // ── phone ──
            if (request.get("phone") != null) {
                String newPhone = request.get("phone").toString().trim();
                if (!newPhone.equals(coach.getPhone() == null ? "" : coach.getPhone())) {
                    changes.add("Téléphone: '" + coach.getPhone() + "' → '" + newPhone + "'");
                    coach.setPhone(newPhone);
                }
            }

            // ── email ──
            if (request.get("email") != null && !request.get("email").toString().isBlank()) {
                String newEmail = request.get("email").toString().trim().toLowerCase();
                if (!newEmail.equals(coach.getEmail() == null ? "" : coach.getEmail().toLowerCase())) {
                    // Check email not already used by another user
                    boolean emailTakenByUser = userRepository.existsByEmail(newEmail);
                    boolean emailTakenByCoach = coachRepository.findAll().stream()
                            .anyMatch(c -> !c.getId().equals(id) && newEmail.equalsIgnoreCase(c.getEmail()));

                    if (emailTakenByUser || emailTakenByCoach) {
                        return ResponseEntity.badRequest().body(
                                Map.of("error", "Cet email est déjà utilisé par un autre compte"));
                    }
                    changes.add("Email: '" + coach.getEmail() + "' → '" + newEmail + "'");
                    coach.setEmail(newEmail);
                    // Also update the linked user's email
                    if (coach.getUser() != null) {
                        coach.getUser().setEmail(newEmail);
                        userRepository.save(coach.getUser());
                    }
                }
            }

            // ── experience ──
            if (request.get("experience") != null) {
                int newExp = Integer.parseInt(request.get("experience").toString());
                if (newExp < 0) return ResponseEntity.badRequest().body(Map.of("error", "L'expérience ne peut pas être négative"));
                if (newExp != coach.getExperience()) {
                    changes.add("Expérience: " + coach.getExperience() + " → " + newExp + " ans");
                    coach.setExperience(newExp);
                }
            }

            // ── active (optional) ──
            if (request.get("active") != null) {
                boolean newActive = (Boolean) request.get("active");
                if (newActive != coach.isActive()) {
                    changes.add("Statut: " + (coach.isActive() ? "actif" : "inactif") + " → " + (newActive ? "actif" : "inactif"));
                    coach.setActive(newActive);
                }
            }

            coachRepository.save(coach);

            // Add audit entry if anything changed
            if (!changes.isEmpty()) {
                _addAuditEntry(id, "MODIFICATION", String.join(", ", changes), null);
            }

            Map<String, Object> result = new HashMap<>();
            result.put("message", "Coach mis à jour avec succès");
            result.put("coachId", coach.getId());
            result.put("fullName", coach.getFullName());
            result.put("email", coach.getEmail());
            result.put("phone", coach.getPhone());
            result.put("experience", coach.getExperience());
            result.put("active", coach.isActive());
            result.put("changesApplied", changes);

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(
                    Map.of("error", e.getMessage()));
        }
    }

    // ════════════════════════════════════════════════════════════════
    // ── ACTIVER / DÉSACTIVER UN COACH ──
    // ════════════════════════════════════════════════════════════════
    @PostMapping("/coaches/{id}/toggle-active")
    public ResponseEntity<?> toggleCoachActive(@PathVariable Long id) {
        try {
            Coach coach = coachRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Coach introuvable"));
            boolean wasActive = coach.isActive();
            coach.setActive(!wasActive);
            coachRepository.save(coach);

            String action = coach.isActive() ? "ACTIVATION" : "DÉSACTIVATION";
            _addAuditEntry(id, action, "Statut changé: " + (wasActive ? "actif → inactif" : "inactif → actif"), null);

            return ResponseEntity.ok(Map.of(
                    "message", coach.isActive() ? "Coach activé avec succès" : "Coach désactivé avec succès",
                    "coachId", id,
                    "active", coach.isActive()
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ════════════════════════════════════════════════════════════════
    // ── HISTORIQUE DES MODIFICATIONS D'UN COACH ──
    // ════════════════════════════════════════════════════════════════
    @GetMapping("/coaches/{id}/history")
    public ResponseEntity<?> getCoachHistory(@PathVariable Long id) {
        try {
            coachRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Coach introuvable"));
            List<Map<String, Object>> history = coachAuditLog.getOrDefault(id, List.of());
            return ResponseEntity.ok(Map.of(
                    "coachId", id,
                    "totalEntries", history.size(),
                    "history", history
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── Stats globales ──
    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getStats() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalMembers", memberRepository.count());
        stats.put("totalCoaches", coachRepository.count());
        stats.put("totalUsers", userRepository.count());

        long males = memberRepository.findAll().stream()
                .filter(m -> "MALE".equals(m.getGender())).count();
        long females = memberRepository.findAll().stream()
                .filter(m -> "FEMALE".equals(m.getGender())).count();

        stats.put("maleMembers", males);
        stats.put("femaleMembers", females);

        return ResponseEntity.ok(stats);
    }

    // ── Liste tous les membres (avec userId + username) ──
    @GetMapping("/members")
    public ResponseEntity<List<Map<String, Object>>> getAllMembers() {
        Map<Long, User> userByMemberId = userRepository.findAll().stream()
                .filter(u -> u.getMember() != null)
                .collect(java.util.stream.Collectors.toMap(
                        u -> u.getMember().getId(), u -> u, (a, b) -> a));

        List<Map<String, Object>> result = memberRepository.findAll().stream()
                .map(member -> {
                    Map<String, Object> map = new HashMap<>();
                    map.put("id", member.getId());
                    map.put("fullName", member.getFullName());
                    map.put("age", member.getAge());
                    map.put("gender", member.getGender());
                    map.put("email", member.getEmail());
                    map.put("phone", member.getPhone());
                    map.put("weight", member.getWeight());
                    map.put("height", member.getHeight());
                    map.put("registrationDate", member.getRegistrationDate());
                    User user = userByMemberId.get(member.getId());
                    if (user != null) {
                        map.put("userId", user.getId());
                        map.put("username", user.getUsername());
                    }
                    return map;
                }).toList();
        return ResponseEntity.ok(result);
    }

    // ── Supprimer un membre ──
    @DeleteMapping("/members/{id}")
    public ResponseEntity<?> deleteMember(@PathVariable Long id) {
        try {
            memberService.deleteMember(id);
            return ResponseEntity.ok(Map.of("message", "Membre supprimé"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(
                    Map.of("error", e.getMessage()));
        }
    }

    // ════════════════════════════════════════════════════════════════
    // HELPER — Audit log
    // ════════════════════════════════════════════════════════════════
    private void _addAuditEntry(Long coachId, String action, String detail, String performedBy) {
        coachAuditLog.computeIfAbsent(coachId, k -> new CopyOnWriteArrayList<>());
        List<Map<String, Object>> log = coachAuditLog.get(coachId);
        Map<String, Object> entry = new LinkedHashMap<>();
        entry.put("action", action);
        entry.put("detail", detail);
        entry.put("performedBy", performedBy != null ? performedBy : "admin");
        entry.put("timestamp", LocalDateTime.now().toString());
        log.add(0, entry); // newest first
        if (log.size() > 50) log.remove(log.size() - 1); // cap at 50
    }
}