package com.example.project_backend.Service;

import com.example.project_backend.Entity.Member;
import com.example.project_backend.Entity.SessionExercise;
import com.example.project_backend.Entity.TrainingSession;
import com.example.project_backend.Repository.SessionExerciseRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class AIService {

    private final WebClient webClient;
    private final MemberProfileService memberProfileService;
    private final SessionExerciseRepository exerciseRepository;

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

    public AIService(@Value("${ai.service.url}") String aiServiceUrl,
                     MemberProfileService memberProfileService,
                     SessionExerciseRepository exerciseRepository) {
        this.webClient = WebClient.builder()
                .baseUrl(aiServiceUrl)
                .build();
        this.memberProfileService = memberProfileService;
        this.exerciseRepository = exerciseRepository;
    }

    public Map<String, Object> analyzeOverload(Member member, TrainingSession lastSession, List<TrainingSession> previousSessions) {
        Map<String, Object> analysis = new LinkedHashMap<>();
        List<String> warnings = new ArrayList<>();
        List<String> recommendations = new ArrayList<>();

        double effectiveWeight = getEffectiveWeight(lastSession);
        Double weightProgressPct = calculateWeightProgressionPercent(effectiveWeight, previousSessions);
        boolean usedRealExercises = lastSession.getExercises() != null && !lastSession.getExercises().isEmpty();

        if (weightProgressPct != null) {
            analysis.put("weightProgressionPercent", Math.round(weightProgressPct * 10.0) / 10.0);
            analysis.put("weightProgressionBasedOnRealExercises", usedRealExercises);
        }

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

        analysis.put("warnings", warnings);
        analysis.put("recommendations", recommendations);

        return analysis;
    }

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
}