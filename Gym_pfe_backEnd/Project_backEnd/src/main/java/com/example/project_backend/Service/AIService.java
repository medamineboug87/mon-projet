package com.example.project_backend.Service;

import com.example.project_backend.Entity.Member;
import com.example.project_backend.Entity.MemberProfile;
import com.example.project_backend.Entity.TrainingSession;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.Duration;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class AIService {

    private final WebClient webClient;
    private final MemberProfileService memberProfileService; // ← NIVEAU 3

    private static final Duration AI_TIMEOUT = Duration.ofSeconds(10);

    // ── Risque par muscle (1=faible, 2=moyen, 3=élevé) ──
    private static final Map<String, Double> MUSCLE_RISK_MAP = new HashMap<>() {{
        put("pectoraux",              2.0);
        put("dorsaux",               2.0);
        put("épaules",               3.0);
        put("biceps",                1.0);
        put("biceps droit",          1.0);
        put("biceps d.",             1.0);
        put("triceps",               1.0);
        put("triceps droit",         1.0);
        put("triceps d.",            1.0);
        put("abdominaux",            1.0);
        put("quadriceps",            3.0);
        put("quadriceps droit",      3.0);
        put("quadriceps d.",         3.0);
        put("ischio-jambiers",       3.0);
        put("ischio-jambiers droits",3.0);
        put("ischio d.",             3.0);
        put("mollets",               2.0);
        put("mollets droits",        2.0);
        put("mollets d.",            2.0);
        put("fessiers",              2.0);
        put("lombaires",             3.0);
        put("trapèzes",              2.0);
    }};

    // ── Récupération minimale recommandée par muscle (en heures) ──
    private static final Map<String, Integer> MUSCLE_RECOVERY_HOURS = new HashMap<>() {{
        put("pectoraux",              48);
        put("dorsaux",               48);
        put("épaules",               24);
        put("biceps",                24);
        put("biceps droit",          24);
        put("triceps",               24);
        put("triceps droit",         24);
        put("abdominaux",            24);
        put("quadriceps",            72);
        put("quadriceps droit",      72);
        put("ischio-jambiers",       72);
        put("ischio-jambiers droits",72);
        put("mollets",               24);
        put("mollets droits",        24);
        put("fessiers",              48);
        put("lombaires",             48);
        put("trapèzes",              24);
    }};

    // ── Muscles antagonistes ──
    private static final List<String[]> ANTAGONIST_PAIRS = List.of(
            new String[]{"pectoraux",   "dorsaux"},
            new String[]{"biceps",      "triceps"},
            new String[]{"quadriceps",  "ischio-jambiers"},
            new String[]{"épaules",     "trapèzes"}
    );

    // ── Constructeur — injection de MemberProfileService ──
    public AIService(@Value("${ai.service.url}") String aiServiceUrl,
                     MemberProfileService memberProfileService) {
        this.webClient = WebClient.builder()
                .baseUrl(aiServiceUrl)
                .build();
        this.memberProfileService = memberProfileService;
    }

    // ═══════════════════════════════════════════════════════════════════
    // CALCUL DU MUSCLE RISK SCORE
    // ═══════════════════════════════════════════════════════════════════

    private double calculateMuscleRiskScore(String targetMuscles) {
        if (targetMuscles == null || targetMuscles.isBlank()) return 1.5;
        String[] muscles = targetMuscles.toLowerCase().split(",");
        double totalRisk = 0.0;
        int count = 0;
        for (String muscle : muscles) {
            Double risk = MUSCLE_RISK_MAP.get(muscle.trim());
            if (risk != null) { totalRisk += risk; count++; }
        }
        if (count == 0) return 1.5;
        return Math.min(3.0, Math.max(1.0, Math.round((totalRisk / count) * 10.0) / 10.0));
    }

    // ═══════════════════════════════════════════════════════════════════
    // PROBLÈME #1 : Niveau d'expérience
    // ═══════════════════════════════════════════════════════════════════

    private double getExperienceRiskMultiplier(int totalSessionCount) {
        if (totalSessionCount < 10)  return 1.5;
        if (totalSessionCount < 20)  return 1.3;
        if (totalSessionCount < 60)  return 1.0;
        if (totalSessionCount < 120) return 0.85;
        return 0.7;
    }

    private double getExperienceRecoveryMultiplier(int totalSessionCount) {
        if (totalSessionCount < 10)  return 2.0;
        if (totalSessionCount < 20)  return 1.6;
        if (totalSessionCount < 60)  return 1.2;
        if (totalSessionCount < 120) return 1.0;
        return 0.85;
    }

    // ═══════════════════════════════════════════════════════════════════
    // NIVEAU 2 — HELPERS painLevel / warmupDone
    // ═══════════════════════════════════════════════════════════════════

    /**
     * Calcule le multiplicateur d'intensité lié à la douleur ressentie.
     * painLevel null ou 0 → multiplicateur 1.0 (aucun effet).
     * painLevel 4-6 → +10%  (douleur modérée).
     * painLevel ≥ 7 → +20%  (douleur intense).
     */
    private double getPainIntensityMultiplier(Integer painLevel) {
        if (painLevel == null || painLevel == 0) return 1.0;
        if (painLevel >= 7) return 1.20;
        if (painLevel >= 4) return 1.10;
        return 1.0;
    }

    /**
     * Calcule le multiplicateur de risque musculaire lié à la douleur.
     * painLevel null ou 0 → 1.0.
     * painLevel 4-6 → ×1.15.
     * painLevel ≥ 7 → ×1.30.
     */
    private double getPainRiskMultiplier(Integer painLevel) {
        if (painLevel == null || painLevel == 0) return 1.0;
        if (painLevel >= 7) return 1.30;
        if (painLevel >= 4) return 1.15;
        return 1.0;
    }

    /**
     * Multiplicateur d'intensité lié à l'absence d'échauffement.
     * warmupDone false → +15% sur l'intensité perçue.
     */
    private double getWarmupIntensityMultiplier(Boolean warmupDone) {
        return (warmupDone != null && !warmupDone) ? 1.15 : 1.0;
    }

    private double getWarmupRiskMultiplier(Boolean warmupDone) {
        return (warmupDone != null && !warmupDone) ? 1.25 : 1.0;
    }

    // ═══════════════════════════════════════════════════════════════════
    // PROBLÈME #6 : Heures depuis la dernière séance par muscle
    // ═══════════════════════════════════════════════════════════════════

    private Map<String, Long> getHoursSinceLastWorkPerMuscle(
            List<String> musclesCurrentSession,
            List<TrainingSession> allPreviousSessions) {

        Map<String, Long> result = new LinkedHashMap<>();
        LocalDate today = LocalDate.now();

        for (String muscle : musclesCurrentSession) {
            String muscleLower = muscle.trim().toLowerCase();
            OptionalLong hours = allPreviousSessions.stream()
                    .filter(s -> s.getTargetMuscles() != null
                            && Arrays.stream(s.getTargetMuscles().toLowerCase().split(","))
                            .map(String::trim)
                            .anyMatch(m -> m.equals(muscleLower)))
                    .mapToLong(s -> ChronoUnit.HOURS.between(
                            s.getDate().atStartOfDay(),
                            today.atStartOfDay()))
                    .min();

            result.put(muscleLower, hours.isPresent() ? hours.getAsLong() : null);
        }
        return result;
    }

    // ═══════════════════════════════════════════════════════════════════
    // PROBLÈME #8 : Progression trop rapide des charges
    // ═══════════════════════════════════════════════════════════════════

    private Double calculateWeightProgressionPercent(
            double currentWeight, List<TrainingSession> previousSessions) {

        if (previousSessions.size() < 2) return null;

        double avgPrevious = previousSessions.stream()
                .limit(4)
                .mapToDouble(TrainingSession::getWeightLifted)
                .average()
                .orElse(0.0);

        if (avgPrevious <= 0) return null;
        return ((currentWeight - avgPrevious) / avgPrevious) * 100.0;
    }

    // ═══════════════════════════════════════════════════════════════════
    // PROBLÈME #9 : Déséquilibre musculaire
    // ═══════════════════════════════════════════════════════════════════

    private List<String> detectMuscleImbalances(List<TrainingSession> allSessions) {
        List<String> imbalances = new ArrayList<>();
        LocalDate thirtyDaysAgo = LocalDate.now().minusDays(30);

        Map<String, Long> muscleCounts = new HashMap<>();
        allSessions.stream()
                .filter(s -> s.getDate() != null && !s.getDate().isBefore(thirtyDaysAgo))
                .filter(s -> s.getTargetMuscles() != null)
                .forEach(s -> {
                    for (String m : s.getTargetMuscles().toLowerCase().split(",")) {
                        String muscle = m.trim();
                        muscleCounts.merge(muscle, 1L, Long::sum);
                    }
                });

        for (String[] pair : ANTAGONIST_PAIRS) {
            String m1 = pair[0];
            String m2 = pair[1];
            long count1 = muscleCounts.getOrDefault(m1, 0L);
            long count2 = muscleCounts.getOrDefault(m2, 0L);

            if (count1 > 0 && count2 == 0 && count1 >= 3) {
                imbalances.add("Aucun travail de " + m2 + " alors que " + m1 + " travaillé " + count1 + "× ce mois");
            } else if (count2 > 0 && count1 == 0 && count2 >= 3) {
                imbalances.add("Aucun travail de " + m1 + " alors que " + m2 + " travaillé " + count2 + "× ce mois");
            } else if (count1 > 0 && count2 > 0) {
                double ratio = (double) Math.max(count1, count2) / Math.min(count1, count2);
                if (ratio >= 3.0) {
                    String dominant  = count1 > count2 ? m1 : m2;
                    String neglected = count1 > count2 ? m2 : m1;
                    imbalances.add("Déséquilibre : " + dominant + " travaillé "
                            + (int) ratio + "× plus que " + neglected + " ce mois");
                }
            }
        }
        return imbalances;
    }

    // ═══════════════════════════════════════════════════════════════════
    // PROBLÈME #2 + #6 : Muscles non récupérés
    // ═══════════════════════════════════════════════════════════════════

    private List<String> getUnrecoveredMuscles(
            List<String> targetMuscles,
            Map<String, Long> hoursSinceLastWork,
            int totalSessionCount) {

        double recovMultiplier = getExperienceRecoveryMultiplier(totalSessionCount);
        List<String> unrecovered = new ArrayList<>();

        for (String muscle : targetMuscles) {
            String key = muscle.trim().toLowerCase();
            Long hours = hoursSinceLastWork.get(key);
            if (hours == null) continue;

            Integer baseRecovery = MUSCLE_RECOVERY_HOURS.getOrDefault(key, 48);
            double requiredRecovery = baseRecovery * recovMultiplier;

            if (hours < requiredRecovery) {
                long remaining = (long) (requiredRecovery - hours);
                unrecovered.add(muscle.trim() + " (encore " + remaining + "h de récupération recommandées)");
            }
        }
        return unrecovered;
    }

    // ═══════════════════════════════════════════════════════════════════
    // ANALYSE DE SURCHARGE — Niveau 1 + Niveau 2
    // ═══════════════════════════════════════════════════════════════════

    public Map<String, Object> analyzeOverload(Member member, List<TrainingSession> sessions) {

        Map<String, Object> analysis = new HashMap<>();
        List<String> warnings = new ArrayList<>();
        List<String> recommendations = new ArrayList<>();

        if (sessions == null || sessions.isEmpty()) {
            analysis.put("warnings", warnings);
            analysis.put("recommendations", recommendations);
            analysis.put("riskLevel", "NORMAL");
            analysis.put("sessionCount", 0);
            analysis.put("totalMinutes", 0);
            analysis.put("totalCardioMinutes", 0);
            return analysis;
        }

        // ── Données de base semaine ──
        int sessionCount = sessions.size();
        int totalMinutes = sessions.stream().mapToInt(TrainingSession::getDuration).sum();
        int totalCardio  = sessions.stream().mapToInt(TrainingSession::getCardioDurationMinutes).sum();

        // ── Expérience ──
        int totalSessionCount = sessions.size();
        double expRiskMult = getExperienceRiskMultiplier(totalSessionCount);
        String experienceLevel;
        if (totalSessionCount < 10)       experienceLevel = "Grand débutant";
        else if (totalSessionCount < 20)  experienceLevel = "Débutant";
        else if (totalSessionCount < 60)  experienceLevel = "Intermédiaire";
        else if (totalSessionCount < 120) experienceLevel = "Confirmé";
        else                              experienceLevel = "Avancé";

        analysis.put("experienceLevel", experienceLevel);
        analysis.put("experienceRiskMultiplier", expRiskMult);

        // ── Muscles à risque ──
        Set<String> allMusclesThisWeek = new HashSet<>();
        List<String> highRiskMuscles = new ArrayList<>();

        for (TrainingSession s : sessions) {
            if (s.getTargetMuscles() == null) continue;
            for (String m : s.getTargetMuscles().split(",")) {
                String muscle = m.trim();
                allMusclesThisWeek.add(muscle);
                double risk = MUSCLE_RISK_MAP.getOrDefault(muscle.toLowerCase(), 1.0);
                if (risk >= 3.0) highRiskMuscles.add(muscle);
            }
        }

        // ── Muscles non récupérés ──
        TrainingSession lastSession = sessions.get(0);
        List<String> currentMuscles = lastSession.getTargetMuscles() != null
                ? Arrays.asList(lastSession.getTargetMuscles().split(","))
                : Collections.emptyList();

        List<TrainingSession> previousSessions = sessions.size() > 1
                ? sessions.subList(1, sessions.size())
                : Collections.emptyList();

        Map<String, Long> hoursSince = getHoursSinceLastWorkPerMuscle(currentMuscles, previousSessions);
        List<String> unrecovered = getUnrecoveredMuscles(currentMuscles, hoursSince, totalSessionCount);

        if (!unrecovered.isEmpty()) {
            warnings.addAll(unrecovered.stream()
                    .map(m -> "⚠️ " + m)
                    .collect(Collectors.toList()));
        }

        // ── Progression des charges ──
        Double weightProgressPct = calculateWeightProgressionPercent(
                lastSession.getWeightLifted(), previousSessions);

        if (weightProgressPct != null) {
            analysis.put("weightProgressionPercent", Math.round(weightProgressPct * 10.0) / 10.0);
            if (weightProgressPct > 15.0) {
                warnings.add("⚠️ Augmentation des charges trop rapide : +"
                        + Math.round(weightProgressPct) + "% vs séances précédentes (max recommandé : +10%)");
                recommendations.add("💡 Réduisez les charges de " + Math.round(weightProgressPct - 10) + "% pour limiter le risque de blessure.");
            } else if (weightProgressPct > 0) {
                analysis.put("weightProgressionStatus", "OK (" + Math.round(weightProgressPct) + "% d'augmentation)");
            }
        }

        // ── Déséquilibres musculaires ──
        List<String> imbalances = detectMuscleImbalances(sessions);
        if (!imbalances.isEmpty()) {
            imbalances.forEach(i -> warnings.add("⚖️ " + i));
            recommendations.add("💡 Intégrez davantage de séances pour les muscles antagonistes pour prévenir les blessures chroniques.");
        }
        analysis.put("muscleImbalances", imbalances);

        // ════════════════════════════════════════════════════════════
        // NIVEAU 2 — Intégration painLevel et warmupDone
        // ════════════════════════════════════════════════════════════

        Integer painLevel  = lastSession.getPainLevel();
        Boolean warmupDone = lastSession.getWarmupDone();
        int painWarmupScoreBonus = 0;

        if (painLevel != null && painLevel >= 7) {
            warnings.add("⚠️ Douleur intense signalée (" + painLevel + "/10) — repos recommandé avant la prochaine séance");
            recommendations.add("🔴 Douleur élevée détectée : évitez de solliciter les muscles douloureux lors de la prochaine séance.");
            if (painLevel >= 9) {
                recommendations.add("🔴 Douleur très intense (" + painLevel + "/10) : consultez un professionnel de santé si la douleur persiste.");
            }
            painWarmupScoreBonus += 2;
            analysis.put("hasHighPain", true);
        } else if (painLevel != null && painLevel >= 4) {
            warnings.add("⚠️ Douleur modérée signalée (" + painLevel + "/10) — surveillez l'évolution lors de la prochaine séance");
            analysis.put("hasHighPain", false);
        } else {
            analysis.put("hasHighPain", false);
        }

        if (warmupDone != null && !warmupDone) {
            warnings.add("⚠️ Séance effectuée sans échauffement — risque de blessure accru");
            recommendations.add("💡 Effectuez toujours 5 à 10 minutes d'échauffement avant chaque séance pour réduire le risque de blessure de ~40%.");
            painWarmupScoreBonus += 1;
        }

        analysis.put("painLevel",  painLevel  != null ? painLevel  : 0);
        analysis.put("warmupDone", warmupDone != null ? warmupDone : true);

        // ── Calcul du niveau de risque global ──
        String riskLevel = computeRiskLevel(
                sessionCount, totalMinutes, totalCardio,
                expRiskMult, !highRiskMuscles.isEmpty(),
                !unrecovered.isEmpty(), weightProgressPct,
                !imbalances.isEmpty(),
                painWarmupScoreBonus);

        addGeneralRecommendations(recommendations, riskLevel, sessionCount,
                totalMinutes, experienceLevel, unrecovered, highRiskMuscles);

        analysis.put("warnings",          warnings);
        analysis.put("recommendations",    recommendations);
        analysis.put("riskLevel",          riskLevel);
        analysis.put("sessionCount",       sessionCount);
        analysis.put("totalMinutes",       totalMinutes);
        analysis.put("totalCardioMinutes", totalCardio);
        analysis.put("highRiskMuscles",    highRiskMuscles);
        analysis.put("unrecoveredMuscles", unrecovered);
        analysis.put("musclesThisWeek",    new ArrayList<>(allMusclesThisWeek));

        return analysis;
    }

    // ── Calcul du score de risque global ──
    private String computeRiskLevel(
            int sessionCount, int totalMinutes, int totalCardio,
            double expRiskMult, boolean hasHighRiskMuscles,
            boolean hasUnrecovered, Double weightProgPct,
            boolean hasImbalances,
            int painWarmupScoreBonus) {

        int score = 0;

        if (sessionCount >= 7)      score += 3;
        else if (sessionCount >= 6) score += 2;
        else if (sessionCount >= 5) score += 1;

        int totalVol = totalMinutes + totalCardio;
        if (totalVol > 600)      score += 3;
        else if (totalVol > 420) score += 2;
        else if (totalVol > 300) score += 1;

        if (expRiskMult >= 1.5)      score += 2;
        else if (expRiskMult >= 1.3) score += 1;

        if (hasHighRiskMuscles) score += 1;
        if (hasUnrecovered)     score += 2;

        if (weightProgPct != null && weightProgPct > 15)      score += 2;
        else if (weightProgPct != null && weightProgPct > 10) score += 1;

        if (hasImbalances) score += 1;

        score += painWarmupScoreBonus;

        if (score >= 8) return "CRITIQUE";
        if (score >= 5) return "ÉLEVÉ";
        if (score >= 3) return "MODÉRÉ";
        return "NORMAL";
    }

    private void addGeneralRecommendations(
            List<String> recommendations, String riskLevel,
            int sessionCount, int totalMinutes,
            String experienceLevel, List<String> unrecovered,
            List<String> highRiskMuscles) {

        if ("CRITIQUE".equals(riskLevel) || "ÉLEVÉ".equals(riskLevel)) {
            recommendations.add("🔴 Planifiez 1 à 2 jours de repos complet dans les prochains jours.");
            recommendations.add("🔴 Réduisez le volume de vos séances de 20 à 30% cette semaine.");
        }
        if (sessionCount >= 6) {
            recommendations.add("💡 " + sessionCount + " séances cette semaine : prévoyez au moins 1 jour de repos.");
        }
        if (!unrecovered.isEmpty()) {
            recommendations.add("💡 Privilégiez des groupes musculaires différents lors de votre prochaine séance.");
        }
        if (highRiskMuscles.contains("lombaires") || highRiskMuscles.contains("épaules")) {
            recommendations.add("💡 Pour les muscles à risque élevé, privilégiez la technique sur la charge.");
        }
        if ("Grand débutant".equals(experienceLevel) || "Débutant".equals(experienceLevel)) {
            recommendations.add("💡 En tant que " + experienceLevel.toLowerCase()
                    + ", votre corps a besoin de plus de temps pour récupérer. Préférez 3 séances/semaine maximum.");
        }
        if (totalMinutes > 90) {
            recommendations.add("💡 Séances longues détectées (> 90 min) : au-delà, l'hormone de stress (cortisol) augmente significativement.");
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // PRÉDICTION FATIGUE — Niveau 1 + 2 + 3 (MemberProfile)
    // ═══════════════════════════════════════════════════════════════════

    public Map<String, Object> predictFatigue(Member member, List<TrainingSession> sessions) {
        if (sessions == null || sessions.isEmpty()) return fatigueFallback();

        try {
            TrainingSession lastSession = sessions.get(0);

            int    age    = member.getAge();
            double weight = member.getWeight();
            double height = member.getHeight();
            double bmi    = (height > 0) ? weight / Math.pow(height / 100.0, 2) : 22.5;
            bmi = Math.round(bmi * 10.0) / 10.0;
            int gender = "MALE".equalsIgnoreCase(member.getGender()) ? 1 : 0;

            double muscleRiskScore = calculateMuscleRiskScore(lastSession.getTargetMuscles());

            // Niveau 1 : multiplicateur expérience
            double expMultiplier = getExperienceRiskMultiplier(sessions.size());
            double adjustedIntensity = Math.min(10.0, lastSession.getIntensity() * expMultiplier);

            // Niveau 2 : ajustements painLevel et warmupDone
            Integer painLevel  = lastSession.getPainLevel();
            Boolean warmupDone = lastSession.getWarmupDone();

            double painIntensityMult   = getPainIntensityMultiplier(painLevel);
            double warmupIntensityMult = getWarmupIntensityMultiplier(warmupDone);

            adjustedIntensity = Math.min(10.0, adjustedIntensity * painIntensityMult * warmupIntensityMult);

            boolean hasHighPain           = painLevel != null && painLevel >= 7;
            boolean painAdjustmentApplied = painIntensityMult != 1.0 || warmupIntensityMult != 1.0;

            // ════════════════════════════════════════════════════════
            // NIVEAU 3 — Intégration MemberProfile dans predictFatigue
            // ════════════════════════════════════════════════════════
            double profileIntensityMult = 1.0;
            boolean profileApplied = false;
            String profileGoal = null;

            Optional<MemberProfile> profileOpt = memberProfileService.getProfile(member.getId());
            if (profileOpt.isPresent()) {
                MemberProfile profile = profileOpt.get();

                // Multiplicateur objectif : performance/muscleGain = effort accru = plus de fatigue
                double goalMult = memberProfileService.goalRiskMultiplier(profile.getPrimaryGoal());

                // Multiplicateur récupération : mauvais sommeil + stress élevé = récupération ralentie
                double recoveryMult = memberProfileService.recoveryMultiplier(profile);

                // Appliquer sur l'intensité perçue (cap à 10)
                profileIntensityMult = Math.min(2.0, goalMult * recoveryMult);
                adjustedIntensity = Math.min(10.0, adjustedIntensity * profileIntensityMult);

                profileApplied = true;
                profileGoal = profile.getPrimaryGoal() != null ? profile.getPrimaryGoal().name() : null;
            }

            double totalDuration = lastSession.getDuration() + lastSession.getCardioDurationMinutes();

            Map<String, Object> body = new HashMap<>();
            body.put("age",                   age);
            body.put("bmi",                   bmi);
            body.put("gender",                gender);
            body.put("muscleRiskScore",        muscleRiskScore);
            body.put("duration",              (double) lastSession.getDuration());
            body.put("totalDuration",          totalDuration);
            body.put("weightLifted",           lastSession.getWeightLifted());
            body.put("intensity",              adjustedIntensity); // ← exp + pain + warmup + profil
            body.put("recoveryDaysPerWeek",    lastSession.getRecoveryDaysPerWeek() != null
                    ? lastSession.getRecoveryDaysPerWeek() : 2);
            body.put("hasCardio",             lastSession.getHasCardio() ? 1 : 0);
            body.put("cardioDurationMinutes", (double) lastSession.getCardioDurationMinutes());
            body.put("cardioIntensity",       (double) lastSession.getCardioIntensity());

            Map result = webClient.post()
                    .uri("/predict_fatigue")
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .timeout(AI_TIMEOUT)
                    .block();

            if (result == null) return fatigueFallback();

            // ── Champs contextuels retournés au front ──
            result.put("hasCardio",             lastSession.getHasCardio());
            result.put("adjustedIntensity",     Math.round(adjustedIntensity * 10.0) / 10.0);
            result.put("experienceMultiplier",  expMultiplier);
            // Niveau 2
            result.put("painLevel",             painLevel  != null ? painLevel  : 0);
            result.put("warmupDone",            warmupDone != null ? warmupDone : true);
            result.put("hasHighPain",           hasHighPain);
            result.put("painAdjustmentApplied", painAdjustmentApplied);
            result.put("painIntensityMult",     Math.round(painIntensityMult   * 100.0) / 100.0);
            result.put("warmupIntensityMult",   Math.round(warmupIntensityMult * 100.0) / 100.0);
            // Niveau 3
            result.put("profileApplied",        profileApplied);
            result.put("profileGoal",           profileGoal);
            result.put("profileIntensityMult",  Math.round(profileIntensityMult * 100.0) / 100.0);

            return result;

        } catch (Exception e) {
            System.err.println("❌ Erreur fatigue AI: " + e.getMessage());
            Map<String, Object> error = new HashMap<>(fatigueFallback());
            error.put("error", "AI service error: " + e.getMessage());
            return error;
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // PRÉDICTION BLESSURE — Niveau 1 + 2 + 3 (MemberProfile)
    // ═══════════════════════════════════════════════════════════════════

    public Map<String, Object> predictInjury(Member member, List<TrainingSession> sessions) {
        if (sessions == null || sessions.isEmpty()) return injuryFallback();

        try {
            TrainingSession lastSession = sessions.get(0);
            List<TrainingSession> prevSessions = sessions.size() > 1
                    ? sessions.subList(1, sessions.size()) : Collections.emptyList();

            double avgIntensity      = sessions.stream().mapToInt(TrainingSession::getIntensity).average().orElse(5.0);
            double avgTrainingHours  = sessions.stream()
                    .mapToDouble(s -> (s.getDuration() + s.getCardioDurationMinutes()) / 60.0)
                    .average().orElse(1.0);
            double avgRecoveryDays   = sessions.stream()
                    .mapToInt(s -> s.getRecoveryDaysPerWeek() != null ? s.getRecoveryDaysPerWeek() : 2)
                    .average().orElse(2.0);
            double avgFatigueScore   = sessions.stream()
                    .mapToDouble(s -> s.getFatigueScore()     != null ? s.getFatigueScore()     : 5.0)
                    .average().orElse(5.0);
            double avgLoadBalance    = sessions.stream()
                    .mapToDouble(s -> s.getLoadBalanceScore() != null ? s.getLoadBalanceScore() : 5.0)
                    .average().orElse(5.0);
            double avgAclRisk        = sessions.stream()
                    .mapToDouble(s -> s.getAclRiskScore()     != null ? s.getAclRiskScore()     : 3.0)
                    .average().orElse(3.0);

            double muscleRiskScore = calculateMuscleRiskScore(lastSession.getTargetMuscles());
            double sessionsPerWeek = sessions.size();

            int    gender = "MALE".equalsIgnoreCase(member.getGender()) ? 1 : 0;
            double bmi    = member.getWeight() / Math.pow(member.getHeight() / 100.0, 2);
            bmi = Math.round(bmi * 10.0) / 10.0;

            // Niveau 1 : multiplicateur expérience
            double expMult = getExperienceRiskMultiplier(sessions.size());
            double adjustedMuscleRisk = Math.min(3.0, muscleRiskScore * expMult);

            // Niveau 1 : progression charges
            Double weightProg = calculateWeightProgressionPercent(lastSession.getWeightLifted(), prevSessions);
            double weightRiskAdj = lastSession.getWeightLifted();
            if (weightProg != null && weightProg > 10) {
                weightRiskAdj *= (1 + (weightProg - 10) / 100.0);
            }

            // Niveau 2 : multiplicateurs painLevel et warmupDone
            Integer painLevel  = lastSession.getPainLevel();
            Boolean warmupDone = lastSession.getWarmupDone();

            double painRiskMult   = getPainRiskMultiplier(painLevel);
            double warmupRiskMult = getWarmupRiskMultiplier(warmupDone);

            adjustedMuscleRisk = Math.min(3.0, adjustedMuscleRisk * painRiskMult * warmupRiskMult);

            boolean hasHighPain = painLevel != null && painLevel >= 7;

            // ════════════════════════════════════════════════════════
            // NIVEAU 3 — Intégration MemberProfile dans predictInjury
            // ════════════════════════════════════════════════════════
            double profileRiskMult = 1.0;
            boolean profileApplied = false;
            String profileGoal = null;
            List<String> profileAlerts = new ArrayList<>();

            Optional<MemberProfile> profileOpt = memberProfileService.getProfile(member.getId());
            if (profileOpt.isPresent()) {
                MemberProfile profile = profileOpt.get();

                // Multiplicateur douleurs chroniques : zones douloureuses = risque accru de blessure
                double chronicMult = memberProfileService.chronicPainRiskMultiplier(profile);

                // Multiplicateur objectif : performance = plus de risque
                double goalMult = memberProfileService.goalRiskMultiplier(profile.getPrimaryGoal());

                // Multiplicateur récupération : mauvais sommeil / stress = moins bonne récupération
                double recoveryMult = memberProfileService.recoveryMultiplier(profile);

                // Combiner sur adjustedMuscleRisk (cap à 3.0)
                profileRiskMult = Math.min(2.0, chronicMult * goalMult * recoveryMult);
                adjustedMuscleRisk = Math.min(3.0, adjustedMuscleRisk * profileRiskMult);

                profileApplied = true;
                profileGoal = profile.getPrimaryGoal() != null ? profile.getPrimaryGoal().name() : null;

                // Alertes blessures actuelles et zones chroniques
                if (profile.getCurrentInjuries() != null && !profile.getCurrentInjuries().isBlank()) {
                    profileAlerts.add("🔴 Blessure actuelle : " + profile.getCurrentInjuries());
                }
                if (profile.getChronicPainZones() != null
                        && !profile.getChronicPainZones().isBlank()
                        && !profile.getChronicPainZones().equalsIgnoreCase("NONE")) {
                    profileAlerts.add("⚠️ Douleurs chroniques connues : " + profile.getChronicPainZones());
                }
                if (profile.getExerciseRestrictions() != null && !profile.getExerciseRestrictions().isBlank()) {
                    profileAlerts.add("🚫 Exercices restreints : " + profile.getExerciseRestrictions());
                }
            }

            Map<String, Object> body = new HashMap<>();
            body.put("age",                   member.getAge());
            body.put("trainingIntensity",      avgIntensity);
            body.put("trainingHoursPerWeek",   avgTrainingHours);
            body.put("recoveryDaysPerWeek",    avgRecoveryDays);
            body.put("fatigueScore",           avgFatigueScore);
            body.put("loadBalanceScore",       avgLoadBalance);
            body.put("aclRiskScore",           avgAclRisk);
            body.put("weightLifted",           weightRiskAdj);
            body.put("sessionsPerWeek",        sessionsPerWeek);
            body.put("hasCardio",             lastSession.getHasCardio() ? 1 : 0);
            body.put("cardioDuration",        (double) lastSession.getCardioDurationMinutes());
            body.put("cardioIntensity",       (double) lastSession.getCardioIntensity());
            body.put("muscleRiskScore",        adjustedMuscleRisk); // ← exp + pain + warmup + profil
            body.put("Gender",                 gender);
            body.put("BMI",                    bmi);

            Map result = webClient.post()
                    .uri("/predict_injury")
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .timeout(AI_TIMEOUT)
                    .block();

            if (result == null) return injuryFallback();

            // ── Champs contextuels retournés au front ──
            // Niveau 2
            result.put("painLevel",           painLevel  != null ? painLevel  : 0);
            result.put("warmupDone",          warmupDone != null ? warmupDone : true);
            result.put("hasHighPain",         hasHighPain);
            result.put("painRiskMult",        Math.round(painRiskMult   * 100.0) / 100.0);
            result.put("warmupRiskMult",      Math.round(warmupRiskMult * 100.0) / 100.0);
            result.put("adjustedMuscleRisk",  Math.round(adjustedMuscleRisk * 100.0) / 100.0);
            // Niveau 3
            result.put("profileApplied",      profileApplied);
            result.put("profileGoal",         profileGoal);
            result.put("profileRiskMult",     Math.round(profileRiskMult * 100.0) / 100.0);
            result.put("profileAlerts",       profileAlerts);

            return result;

        } catch (Exception e) {
            System.err.println("❌ Erreur injury AI: " + e.getMessage());
            Map<String, Object> error = new HashMap<>(injuryFallback());
            error.put("error", "AI service error: " + e.getMessage());
            return error;
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // FALLBACKS
    // ═══════════════════════════════════════════════════════════════════

    private Map<String, Object> fatigueFallback() {
        Map<String, Object> f = new HashMap<>();
        f.put("fatigue",    0);
        f.put("label",      "normal");
        f.put("confidence", 0.5);
        f.put("source",     "fallback");
        return f;
    }

    private Map<String, Object> injuryFallback() {
        Map<String, Object> f = new HashMap<>();
        f.put("injury_risk", 0);
        f.put("label",       "risque faible");
        f.put("confidence",  0.5);
        f.put("source",      "fallback");
        return f;
    }
}