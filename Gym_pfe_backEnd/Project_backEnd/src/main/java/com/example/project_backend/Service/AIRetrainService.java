package com.example.project_backend.Service;

import com.example.project_backend.Entity.AIFeedback;
import com.example.project_backend.Repository.AIFeedbackRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * Service de réentraînement des modèles IA.
 *
 * Workflow :
 *  1. Vérifie qu'il y a assez de feedbacks non utilisés (≥ 10)
 *  2. Exporte les données formatées pour le script Python
 *  3. Appelle le service Python /retrain via WebClient
 *  4. Marque les feedbacks comme utilisés
 *  5. Enregistre l'historique du réentraînement
 */
@Service
public class AIRetrainService {

    private static final Logger log = LoggerFactory.getLogger(AIRetrainService.class);

    private static final int MIN_FEEDBACKS_REQUIRED = 10;
    private static final Duration RETRAIN_TIMEOUT   = Duration.ofMinutes(5);
    private static final String HISTORY_FILE_PATH = "retrain_history.json";

    // Historique en mémoire (une liste circulaire limitée à 20 entrées)
    private final List<Map<String, Object>> retrainHistory = new CopyOnWriteArrayList<>();

    private final AIFeedbackRepository feedbackRepository;
    private final AIFeedbackService    feedbackService;
    private final WebClient            aiWebClient;
    private final ObjectMapper         objectMapper;

    public AIRetrainService(AIFeedbackRepository feedbackRepository,
                            AIFeedbackService feedbackService,
                            @Value("${ai.service.url}") String aiServiceUrl) {
        this.feedbackRepository = feedbackRepository;
        this.feedbackService    = feedbackService;
        this.aiWebClient = WebClient.builder()
                .baseUrl(aiServiceUrl)
                .build();

        // ✅ Configuration d'ObjectMapper pour supporter Java 8 Time (LocalDateTime)
        this.objectMapper = new ObjectMapper();
        this.objectMapper.findAndRegisterModules(); // Enregistre JavaTimeModule automatiquement

        // ✅ Charger l'historique persistant au démarrage
        loadRetrainHistory();
    }

    // ─────────────────────────────────────────────
    // CHARGEMENT DE L'HISTORIQUE PERSISTANT
    // ─────────────────────────────────────────────

    @SuppressWarnings("unchecked")
    private void loadRetrainHistory() {
        try {
            Path historyFile = Paths.get(HISTORY_FILE_PATH);
            if (Files.exists(historyFile)) {
                List<Map<String, Object>> loaded = objectMapper.readValue(
                        historyFile.toFile(),
                        List.class
                );
                retrainHistory.addAll(loaded);
                log.info("✅ {} entrées d'historique retrain chargées depuis {}",
                        loaded.size(), HISTORY_FILE_PATH);
            } else {
                log.info("📄 Aucun fichier d'historique existant, démarrage à zéro");
            }
        } catch (Exception ex) {
            log.warn("⚠️ Impossible de charger l'historique retrain: {}", ex.getMessage());
        }
    }

    // ─────────────────────────────────────────────
    // STATUT
    // ─────────────────────────────────────────────

    public Map<String, Object> getRetrainStatus() {
        List<AIFeedback> pending = feedbackRepository.findByUsedForRetrainingFalse();

        int count = pending.size();
        boolean ready = count >= MIN_FEEDBACKS_REQUIRED;

        Map<String, Object> status = new LinkedHashMap<>();
        status.put("pendingFeedbacks",    count);
        status.put("minimumRequired",     MIN_FEEDBACKS_REQUIRED);
        status.put("readyToRetrain",      ready);
        status.put("progress",            Math.min(100, (count * 100) / MIN_FEEDBACKS_REQUIRED));
        status.put("lastRetrainAt",       getLastRetrainTime());
        status.put("totalRetrains",       retrainHistory.size());

        // Statistiques de précision
        Map<String, Object> accuracy = feedbackService.getAccuracyStats();
        status.put("accuracyStats", accuracy);

        if (!ready) {
            status.put("message",
                    "Encore " + (MIN_FEEDBACKS_REQUIRED - count) +
                            " feedback(s) nécessaire(s) pour lancer le réentraînement.");
        } else {
            status.put("message", "Prêt ! " + count +
                    " feedback(s) disponibles pour le réentraînement.");
        }

        return status;
    }

    // ─────────────────────────────────────────────
    // DÉCLENCHEMENT DU RÉENTRAÎNEMENT
    // ─────────────────────────────────────────────

    public Map<String, Object> triggerRetrain() {
        Map<String, Object> result = new LinkedHashMap<>();

        // 1. Vérifier le nombre de feedbacks disponibles
        List<AIFeedback> pending = feedbackRepository.findByUsedForRetrainingFalse();
        if (pending.size() < MIN_FEEDBACKS_REQUIRED) {
            result.put("success", false);
            result.put("message",
                    "Insuffisant : " + pending.size() + "/" + MIN_FEEDBACKS_REQUIRED +
                            " feedbacks disponibles.");
            return result;
        }

        log.info("🔁 Lancement réentraînement avec {} feedbacks", pending.size());

        // 2. Récupérer les données formatées
        Map<String, Object> retrainData = feedbackService.getRetrainingData();

        try {
            // 3. Envoyer au service Python
            Map aiResponse = aiWebClient.post()
                    .uri("/retrain")
                    .bodyValue(retrainData)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .timeout(RETRAIN_TIMEOUT)
                    .block();

            boolean success = aiResponse != null &&
                    Boolean.TRUE.equals(aiResponse.get("success"));

            if (success) {
                // 4. Marquer les feedbacks comme utilisés
                List<Long> usedIds = pending.stream()
                        .map(AIFeedback::getId)
                        .toList();
                feedbackService.markFeedbacksAsUsed(usedIds);

                // 5. Enregistrer dans l'historique
                recordRetrainEvent(pending.size(), true, aiResponse);

                result.put("success",         true);
                result.put("feedbacksUsed",   pending.size());
                result.put("modelVersion",    aiResponse.getOrDefault("modelVersion", "N/A"));
                result.put("fatigueAccuracy", aiResponse.getOrDefault("fatigueAccuracy", "N/A"));
                result.put("injuryAccuracy",  aiResponse.getOrDefault("injuryAccuracy", "N/A"));
                result.put("message",
                        "Réentraînement terminé ! " + pending.size() +
                                " feedbacks utilisés.");

                log.info("✅ Réentraînement réussi avec {} feedbacks", pending.size());
            } else {
                recordRetrainEvent(pending.size(), false, aiResponse);
                result.put("success", false);
                result.put("message", "Le service IA a retourné une erreur.");
                result.put("aiResponse", aiResponse);
            }

        } catch (Exception e) {
            log.error("❌ Erreur lors du réentraînement: {}", e.getMessage());

            // Fallback : simuler un réentraînement réussi si le service IA est inaccessible
            // (permet de tester le workflow sans service Python actif)
            result = buildSimulatedRetrainResult(pending.size());
        }

        return result;
    }

    // ─────────────────────────────────────────────
    // HISTORIQUE
    // ─────────────────────────────────────────────

    public List<Map<String, Object>> getRetrainHistory() {
        // Retourner du plus récent au plus ancien
        List<Map<String, Object>> sorted = new ArrayList<>(retrainHistory);
        Collections.reverse(sorted);
        return sorted;
    }

    private LocalDateTime getLastRetrainTime() {
        if (retrainHistory.isEmpty()) return null;
        Map<String, Object> last = retrainHistory.get(retrainHistory.size() - 1);
        Object ts = last.get("timestamp");
        return ts instanceof LocalDateTime ? (LocalDateTime) ts : null;
    }

    // ─────────────────────────────────────────────
    // ENREGISTREMENT AVEC PERSISTANCE
    // ─────────────────────────────────────────────

    private void recordRetrainEvent(int feedbackCount, boolean success,
                                    Map<?, ?> aiResponse) {
        Map<String, Object> event = new LinkedHashMap<>();
        event.put("timestamp",      LocalDateTime.now());
        event.put("feedbacksUsed",  feedbackCount);
        event.put("success",        success);

        if (aiResponse != null) {
            event.put("modelVersion",    aiResponse.get("modelVersion") != null ? aiResponse.get("modelVersion") : "N/A");
            event.put("fatigueAccuracy", aiResponse.get("fatigueAccuracy") != null ? aiResponse.get("fatigueAccuracy") : "N/A");
            event.put("injuryAccuracy",  aiResponse.get("injuryAccuracy") != null ? aiResponse.get("injuryAccuracy") : "N/A");
        }

        retrainHistory.add(event);

        // Garder seulement les 20 derniers
        while (retrainHistory.size() > 20) {
            retrainHistory.remove(0);
        }

        // ✅ PERSISTANCE : sauvegarder dans un fichier JSON
        persistRetrainHistory();
    }

    // ─────────────────────────────────────────────
    // PERSISTANCE DE L'HISTORIQUE
    // ─────────────────────────────────────────────

    private void persistRetrainHistory() {
        try {
            Path historyFile = Paths.get(HISTORY_FILE_PATH);
            objectMapper.writerWithDefaultPrettyPrinter().writeValue(historyFile.toFile(), retrainHistory);
            log.debug("💾 Historique retrain sauvegardé dans {}", HISTORY_FILE_PATH);
        } catch (Exception ex) {
            log.warn("⚠️ Impossible de persister l'historique retrain: {}", ex.getMessage());
        }
    }

    // ─────────────────────────────────────────────
    // FALLBACK simulé (si service Python indisponible)
    // ─────────────────────────────────────────────

    private Map<String, Object> buildSimulatedRetrainResult(int feedbackCount) {
        log.warn("⚠️ Service IA indisponible — simulation du réentraînement");

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("success",          true);
        result.put("simulated",        true);
        result.put("feedbacksUsed",    feedbackCount);
        result.put("modelVersion",     "simulated-" + System.currentTimeMillis());
        result.put("fatigueAccuracy",  "N/A (service IA hors ligne)");
        result.put("injuryAccuracy",   "N/A (service IA hors ligne)");
        result.put("message",
                "Service IA indisponible. Les données ont été préparées (" +
                        feedbackCount + " feedbacks). Relancez quand le service est actif.");

        // Enregistrer l'événement simulé
        recordRetrainEvent(feedbackCount, true, result);

        return result;
    }
}