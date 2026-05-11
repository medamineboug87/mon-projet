package com.example.project_backend.Controller;

import com.example.project_backend.Entity.MemberProfile;
import com.example.project_backend.Service.MemberProfileService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Endpoints du profil médical / sportif étendu d'un membre.
 * Base URL : /members/{memberId}/ai-profile
 */
@RestController
@CrossOrigin
public class MemberProfileController {

    private final MemberProfileService profileService;

    public MemberProfileController(MemberProfileService profileService) {
        this.profileService = profileService;
    }

    // ── GET profil (crée un profil vide si inexistant) ──
    @GetMapping("/members/{memberId}/ai-profile")
    public ResponseEntity<?> getProfile(@PathVariable Long memberId) {
        try {
            MemberProfile profile = profileService.getOrCreateProfile(memberId);
            return ResponseEntity.ok(profileService.toMap(profile));
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    // ── CREATE / UPDATE profil ──
    @PutMapping("/members/{memberId}/ai-profile")
    public ResponseEntity<?> saveProfile(@PathVariable Long memberId,
                                         @RequestBody Map<String, Object> data) {
        try {
            MemberProfile saved = profileService.saveProfile(memberId, data);
            return ResponseEntity.ok(profileService.toMap(saved));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", "Valeur d'énumération invalide : " + e.getMessage()));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── DELETE profil (réinitialisation complète) ──
    @DeleteMapping("/members/{memberId}/ai-profile")
    public ResponseEntity<?> deleteProfile(@PathVariable Long memberId) {
        try {
            profileService.deleteProfile(memberId);
            return ResponseEntity.ok(Map.of("message", "Profil IA réinitialisé"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── GET enum options (pour alimenter les dropdowns du front) ──
    @GetMapping("/members/ai-profile/options")
    public ResponseEntity<?> getEnumOptions() {
        return ResponseEntity.ok(Map.of(
            "fitnessGoals", Arrays.stream(MemberProfile.FitnessGoal.values())
                    .map(g -> Map.of(
                            "value", g.name(),
                            "label", goalLabel(g)
                    ))
                    .collect(Collectors.toList()),

            "fitnessLevels", Arrays.stream(MemberProfile.FitnessLevel.values())
                    .map(l -> Map.of(
                            "value", l.name(),
                            "label", levelLabel(l)
                    ))
                    .collect(Collectors.toList()),

            "painZones", List.of(
                    Map.of("value", "NONE",            "label", "Aucune"),
                    Map.of("value", "NECK",             "label", "Nuque / Cou"),
                    Map.of("value", "LOWER_BACK",       "label", "Bas du dos (lombaires)"),
                    Map.of("value", "UPPER_BACK",       "label", "Haut du dos"),
                    Map.of("value", "LEFT_SHOULDER",    "label", "Épaule gauche"),
                    Map.of("value", "RIGHT_SHOULDER",   "label", "Épaule droite"),
                    Map.of("value", "LEFT_KNEE",        "label", "Genou gauche"),
                    Map.of("value", "RIGHT_KNEE",       "label", "Genou droit"),
                    Map.of("value", "LEFT_ANKLE",       "label", "Cheville gauche"),
                    Map.of("value", "RIGHT_ANKLE",      "label", "Cheville droite"),
                    Map.of("value", "LEFT_HIP",         "label", "Hanche gauche"),
                    Map.of("value", "RIGHT_HIP",        "label", "Hanche droite"),
                    Map.of("value", "LEFT_ELBOW",       "label", "Coude gauche"),
                    Map.of("value", "RIGHT_ELBOW",      "label", "Coude droit"),
                    Map.of("value", "WRISTS",           "label", "Poignets")
            ),

            "dietTypes", List.of(
                    "Omnivore", "Végétarien", "Vegan", "Végétalien",
                    "Keto / Low-carb", "Méditerranéen", "Sans gluten",
                    "Halal", "Autre"
            )
        ));
    }

    private String goalLabel(MemberProfile.FitnessGoal g) {
        return switch (g) {
            case WEIGHT_LOSS     -> "Perte de poids";
            case MUSCLE_GAIN     -> "Prise de masse";
            case ENDURANCE       -> "Endurance cardiovasculaire";
            case TONING          -> "Tonification";
            case GENERAL_FITNESS -> "Bien-être général";
            case REHABILITATION  -> "Rééducation";
            case PERFORMANCE     -> "Performance sportive";
        };
    }

    private String levelLabel(MemberProfile.FitnessLevel l) {
        return switch (l) {
            case BEGINNER     -> "Débutant (< 1 an)";
            case INTERMEDIATE -> "Intermédiaire (1-3 ans)";
            case ADVANCED     -> "Avancé (3-5 ans)";
            case ATHLETE      -> "Athlète / Compétiteur (5+ ans)";
        };
    }
}
