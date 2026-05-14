package com.example.project_backend.Service;

import com.example.project_backend.Entity.*;
import com.example.project_backend.Repository.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;

@Service
public class AIFeedbackService {

    private static final Logger log = LoggerFactory.getLogger(AIFeedbackService.class);

    private final AIFeedbackRepository     feedbackRepository;
    private final MemberRepository         memberRepository;
    private final CoachRepository          coachRepository;
    private final TrainingSessionRepository sessionRepository;

    public AIFeedbackService(AIFeedbackRepository feedbackRepository,
                             MemberRepository memberRepository,
                             CoachRepository coachRepository,
                             TrainingSessionRepository sessionRepository) {
        this.feedbackRepository = feedbackRepository;
        this.memberRepository   = memberRepository;
        this.coachRepository    = coachRepository;
        this.sessionRepository  = sessionRepository;
    }

    // ═══════════════════════════════════════════════════════════════
    // CRÉER OU METTRE À JOUR UN FEEDBACK
    // ═══════════════════════════════════════════════════════════════

    @Transactional
    public AIFeedback saveFeedback(Long memberId, Long coachId,
                                   Long sessionId, Map<String, Object> data) {

        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new RuntimeException("Membre introuvable: " + memberId));

        Coach coach = coachRepository.findById(coachId)
                .orElseThrow(() -> new RuntimeException("Coach introuvable: " + coachId));

        AIFeedback feedback = sessionId != null
                ? feedbackRepository.findBySessionId(sessionId).orElse(new AIFeedback())
                : new AIFeedback();

        feedback.setMember(member);
        feedback.setCoach(coach);

        if (sessionId != null) {
            sessionRepository.findById(sessionId).ifPresent(feedback::setSession);
        }

        // ═══════════════════════════════════════════════════════════════
        // PRÉDICTIONS ORIGINALES (stockées pour référence)
        // ═══════════════════════════════════════════════════════════════
        if (data.containsKey("originalFatigueLabel"))
            feedback.setOriginalFatigueLabel((String) data.get("originalFatigueLabel"));
        if (data.containsKey("originalFatigueConfidence") && data.get("originalFatigueConfidence") != null)
            feedback.setOriginalFatigueConfidence(((Number) data.get("originalFatigueConfidence")).doubleValue());
        if (data.containsKey("originalInjuryLabel"))
            feedback.setOriginalInjuryLabel((String) data.get("originalInjuryLabel"));
        if (data.containsKey("originalInjuryConfidence") && data.get("originalInjuryConfidence") != null)
            feedback.setOriginalInjuryConfidence(((Number) data.get("originalInjuryConfidence")).doubleValue());
        if (data.containsKey("originalOverloadLevel"))
            feedback.setOriginalOverloadLevel((String) data.get("originalOverloadLevel"));

        // ═══════════════════════════════════════════════════════════════
        // ✅ CORRECTIONS STRUCTURÉES (avec VALIDATION)
        // ═══════════════════════════════════════════════════════════════

        // Fatigue correction
        if (data.containsKey("fatiguePredictionCorrect") && data.get("fatiguePredictionCorrect") != null)
            feedback.setFatiguePredictionCorrect((Boolean) data.get("fatiguePredictionCorrect"));

        if (data.containsKey("correctedFatigueLabel") && data.get("correctedFatigueLabel") != null) {
            String label = (String) data.get("correctedFatigueLabel");
            // ✅ VALIDATION : seulement "normal" ou "fatigué"
            if (!List.of("normal", "fatigué").contains(label)) {
                throw new IllegalArgumentException("Label fatigue invalide: " + label + ". Valeurs autorisées: normal, fatigué");
            }
            feedback.setCorrectedFatigueLabel(label);
        }

        // Injury correction
        if (data.containsKey("injuryPredictionCorrect") && data.get("injuryPredictionCorrect") != null)
            feedback.setInjuryPredictionCorrect((Boolean) data.get("injuryPredictionCorrect"));

        if (data.containsKey("correctedInjuryLabel") && data.get("correctedInjuryLabel") != null) {
            String label = (String) data.get("correctedInjuryLabel");
            // ✅ VALIDATION : seulement "risque faible" ou "risque élevé"
            if (!List.of("risque faible", "risque élevé").contains(label)) {
                throw new IllegalArgumentException("Label blessure invalide: " + label + ". Valeurs autorisées: risque faible, risque élevé");
            }
            feedback.setCorrectedInjuryLabel(label);
        }

        // Overload correction
        if (data.containsKey("overloadPredictionCorrect") && data.get("overloadPredictionCorrect") != null)
            feedback.setOverloadPredictionCorrect((Boolean) data.get("overloadPredictionCorrect"));

        if (data.containsKey("correctedOverloadLevel") && data.get("correctedOverloadLevel") != null) {
            String level = (String) data.get("correctedOverloadLevel");
            // ✅ VALIDATION : seulement les 4 niveaux
            if (!List.of("NORMAL", "MODÉRÉ", "ÉLEVÉ", "CRITIQUE").contains(level)) {
                throw new IllegalArgumentException("Niveau surcharge invalide: " + level + ". Valeurs autorisées: NORMAL, MODÉRÉ, ÉLEVÉ, CRITIQUE");
            }
            feedback.setCorrectedOverloadLevel(level);
        }

        // ═══════════════════════════════════════════════════════════════
        // NOTE ET COMMENTAIRE
        // ═══════════════════════════════════════════════════════════════
        if (data.containsKey("coachRating") && data.get("coachRating") != null) {
            int rating = ((Number) data.get("coachRating")).intValue();
            if (rating < 1 || rating > 5)
                throw new IllegalArgumentException("La note doit être entre 1 et 5");
            feedback.setCoachRating(rating);
        }

        // 📝 TEXTE LIBRE - stocké sans validation (juste limité en longueur)
        if (data.containsKey("coachComment")) {
            String comment = (String) data.get("coachComment");
            if (comment != null && comment.length() > 1000) {
                comment = comment.substring(0, 1000);
            }
            feedback.setCoachComment(comment);
        }

        // Observations physiques
        if (data.containsKey("observedFatigueLevel") && data.get("observedFatigueLevel") != null) {
            int level = ((Number) data.get("observedFatigueLevel")).intValue();
            if (level < 0 || level > 10)
                throw new IllegalArgumentException("Le niveau de fatigue observé doit être entre 0 et 10");
            feedback.setObservedFatigueLevel(level);
        }

        if (data.containsKey("injurySignsObserved") && data.get("injurySignsObserved") != null)
            feedback.setInjurySignsObserved((Boolean) data.get("injurySignsObserved"));

        if (data.containsKey("injuryObservationDetail")) {
            String detail = (String) data.get("injuryObservationDetail");
            if (detail != null && detail.length() > 500) {
                detail = detail.substring(0, 500);
            }
            feedback.setInjuryObservationDetail(detail);
        }

        if (data.containsKey("recommendedNextSessionLoad") && data.get("recommendedNextSessionLoad") != null)
            feedback.setRecommendedNextSessionLoad(((Number) data.get("recommendedNextSessionLoad")).doubleValue());

        if (data.containsKey("recommendedRestDays") && data.get("recommendedRestDays") != null)
            feedback.setRecommendedRestDays(((Number) data.get("recommendedRestDays")).intValue());

        feedback.setUpdatedAt(LocalDateTime.now());
        AIFeedback saved = feedbackRepository.save(feedback);

        log.info("✅ Feedback IA sauvegardé — memberId={} coachId={} sessionId={} rating={}",
                memberId, coachId, sessionId, feedback.getCoachRating());

        return saved;
    }

    // ═══════════════════════════════════════════════════════════════
    // LECTURES
    // ═══════════════════════════════════════════════════════════════

    public List<AIFeedback> getFeedbacksByMember(Long memberId) {
        return feedbackRepository.findByMemberIdOrderByCreatedAtDesc(memberId);
    }

    public List<AIFeedback> getFeedbacksByCoach(Long coachId) {
        return feedbackRepository.findByCoachIdOrderByCreatedAtDesc(coachId);
    }

    public Optional<AIFeedback> getFeedbackBySession(Long sessionId) {
        return feedbackRepository.findBySessionId(sessionId);
    }

    public List<AIFeedback> getAllFeedbacksWithCorrections() {
        return feedbackRepository.findAllWithCorrections();
    }

    // ═══════════════════════════════════════════════════════════════
    // STATISTIQUES GLOBALES DE PRÉCISION
    // ═══════════════════════════════════════════════════════════════

    public Map<String, Object> getAccuracyStats() {
        Map<String, Object> stats = new LinkedHashMap<>();

        long totalFeedbacks = feedbackRepository.count();
        stats.put("totalFeedbacks", totalFeedbacks);

        // Précision fatigue
        long correctFatigue   = feedbackRepository.countCorrectFatiguePredictions();
        long evaluatedFatigue = feedbackRepository.countEvaluatedFatiguePredictions();
        double fatigueAccuracy = evaluatedFatigue > 0
                ? Math.round((double) correctFatigue / evaluatedFatigue * 1000.0) / 10.0
                : 0.0;

        stats.put("fatigue", Map.of(
                "correct",   correctFatigue,
                "evaluated", evaluatedFatigue,
                "accuracyValue", fatigueAccuracy
        ));

        // Précision blessure
        long correctInjury   = feedbackRepository.countCorrectInjuryPredictions();
        long evaluatedInjury = feedbackRepository.countEvaluatedInjuryPredictions();
        double injuryAccuracy = evaluatedInjury > 0
                ? Math.round((double) correctInjury / evaluatedInjury * 1000.0) / 10.0
                : 0.0;

        stats.put("injury", Map.of(
                "correct",   correctInjury,
                "evaluated", evaluatedInjury,
                "accuracyValue", injuryAccuracy
        ));

        // Note moyenne des coaches
        List<AIFeedback> allFeedbacks = feedbackRepository.findAll();
        OptionalDouble avgRating = allFeedbacks.stream()
                .filter(f -> f.getCoachRating() != null)
                .mapToInt(AIFeedback::getCoachRating)
                .average();
        stats.put("averageRating", avgRating.isPresent()
                ? Math.round(avgRating.getAsDouble() * 10.0) / 10.0 : null);

        // Réentraînement
        long pendingRetraining = feedbackRepository.findByUsedForRetrainingFalse().size();
        stats.put("pendingRetrainingFeedbacks", pendingRetraining);
        stats.put("readyForRetraining", pendingRetraining >= 10);

        // Qualité globale
        double avgAccuracy = (fatigueAccuracy + injuryAccuracy) / 2.0;
        String quality;
        if (avgAccuracy >= 85)      quality = "Excellent";
        else if (avgAccuracy >= 70) quality = "Bon";
        else if (avgAccuracy >= 55) quality = "Acceptable";
        else if (avgAccuracy > 0)   quality = "À améliorer — réentraînement recommandé";
        else                        quality = "Données insuffisantes";

        stats.put("qualityLabel", quality);

        return stats;
    }

    // ═══════════════════════════════════════════════════════════════
    // STATISTIQUES PAR MEMBRE
    // ═══════════════════════════════════════════════════════════════

    public Map<String, Object> getMemberAccuracyStats(Long memberId) {
        List<AIFeedback> feedbacks = feedbackRepository.findByMemberIdOrderByCreatedAtDesc(memberId);

        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("memberId",       memberId);
        stats.put("totalFeedbacks", feedbacks.size());

        if (feedbacks.isEmpty()) {
            stats.put("message", "Aucun feedback pour ce membre.");
            return stats;
        }

        // Précision fatigue pour ce membre
        long evalFat = feedbacks.stream()
                .filter(f -> f.getFatiguePredictionCorrect() != null).count();
        long corrFat = feedbacks.stream()
                .filter(f -> Boolean.TRUE.equals(f.getFatiguePredictionCorrect())).count();
        double fatAcc = evalFat > 0 ? Math.round((double) corrFat / evalFat * 1000.0) / 10.0 : 0;

        // Précision blessure pour ce membre
        long evalInj = feedbacks.stream()
                .filter(f -> f.getInjuryPredictionCorrect() != null).count();
        long corrInj = feedbacks.stream()
                .filter(f -> Boolean.TRUE.equals(f.getInjuryPredictionCorrect())).count();
        double injAcc = evalInj > 0 ? Math.round((double) corrInj / evalInj * 1000.0) / 10.0 : 0;

        stats.put("fatigue", Map.of(
                "correct", corrFat, "evaluated", evalFat,
                "accuracyValue", fatAcc));
        stats.put("injury", Map.of(
                "correct", corrInj, "evaluated", evalInj,
                "accuracyValue", injAcc));

        // Note moyenne
        OptionalDouble avgRating = feedbacks.stream()
                .filter(f -> f.getCoachRating() != null)
                .mapToInt(AIFeedback::getCoachRating)
                .average();
        stats.put("averageRating", avgRating.isPresent()
                ? Math.round(avgRating.getAsDouble() * 10.0) / 10.0 : null);

        // Nombre de corrections
        long corrections = feedbacks.stream()
                .filter(f -> Boolean.FALSE.equals(f.getFatiguePredictionCorrect())
                        || Boolean.FALSE.equals(f.getInjuryPredictionCorrect()))
                .count();
        stats.put("correctionsCount", corrections);

        return stats;
    }

    // ═══════════════════════════════════════════════════════════════
    // DONNÉES POUR LE RÉENTRAÎNEMENT (CE QUI PART À PYTHON)
    // ═══════════════════════════════════════════════════════════════

    public Map<String, Object> getRetrainingData() {
        List<AIFeedback> feedbacks = feedbackRepository.findByUsedForRetrainingFalse();

        List<Map<String, Object>> rows = new ArrayList<>();
        for (AIFeedback fb : feedbacks) {
            if (fb.getSession() == null) continue;

            TrainingSession session = fb.getSession();
            Member member = fb.getMember();

            Map<String, Object> row = new LinkedHashMap<>();

            // ═══════════════════════════════════════════════════════
            // ⚠️ IMPORTANT : Seuls les champs NUMÉRIQUES partent à Python
            // Le commentaire texte (coachComment) N'EST PAS inclus ici !
            // ═══════════════════════════════════════════════════════

            row.put("duration", session.getDuration());
            row.put("intensity", session.getIntensity());
            row.put("weightLifted", session.getWeightLifted());
            row.put("hasCardio", session.getHasCardio() ? 1 : 0);
            row.put("painLevel", session.getPainLevel() != null ? session.getPainLevel() : 0);
            row.put("warmupDone", session.getWarmupDone() != null ? (session.getWarmupDone() ? 1 : 0) : 1);
            row.put("age", member.getAge());
            row.put("gender", "MALE".equalsIgnoreCase(member.getGender()) ? 1 : 0);

            double bmi = member.getHeight() > 0
                    ? member.getWeight() / Math.pow(member.getHeight() / 100.0, 2) : 22.5;
            row.put("bmi", Math.round(bmi * 10.0) / 10.0);

            // ✅ Fatigue label → binaire (0 ou 1)
            String fatigueLabel = fb.getCorrectedFatigueLabel() != null
                    ? fb.getCorrectedFatigueLabel() : fb.getOriginalFatigueLabel();
            row.put("fatigue_binary", "fatigué".equals(fatigueLabel) ? 1 : 0);

            // ✅ Injury label → binaire (0 ou 1)
            String injuryLabel = fb.getCorrectedInjuryLabel() != null
                    ? fb.getCorrectedInjuryLabel() : fb.getOriginalInjuryLabel();
            row.put("injury_binary", "risque élevé".equals(injuryLabel) ? 1 : 0);

            // ✅ Note du coach (1-5)
            row.put("coach_rating", fb.getCoachRating());

            // Observations physiques
            row.put("coach_observed_fatigue", fb.getObservedFatigueLevel());
            row.put("injury_signs_observed", fb.getInjurySignsObserved() != null
                    ? (fb.getInjurySignsObserved() ? 1 : 0) : null);

            // 📝 Le commentaire texte (coachComment) N'EST PAS inclus !

            rows.add(row);
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("totalSamples",    rows.size());
        result.put("readyToRetrain",  rows.size() >= 10);
        result.put("minimumRequired", 10);
        result.put("data",            rows);
        result.put("message", rows.size() < 10
                ? "Insuffisant : " + rows.size() + "/10 feedbacks minimum requis."
                : rows.size() + " feedbacks disponibles pour le réentraînement.");

        return result;
    }

    // ═══════════════════════════════════════════════════════════════
    // MARQUER LES FEEDBACKS COMME UTILISÉS
    // ═══════════════════════════════════════════════════════════════

    @Transactional
    public int markFeedbacksAsUsed(List<Long> feedbackIds) {
        int[] count = {0};  // ← tableau = référence modifiable
        for (Long id : feedbackIds) {
            feedbackRepository.findById(id).ifPresent(fb -> {
                fb.setUsedForRetraining(true);
                fb.setUpdatedAt(LocalDateTime.now());
                feedbackRepository.save(fb);
                count[0]++;  // ✅ Plus d'erreur
            });
        }
        log.info("✅ {} feedbacks marqués comme utilisés", count[0]);
        return count[0];
    }

    // ═══════════════════════════════════════════════════════════════
    // SÉRIALISATION (pour les réponses API)
    // ═══════════════════════════════════════════════════════════════

    public Map<String, Object> toMap(AIFeedback fb) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id",            fb.getId());
        m.put("memberId",      fb.getMember() != null ? fb.getMember().getId()        : null);
        m.put("memberName",    fb.getMember() != null ? fb.getMember().getFullName()  : null);
        m.put("coachId",       fb.getCoach()  != null ? fb.getCoach().getId()         : null);
        m.put("coachName",     fb.getCoach()  != null ? fb.getCoach().getFullName()   : null);
        m.put("sessionId",     fb.getSession() != null ? fb.getSession().getId()      : null);
        m.put("sessionDate",   fb.getSession() != null ? fb.getSession().getDate()    : null);
        m.put("originalFatigueLabel",      fb.getOriginalFatigueLabel());
        m.put("originalFatigueConfidence", fb.getOriginalFatigueConfidence());
        m.put("originalInjuryLabel",       fb.getOriginalInjuryLabel());
        m.put("originalInjuryConfidence",  fb.getOriginalInjuryConfidence());
        m.put("originalOverloadLevel",     fb.getOriginalOverloadLevel());
        m.put("fatiguePredictionCorrect",  fb.getFatiguePredictionCorrect());
        m.put("injuryPredictionCorrect",   fb.getInjuryPredictionCorrect());
        m.put("overloadPredictionCorrect", fb.getOverloadPredictionCorrect());
        m.put("correctedFatigueLabel",  fb.getCorrectedFatigueLabel());
        m.put("correctedInjuryLabel",   fb.getCorrectedInjuryLabel());
        m.put("correctedOverloadLevel", fb.getCorrectedOverloadLevel());
        m.put("coachRating",  fb.getCoachRating());
        m.put("coachComment", fb.getCoachComment());
        m.put("observedFatigueLevel",       fb.getObservedFatigueLevel());
        m.put("injurySignsObserved",        fb.getInjurySignsObserved());
        m.put("injuryObservationDetail",    fb.getInjuryObservationDetail());
        m.put("recommendedNextSessionLoad", fb.getRecommendedNextSessionLoad());
        m.put("recommendedRestDays",        fb.getRecommendedRestDays());
        m.put("usedForRetraining", fb.getUsedForRetraining());
        m.put("createdAt",         fb.getCreatedAt());
        m.put("updatedAt",         fb.getUpdatedAt());
        return m;
    }
}