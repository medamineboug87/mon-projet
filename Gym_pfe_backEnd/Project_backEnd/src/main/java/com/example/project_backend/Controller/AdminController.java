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

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/admin")
@CrossOrigin(origins = "*")
public class AdminController {

    private final UserService userService;
    private final MemberService memberService;
    private final UserRepository userRepository;
    private final MemberRepository memberRepository;
    private final CoachRepository coachRepository;

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
            User user = new User();
            user.setUsername((String) request.get("username"));
            user.setPassword((String) request.get("password"));
            user.setEmail((String) request.get("email"));
            user.setPhone((String) request.get("phone"));
            user.setRole(Role.COACH);
            userService.register(user, null);

            Coach coach = new Coach();
            coach.setFullName((String) request.get("fullName"));
            coach.setPhone((String) request.get("phone"));
            coach.setEmail((String) request.get("email"));
            coach.setExperience(Integer.parseInt(
                    request.get("experience").toString()));
            coach.setUser(user);
            coachRepository.save(coach);

            user.setCoach(coach);
            userRepository.save(user);

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

    // ── Liste tous les coachs (avec userId + username) ──
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
        // Charger tous les users une seule fois
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

    // ── Récupérer un coach par ID ──
    @GetMapping("/coaches/{id}")
    public ResponseEntity<?> getCoachById(@PathVariable Long id) {
        return coachRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ── Modifier un coach ──
    @PutMapping("/coaches/{id}")
    public ResponseEntity<?> updateCoach(
            @PathVariable Long id,
            @RequestBody Map<String, Object> request) {
        try {
            Coach coach = coachRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Coach not found"));

            if (request.get("fullName") != null)
                coach.setFullName((String) request.get("fullName"));
            if (request.get("phone") != null)
                coach.setPhone((String) request.get("phone"));
            if (request.get("email") != null)
                coach.setEmail((String) request.get("email"));
            if (request.get("experience") != null)
                coach.setExperience(Integer.parseInt(
                        request.get("experience").toString()));

            coachRepository.save(coach);
            return ResponseEntity.ok(Map.of("message", "Coach mis à jour avec succès"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(
                    Map.of("error", e.getMessage()));
        }
    }

    // ── Supprimer un membre (avec cascade correcte via MemberService) ──
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
}