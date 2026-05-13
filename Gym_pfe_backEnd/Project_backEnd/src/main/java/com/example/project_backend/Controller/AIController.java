package com.example.project_backend.Controller;

import com.example.project_backend.Entity.Member;
import com.example.project_backend.Entity.MemberProfile;
import com.example.project_backend.Entity.TrainingSession;
import com.example.project_backend.Service.AIService;
import com.example.project_backend.Service.MemberProfileService;
import com.example.project_backend.Service.MemberService;
import com.example.project_backend.Service.TrainingSessionService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/ai")
@CrossOrigin(origins = "*")
public class AIController {

    private static final Logger log = LoggerFactory.getLogger(AIController.class);

    private final AIService aiService;
    private final MemberService memberService;
    private final TrainingSessionService trainingSessionService;
    private final MemberProfileService memberProfileService;

    public AIController(AIService aiService,
                        MemberService memberService,
                        TrainingSessionService trainingSessionService,
                        MemberProfileService memberProfileService) {
        this.aiService = aiService;
        this.memberService = memberService;
        this.trainingSessionService = trainingSessionService;
        this.memberProfileService = memberProfileService;
    }

    private List<TrainingSession> getSessionsOrFallback(Long memberId, Long sessionId) {
        List<TrainingSession> sessions = trainingSessionService.getSessionsLastWeek(memberId);
        if (sessions.isEmpty()) {
            log.debug("Aucune séance cette semaine, utilisation de la séance courante seule");
            sessions = List.of(trainingSessionService.getById(sessionId));
        }
        return sessions;
    }

    @GetMapping("/fatigue/{memberId}/{sessionId}")
    public ResponseEntity<?> getFatigue(
            @PathVariable Long memberId,
            @PathVariable Long sessionId) {

        log.info("🎯 Prédiction FATIGUE — memberId={}, sessionId={}", memberId, sessionId);
        try {
            Member member = memberService.getMemberById(memberId);
            List<TrainingSession> sessions = getSessionsOrFallback(memberId, sessionId);
            Map<String, Object> result = aiService.predictFatigue(member, sessions);
            return ResponseEntity.ok(result);
        } catch (RuntimeException e) {
            log.error("❌ Erreur fatigue: {}", e.getMessage());
            return ResponseEntity.status(404).body(Map.of(
                    "error", e.getMessage(),
                    "memberId", memberId,
                    "sessionId", sessionId
            ));
        }
    }

    @GetMapping("/injury/{memberId}/{sessionId}")
    public ResponseEntity<?> getInjury(
            @PathVariable Long memberId,
            @PathVariable Long sessionId) {

        log.info("🎯 Prédiction BLESSURE — memberId={}, sessionId={}", memberId, sessionId);
        try {
            Member member = memberService.getMemberById(memberId);
            List<TrainingSession> sessions = getSessionsOrFallback(memberId, sessionId);
            Map<String, Object> result = aiService.predictInjury(member, sessions);
            return ResponseEntity.ok(result);
        } catch (RuntimeException e) {
            log.error("❌ Erreur blessure: {}", e.getMessage());
            return ResponseEntity.status(404).body(Map.of(
                    "error", e.getMessage(),
                    "memberId", memberId,
                    "sessionId", sessionId
            ));
        }
    }

    @GetMapping("/predict/{memberId}/{sessionId}")
    public ResponseEntity<?> getFullPrediction(
            @PathVariable Long memberId,
            @PathVariable Long sessionId) {

        log.info("🎯 Prédiction COMPLÈTE — memberId={}, sessionId={}", memberId, sessionId);

        try {
            Member member = memberService.getMemberById(memberId);
            TrainingSession lastSession = trainingSessionService.getById(sessionId);
            List<TrainingSession> previousSessions = trainingSessionService.getSessionsLastWeek(memberId);

            Map<String, Object> result = new HashMap<>();
            result.put("fatigue", aiService.predictFatigue(member, previousSessions));
            result.put("injury", aiService.predictInjury(member, previousSessions));
            result.put("overload", aiService.analyzeOverload(member, lastSession, previousSessions));
            result.put("memberId", memberId);
            result.put("sessionId", sessionId);
            result.put("sessionsAnalyzed", previousSessions.size());
            result.put("period", "7 derniers jours");

            Optional<MemberProfile> profileOpt = memberProfileService.getProfile(memberId);
            if (profileOpt.isPresent()) {
                MemberProfile profile = profileOpt.get();
                Map<String, Object> profileMap = memberProfileService.toMap(profile);

                double goalMult = memberProfileService.goalRiskMultiplier(profile.getPrimaryGoal());
                double chronicMult = memberProfileService.chronicPainRiskMultiplier(profile);
                double recoveryMult = memberProfileService.recoveryMultiplier(profile);

                result.put("memberProfile", profileMap);
                result.put("personalizedRecommendations", buildPersonalizedRecommendations(profile, previousSessions));
                result.put("medicalAlerts", buildMedicalAlerts(profile));

                result.put("profileRiskMultipliers", Map.of(
                        "goal", goalMult,
                        "chronicPain", chronicMult,
                        "recovery", recoveryMult,
                        "combined", Math.round(goalMult * chronicMult * recoveryMult * 100.0) / 100.0
                ));

                result.put("levelConsistency", checkLevelConsistency(profile, previousSessions));

                log.info("✅ Profil IA intégré — objectif={}, niveau={}",
                        profile.getPrimaryGoal(), profile.getSelfDeclaredLevel());
            } else {
                result.put("memberProfile", null);
                result.put("profileComplete", false);
                result.put("profileMessage", "Profil IA non renseigné — complétez votre profil pour des recommandations personnalisées");
            }

            log.info("✅ Prédiction complète retournée — {} séances analysées", previousSessions.size());
            return ResponseEntity.ok(result);

        } catch (RuntimeException e) {
            log.error("❌ Erreur prédiction complète: {}", e.getMessage());
            return ResponseEntity.status(404).body(Map.of(
                    "error", e.getMessage(),
                    "memberId", memberId,
                    "sessionId", sessionId
            ));
        }
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        return ResponseEntity.ok(Map.of(
                "status", "available",
                "service", "AI Controller + MemberProfile",
                "version", "3.1"
        ));
    }

    private List<String> buildPersonalizedRecommendations(MemberProfile profile, List<TrainingSession> sessions) {
        List<String> recs = new java.util.ArrayList<>();
        if (profile.getPrimaryGoal() == null) return recs;

        int sessionCount = sessions.size();
        int totalMin = sessions.stream().mapToInt(TrainingSession::getDuration).sum();
        int totalCardio = sessions.stream().mapToInt(TrainingSession::getCardioDurationMinutes).sum();

        String level = profile.getSelfDeclaredLevel() != null ? profile.getSelfDeclaredLevel().name() : "BEGINNER";

        // Recommandations basées sur l'objectif (Limite #11)
        switch (profile.getPrimaryGoal()) {
            case WEIGHT_LOSS -> {
                if (totalCardio < 90) recs.add("🏃 Objectif perte de poids : visez au moins 150 min de cardio/semaine (vous avez " + totalCardio + " min cette semaine).");
                if (sessionCount < 3) recs.add("💡 Pour optimiser la perte de poids, ciblez 4-5 séances par semaine avec alternance muscu + cardio.");
                recs.add("💡 Priorisez les exercices composés (squats, soulevé de terre, tractions) : plus de calories brûlées en moins de temps.");
            }
            case MUSCLE_GAIN -> {
                if (totalMin < 180) recs.add("💪 Objectif prise de masse : votre volume de muscu cette semaine est faible (" + totalMin + " min). Visez 3-4 séances de 60-90 min.");
                recs.add("💡 Concentrez-vous sur la progression des charges chaque semaine (+2,5 à 5% max).");
                recs.add("💡 Assurez-vous d'avoir un surplus calorique et 1,6-2,2g de protéines / kg de poids corporel.");
            }
            case ENDURANCE -> {
                if (totalCardio < 120) recs.add("🏅 Objectif endurance : augmentez progressivement le volume cardio (actuellement " + totalCardio + " min, cible : 200+ min/semaine).");
                recs.add("💡 Alternez séances longues à intensité modérée et séances courtes à haute intensité (HIIT 1×/semaine max).");
            }
            case TONING -> {
                recs.add("✨ Objectif tonification : combinez résistance modérée (15-20 reps) avec cardio régulier (3×/semaine).");
                recs.add("💡 Évitez les charges trop lourdes — concentrez-vous sur la contraction musculaire et la forme.");
            }
            case REHABILITATION -> {
                recs.add("🩺 Mode rééducation actif : privilégiez les exercices doux et le travail de mobilité.");
                recs.add("⚠️ Respectez strictement les limites de douleur — arrêtez si douleur > 4/10 pendant l'exercice.");
                if (profile.getCurrentInjuries() != null && !profile.getCurrentInjuries().isBlank())
                    recs.add("🔴 Blessure actuelle déclarée : " + profile.getCurrentInjuries() + " — consultez votre kiné avant d'augmenter la charge.");
            }
            case PERFORMANCE -> {
                recs.add("🏆 Mode performance : suivez un programme périodisé avec phases d'accumulation, d'intensification et de récupération.");
                recs.add("💡 Surveillez de près votre récupération — c'est là que la performance se construit.");
            }
            case GENERAL_FITNESS -> recs.add("💚 Objectif bien-être : continuez votre routine équilibrée — vous êtes sur la bonne voie.");
        }

        // Recommandations basées sur le niveau (Limite #1)
        if ("BEGINNER".equals(level)) {
            recs.add("🟢 Débutant : privilégiez la technique à la charge. Ne cherchez pas l'échec musculaire systématique.");
            recs.add("💡 Augmentez les charges uniquement quand vous maîtrisez parfaitement le mouvement.");
        } else if ("ATHLETE".equals(level)) {
            recs.add("🏆 Athlète confirmé : votre récupération est plus rapide. Vous pouvez entraîner les mêmes muscles 2-3x/semaine.");
            recs.add("💡 Surveillez les signes de surentraînement fatigue chronique, baisse de performance, troubles du sommeil).");
        }

        if (profile.getAvgSleepHours() != null && profile.getAvgSleepHours() < 6.5) {
            recs.add("😴 Sommeil insuffisant (" + profile.getAvgSleepHours() + "h/nuit) : la récupération musculaire est fortement impactée. Visez 7-9h.");
        }

        if (profile.getStressLevel() != null && profile.getStressLevel() >= 7) {
            recs.add("🧘 Niveau de stress élevé (" + profile.getStressLevel() + "/10) : intégrez des techniques de récupération active (yoga, respiration, marche).");
        }

        if (profile.getExerciseRestrictions() != null && !profile.getExerciseRestrictions().isBlank()) {
            recs.add("🚫 Exercices à éviter (déclarés) : " + profile.getExerciseRestrictions());
        }

        return recs;
    }

    private List<String> buildMedicalAlerts(MemberProfile profile) {
        List<String> alerts = new java.util.ArrayList<>();

        if (profile.getCurrentInjuries() != null && !profile.getCurrentInjuries().isBlank()) {
            alerts.add("🔴 Blessure en cours : " + profile.getCurrentInjuries() + " — adapter la séance en conséquence.");
        }
        if (profile.getMedicalConditions() != null && !profile.getMedicalConditions().isBlank()) {
            alerts.add("⚕️ Condition médicale déclarée : " + profile.getMedicalConditions());
        }
        if (profile.getChronicPainZones() != null
                && !profile.getChronicPainZones().isBlank()
                && !profile.getChronicPainZones().equalsIgnoreCase("NONE")) {
            int intensity = profile.getChronicPainIntensity() != null ? profile.getChronicPainIntensity() : 0;
            alerts.add("⚠️ Douleurs chroniques (" + profile.getChronicPainZones() + ") — intensité " + intensity + "/10 : risque de blessure accru dans ces zones.");
        }
        if (Boolean.TRUE.equals(profile.getHasMedicalFollowUp()) && profile.getMedicalFollowUpDetail() != null) {
            alerts.add("👨‍⚕️ Suivi médical actif : " + profile.getMedicalFollowUpDetail());
        }

        return alerts;
    }

    private Map<String, Object> checkLevelConsistency(MemberProfile profile, List<TrainingSession> sessions) {
        Map<String, Object> consistency = new HashMap<>();

        int sessionCount = sessions.size();
        String aiEstimatedLevel;
        if (sessionCount < 10) aiEstimatedLevel = "BEGINNER";
        else if (sessionCount < 60) aiEstimatedLevel = "INTERMEDIATE";
        else if (sessionCount < 120) aiEstimatedLevel = "ADVANCED";
        else aiEstimatedLevel = "ATHLETE";

        String declaredLevel = profile.getSelfDeclaredLevel() != null
                ? profile.getSelfDeclaredLevel().name() : "BEGINNER";

        boolean isConsistent = declaredLevel.equals(aiEstimatedLevel);

        consistency.put("declaredLevel", declaredLevel);
        consistency.put("aiEstimatedLevel", aiEstimatedLevel);
        consistency.put("isConsistent", isConsistent);

        if (!isConsistent) {
            if (isHigherThan(declaredLevel, aiEstimatedLevel)) {
                consistency.put("message", "Niveau déclaré plus élevé que l'estimation IA. Les recommandations tiennent compte des deux.");
            } else {
                consistency.put("message", "Niveau déclaré plus prudent que l'estimation IA — bonne approche de progression sécurisée.");
            }
        }

        return consistency;
    }

    private boolean isHigherThan(String l1, String l2) {
        List<String> order = List.of("BEGINNER", "INTERMEDIATE", "ADVANCED", "ATHLETE");
        return order.indexOf(l1) > order.indexOf(l2);
    }
}