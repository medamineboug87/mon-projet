package com.example.project_backend.Service;

import com.example.project_backend.DTO.MuscleRestStatus;
import com.example.project_backend.Entity.MemberProfile;
import com.example.project_backend.Entity.SessionExercise;
import com.example.project_backend.Entity.TrainingSession;
import com.example.project_backend.Repository.MemberProfileRepository;
import com.example.project_backend.Repository.SessionExerciseRepository;
import com.example.project_backend.Repository.TrainingSessionRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class MuscleRecoveryService {

    private final TrainingSessionRepository sessionRepository;
    private final SessionExerciseRepository exerciseRepository;
    private final MemberProfileRepository   profileRepository;

    // ── Groupes musculaires ──
    private static final Map<String, String> MUSCLE_GROUP = new HashMap<>() {{
        put("pectoraux",              "PUSH");
        put("épaules",                "PUSH");
        put("triceps",                "PUSH");
        put("triceps droit",          "PUSH");
        put("dorsaux",                "PULL");
        put("biceps",                 "PULL");
        put("biceps droit",           "PULL");
        put("trapèzes",               "PULL");
        put("quadriceps",             "LEGS");
        put("quadriceps droit",       "LEGS");
        put("ischio-jambiers",        "LEGS");
        put("ischio-jambiers droits", "LEGS");
        put("fessiers",               "LEGS");
        put("mollets",                "LEGS");
        put("mollets droits",         "LEGS");
        put("abdominaux",             "CORE");
        put("lombaires",              "CORE");
    }};

    // ── Temps de base en heures (selon littérature scientifique) ──
    private static final Map<String, Integer> BASE_RECOVERY_HOURS = new HashMap<>() {{
        put("pectoraux",              48);
        put("épaules",                48);
        put("triceps",                36);
        put("triceps droit",          36);
        put("dorsaux",                48);
        put("biceps",                 36);
        put("biceps droit",           36);
        put("trapèzes",               48);
        put("quadriceps",             72);
        put("quadriceps droit",       72);
        put("ischio-jambiers",        72);
        put("ischio-jambiers droits", 72);
        put("fessiers",               60);
        put("mollets",                36);
        put("mollets droits",         36);
        put("abdominaux",             24);
        put("lombaires",              72);
    }};

    public MuscleRecoveryService(TrainingSessionRepository sessionRepository,
                                  SessionExerciseRepository exerciseRepository,
                                  MemberProfileRepository profileRepository) {
        this.sessionRepository = sessionRepository;
        this.exerciseRepository = exerciseRepository;
        this.profileRepository  = profileRepository;
    }

    // ════════════════════════════════════════════════════════════════
    // MÉTHODE PRINCIPALE
    // Retourne le statut de récupération de chaque muscle travaillé
    // ════════════════════════════════════════════════════════════════

    public Map<String, Object> getMuscleRecoveryStatus(Long memberId) {

        MemberProfile profile = profileRepository
                .findByMemberId(memberId).orElse(null);
        String level = profile != null && profile.getSelfDeclaredLevel() != null
                ? profile.getSelfDeclaredLevel().name() : "BEGINNER";

        // Récupérer toutes les séances des 14 derniers jours
        LocalDate twoWeeksAgo = LocalDate.now().minusDays(14);
        List<TrainingSession> sessions = sessionRepository
                .findByMemberIdSince(memberId, twoWeeksAgo)
                .stream()
                .sorted((a, b) -> b.getDate().compareTo(a.getDate()))
                .collect(Collectors.toList());

        // Aucune séance trouvée
        if (sessions.isEmpty()) {
            return buildEmptyResponse();
        }

        // ── Construire la carte : muscle → dernière séance où il a été travaillé ──
        Map<String, TrainingSession> lastSessionByMuscle  = new LinkedHashMap<>();
        Map<String, SessionExercise> lastExerciseByMuscle = new LinkedHashMap<>();

        for (TrainingSession session : sessions) {
            List<SessionExercise> exercises = exerciseRepository
                    .findBySessionIdOrderByExerciseOrderAsc(session.getId());

            for (SessionExercise ex : exercises) {
                String muscle = normalize(ex.getMuscleName());
                if (muscle == null || muscle.isBlank()) continue;

                // Ne garder que la plus récente
                if (!lastSessionByMuscle.containsKey(muscle)) {
                    lastSessionByMuscle.put(muscle, session);
                    lastExerciseByMuscle.put(muscle, ex);
                }
            }
        }

        // Aucun exercice détaillé enregistré
        if (lastSessionByMuscle.isEmpty()) {
            return buildNoExerciseResponse();
        }

        // ── Calculer le statut par muscle ──
        List<MuscleRestStatus> muscleStatuses = new ArrayList<>();

        for (Map.Entry<String, TrainingSession> entry : lastSessionByMuscle.entrySet()) {
            String muscle           = entry.getKey();
            TrainingSession lastSes = entry.getValue();
            SessionExercise lastEx  = lastExerciseByMuscle.get(muscle);

            MuscleRestStatus status = calculateMuscleStatus(
                    muscle, lastSes, lastEx, level);
            muscleStatuses.add(status);
        }

        // ── Trier : CRITICAL d'abord, puis RECOVERING, puis READY ──
        muscleStatuses.sort((a, b) -> {
            Map<String, Integer> order = Map.of(
                    "CRITICAL", 0, "RECOVERING", 1, "READY", 2);
            return Integer.compare(
                    order.getOrDefault(a.getStatus(), 2),
                    order.getOrDefault(b.getStatus(), 2));
        });

        return buildResponse(muscleStatuses, level);
    }

    // ════════════════════════════════════════════════════════════════
    // CALCUL DU STATUT POUR UN MUSCLE
    // ════════════════════════════════════════════════════════════════

    private MuscleRestStatus calculateMuscleStatus(String muscle,
                                                    TrainingSession lastSession,
                                                    SessionExercise lastEx,
                                                    String level) {
        MuscleRestStatus status = new MuscleRestStatus();
        status.setMuscleName(capitalize(muscle));
        status.setMuscleGroup(MUSCLE_GROUP.getOrDefault(muscle, "OTHER"));

        // ── Temps de récupération dynamique ──
        int baseHours     = BASE_RECOVERY_HOURS.getOrDefault(muscle, 48);
        int requiredHours = adjustRecoveryHours(baseHours, lastSession, lastEx, level);
        status.setHoursRequired(requiredHours);

        // ── Heures écoulées depuis la séance ──
        LocalDate sessionDate = lastSession.getDate();
        long hoursElapsed = ChronoUnit.HOURS.between(
                sessionDate.atStartOfDay(),
                LocalDateTime.now());
        status.setHoursElapsed((int) Math.min(hoursElapsed, requiredHours));

        // ── Heures restantes ──
        int hoursRemaining = (int) Math.max(0, requiredHours - hoursElapsed);
        status.setHoursRemaining(hoursRemaining);

        // ── Disponibilité ──
        status.setAvailable(hoursRemaining == 0);

        // ── Statut textuel ──
        if (hoursRemaining == 0) {
            status.setStatus("READY");
        } else if (hoursElapsed < requiredHours / 2.0) {
            status.setStatus("CRITICAL");   // moins de la moitié du temps écoulé
        } else {
            status.setStatus("RECOVERING");
        }

        // ── Informations de la dernière séance ──
        status.setLastWorkedDate(sessionDate.toString());
        status.setLastIntensity(lastSession.getIntensity());

        double volume = lastEx != null && lastEx.getTotalVolume() != null
                ? lastEx.getTotalVolume() : 0.0;
        status.setLastVolume(Math.round(volume * 10.0) / 10.0);

        return status;
    }

    // ════════════════════════════════════════════════════════════════
    // AJUSTEMENT DYNAMIQUE DU TEMPS DE RÉCUPÉRATION
    // ════════════════════════════════════════════════════════════════

    private int adjustRecoveryHours(int baseHours,
                                     TrainingSession session,
                                     SessionExercise ex,
                                     String level) {
        double multiplier = 1.0;

        // 1. Niveau du membre
        multiplier *= switch (level) {
            case "BEGINNER"     -> 1.3;
            case "INTERMEDIATE" -> 1.1;
            case "ADVANCED"     -> 1.0;
            case "ATHLETE"      -> 0.85;
            default             -> 1.0;
        };

        // 2. Intensité de la séance (1-10)
        int intensity = session.getIntensity();
        if (intensity >= 9)      multiplier += 0.3;
        else if (intensity >= 7) multiplier += 0.15;
        else if (intensity <= 3) multiplier -= 0.1;

        // 3. Échec musculaire atteint
        if (ex != null && Boolean.TRUE.equals(ex.getFailureReached())) {
            multiplier += 0.25;
        }

        // 4. RPE élevé (effort perçu)
        if (ex != null && ex.getRpe() != null) {
            if (ex.getRpe() >= 9)      multiplier += 0.2;
            else if (ex.getRpe() >= 7) multiplier += 0.1;
        }

        // 5. Douleur ressentie post-séance
        if (session.getPainLevel() != null) {
            if (session.getPainLevel() >= 7)      multiplier += 0.3;
            else if (session.getPainLevel() >= 4) multiplier += 0.15;
        }

        // 6. Pas d'échauffement → récupération plus longue
        if (Boolean.FALSE.equals(session.getWarmupDone())) {
            multiplier += 0.1;
        }

        // Plafonner entre 0.8× et 2.0× le temps de base
        multiplier = Math.min(2.0, Math.max(0.8, multiplier));

        return (int) Math.round(baseHours * multiplier);
    }

    // ════════════════════════════════════════════════════════════════
    // CONSTRUCTION DE LA RÉPONSE FINALE
    // ════════════════════════════════════════════════════════════════

    private Map<String, Object> buildResponse(List<MuscleRestStatus> statuses,
                                               String level) {
        Map<String, Object> response = new LinkedHashMap<>();

        // ── Grouper par statut ──
        List<MuscleRestStatus> ready = statuses.stream()
                .filter(s -> "READY".equals(s.getStatus())).toList();
        List<MuscleRestStatus> recovering = statuses.stream()
                .filter(s -> "RECOVERING".equals(s.getStatus())).toList();
        List<MuscleRestStatus> critical = statuses.stream()
                .filter(s -> "CRITICAL".equals(s.getStatus())).toList();

        response.put("muscleStatuses",    statuses);
        response.put("readyMuscles",      ready.stream().map(MuscleRestStatus::getMuscleName).toList());
        response.put("recoveringMuscles", recovering.stream().map(MuscleRestStatus::getMuscleName).toList());
        response.put("criticalMuscles",   critical.stream().map(MuscleRestStatus::getMuscleName).toList());

        // ── Groupes musculaires disponibles aujourd'hui ──
        Set<String> availableGroups = ready.stream()
                .map(MuscleRestStatus::getMuscleGroup)
                .collect(Collectors.toSet());
        response.put("availableMuscleGroups", availableGroups);

        // ── Recommandation pour aujourd'hui ──
        response.put("todayRecommendation",
                buildTodayRecommendation(availableGroups, critical, recovering));

        // ── Récapitulatif ──
        response.put("summary", Map.of(
                "totalTracked",    statuses.size(),
                "readyCount",      ready.size(),
                "recoveringCount", recovering.size(),
                "criticalCount",   critical.size(),
                "fitnessLevel",    level
        ));

        return response;
    }

    // ════════════════════════════════════════════════════════════════
    // RECOMMANDATION DE SÉANCE POUR AUJOURD'HUI
    // ════════════════════════════════════════════════════════════════

    private Map<String, Object> buildTodayRecommendation(
            Set<String> availableGroups,
            List<MuscleRestStatus> critical,
            List<MuscleRestStatus> recovering) {

        Map<String, Object> rec = new LinkedHashMap<>();

        if (!critical.isEmpty() && availableGroups.isEmpty()) {
            // Tous les muscles en phase critique
            rec.put("canTrain",  false);
            rec.put("type",      "REST");
            rec.put("message",   "💤 Repos complet recommandé. Muscles en récupération critique.");
            rec.put("avoid",     critical.stream()
                    .map(MuscleRestStatus::getMuscleName).toList());

        } else if (!critical.isEmpty()) {
            // Certains muscles critiques mais d'autres disponibles
            rec.put("canTrain",  true);
            rec.put("type",      "PARTIAL");
            rec.put("message",   "⚠️ Entraînez uniquement les groupes disponibles.");
            rec.put("avoid",     critical.stream()
                    .map(MuscleRestStatus::getMuscleName).toList());
            rec.put("availableGroups", availableGroups);

        } else if (availableGroups.isEmpty() && !recovering.isEmpty()) {
            // Tous les muscles en récupération (pas critique)
            rec.put("canTrain",  false);
            rec.put("type",      "REST");
            rec.put("message",   "💤 Repos recommandé. Tous vos muscles récupèrent encore.");
            rec.put("avoid",     recovering.stream()
                    .map(MuscleRestStatus::getMuscleName).toList());

        } else if (!availableGroups.isEmpty()) {
            // Des groupes musculaires sont disponibles
            rec.put("canTrain",  true);
            rec.put("type",      "TARGETED");
            rec.put("message",   "✅ Vous pouvez travailler : "
                    + String.join(", ", availableGroups));
            rec.put("availableGroups", availableGroups);
            rec.put("avoid",     List.of());

        } else {
            // Aucune donnée suffisante
            rec.put("canTrain",  true);
            rec.put("type",      "FREE");
            rec.put("message",   "✅ Aucune restriction détectée. Bonne séance !");
            rec.put("avoid",     List.of());
        }

        // Le cardio reste possible sauf si douleur critique généralisée
        rec.put("cardioOk", critical.size() < 3);

        return rec;
    }

    // ════════════════════════════════════════════════════════════════
    // RÉPONSES VIDES
    // ════════════════════════════════════════════════════════════════

    private Map<String, Object> buildEmptyResponse() {
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("muscleStatuses",    List.of());
        response.put("readyMuscles",      List.of());
        response.put("recoveringMuscles", List.of());
        response.put("criticalMuscles",   List.of());
        response.put("availableMuscleGroups", Set.of());
        response.put("todayRecommendation", Map.of(
                "canTrain", true,
                "type",     "FREE",
                "message",  "✅ Aucune séance récente trouvée. Vous pouvez vous entraîner !",
                "cardioOk", true
        ));
        response.put("summary", Map.of(
                "totalTracked",    0,
                "readyCount",      0,
                "recoveringCount", 0,
                "criticalCount",   0,
                "note", "Aucune séance enregistrée dans les 14 derniers jours"
        ));
        return response;
    }

    private Map<String, Object> buildNoExerciseResponse() {
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("muscleStatuses",    List.of());
        response.put("readyMuscles",      List.of());
        response.put("recoveringMuscles", List.of());
        response.put("criticalMuscles",   List.of());
        response.put("availableMuscleGroups", Set.of());
        response.put("todayRecommendation", Map.of(
                "canTrain", true,
                "type",     "FREE",
                "message",  "✅ Aucun exercice détaillé trouvé. Ajoutez vos exercices pour un suivi musculaire.",
                "cardioOk", true
        ));
        response.put("summary", Map.of(
                "totalTracked", 0,
                "note", "Enregistrez vos exercices avec le muscle ciblé pour activer le suivi de récupération"
        ));
        return response;
    }

    // ════════════════════════════════════════════════════════════════
    // HELPERS
    // ════════════════════════════════════════════════════════════════

    private String normalize(String input) {
        if (input == null) return "";
        return input.toLowerCase().trim();
    }

    private String capitalize(String input) {
        if (input == null || input.isBlank()) return input;
        return Character.toUpperCase(input.charAt(0)) + input.substring(1);
    }
}
