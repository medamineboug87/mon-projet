package com.example.project_backend.Controller;

import com.example.project_backend.Entity.Member;
import com.example.project_backend.Service.MemberService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/members")
@CrossOrigin(origins = "*")
public class MemberController {

    private final MemberService memberService;

    public MemberController(MemberService memberService) {
        this.memberService = memberService;
    }

    // ── GET ALL ──
    @GetMapping
    public ResponseEntity<List<Member>> getAllMembers() {
        return ResponseEntity.ok(memberService.getAllMembers());
    }

    // ── GET BY ID ──
    // ✅ FIX : ResponseEntity + gestion 404
    @GetMapping("/{id}")
    public ResponseEntity<?> getMemberById(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(memberService.getMemberById(id));
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    // ── CREATE ──
    // ✅ FIX : validation champs obligatoires
    @PostMapping
    public ResponseEntity<?> createMember(@RequestBody Member member) {
        if (member.getFullName() == null || member.getFullName().isBlank()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "fullName est obligatoire"));
        }
        if (member.getAge() <= 0 || member.getAge() > 120) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Age invalide"));
        }
        if (member.getWeight() <= 0) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Poids invalide"));
        }
        if (member.getHeight() <= 0) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Taille invalide"));
        }
        return ResponseEntity.ok(memberService.createMember(member));
    }

    // ── UPDATE ──
    @PutMapping("/{id}")
    public ResponseEntity<?> updateMember(@PathVariable Long id,
                                          @RequestBody Member updatedMember) {
        try {
            return ResponseEntity.ok(memberService.updateMember(id, updatedMember));
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    // ── PROFIL ──
    @GetMapping("/{id}/profile")
    public ResponseEntity<Map<String, Object>> getMemberProfile(
            @PathVariable Long id) {

        // ✅ FIX : try-catch → 404 propre
        try {
            Member member = memberService.getMemberById(id);
            Map<String, Object> profile = buildProfile(member);
            return ResponseEntity.ok(profile);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    // ── UPDATE PROFIL ──
    @PutMapping("/{id}/profile")
    public ResponseEntity<?> updateProfile(@PathVariable Long id,
                                           @RequestBody Member updatedMember) {
        try {
            Member member = memberService.getMemberById(id);
            member.setFullName(updatedMember.getFullName());
            member.setAge(updatedMember.getAge());
            member.setWeight(updatedMember.getWeight());
            member.setHeight(updatedMember.getHeight());
            member.setGender(updatedMember.getGender());
            return ResponseEntity.ok(memberService.updateMember(id, member));
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    // ── DELETE ──
    // ✅ FIX : retourner ResponseEntity au lieu de void
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteMember(@PathVariable Long id) {
        try {
            memberService.deleteMember(id);
            return ResponseEntity.ok(Map.of("message", "Membre supprimé"));
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    // ── Helper : construction du profil + BMI ──
    private Map<String, Object> buildProfile(Member member) {
        Map<String, Object> profile = new HashMap<>();
        profile.put("id",               member.getId());
        profile.put("fullName",         member.getFullName());
        profile.put("age",              member.getAge());
        profile.put("gender",           member.getGender());
        profile.put("weight",           member.getWeight());
        profile.put("height",           member.getHeight());
        profile.put("registrationDate", member.getRegistrationDate());

        if (member.getHeight() > 0) {
            double bmi = member.getWeight()
                    / Math.pow(member.getHeight() / 100.0, 2);
            double bmiRounded = Math.round(bmi * 10.0) / 10.0;
            profile.put("bmi", bmiRounded);

            String category;
            if      (bmi < 18.5) category = "Insuffisance pondérale";
            else if (bmi < 25.0) category = "Poids normal";
            else if (bmi < 30.0) category = "Surpoids";
            else                 category = "Obésité";

            profile.put("bmiCategory", category);
        }
        return profile;
    }
    // Ajouter cette méthode dans MemberController.java

    @GetMapping("/coach/{coachId}")
    public ResponseEntity<?> getMembersByCoach(@PathVariable Long coachId) {
        try {
            // Récupérer tous les membres
            List<Member> allMembers = memberService.getAllMembers();

            // TODO: Filtrer par coachId (à adapter selon ta logique de relation coach-membre)
            // Pour l'instant, retourne tous les membres
            // Idéalement, ajouter un champ coachId dans Member ou une table de relation

            return ResponseEntity.ok(allMembers);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}