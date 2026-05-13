package com.example.project_backend.Service;

import com.example.project_backend.Entity.Member;
import com.example.project_backend.Entity.MemberProfile;
import com.example.project_backend.Entity.SessionExercise;
import com.example.project_backend.Entity.TrainingSession;
import com.example.project_backend.Repository.SessionExerciseRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import com.example.project_backend.Repository.MemberProfileRepository;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class AIService {

    private final WebClient webClient;
    private final MemberProfileService memberProfileService;
    private final SessionExerciseRepository exerciseRepository;
    private final MemberProfileRepository memberProfileRepository;

    private static final Map<String, Double> SAFE_PROGRESSION_PCT = new HashMap<>() {{
        put("pectoraux", 10.0);
        put("dorsaux", 10.0);
        put("épaules", 8.0);
        put("biceps", 12.0);
        put("biceps droit", 12.0);
        put("triceps", 12.0);
        put("triceps droit", 12.0);
        put("abdominaux", 15.0);
        put("quadriceps", 8.0);
        put("quadriceps droit", 8.0);
        put("ischio-jambiers", 8.0);
        put("ischio-jambiers droits", 8.0);
        put("mollets", 15.0);
        put("mollets droits", 15.0);
        put("fessiers", 10.0);
        put("lombaires", 7.0);
        put("trapèzes", 12.0);
    }};

    // Mapping muscle → groupe fonctionnel pour détection déséquilibres
    private static final Map<String, String> MUSCLE_TO_GROUP = new HashMap<>() {{
        put("pectoraux", "push");
        put("dorsaux", "pull");
        put("épaules", "push");
        put("biceps", "pull");
        put("biceps droit", "pull");
        put("triceps", "push");
        put("triceps droit", "push");
        put("abdominaux", "core");
        put("quadriceps", "legs");
        put("quadriceps droit", "legs");
        put("ischio-jambiers", "legs");
        put("ischio-jambiers droits", "legs");
        put("fessiers", "legs");
        put("mollets", "legs");
        put("mollets droits", "legs");
        put("lombaires", "core");
        put("trapèzes", "pull");
    }};

    public AIService(@Value("${ai.service.url}") String aiServiceUrl,
                     MemberProfileService memberProfileService,
                     SessionExerciseRepository exerciseRepository,
                     MemberProfileRepository memberProfileRepository) {
        this.webClient = WebClient.builder()
                .baseUrl(aiServiceUrl)
                .build();
        this.memberProfileService = memberProfileService;
        this.exerciseRepository = exerciseRepository;
        this.memberProfileRepository = memberProfileRepository;
    }

    // ═══════════════════════════════════════════════════════════════
    // PRÉDICTION FATIGUE (avec niveau du membre)
    // ═══════════════════════════════════════════════════════════════

    public Map<String, Object> predictFatigue(Member member, List<TrainingSession> sessions) {
        Map<String, Object> result = new LinkedHashMap<>();

        if (sessions == null || sessions.isEmpty()) {
            result.put("fatigueScore", 5.0);
            result.put("label", "normal");
            result.put("confidence", 0.8);
            result.put("message", "Pas assez de données pour analyser la fatigue");
            result.put("exerciseCount", 0);
            result.put("effectiveWeightUsed", 0);
            result.put("muscleRiskSource", "NONE");
            return result;
        }

        // Récupérer le profil du membre (Limite #1)
        MemberProfile profile = memberProfileRepository.findByMemberId(member.getId()).orElse(null);
        String fitnessLevel = profile != null && profile.getSelfDeclaredLevel() != null
                ? profile.getSelfDeclaredLevel().name() : "BEGINNER";

        // Multiplicateur de fatigue selon le niveau (débutant = fatigue plus rapide)
        double levelMultiplier = getFatigueLevelMultiplier(fitnessLevel);

        // Récupérer la dernière séance
        TrainingSession lastSession = sessions.get(0);

        // Calculer les métriques
        int sessionCount = Math.min(sessions.size(), 7);
        double totalIntensity = sessions.stream().mapToInt(TrainingSession::getIntensity).average().orElse(5.0);
        double totalVolume = sessions.stream().mapToDouble(TrainingSession::getTotalVolume).average().orElse(0.0);
        double avgDuration = sessions.stream().mapToInt(TrainingSession::getDuration).average().orElse(0.0);

        // Récupérer le niveau de douleur
        int painLevel = lastSession.getPainLevel() != null ? lastSession.getPainLevel() : 0;

        // Facteurs de récupération (Limite #4)
        double sleepMultiplier = 1.0;
        double stressMultiplier = 1.0;
        if (profile != null) {
            if (profile.getAvgSleepHours() != null && profile.getAvgSleepHours() < 6.0) sleepMultiplier = 1.3;
            else if (profile.getAvgSleepHours() != null && profile.getAvgSleepHours() < 7.0) sleepMultiplier = 1.15;

            if (profile.getStressLevel() != null && profile.getStressLevel() >= 7) stressMultiplier = 1.25;
            else if (profile.getStressLevel() != null && profile.getStressLevel() >= 5) stressMultiplier = 1.1;
        }

        // Calcul du score de fatigue
        double fatigueScore = (sessionCount * 0.25)
                + (totalIntensity * 0.3)
                + (totalVolume / 1000 * 0.2)
                + (avgDuration / 60 * 0.15)
                + (painLevel / 10.0) * 0.1;

        fatigueScore = fatigueScore * levelMultiplier * sleepMultiplier * stressMultiplier;
        fatigueScore = Math.min(10.0, Math.max(1.0, fatigueScore));

        boolean isFatigued = fatigueScore > 6.0;

        // Calculer le poids effectif utilisé
        double effectiveWeight = getEffectiveWeight(lastSession);
        int exerciseCount = lastSession.getExercises() != null ? lastSession.getExercises().size() : 0;

        result.put("fatigueScore", Math.round(fatigueScore * 10.0) / 10.0);
        result.put("label", isFatigued ? "fatigué" : "normal");
        result.put("confidence", Math.min(0.95, 0.6 + (fatigueScore / 20)));
        result.put("sessionsAnalyzed", sessionCount);
        result.put("exerciseCount", exerciseCount);
        result.put("effectiveWeightUsed", effectiveWeight);
        result.put("muscleRiskSource", exerciseCount > 0 ? "EXERCICES_RÉELS" : "GLOBAL");
        result.put("fitnessLevel", fitnessLevel);
        result.put("fatigueMultipliers", Map.of(
                "level", levelMultiplier,
                "sleep", sleepMultiplier,
                "stress", stressMultiplier
        ));

        String recommendation;
        if (isFatigued) {
            recommendation = "Fatigue élevée détectée. Prévoyez 48h de récupération.";
        } else if (fatigueScore > 4) {
            recommendation = "Fatigue modérée. Surveillez votre RPE.";
        } else {
            recommendation = "Bon niveau d'énergie. Vous pouvez augmenter l'intensité.";
        }
        result.put("recommendation", recommendation);

        return result;
    }

    // ═══════════════════════════════════════════════════════════════
    // PRÉDICTION BLESSURE (avec niveau du membre + déséquilibres)
    // ═══════════════════════════════════════════════════════════════

    public Map<String, Object> predictInjury(Member member, List<TrainingSession> sessions) {
        Map<String, Object> result = new LinkedHashMap<>();

        if (sessions == null || sessions.isEmpty()) {
            result.put("injuryRisk", 0.25);
            result.put("label", "risque faible");
            result.put("riskLevel", "FAIBLE");
            result.put("confidence", 0.8);
            result.put("message", "Pas assez de données pour analyser le risque de blessure");
            return result;
        }

        // Récupérer le profil du membre
        MemberProfile profile = memberProfileRepository.findByMemberId(member.getId()).orElse(null);
        String fitnessLevel = profile != null && profile.getSelfDeclaredLevel() != null
                ? profile.getSelfDeclaredLevel().name() : "BEGINNER";

        double levelRiskMultiplier = getInjuryRiskMultiplier(fitnessLevel);

        // Récupérer la prédiction fatigue
        Map<String, Object> fatigue = predictFatigue(member, sessions);
        double fatigueScore = (Double) fatigue.get("fatigueScore");

        // Récupérer les douleurs et antécédents médicaux
        int painOccurrences = (int) sessions.stream()
                .filter(s -> s.getPainLevel() != null && s.getPainLevel() > 3)
                .count();

        boolean hasChronicPain = profile != null && profile.getChronicPainZones() != null
                && !profile.getChronicPainZones().isBlank()
                && !profile.getChronicPainZones().equalsIgnoreCase("NONE");

        boolean hasInjuryHistory = profile != null && profile.getCurrentInjuries() != null
                && !profile.getCurrentInjuries().isBlank();

        // Détecter les progressions trop rapides
        double rapidProgressionRisk = 0.0;
        for (TrainingSession session : sessions) {
            List<SessionExercise> exercises = session.getExercises();
            if (exercises != null) {
                for (SessionExercise ex : exercises) {
                    if (Boolean.TRUE.equals(ex.getFailureReached())) {
                        rapidProgressionRisk += 0.05;
                    }
                    if (ex.getRpe() != null && ex.getRpe() >= 9) {
                        rapidProgressionRisk += 0.03;
                    }
                }
            }
        }
        rapidProgressionRisk = Math.min(0.5, rapidProgressionRisk);

        // Détecter les déséquilibres musculaires (Limite #9)
        Map<String, Object> imbalanceRisk = detectMuscleImbalance(member, sessions);
        double imbalanceScore = (Double) imbalanceRisk.getOrDefault("riskScore", 0.0);

        // Vérifier si un muscle n'est pas assez récupéré (Limite #6)
        Map<String, Object> recoveryRisk = checkMuscleRecovery(member, sessions);
        double recoveryScore = (Double) recoveryRisk.getOrDefault("riskScore", 0.0);

        // Calcul du risque global
        double injuryRisk = (fatigueScore / 10) * 0.25
                + (painOccurrences / Math.max(1, sessions.size())) * 0.15
                + rapidProgressionRisk * 0.2
                + imbalanceScore * 0.2
                + recoveryScore * 0.1;

        if (hasChronicPain) injuryRisk += 0.15;
        if (hasInjuryHistory) injuryRisk += 0.2;

        injuryRisk = injuryRisk * levelRiskMultiplier;
        injuryRisk = Math.min(0.95, Math.max(0.05, injuryRisk));

        String riskLevel;
        String label;
        if (injuryRisk > 0.7) {
            riskLevel = "ÉLEVÉ";
            label = "risque élevé";
        } else if (injuryRisk > 0.4) {
            riskLevel = "MODÉRÉ";
            label = "risque modéré";
        } else {
            riskLevel = "FAIBLE";
            label = "risque faible";
        }

        result.put("injuryRisk", Math.round(injuryRisk * 100.0) / 100.0);
        result.put("label", label);
        result.put("riskLevel", riskLevel);
        result.put("confidence", Math.min(0.9, 0.5 + injuryRisk));
        result.put("muscleImbalance", imbalanceRisk);
        result.put("muscleRecovery", recoveryRisk);

        List<String> warnings = new ArrayList<>();
        if (imbalanceScore > 0.3) {
            warnings.addAll((List<String>) imbalanceRisk.getOrDefault("warnings", List.of()));
        }
        if (recoveryScore > 0.3) {
            warnings.addAll((List<String>) recoveryRisk.getOrDefault("warnings", List.of()));
        }
        if (hasChronicPain) {
            warnings.add("⚠️ Douleur chronique déclarée : " + profile.getChronicPainZones());
        }
        if (hasInjuryHistory) {
            warnings.add("🔴 Antécédent de blessure : " + profile.getCurrentInjuries());
        }
        result.put("warnings", warnings);

        String recommendation;
        if (injuryRisk > 0.7) {
            recommendation = "⚠️ Risque de blessure élevé. Consultez un coach et réduisez l'intensité.";
        } else if (injuryRisk > 0.4) {
            recommendation = "💡 Risque modéré. Surveillez la technique et les temps de repos.";
        } else {
            recommendation = "✅ Risque faible. Continuez votre progression.";
        }
        result.put("recommendation", recommendation);

        return result;
    }

    // ═══════════════════════════════════════════════════════════════
    // ANALYSE DE SURCHARGE (avec repos personnalisé)
    // ═══════════════════════════════════════════════════════════════

    public Map<String, Object> analyzeOverload(Member member, TrainingSession lastSession, List<TrainingSession> previousSessions) {
        Map<String, Object> analysis = new LinkedHashMap<>();
        List<String> warnings = new ArrayList<>();
        List<String> recommendations = new ArrayList<>();

        // Récupérer le profil pour les recommandations personnalisées
        MemberProfile profile = memberProfileRepository.findByMemberId(member.getId()).orElse(null);
        String fitnessLevel = profile != null && profile.getSelfDeclaredLevel() != null
                ? profile.getSelfDeclaredLevel().name() : "BEGINNER";

        double effectiveWeight = getEffectiveWeight(lastSession);
        Double weightProgressPct = calculateWeightProgressionPercent(effectiveWeight, previousSessions);
        boolean usedRealExercises = lastSession.getExercises() != null && !lastSession.getExercises().isEmpty();

        if (weightProgressPct != null) {
            analysis.put("weightProgressionPercent", Math.round(weightProgressPct * 10.0) / 10.0);
            analysis.put("weightProgressionBasedOnRealExercises", usedRealExercises);
        }

        // Progression par exercice
        Map<String, Object> exerciseProgressions = calculateExerciseProgressions(member, lastSession);
        analysis.put("exerciseProgressions", exerciseProgressions);

        @SuppressWarnings("unchecked")
        List<String> progressionAlerts = (List<String>) exerciseProgressions.get("alerts");
        if (progressionAlerts != null) {
            warnings.addAll(progressionAlerts);
        }

        boolean hasRapidProgression = Boolean.TRUE.equals(exerciseProgressions.get("hasRapidProgression"));
        double maxProgressionPct = ((Number) exerciseProgressions.getOrDefault("maxProgressionPct", 0.0)).doubleValue();

        if (hasRapidProgression) {
            if (maxProgressionPct > 20) {
                recommendations.add("🔴 Progression très rapide détectée. Réduisez les charges " +
                        "et concentrez-vous sur la technique avant d'augmenter le poids.");
            } else {
                recommendations.add("💡 Progression plus rapide que recommandé sur certains exercices. " +
                        "Vérifiez votre technique et votre récupération.");
            }
        }

        // Détection des muscles non récupérés (Limite #6)
        Map<String, Object> muscleRecovery = checkMuscleRecovery(member, List.of(lastSession));
        if (Boolean.TRUE.equals(muscleRecovery.get("hasUnrecoveredMuscles"))) {
            @SuppressWarnings("unchecked")
            List<String> recoveryWarnings = (List<String>) muscleRecovery.get("warnings");
            if (recoveryWarnings != null) {
                warnings.addAll(recoveryWarnings);
            }
        }

        // Détection des déséquilibres musculaires (Limite #9)
        Map<String, Object> imbalance = detectMuscleImbalance(member, previousSessions);
        if (Boolean.TRUE.equals(imbalance.get("hasImbalance"))) {
            @SuppressWarnings("unchecked")
            List<String> imbalanceWarnings = (List<String>) imbalance.get("warnings");
            if (imbalanceWarnings != null) {
                warnings.addAll(imbalanceWarnings);
            }
        }

        // Recommandation de repos personnalisée (Limite #2)
        int recommendedRestDays = getRecommendedRestDays(profile, lastSession);
        if (recommendedRestDays > 0) {
            recommendations.add("💤 Repos recommandé : " + recommendedRestDays + " jour(s) avant la prochaine séance intense.");
        }

        // Recommandations basées sur le niveau (Limite #1)
        if ("BEGINNER".equals(fitnessLevel)) {
            recommendations.add("🟢 Débutant : privilégiez la technique à la charge. Augmentez progressivement sur 4-6 semaines.");
        } else if ("ATHLETE".equals(fitnessLevel)) {
            recommendations.add("🏆 Athlète : votre récupération est plus rapide. Vous pouvez espacer les séances de 24-48h.");
        }

        List<Map<String, Object>> exerciseSummary = buildExerciseSummary(lastSession);
        if (!exerciseSummary.isEmpty()) {
            analysis.put("exerciseDetails", exerciseSummary);
            analysis.put("exerciseBasedAnalysis", true);

            exerciseSummary.stream()
                    .filter(e -> "TRÈS ÉLEVÉE".equals(e.get("chargeLevel")))
                    .forEach(e -> warnings.add("⚠️ Charge très élevée sur " + e.get("exerciseName") +
                            " (" + e.get("weightKg") + "kg) — technique irréprochable exigée"));

            exerciseSummary.stream()
                    .filter(e -> Boolean.TRUE.equals(e.get("failureReached")))
                    .forEach(e -> warnings.add("⚠️ Échec musculaire atteint sur " + e.get("exerciseName") +
                            " — récupération accrue nécessaire"));
        } else {
            analysis.put("exerciseBasedAnalysis", false);
            analysis.put("exerciseAnalysisNote",
                    "Aucun exercice détaillé enregistré — saisissez vos exercices pour une analyse plus précise");
        }

        double totalVolume = getEffectiveTotalVolume(lastSession);
        analysis.put("totalVolumeSessions", Math.round(totalVolume));
        analysis.put("sessionCount", previousSessions.size() + 1);
        analysis.put("totalMinutes", previousSessions.stream().mapToInt(TrainingSession::getDuration).sum() + lastSession.getDuration());
        analysis.put("riskLevel", getRiskLevelFromWarnings(warnings));

        analysis.put("warnings", warnings);
        analysis.put("recommendations", recommendations);
        analysis.put("fitnessLevel", fitnessLevel);
        analysis.put("recommendedRestDays", recommendedRestDays);

        return analysis;
    }

    // ═══════════════════════════════════════════════════════════════
    // PROGRESSION DES CHARGES PAR EXERCICE
    // ═══════════════════════════════════════════════════════════════

    public Map<String, Object> calculateExerciseProgressions(Member member, TrainingSession lastSession) {
        Map<String, Object> result = new LinkedHashMap<>();
        List<String> alerts = new ArrayList<>();
        List<Map<String, Object>> progressions = new ArrayList<>();

        List<SessionExercise> currentExercises = lastSession.getExercises();
        if (currentExercises == null || currentExercises.isEmpty()) {
            result.put("alerts", alerts);
            result.put("progressions", progressions);
            result.put("hasRapidProgression", false);
            result.put("maxProgressionPct", 0.0);
            result.put("note", "Aucun exercice détaillé — saisissez vos exercices pour activer le suivi de progression");
            return result;
        }

        double maxProgressionPct = 0.0;
        LocalDate sessionDate = lastSession.getDate() != null ? lastSession.getDate() : LocalDate.now();

        for (SessionExercise currentEx : currentExercises) {
            if (currentEx.getWeightKg() == null || currentEx.getWeightKg() <= 0) continue;
            if (currentEx.getExerciseName() == null || currentEx.getExerciseName().isBlank()) continue;

            String exerciseName = currentEx.getExerciseName().trim();
            String muscleName = currentEx.getMuscleName() != null
                    ? currentEx.getMuscleName().toLowerCase().trim()
                    : "";

            List<SessionExercise> history = exerciseRepository
                    .findPreviousOccurrencesByExercise(
                            member.getId(),
                            exerciseName,
                            sessionDate)
                    .stream()
                    .limit(4)
                    .collect(Collectors.toList());

            if (history.isEmpty()) {
                Map<String, Object> point = new LinkedHashMap<>();
                point.put("exerciseName", exerciseName);
                point.put("muscleName", currentEx.getMuscleName());
                point.put("currentWeight", currentEx.getWeightKg());
                point.put("previousAvg", null);
                point.put("progressionPct", null);
                point.put("status", "NEW");
                point.put("note", "Premier enregistrement de cet exercice");
                progressions.add(point);
                continue;
            }

            double avgPreviousWeight = history.stream()
                    .filter(ex -> ex.getWeightKg() != null && ex.getWeightKg() > 0)
                    .mapToDouble(SessionExercise::getWeightKg)
                    .average()
                    .orElse(0.0);

            if (avgPreviousWeight <= 0) continue;

            double currentWeight = currentEx.getWeightKg();
            double progressionPct = ((currentWeight - avgPreviousWeight) / avgPreviousWeight) * 100.0;
            progressionPct = Math.round(progressionPct * 10.0) / 10.0;

            double safeThreshold = SAFE_PROGRESSION_PCT.getOrDefault(muscleName, 10.0);

            Double allTimeMax = exerciseRepository
                    .findMaxWeightByMemberAndExercise(member.getId(), exerciseName);

            String status;
            if (progressionPct <= 0) {
                status = "DOWN";
            } else if (progressionPct <= safeThreshold) {
                status = "OK";
            } else if (progressionPct <= safeThreshold * 1.5) {
                status = "WARNING";
            } else {
                status = "CRITICAL";
            }

            if ("WARNING".equals(status)) {
                alerts.add(String.format(
                        "⚠️ %s : +%.0f%% de charge (seuil recommandé : +%.0f%%) — progression rapide pour %s",
                        exerciseName, progressionPct, safeThreshold,
                        currentEx.getMuscleName() != null ? currentEx.getMuscleName() : "ce muscle"));
            } else if ("CRITICAL".equals(status)) {
                alerts.add(String.format(
                        "🔴 %s : +%.0f%% de charge en une séance ! Risque de blessure élevé. " +
                                "Seuil sûr pour %s : +%.0f%%",
                        exerciseName, progressionPct,
                        currentEx.getMuscleName() != null ? currentEx.getMuscleName() : "ce muscle",
                        safeThreshold));
            }

            Map<String, Object> point = new LinkedHashMap<>();
            point.put("exerciseName", exerciseName);
            point.put("muscleName", currentEx.getMuscleName());
            point.put("currentWeight", currentWeight);
            point.put("previousAvg", Math.round(avgPreviousWeight * 10.0) / 10.0);
            point.put("previousSessions", history.size());
            point.put("progressionPct", progressionPct);
            point.put("safeThreshold", safeThreshold);
            point.put("allTimeMax", allTimeMax != null ? allTimeMax : currentWeight);
            point.put("isNewPersonalRecord", allTimeMax != null && currentWeight > allTimeMax);
            point.put("status", status);
            point.put("rpe", currentEx.getRpe());
            point.put("failureReached", currentEx.getFailureReached());

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

        result.put("alerts", alerts);
        result.put("progressions", progressions);
        result.put("hasRapidProgression", !alerts.isEmpty());
        result.put("maxProgressionPct", Math.round(maxProgressionPct * 10.0) / 10.0);
        result.put("totalExercisesTracked", progressions.size());

        return result;
    }

    // ═══════════════════════════════════════════════════════════════
    // MÉTHODES PRIVÉES (Limites #1, #2, #6, #9)
    // ═══════════════════════════════════════════════════════════════

    private double getFatigueLevelMultiplier(String fitnessLevel) {
        return switch (fitnessLevel) {
            case "BEGINNER" -> 1.4;
            case "INTERMEDIATE" -> 1.15;
            case "ADVANCED" -> 1.0;
            case "ATHLETE" -> 0.85;
            default -> 1.0;
        };
    }

    private double getInjuryRiskMultiplier(String fitnessLevel) {
        return switch (fitnessLevel) {
            case "BEGINNER" -> 1.5;
            case "INTERMEDIATE" -> 1.2;
            case "ADVANCED" -> 1.0;
            case "ATHLETE" -> 0.9;
            default -> 1.0;
        };
    }

    private int getRecommendedRestDays(MemberProfile profile, TrainingSession session) {
        if (profile == null) return 1;

        int restDays = 0;
        String level = profile.getSelfDeclaredLevel() != null
                ? profile.getSelfDeclaredLevel().name() : "BEGINNER";

        // Base selon niveau (Limite #2)
        switch (level) {
            case "BEGINNER" -> restDays = 2;
            case "INTERMEDIATE" -> restDays = 1;
            case "ADVANCED" -> restDays = 1;
            case "ATHLETE" -> restDays = 0;
            default -> restDays = 1;
        }

        // Ajustements selon la séance
        List<SessionExercise> exercises = session.getExercises();
        if (exercises != null) {
            boolean hasFailure = exercises.stream().anyMatch(e -> Boolean.TRUE.equals(e.getFailureReached()));
            boolean hasHighRpe = exercises.stream().anyMatch(e -> e.getRpe() != null && e.getRpe() >= 9);

            if (hasFailure || hasHighRpe) restDays++;
        }

        // Ajustements selon douleur
        if (session.getPainLevel() != null && session.getPainLevel() >= 7) {
            restDays++;
        }

        // Ajustements selon sommeil/stress
        if (profile.getAvgSleepHours() != null && profile.getAvgSleepHours() < 6.0) restDays++;
        if (profile.getStressLevel() != null && profile.getStressLevel() >= 7) restDays++;

        return Math.min(5, restDays);
    }

    private Map<String, Object> checkMuscleRecovery(Member member, List<TrainingSession> sessions) {
        Map<String, Object> result = new LinkedHashMap<>();
        List<String> warnings = new ArrayList<>();
        Set<String> unrecoveredMuscles = new HashSet<>();
        double riskScore = 0.0;

        LocalDate today = LocalDate.now();

        for (TrainingSession session : sessions) {
            List<SessionExercise> exercises = session.getExercises();
            if (exercises == null) continue;

            LocalDate sessionDate = session.getDate() != null ? session.getDate() : today;
            long daysSince = ChronoUnit.DAYS.between(sessionDate, today);

            for (SessionExercise ex : exercises) {
                String muscleName = ex.getMuscleName();
                if (muscleName == null || muscleName.isBlank()) continue;

                int recoveryNeeded = getRecoveryHoursForMuscle(muscleName);
                int recoveryDays = recoveryNeeded / 24;

                if (daysSince < recoveryDays) {
                    unrecoveredMuscles.add(muscleName);
                    riskScore += 0.1;
                }
            }
        }

        if (!unrecoveredMuscles.isEmpty()) {
            warnings.add("⚠️ Muscle(s) potentiellement non récupéré(s) : " + String.join(", ", unrecoveredMuscles));
            result.put("hasUnrecoveredMuscles", true);
            result.put("unrecoveredMuscles", unrecoveredMuscles);
        } else {
            result.put("hasUnrecoveredMuscles", false);
        }

        result.put("riskScore", Math.min(0.5, riskScore));
        result.put("warnings", warnings);

        return result;
    }

    private int getRecoveryHoursForMuscle(String muscleName) {
        return switch (muscleName.toLowerCase().trim()) {
            case "pectoraux", "dorsaux", "fessiers" -> 48;
            case "quadriceps", "quadriceps droit", "ischio-jambiers", "ischio-jambiers droits" -> 72;
            case "abdominaux", "mollets", "mollets droits" -> 24;
            case "biceps", "biceps droit", "triceps", "triceps droit" -> 48;
            case "épaules", "trapèzes" -> 48;
            case "lombaires" -> 72;
            default -> 48;
        };
    }

    private Map<String, Object> detectMuscleImbalance(Member member, List<TrainingSession> sessions) {
        Map<String, Object> result = new LinkedHashMap<>();
        List<String> warnings = new ArrayList<>();
        Map<String, Double> groupVolume = new HashMap<>();
        double totalVolume = 0.0;

        for (TrainingSession session : sessions) {
            List<SessionExercise> exercises = session.getExercises();
            if (exercises == null) continue;

            for (SessionExercise ex : exercises) {
                String muscle = ex.getMuscleName();
                if (muscle == null || muscle.isBlank()) continue;

                String group = MUSCLE_TO_GROUP.getOrDefault(muscle.toLowerCase(), "other");
                double volume = ex.getWeightKg() != null ? ex.getWeightKg() * (ex.getSetsCompleted() != null ? ex.getSetsCompleted() : 1) : 0;

                groupVolume.merge(group, volume, Double::sum);
                totalVolume += volume;
            }
        }

        if (totalVolume == 0) {
            result.put("hasImbalance", false);
            result.put("riskScore", 0.0);
            result.put("warnings", warnings);
            return result;
        }

        double pushVolume = groupVolume.getOrDefault("push", 0.0);
        double pullVolume = groupVolume.getOrDefault("pull", 0.0);
        double legsVolume = groupVolume.getOrDefault("legs", 0.0);

        double riskScore = 0.0;

        // Déséquilibre PUSH/PULL (recommandé: ratio 1:1 à 1.2:1)
        if (pushVolume > 0 && pullVolume > 0) {
            double ratio = pushVolume / pullVolume;
            if (ratio > 1.5) {
                warnings.add("⚠️ Déséquilibre PUSH/PULL : trop de développés (" +
                        String.format("%.0f", pushVolume) + "kg) vs tractions (" +
                        String.format("%.0f", pullVolume) + "kg)");
                riskScore += 0.15;
            } else if (pullVolume > pushVolume * 1.5) {
                warnings.add("⚠️ Déséquilibre PULL/PUSH : trop de tractions (" +
                        String.format("%.0f", pullVolume) + "kg) vs développés (" +
                        String.format("%.0f", pushVolume) + "kg)");
                riskScore += 0.1;
            }
        }

        // Déséquilibre Quadriceps / Ischio-jambiers
        double quadVolume = 0.0;
        double hamVolume = 0.0;

        for (TrainingSession session : sessions) {
            List<SessionExercise> exercises = session.getExercises();
            if (exercises != null) {
                for (SessionExercise ex : exercises) {
                    String muscle = ex.getMuscleName();
                    if (muscle == null) continue;
                    double volume = ex.getWeightKg() != null ? ex.getWeightKg() * (ex.getSetsCompleted() != null ? ex.getSetsCompleted() : 1) : 0;

                    if (muscle.toLowerCase().contains("quadriceps")) quadVolume += volume;
                    if (muscle.toLowerCase().contains("ischio")) hamVolume += volume;
                }
            }
        }

        if (quadVolume > 0 && hamVolume > 0) {
            double ratio = quadVolume / hamVolume;
            if (ratio > 2.0) {
                warnings.add("⚠️ Déséquilibre Quadriceps/Ischio-jambiers : ratio " +
                        String.format("%.1f", ratio) + ":1 — risque accru pour le genou");
                riskScore += 0.2;
            }
        }

        result.put("hasImbalance", !warnings.isEmpty());
        result.put("riskScore", Math.min(0.5, riskScore));
        result.put("warnings", warnings);
        result.put("groupVolumes", groupVolume);

        return result;
    }

    private double getEffectiveWeight(TrainingSession session) {
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

    private Double calculateWeightProgressionPercent(double currentWeight, List<TrainingSession> previousSessions) {
        if (previousSessions == null || previousSessions.isEmpty() || currentWeight <= 0) return null;

        double avgPreviousWeight = previousSessions.stream()
                .mapToDouble(this::getEffectiveWeight)
                .filter(w -> w > 0)
                .average()
                .orElse(0.0);

        if (avgPreviousWeight <= 0) return null;

        return ((currentWeight - avgPreviousWeight) / avgPreviousWeight) * 100.0;
    }

    private double getEffectiveTotalVolume(TrainingSession session) {
        List<SessionExercise> exercises = session.getExercises();
        if (exercises != null && !exercises.isEmpty()) {
            return exercises.stream()
                    .filter(ex -> ex.getWeightKg() != null && ex.getWeightKg() > 0 && ex.getRepsCompleted() != null)
                    .mapToDouble(ex -> ex.getWeightKg() * parseReps(ex.getRepsCompleted()) * (ex.getSetsCompleted() != null ? ex.getSetsCompleted() : 1))
                    .sum();
        }
        return session.getTotalVolume();
    }

    private List<Map<String, Object>> buildExerciseSummary(TrainingSession session) {
        List<Map<String, Object>> summary = new ArrayList<>();
        List<SessionExercise> exercises = session.getExercises();

        if (exercises == null) return summary;

        for (SessionExercise ex : exercises) {
            if (ex.getExerciseName() == null || ex.getExerciseName().isBlank()) continue;

            Map<String, Object> exData = new LinkedHashMap<>();
            exData.put("exerciseName", ex.getExerciseName());
            exData.put("muscleName", ex.getMuscleName());
            exData.put("weightKg", ex.getWeightKg());
            exData.put("reps", ex.getRepsCompleted());
            exData.put("sets", ex.getSetsCompleted());
            exData.put("rpe", ex.getRpe());
            exData.put("failureReached", ex.getFailureReached());

            if (ex.getWeightKg() != null && ex.getRepsCompleted() != null) {
                int reps = parseReps(ex.getRepsCompleted());
                int sets = ex.getSetsCompleted() != null ? ex.getSetsCompleted() : 1;
                double volume = ex.getWeightKg() * reps * sets;
                exData.put("volume", Math.round(volume));

                String chargeLevel;
                if (ex.getWeightKg() >= 100) chargeLevel = "TRÈS ÉLEVÉE";
                else if (ex.getWeightKg() >= 70) chargeLevel = "ÉLEVÉE";
                else if (ex.getWeightKg() >= 40) chargeLevel = "MODÉRÉE";
                else chargeLevel = "LÉGÈRE";
                exData.put("chargeLevel", chargeLevel);
            }

            summary.add(exData);
        }

        return summary;
    }

    private int parseReps(String repsCompleted) {
        if (repsCompleted == null || repsCompleted.isBlank()) return 10;
        try {
            if (repsCompleted.contains("-")) {
                return Integer.parseInt(repsCompleted.split("-")[1]);
            }
            return Integer.parseInt(repsCompleted);
        } catch (NumberFormatException e) {
            return 10;
        }
    }

    private String getRiskLevelFromWarnings(List<String> warnings) {
        long criticalCount = warnings.stream().filter(w -> w.contains("🔴") || w.contains("CRITICAL")).count();
        long warningCount = warnings.stream().filter(w -> w.contains("⚠️") || w.contains("WARNING")).count();

        if (criticalCount > 0) return "CRITIQUE";
        if (warningCount > 2) return "ÉLEVÉ";
        if (warningCount > 0) return "MODÉRÉ";
        return "NORMAL";
    }
}