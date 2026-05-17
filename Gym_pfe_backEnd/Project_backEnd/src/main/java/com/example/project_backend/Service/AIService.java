package com.example.project_backend.Service;

import com.example.project_backend.Entity.Member;
import com.example.project_backend.Entity.MemberProfile;
import com.example.project_backend.Entity.SessionExercise;
import com.example.project_backend.Entity.TrainingSession;
import com.example.project_backend.Repository.MemberProfileRepository;
import com.example.project_backend.Repository.SessionExerciseRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.time.Duration;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class AIService {

    private static final Logger log = LoggerFactory.getLogger(AIService.class);

    private final WebClient                  webClient;
    private final MemberProfileService       memberProfileService;
    private final SessionExerciseRepository  exerciseRepository;
    private final MemberProfileRepository    memberProfileRepository;

    // ── Seuils de progression sécuritaire par muscle (%) ──
    private static final Map<String, Double> SAFE_PROGRESSION_PCT = new HashMap<>() {{
        put("pectoraux",              10.0);
        put("dorsaux",                10.0);
        put("épaules",                 8.0);
        put("biceps",                 12.0);
        put("biceps droit",           12.0);
        put("triceps",                12.0);
        put("triceps droit",          12.0);
        put("abdominaux",             15.0);
        put("quadriceps",              8.0);
        put("quadriceps droit",        8.0);
        put("ischio-jambiers",         8.0);
        put("ischio-jambiers droits",  8.0);
        put("mollets",                15.0);
        put("mollets droits",         15.0);
        put("fessiers",               10.0);
        put("lombaires",               7.0);
        put("trapèzes",               12.0);
    }};

    // ── Groupes musculaires pour la détection de déséquilibre ──
    private static final Map<String, String> MUSCLE_TO_GROUP = new HashMap<>() {{
        put("pectoraux",              "push");
        put("dorsaux",                "pull");
        put("épaules",                "push");
        put("biceps",                 "pull");
        put("biceps droit",           "pull");
        put("triceps",                "push");
        put("triceps droit",          "push");
        put("abdominaux",             "core");
        put("quadriceps",             "legs");
        put("quadriceps droit",       "legs");
        put("ischio-jambiers",        "legs");
        put("ischio-jambiers droits", "legs");
        put("fessiers",               "legs");
        put("mollets",                "legs");
        put("mollets droits",         "legs");
        put("lombaires",              "core");
        put("trapèzes",               "pull");
    }};

    public AIService(@Value("${ai.service.url}") String aiServiceUrl,
                     MemberProfileService memberProfileService,
                     SessionExerciseRepository exerciseRepository,
                     MemberProfileRepository memberProfileRepository) {
        this.webClient = WebClient.builder()
                .baseUrl(aiServiceUrl)
                .build();
        this.memberProfileService    = memberProfileService;
        this.exerciseRepository      = exerciseRepository;
        this.memberProfileRepository = memberProfileRepository;
    }

    // ════════════════════════════════════════════════════════════════
    // PRÉDICTION FATIGUE
    // ════════════════════════════════════════════════════════════════

    public Map<String, Object> predictFatigueWithAI(Member member,
                                                    List<TrainingSession> sessions) {
        try {
            MemberProfile profile   = memberProfileRepository.findByMemberId(member.getId()).orElse(null);
            TrainingSession lastSes = sessions.isEmpty() ? null : sessions.get(0);

            // ── CORRECTION #1 : totalDuration calculé et envoyé explicitement ──
            double duration           = lastSes != null ? lastSes.getDuration() : 60;
            double cardioDuration     = lastSes != null ? lastSes.getCardioDurationMinutes() : 0;
            double totalDuration      = duration + cardioDuration;

            // ── CORRECTION #2 : painLevel inclus et documenté ──
            // painLevel est utilisé côté Python comme multiplicateur post-modèle
            // (pas dans FATIGUE_FEATURES ML) — envoyé pour l'ajustement du score final
            int painLevel = lastSes != null && lastSes.getPainLevel() != null
                    ? lastSes.getPainLevel() : 0;

            Map<String, Object> request = new HashMap<>();
            // Champs du modèle ML (mappés dans FATIGUE_FEATURES Python)
            request.put("age",                   member.getAge());
            request.put("bmi",                   calculateBMI(member));
            request.put("gender",                "MALE".equalsIgnoreCase(member.getGender()) ? 1 : 0);
            request.put("duration",              duration);
            request.put("totalDuration",         totalDuration);   // FIX: toujours calculé
            request.put("weightLifted",          getEffectiveWeight(lastSes));
            request.put("intensity",             lastSes != null ? lastSes.getIntensity() : 5);
            request.put("hasCardio",             lastSes != null && lastSes.getHasCardio() ? 1 : 0);
            request.put("cardioDurationMinutes", cardioDuration);
            request.put("cardioIntensity",       lastSes != null ? lastSes.getCardioIntensity() : 0);
            request.put("muscleRiskScore",       lastSes != null && lastSes.getExerciseBasedMuscleRiskScore() != null
                    ? lastSes.getExerciseBasedMuscleRiskScore() : 1.0);
            request.put("recoveryDaysPerWeek",   lastSes != null && lastSes.getRecoveryDaysPerWeek() != null
                    ? lastSes.getRecoveryDaysPerWeek() : 2);

            // Champs de personnalisation (multiplicateurs post-modèle côté Python)
            // ⚠ Ces champs ne font PAS partie de FATIGUE_FEATURES du modèle ML —
            //   ils sont utilisés par Python pour ajuster le score final via des multiplicateurs
            //   (fitnessLevel → level_multiplier, avgSleepHours → sleep_multiplier, etc.)
            request.put("fitnessLevel",      profile != null && profile.getSelfDeclaredLevel() != null
                    ? profile.getSelfDeclaredLevel().name() : "BEGINNER");
            request.put("avgSleepHours",     profile != null && profile.getAvgSleepHours() != null
                    ? profile.getAvgSleepHours() : 7.0);
            request.put("stressLevel",       profile != null && profile.getStressLevel() != null
                    ? profile.getStressLevel() : 5);
            request.put("painLevel",         painLevel); // multiplicateur post-modèle

            log.info("📤 Appel Python /predict_fatigue — memberId={} | duration={} | totalDuration={} | painLevel={}",
                    member.getId(), duration, totalDuration, painLevel);

            Map<String, Object> response = webClient.post()
                    .uri("/predict_fatigue")
                    .bodyValue(request)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .timeout(Duration.ofSeconds(15))
                    .block();

            if (response != null) {
                log.info("✅ Réponse Python fatigue: label={} | proba={}",
                        response.get("label"), response.get("proba_fatigued"));
                return response;
            }
        } catch (WebClientResponseException e) {
            log.error("❌ Erreur HTTP appel Python fatigue: {} - {}", e.getStatusCode(), e.getResponseBodyAsString());
        } catch (Exception e) {
            log.warn("⚠️ Service IA indisponible pour fatigue, fallback heuristique: {}", e.getMessage());
        }

        return predictFatigueHeuristic(member, sessions);
    }

    public Map<String, Object> predictFatigueHeuristic(Member member,
                                                       List<TrainingSession> sessions) {
        Map<String, Object> result = new LinkedHashMap<>();

        if (sessions == null || sessions.isEmpty()) {
            result.put("fatigueScore",        5.0);
            result.put("label",               "normal");
            result.put("confidence",          0.8);
            result.put("message",             "Pas assez de données pour analyser la fatigue");
            result.put("exerciseCount",       0);
            result.put("effectiveWeightUsed", 0);
            result.put("muscleRiskSource",    "NONE");
            result.put("source",              "HEURISTIC_NO_DATA");
            return result;
        }

        MemberProfile profile   = memberProfileRepository.findByMemberId(member.getId()).orElse(null);
        String fitnessLevel     = profile != null && profile.getSelfDeclaredLevel() != null
                ? profile.getSelfDeclaredLevel().name() : "BEGINNER";

        double levelMultiplier  = getFatigueLevelMultiplier(fitnessLevel);
        TrainingSession lastSes = sessions.get(0);

        int    sessionCount    = Math.min(sessions.size(), 7);
        double totalIntensity  = sessions.stream().mapToInt(TrainingSession::getIntensity).average().orElse(5.0);
        double totalVolume     = sessions.stream().mapToDouble(TrainingSession::getTotalVolume).average().orElse(0.0);
        double avgDuration     = sessions.stream().mapToInt(TrainingSession::getDuration).average().orElse(0.0);
        int    painLevel       = lastSes.getPainLevel() != null ? lastSes.getPainLevel() : 0;

        double sleepMultiplier  = 1.0;
        double stressMultiplier = 1.0;
        if (profile != null) {
            if (profile.getAvgSleepHours() != null && profile.getAvgSleepHours() < 6.0)
                sleepMultiplier = 1.3;
            else if (profile.getAvgSleepHours() != null && profile.getAvgSleepHours() < 7.0)
                sleepMultiplier = 1.15;
            if (profile.getStressLevel() != null && profile.getStressLevel() >= 7)
                stressMultiplier = 1.25;
            else if (profile.getStressLevel() != null && profile.getStressLevel() >= 5)
                stressMultiplier = 1.1;
        }

        // ── CORRECTION #3 : painMultiplier cohérent avec app.py ──
        double painMultiplier = painLevel > 3 ? 1.0 + (painLevel / 20.0) : 1.0;

        double fatigueScore = (sessionCount * 0.25)
                + (totalIntensity * 0.3)
                + (totalVolume / 1000 * 0.2)
                + (avgDuration / 60 * 0.15)
                + (painLevel / 10.0) * 0.1;
        fatigueScore = fatigueScore * levelMultiplier * sleepMultiplier * stressMultiplier * painMultiplier;
        fatigueScore = Math.min(10.0, Math.max(1.0, fatigueScore));
        boolean isFatigued = fatigueScore > 6.0;

        double effectiveWeight = getEffectiveWeight(lastSes);
        int exerciseCount      = lastSes.getExercises() != null ? lastSes.getExercises().size() : 0;

        result.put("fatigueScore",        Math.round(fatigueScore * 10.0) / 10.0);
        result.put("label",               isFatigued ? "fatigué" : "normal");
        result.put("confidence",          Math.min(0.95, 0.6 + (fatigueScore / 20)));
        result.put("sessionsAnalyzed",    sessionCount);
        result.put("exerciseCount",       exerciseCount);
        result.put("effectiveWeightUsed", effectiveWeight);
        result.put("muscleRiskSource",    exerciseCount > 0 ? "EXERCICES_RÉELS" : "GLOBAL");
        result.put("fitnessLevel",        fitnessLevel);
        result.put("source",              "HEURISTIC");
        result.put("fatigueMultipliers",  Map.of(
                "level",  levelMultiplier,
                "sleep",  sleepMultiplier,
                "stress", stressMultiplier,
                "pain",   painMultiplier
        ));

        return result;
    }

    // ════════════════════════════════════════════════════════════════
    // PRÉDICTION BLESSURE
    // ════════════════════════════════════════════════════════════════

    public Map<String, Object> predictInjuryWithAI(Member member,
                                                   List<TrainingSession> sessions) {
        try {
            MemberProfile profile = memberProfileRepository.findByMemberId(member.getId()).orElse(null);

            Map<String, Object> request = new HashMap<>();
            // Champs du modèle ML (mappés dans INJURY_FEATURES Python)
            request.put("Age",                      member.getAge());
            request.put("Training_Intensity",        calculateAverageIntensity(sessions));
            request.put("Training_Hours_Per_Week",   calculateTrainingHoursPerWeek(sessions));
            request.put("Recovery_Days_Per_Week",    calculateRecoveryDays(sessions));
            request.put("Fatigue_Score",             calculateFatigueScore(member, sessions));
            request.put("Load_Balance_Score",        calculateLoadBalanceScore(sessions));
            request.put("ACL_Risk_Score",            calculateACLRiskScore(member, sessions));
            request.put("WeightLiftedNorm",          getAverageWeightLifted(sessions));
            request.put("SessionsPerWeek",           sessions.size());
            request.put("HasCardio",                 hasCardioInSessions(sessions) ? 1 : 0);
            request.put("CardioDuration",            getAverageCardioDuration(sessions));
            request.put("CardioIntensity",           getAverageCardioIntensity(sessions));
            request.put("MuscleRiskScore",           getAverageMuscleRiskScore(sessions));
            request.put("Gender",                    "MALE".equalsIgnoreCase(member.getGender()) ? 1 : 0);
            request.put("BMI",                       calculateBMI(member));

            // Champs de personnalisation (multiplicateurs post-modèle côté Python)
            // ⚠ Même remarque que pour fatigue : ne font PAS partie de INJURY_FEATURES ML
            request.put("fitnessLevel",  profile != null && profile.getSelfDeclaredLevel() != null
                    ? profile.getSelfDeclaredLevel().name() : "BEGINNER");
            request.put("avgSleepHours", profile != null && profile.getAvgSleepHours() != null
                    ? profile.getAvgSleepHours() : 7.0);
            request.put("stressLevel",   profile != null && profile.getStressLevel() != null
                    ? profile.getStressLevel() : 5);

            log.info("📤 Appel Python /predict_injury — memberId={} | sessions={} | ACL={}",
                    member.getId(), sessions.size(), request.get("ACL_Risk_Score"));

            Map<String, Object> response = webClient.post()
                    .uri("/predict_injury")
                    .bodyValue(request)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .timeout(Duration.ofSeconds(15))
                    .block();

            if (response != null) {
                log.info("✅ Réponse Python injury: label={} | riskLevel={}",
                        response.get("label"), response.get("risk_level"));
                return response;
            }
        } catch (WebClientResponseException e) {
            log.error("❌ Erreur HTTP appel Python injury: {} - {}", e.getStatusCode(), e.getResponseBodyAsString());
        } catch (Exception e) {
            log.warn("⚠️ Service IA indisponible pour blessure, fallback heuristique: {}", e.getMessage());
        }

        return predictInjuryHeuristic(member, sessions);
    }

    public Map<String, Object> predictInjuryHeuristic(Member member,
                                                      List<TrainingSession> sessions) {
        Map<String, Object> result = new LinkedHashMap<>();

        if (sessions == null || sessions.isEmpty()) {
            result.put("injuryRisk",    0.25);
            result.put("label",         "risque faible");
            result.put("riskLevel",     "FAIBLE");
            result.put("confidence",    0.8);
            result.put("injury_risk",   0);
            result.put("risk_level",    "FAIBLE");
            result.put("proba_injured", 0.25);
            result.put("source",        "HEURISTIC_NO_DATA");
            return result;
        }

        MemberProfile profile  = memberProfileRepository.findByMemberId(member.getId()).orElse(null);
        String fitnessLevel    = profile != null && profile.getSelfDeclaredLevel() != null
                ? profile.getSelfDeclaredLevel().name() : "BEGINNER";

        double levelRiskMultiplier = getInjuryRiskMultiplier(fitnessLevel);
        Map<String, Object> fatigue = predictFatigueHeuristic(member, sessions);
        double fatigueScore = (Double) fatigue.get("fatigueScore");

        int painOccurrences = (int) sessions.stream()
                .filter(s -> s.getPainLevel() != null && s.getPainLevel() > 3)
                .count();

        boolean hasChronicPain = profile != null
                && profile.getChronicPainZones() != null
                && !profile.getChronicPainZones().isBlank()
                && !profile.getChronicPainZones().equalsIgnoreCase("NONE");
        boolean hasInjuryHistory = profile != null
                && profile.getCurrentInjuries() != null
                && !profile.getCurrentInjuries().isBlank();

        double rapidProgressionRisk = 0.0;
        for (TrainingSession session : sessions) {
            List<SessionExercise> exercises = session.getExercises();
            if (exercises != null) {
                for (SessionExercise ex : exercises) {
                    if (Boolean.TRUE.equals(ex.getFailureReached())) rapidProgressionRisk += 0.05;
                    if (ex.getRpe() != null && ex.getRpe() >= 9)      rapidProgressionRisk += 0.03;
                }
            }
        }
        rapidProgressionRisk = Math.min(0.5, rapidProgressionRisk);

        Map<String, Object> imbalanceRisk = detectMuscleImbalance(member, sessions);
        double imbalanceScore = (Double) imbalanceRisk.getOrDefault("riskScore", 0.0);

        double recoveryScore = 0.1;

        double injuryRisk = (fatigueScore / 10) * 0.25
                + (painOccurrences / Math.max(1, sessions.size())) * 0.15
                + rapidProgressionRisk * 0.2
                + imbalanceScore * 0.2
                + recoveryScore * 0.1;
        if (hasChronicPain)   injuryRisk += 0.15;
        if (hasInjuryHistory) injuryRisk += 0.2;
        injuryRisk = injuryRisk * levelRiskMultiplier;
        injuryRisk = Math.min(0.95, Math.max(0.05, injuryRisk));

        String riskLevel = injuryRisk > 0.7 ? "ÉLEVÉ"  : (injuryRisk > 0.4 ? "MODÉRÉ" : "FAIBLE");
        String label     = injuryRisk > 0.7 ? "risque élevé" : (injuryRisk > 0.4 ? "risque modéré" : "risque faible");

        result.put("injuryRisk",      Math.round(injuryRisk * 100.0) / 100.0);
        result.put("label",           label);
        result.put("riskLevel",       riskLevel);
        result.put("confidence",      Math.min(0.9, 0.5 + injuryRisk));
        result.put("muscleImbalance", imbalanceRisk);
        result.put("injury_risk",     injuryRisk > 0.5 ? 1 : 0);
        result.put("risk_level",      riskLevel);
        result.put("proba_injured",   injuryRisk);
        result.put("source",          "HEURISTIC");

        return result;
    }

    // ════════════════════════════════════════════════════════════════
    // ANALYSE DE SURCHARGE
    // ════════════════════════════════════════════════════════════════

    public Map<String, Object> analyzeOverload(Member member,
                                               TrainingSession lastSession,
                                               List<TrainingSession> previousSessions) {
        Map<String, Object> analysis = new LinkedHashMap<>();
        List<String> warnings        = new ArrayList<>();
        List<String> recommendations = new ArrayList<>();

        MemberProfile profile = memberProfileRepository.findByMemberId(member.getId()).orElse(null);
        String fitnessLevel   = profile != null && profile.getSelfDeclaredLevel() != null
                ? profile.getSelfDeclaredLevel().name() : "BEGINNER";

        double effectiveWeight    = getEffectiveWeight(lastSession);
        Double weightProgressPct  = calculateWeightProgressionPercent(effectiveWeight, previousSessions);
        boolean usedRealExercises = lastSession.getExercises() != null
                && !lastSession.getExercises().isEmpty();

        if (weightProgressPct != null) {
            analysis.put("weightProgressionPercent",              Math.round(weightProgressPct * 10.0) / 10.0);
            analysis.put("weightProgressionBasedOnRealExercises", usedRealExercises);
        }

        Map<String, Object> exerciseProgressions = calculateExerciseProgressions(member, lastSession);
        analysis.put("exerciseProgressions", exerciseProgressions);

        @SuppressWarnings("unchecked")
        List<String> progressionAlerts = (List<String>) exerciseProgressions.get("alerts");
        if (progressionAlerts != null) warnings.addAll(progressionAlerts);

        boolean hasRapidProgression = Boolean.TRUE.equals(exerciseProgressions.get("hasRapidProgression"));
        double maxProgressionPct    = ((Number) exerciseProgressions.getOrDefault("maxProgressionPct", 0.0)).doubleValue();

        if (hasRapidProgression) {
            if (maxProgressionPct > 20) {
                recommendations.add("🔴 Progression très rapide détectée. Réduisez les charges.");
            } else {
                recommendations.add("💡 Progression plus rapide que recommandé. Soyez prudent.");
            }
        }

        Map<String, Object> imbalance = detectMuscleImbalance(member, previousSessions);
        if (Boolean.TRUE.equals(imbalance.get("hasImbalance"))) {
            @SuppressWarnings("unchecked")
            List<String> imbalanceWarnings = (List<String>) imbalance.get("warnings");
            if (imbalanceWarnings != null) warnings.addAll(imbalanceWarnings);
        }

        //recommendations.add("💡 Consultez /api/ai/recovery/" + member.getId()
               // + " pour l'analyse de récupération musculaire détaillée.");

        if ("BEGINNER".equals(fitnessLevel)) {
            recommendations.add("🟢 Débutant : privilégiez la technique à la charge.");
        } else if ("ATHLETE".equals(fitnessLevel)) {
            recommendations.add("🏆 Athlète : votre récupération est plus rapide.");
        }

        List<Map<String, Object>> exerciseSummary = buildExerciseSummary(lastSession);
        if (!exerciseSummary.isEmpty()) {
            analysis.put("exerciseDetails",       exerciseSummary);
            analysis.put("exerciseBasedAnalysis", true);
        } else {
            analysis.put("exerciseBasedAnalysis", false);
            analysis.put("exerciseAnalysisNote",  "Aucun exercice détaillé enregistré");
        }

        double totalVolume = getEffectiveTotalVolume(lastSession);
        analysis.put("totalVolumeSessions", Math.round(totalVolume));

        int sessionCount = previousSessions != null ? previousSessions.size() + 1 : 1;
        int totalMinutes = (previousSessions != null
                ? previousSessions.stream().mapToInt(TrainingSession::getDuration).sum() : 0)
                + (lastSession != null ? lastSession.getDuration() : 0);

        analysis.put("sessionCount",    sessionCount);
        analysis.put("totalMinutes",    totalMinutes);
        analysis.put("riskLevel",       getRiskLevelFromWarnings(warnings));
        analysis.put("warnings",        warnings);
        analysis.put("recommendations", recommendations);
        analysis.put("fitnessLevel",    fitnessLevel);

        return analysis;
    }

    // ════════════════════════════════════════════════════════════════
    // PROGRESSION DES CHARGES PAR EXERCICE
    // ════════════════════════════════════════════════════════════════

    public Map<String, Object> calculateExerciseProgressions(Member member,
                                                             TrainingSession lastSession) {
        Map<String, Object> result = new LinkedHashMap<>();
        List<String> alerts        = new ArrayList<>();
        List<Map<String, Object>> progressions = new ArrayList<>();

        List<SessionExercise> currentExercises = lastSession.getExercises();
        if (currentExercises == null || currentExercises.isEmpty()) {
            result.put("alerts",              alerts);
            result.put("progressions",        progressions);
            result.put("hasRapidProgression", false);
            result.put("maxProgressionPct",   0.0);
            result.put("note",                "Aucun exercice détaillé");
            return result;
        }

        double maxProgressionPct = 0.0;
        LocalDate sessionDate    = lastSession.getDate() != null
                ? lastSession.getDate() : LocalDate.now();

        for (SessionExercise currentEx : currentExercises) {
            if (currentEx.getWeightKg() == null || currentEx.getWeightKg() <= 0) continue;
            if (currentEx.getExerciseName() == null || currentEx.getExerciseName().isBlank()) continue;

            String exerciseName = currentEx.getExerciseName().trim();
            String muscleName   = currentEx.getMuscleName() != null
                    ? currentEx.getMuscleName().toLowerCase().trim() : "";

            List<SessionExercise> history = exerciseRepository
                    .findPreviousOccurrencesByExercise(member.getId(), exerciseName, sessionDate)
                    .stream().limit(4).collect(Collectors.toList());

            if (history.isEmpty()) {
                Map<String, Object> point = new LinkedHashMap<>();
                point.put("exerciseName",  exerciseName);
                point.put("muscleName",    currentEx.getMuscleName());
                point.put("currentWeight", currentEx.getWeightKg());
                point.put("previousAvg",   null);
                point.put("progressionPct", null);
                point.put("status",        "NEW");
                point.put("note",          "Premier enregistrement");
                progressions.add(point);
                continue;
            }

            double avgPreviousWeight = history.stream()
                    .filter(ex -> ex.getWeightKg() != null && ex.getWeightKg() > 0)
                    .mapToDouble(SessionExercise::getWeightKg)
                    .average().orElse(0.0);
            if (avgPreviousWeight <= 0) continue;

            double currentWeight  = currentEx.getWeightKg();
            double progressionPct = ((currentWeight - avgPreviousWeight) / avgPreviousWeight) * 100.0;
            progressionPct = Math.round(progressionPct * 10.0) / 10.0;

            double safeThreshold = SAFE_PROGRESSION_PCT.getOrDefault(muscleName, 10.0);
            Double allTimeMax    = exerciseRepository.findMaxWeightByMemberAndExercise(
                    member.getId(), exerciseName);

            String status;
            if (progressionPct <= 0)                        status = "DOWN";
            else if (progressionPct <= safeThreshold)       status = "OK";
            else if (progressionPct <= safeThreshold * 1.5) status = "WARNING";
            else                                            status = "CRITICAL";

            if ("WARNING".equals(status)) {
                alerts.add(String.format("⚠️ %s : +%.0f%% de charge (seuil : +%.0f%%)",
                        exerciseName, progressionPct, safeThreshold));
            } else if ("CRITICAL".equals(status)) {
                alerts.add(String.format("🔴 %s : +%.0f%% de charge en une séance ! Risque de blessure élevé.",
                        exerciseName, progressionPct));
            }

            Map<String, Object> point = new LinkedHashMap<>();
            point.put("exerciseName",        exerciseName);
            point.put("muscleName",          currentEx.getMuscleName());
            point.put("currentWeight",       currentWeight);
            point.put("previousAvg",         Math.round(avgPreviousWeight * 10.0) / 10.0);
            point.put("progressionPct",      progressionPct);
            point.put("safeThreshold",       safeThreshold);
            point.put("allTimeMax",          allTimeMax != null ? allTimeMax : currentWeight);
            point.put("isNewPersonalRecord", allTimeMax != null && currentWeight > allTimeMax);
            point.put("status",              status);
            point.put("rpe",                 currentEx.getRpe());
            point.put("failureReached",      currentEx.getFailureReached());

            if (progressionPct > maxProgressionPct) maxProgressionPct = progressionPct;
            progressions.add(point);
        }

        progressions.sort((a, b) -> {
            Map<String, Integer> order = Map.of(
                    "CRITICAL", 0, "WARNING", 1, "OK", 2, "DOWN", 3, "NEW", 4);
            int oa = order.getOrDefault(a.getOrDefault("status", "NEW").toString(), 4);
            int ob = order.getOrDefault(b.getOrDefault("status", "NEW").toString(), 4);
            return Integer.compare(oa, ob);
        });

        result.put("alerts",               alerts);
        result.put("progressions",         progressions);
        result.put("hasRapidProgression",  !alerts.isEmpty());
        result.put("maxProgressionPct",    Math.round(maxProgressionPct * 10.0) / 10.0);
        result.put("totalExercisesTracked", progressions.size());

        return result;
    }

    // ════════════════════════════════════════════════════════════════
    // JOURS DE REPOS RECOMMANDÉS
    // ════════════════════════════════════════════════════════════════

    public int getRecommendedRestDays(MemberProfile profile, TrainingSession session) {
        if (profile == null) return 1;

        int restDays = switch (profile.getSelfDeclaredLevel() != null
                ? profile.getSelfDeclaredLevel().name() : "BEGINNER") {
            case "BEGINNER"     -> 2;
            case "INTERMEDIATE" -> 1;
            case "ADVANCED"     -> 1;
            case "ATHLETE"      -> 0;
            default             -> 1;
        };

        List<SessionExercise> exercises = session.getExercises();
        if (exercises != null) {
            boolean hasFailure = exercises.stream()
                    .anyMatch(e -> Boolean.TRUE.equals(e.getFailureReached()));
            boolean hasHighRpe = exercises.stream()
                    .anyMatch(e -> e.getRpe() != null && e.getRpe() >= 9);
            if (hasFailure || hasHighRpe) restDays++;
        }

        if (session.getPainLevel() != null && session.getPainLevel() >= 7) restDays++;
        if (profile.getAvgSleepHours() != null && profile.getAvgSleepHours() < 6.0) restDays++;
        if (profile.getStressLevel()   != null && profile.getStressLevel()   >= 7)   restDays++;

        return Math.min(5, restDays);
    }

    // ════════════════════════════════════════════════════════════════
    // MÉTHODES DE CALCUL INTERNES
    // ════════════════════════════════════════════════════════════════

    private double calculateBMI(Member member) {
        if (member.getHeight() <= 0) return 22.5;
        double heightM = member.getHeight() / 100.0;
        return member.getWeight() / (heightM * heightM);
    }

    private double calculateACLRiskScore(Member member, List<TrainingSession> sessions) {
        double injuryOccurred = sessions.stream()
                .anyMatch(s -> s.getPainLevel() != null && s.getPainLevel() > 6) ? 1.0 : 0.0;
        return Math.min(1.0, (injuryOccurred * 0.5) + (member.getAge() / 100.0));
    }

    private double calculateLoadBalanceScore(List<TrainingSession> sessions) {
        if (sessions.isEmpty()) return 1.0;
        double totalLoad = sessions.stream().mapToDouble(TrainingSession::getTotalVolume).sum();
        double avgLoad   = totalLoad / sessions.size();
        return Math.min(3.0, avgLoad / 500);
    }

    private double calculateAverageIntensity(List<TrainingSession> sessions) {
        return sessions.stream().mapToInt(TrainingSession::getIntensity).average().orElse(5.0);
    }

    private double calculateTrainingHoursPerWeek(List<TrainingSession> sessions) {
        return sessions.stream().mapToInt(TrainingSession::getDuration).sum() / 60.0;
    }

    private double calculateRecoveryDays(List<TrainingSession> sessions) {
        return sessions.stream()
                .mapToInt(s -> s.getRecoveryDaysPerWeek() != null ? s.getRecoveryDaysPerWeek() : 2)
                .average().orElse(2);
    }

    private double calculateFatigueScore(Member member, List<TrainingSession> sessions) {
        Map<String, Object> fatigue = predictFatigueHeuristic(member, sessions);
        return (Double) fatigue.getOrDefault("fatigueScore", 5.0);
    }

    private double getAverageWeightLifted(List<TrainingSession> sessions) {
        return sessions.stream().mapToDouble(this::getEffectiveWeight).average().orElse(50.0);
    }

    private boolean hasCardioInSessions(List<TrainingSession> sessions) {
        return sessions.stream().anyMatch(s -> s.getHasCardio() != null && s.getHasCardio());
    }

    private double getAverageCardioDuration(List<TrainingSession> sessions) {
        return sessions.stream().mapToInt(TrainingSession::getCardioDurationMinutes).average().orElse(0);
    }

    private double getAverageCardioIntensity(List<TrainingSession> sessions) {
        return sessions.stream().mapToInt(TrainingSession::getCardioIntensity).average().orElse(0);
    }

    private double getAverageMuscleRiskScore(List<TrainingSession> sessions) {
        return sessions.stream()
                .mapToDouble(s -> s.getExerciseBasedMuscleRiskScore() != null
                        ? s.getExerciseBasedMuscleRiskScore() : 1.0)
                .average().orElse(1.0);
    }

    private double getFatigueLevelMultiplier(String fitnessLevel) {
        return switch (fitnessLevel) {
            case "BEGINNER"     -> 1.4;
            case "INTERMEDIATE" -> 1.15;
            case "ADVANCED"     -> 1.0;
            case "ATHLETE"      -> 0.85;
            default             -> 1.0;
        };
    }

    private double getInjuryRiskMultiplier(String fitnessLevel) {
        return switch (fitnessLevel) {
            case "BEGINNER"     -> 1.5;
            case "INTERMEDIATE" -> 1.2;
            case "ADVANCED"     -> 1.0;
            case "ATHLETE"      -> 0.9;
            default             -> 1.0;
        };
    }

    private Map<String, Object> detectMuscleImbalance(Member member,
                                                      List<TrainingSession> sessions) {
        Map<String, Object> result  = new LinkedHashMap<>();
        List<String> warnings       = new ArrayList<>();
        Map<String, Double> groupVolume = new HashMap<>();
        double totalVolume = 0.0;

        for (TrainingSession session : sessions) {
            List<SessionExercise> exercises = session.getExercises();
            if (exercises == null) continue;
            for (SessionExercise ex : exercises) {
                String muscle = ex.getMuscleName();
                if (muscle == null || muscle.isBlank()) continue;
                String group  = MUSCLE_TO_GROUP.getOrDefault(muscle.toLowerCase(), "other");
                double volume = ex.getWeightKg() != null
                        ? ex.getWeightKg() * (ex.getSetsCompleted() != null ? ex.getSetsCompleted() : 1) : 0;
                groupVolume.merge(group, volume, Double::sum);
                totalVolume += volume;
            }
        }

        if (totalVolume == 0) {
            result.put("hasImbalance", false);
            result.put("riskScore",    0.0);
            result.put("warnings",     warnings);
            return result;
        }

        double pushVolume = groupVolume.getOrDefault("push", 0.0);
        double pullVolume = groupVolume.getOrDefault("pull", 0.0);
        double riskScore  = 0.0;

        if (pushVolume > 0 && pullVolume > 0) {
            double ratio = pushVolume / pullVolume;
            if (ratio > 1.5) {
                warnings.add("⚠️ Déséquilibre PUSH/PULL : trop de développés vs tractions");
                riskScore += 0.15;
            } else if (pullVolume > pushVolume * 1.5) {
                warnings.add("⚠️ Déséquilibre PULL/PUSH : trop de tractions vs développés");
                riskScore += 0.1;
            }
        }

        double quadVolume = 0.0, hamVolume = 0.0;
        for (TrainingSession session : sessions) {
            List<SessionExercise> exercises = session.getExercises();
            if (exercises == null) continue;
            for (SessionExercise ex : exercises) {
                String muscle = ex.getMuscleName();
                if (muscle == null) continue;
                double volume = ex.getWeightKg() != null
                        ? ex.getWeightKg() * (ex.getSetsCompleted() != null ? ex.getSetsCompleted() : 1) : 0;
                if (muscle.toLowerCase().contains("quadriceps")) quadVolume += volume;
                if (muscle.toLowerCase().contains("ischio"))     hamVolume  += volume;
            }
        }

        if (quadVolume > 0 && hamVolume > 0 && quadVolume / hamVolume > 2.0) {
            warnings.add("⚠️ Déséquilibre Quadriceps/Ischio-jambiers : risque accru pour le genou");
            riskScore += 0.2;
        }

        result.put("hasImbalance", !warnings.isEmpty());
        result.put("riskScore",    Math.min(0.5, riskScore));
        result.put("warnings",     warnings);
        result.put("groupVolumes", groupVolume);
        return result;
    }

    private double getEffectiveWeight(TrainingSession session) {
        if (session == null) return 0;
        List<SessionExercise> exercises = session.getExercises();
        if (exercises != null && !exercises.isEmpty()) {
            return exercises.stream()
                    .filter(ex -> ex.getWeightKg() != null && ex.getWeightKg() > 0)
                    .mapToDouble(SessionExercise::getWeightKg)
                    .average()
                    .orElse(session.getAverageWeight());
        }
        return session.getAverageWeight();
    }

    private Double calculateWeightProgressionPercent(double currentWeight,
                                                     List<TrainingSession> previousSessions) {
        if (previousSessions == null || previousSessions.isEmpty() || currentWeight <= 0) return null;
        double avgPreviousWeight = previousSessions.stream()
                .mapToDouble(this::getEffectiveWeight)
                .filter(w -> w > 0)
                .average().orElse(0.0);
        if (avgPreviousWeight <= 0) return null;
        return ((currentWeight - avgPreviousWeight) / avgPreviousWeight) * 100.0;
    }

    private double getEffectiveTotalVolume(TrainingSession session) {
        if (session == null) return 0;
        List<SessionExercise> exercises = session.getExercises();
        if (exercises != null && !exercises.isEmpty()) {
            return exercises.stream()
                    .filter(ex -> ex.getWeightKg() != null
                            && ex.getWeightKg() > 0
                            && ex.getRepsCompleted() != null)
                    .mapToDouble(ex -> ex.getWeightKg()
                            * parseReps(ex.getRepsCompleted())
                            * (ex.getSetsCompleted() != null ? ex.getSetsCompleted() : 1))
                    .sum();
        }
        return session.getTotalVolume();
    }

    private List<Map<String, Object>> buildExerciseSummary(TrainingSession session) {
        List<Map<String, Object>> summary = new ArrayList<>();
        if (session == null) return summary;
        List<SessionExercise> exercises = session.getExercises();
        if (exercises == null) return summary;

        for (SessionExercise ex : exercises) {
            if (ex.getExerciseName() == null || ex.getExerciseName().isBlank()) continue;
            Map<String, Object> exData = new LinkedHashMap<>();
            exData.put("exerciseName",   ex.getExerciseName());
            exData.put("muscleName",     ex.getMuscleName());
            exData.put("weightKg",       ex.getWeightKg());
            exData.put("reps",           ex.getRepsCompleted());
            exData.put("sets",           ex.getSetsCompleted());
            exData.put("rpe",            ex.getRpe());
            exData.put("failureReached", ex.getFailureReached());

            if (ex.getWeightKg() != null && ex.getRepsCompleted() != null) {
                int reps   = parseReps(ex.getRepsCompleted());
                int sets   = ex.getSetsCompleted() != null ? ex.getSetsCompleted() : 1;
                double vol = ex.getWeightKg() * reps * sets;
                exData.put("volume", Math.round(vol));
                String chargeLevel = ex.getWeightKg() >= 100 ? "TRÈS ÉLEVÉE"
                        : ex.getWeightKg() >= 70 ? "ÉLEVÉE"
                        : ex.getWeightKg() >= 40 ? "MODÉRÉE" : "LÉGÈRE";
                exData.put("chargeLevel", chargeLevel);
            }
            summary.add(exData);
        }
        return summary;
    }

    private int parseReps(String repsCompleted) {
        if (repsCompleted == null || repsCompleted.isBlank()) return 10;
        try {
            return Integer.parseInt(repsCompleted.split("[-,]")[0].trim());
        } catch (NumberFormatException e) {
            return 10;
        }
    }

    private String getRiskLevelFromWarnings(List<String> warnings) {
        long criticalCount = warnings.stream()
                .filter(w -> w.contains("🔴") || w.contains("CRITICAL")).count();
        long warningCount  = warnings.stream()
                .filter(w -> w.contains("⚠️") || w.contains("WARNING")).count();
        if (criticalCount > 0) return "CRITIQUE";
        if (warningCount  > 2) return "ÉLEVÉ";
        if (warningCount  > 0) return "MODÉRÉ";
        return "NORMAL";
    }
}