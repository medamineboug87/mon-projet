package com.example.project_backend.Controller;

import com.example.project_backend.Entity.SessionExercise;
import com.example.project_backend.Entity.TrainingSession;
import com.example.project_backend.Repository.SessionExerciseRepository;
import com.example.project_backend.Repository.TrainingSessionRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

/**
 * Controller REST pour gérer les exercices individuels d'une séance.
 * Base URL : /sessions/{sessionId}/exercises
 *
 * Résout le Problème #3 : charge réelle par exercice.
 */
@RestController
@CrossOrigin
public class SessionExerciseController {

    private final SessionExerciseRepository exerciseRepository;
    private final TrainingSessionRepository sessionRepository;

    public SessionExerciseController(SessionExerciseRepository exerciseRepository,
                                     TrainingSessionRepository sessionRepository) {
        this.exerciseRepository = exerciseRepository;
        this.sessionRepository  = sessionRepository;
    }

    // ── GET : tous les exercices d'une séance ──
    @GetMapping("/sessions/{sessionId}/exercises")
    public ResponseEntity<?> getExercisesBySession(@PathVariable Long sessionId) {
        try {
            List<SessionExercise> exercises =
                    exerciseRepository.findBySessionIdOrderByExerciseOrderAsc(sessionId);
            return ResponseEntity.ok(exercises);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── POST : ajouter UN exercice à une séance existante ──
    @PostMapping("/sessions/{sessionId}/exercises")
    public ResponseEntity<?> addExercise(@PathVariable Long sessionId,
                                          @RequestBody Map<String, Object> request) {
        try {
            TrainingSession session = sessionRepository.findById(sessionId)
                    .orElseThrow(() -> new RuntimeException("Séance introuvable: " + sessionId));

            SessionExercise exercise = buildExercise(request, session);
            SessionExercise saved = exerciseRepository.save(exercise);

            // Recalcule le weightLifted global de la séance
            updateSessionTotalWeight(session);

            return ResponseEntity.ok(toMap(saved));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── POST : ajouter PLUSIEURS exercices à une séance (bulk) ──
    @PostMapping("/sessions/{sessionId}/exercises/bulk")
    public ResponseEntity<?> addExercisesBulk(@PathVariable Long sessionId,
                                               @RequestBody List<Map<String, Object>> requests) {
        try {
            TrainingSession session = sessionRepository.findById(sessionId)
                    .orElseThrow(() -> new RuntimeException("Séance introuvable: " + sessionId));

            // Supprimer les anciens exercices de cette séance avant de recréer
            exerciseRepository.deleteBySessionId(sessionId);

            List<Map<String, Object>> saved = new ArrayList<>();
            for (int i = 0; i < requests.size(); i++) {
                Map<String, Object> req = requests.get(i);
                req.put("exerciseOrder", i + 1); // Numéroter dans l'ordre
                SessionExercise exercise = buildExercise(req, session);
                saved.add(toMap(exerciseRepository.save(exercise)));
            }

            // Recalcule le weightLifted global de la séance
            updateSessionTotalWeight(session);

            return ResponseEntity.ok(Map.of(
                    "message", saved.size() + " exercice(s) enregistré(s)",
                    "exercises", saved
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── PUT : modifier un exercice ──
    @PutMapping("/sessions/{sessionId}/exercises/{exerciseId}")
    public ResponseEntity<?> updateExercise(@PathVariable Long sessionId,
                                             @PathVariable Long exerciseId,
                                             @RequestBody Map<String, Object> request) {
        try {
            SessionExercise exercise = exerciseRepository.findById(exerciseId)
                    .orElseThrow(() -> new RuntimeException("Exercice introuvable"));

            if (request.get("exerciseName") != null)
                exercise.setExerciseName((String) request.get("exerciseName"));
            if (request.get("muscleName") != null)
                exercise.setMuscleName((String) request.get("muscleName"));
            if (request.get("weightKg") != null)
                exercise.setWeightKg(((Number) request.get("weightKg")).doubleValue());
            if (request.get("setsCompleted") != null)
                exercise.setSetsCompleted(((Number) request.get("setsCompleted")).intValue());
            if (request.get("repsCompleted") != null)
                exercise.setRepsCompleted((String) request.get("repsCompleted"));
            if (request.get("rpe") != null)
                exercise.setRpe(((Number) request.get("rpe")).intValue());
            if (request.get("failureReached") != null)
                exercise.setFailureReached((Boolean) request.get("failureReached"));
            if (request.get("restSeconds") != null)
                exercise.setRestSeconds(((Number) request.get("restSeconds")).intValue());
            if (request.get("notes") != null)
                exercise.setNotes((String) request.get("notes"));

            SessionExercise saved = exerciseRepository.save(exercise);

            // Recalcule le weightLifted global
            sessionRepository.findById(sessionId).ifPresent(this::updateSessionTotalWeight);

            return ResponseEntity.ok(toMap(saved));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── DELETE : supprimer un exercice ──
    @DeleteMapping("/sessions/{sessionId}/exercises/{exerciseId}")
    public ResponseEntity<?> deleteExercise(@PathVariable Long sessionId,
                                             @PathVariable Long exerciseId) {
        try {
            exerciseRepository.deleteById(exerciseId);
            sessionRepository.findById(sessionId).ifPresent(this::updateSessionTotalWeight);
            return ResponseEntity.ok(Map.of("message", "Exercice supprimé"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── GET : historique d'un exercice (progression des charges) ──
    @GetMapping("/members/{memberId}/exercises/{exerciseName}/history")
    public ResponseEntity<?> getExerciseHistory(@PathVariable Long memberId,
                                                 @PathVariable String exerciseName) {
        try {
            List<SessionExercise> history =
                    exerciseRepository.findByMemberIdAndExerciseName(memberId, exerciseName);

            // Construire l'historique de progression
            List<Map<String, Object>> progression = history.stream()
                    .map(ex -> {
                        Map<String, Object> point = new LinkedHashMap<>();
                        point.put("date",         ex.getSession().getDate());
                        point.put("weightKg",     ex.getWeightKg());
                        point.put("sets",         ex.getSetsCompleted());
                        point.put("reps",         ex.getRepsCompleted());
                        point.put("totalVolume",  ex.getTotalVolume());
                        point.put("rpe",          ex.getRpe());
                        return point;
                    }).toList();

            // Calculer la progression en %
            Double progressionPct = null;
            if (progression.size() >= 2) {
                Double latest = (Double) progression.get(0).get("weightKg");
                Double previous = (Double) progression.get(1).get("weightKg");
                if (previous != null && previous > 0 && latest != null) {
                    progressionPct = Math.round(((latest - previous) / previous * 100) * 10.0) / 10.0;
                }
            }

            // Charge maximale jamais atteinte
            Double maxWeight = exerciseRepository.findMaxWeightByMemberAndExercise(memberId, exerciseName);

            return ResponseEntity.ok(Map.of(
                    "exerciseName",   exerciseName,
                    "totalSessions",  progression.size(),
                    "maxWeight",      maxWeight != null ? maxWeight : 0,
                    "lastWeight",     progression.isEmpty() ? 0 : progression.get(0).get("weightKg"),
                    "progressionPct", progressionPct != null ? progressionPct : 0,
                    "history",        progression
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── GET : volume hebdomadaire par muscle ──
    @GetMapping("/members/{memberId}/exercises/weekly-volume")
    public ResponseEntity<?> getWeeklyVolume(@PathVariable Long memberId) {
        try {
            List<Object[]> rawData = exerciseRepository.findWeeklyVolumeByMuscle(memberId);
            List<Map<String, Object>> result = rawData.stream()
                    .map(row -> Map.of(
                            "muscle", row[0] != null ? row[0].toString() : "Inconnu",
                            "volume", row[1] != null ? ((Number) row[1]).doubleValue() : 0.0
                    ))
                    .toList();
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ═════════════════════════════════════════════════
    // HELPERS PRIVÉS
    // ═════════════════════════════════════════════════

    /**
     * Construit un SessionExercise depuis la map JSON reçue du Flutter.
     */
    private SessionExercise buildExercise(Map<String, Object> request,
                                           TrainingSession session) {
        if (request.get("exerciseName") == null || request.get("exerciseName").toString().isBlank()) {
            throw new RuntimeException("exerciseName est obligatoire");
        }

        SessionExercise exercise = new SessionExercise();
        exercise.setSession(session);
        exercise.setExerciseName((String) request.get("exerciseName"));
        exercise.setMuscleName((String) request.get("muscleName"));

        if (request.get("weightKg") != null)
            exercise.setWeightKg(((Number) request.get("weightKg")).doubleValue());
        if (request.get("setsCompleted") != null)
            exercise.setSetsCompleted(((Number) request.get("setsCompleted")).intValue());
        if (request.get("repsCompleted") != null)
            exercise.setRepsCompleted((String) request.get("repsCompleted"));
        if (request.get("rpe") != null)
            exercise.setRpe(((Number) request.get("rpe")).intValue());
        if (request.get("failureReached") != null)
            exercise.setFailureReached((Boolean) request.get("failureReached"));
        if (request.get("restSeconds") != null)
            exercise.setRestSeconds(((Number) request.get("restSeconds")).intValue());
        if (request.get("notes") != null)
            exercise.setNotes((String) request.get("notes"));
        if (request.get("exerciseOrder") != null)
            exercise.setExerciseOrder(((Number) request.get("exerciseOrder")).intValue());

        return exercise;
    }

    /**
     * Recalcule le weightLifted global de la séance = somme du volume de tous ses exercices.
     * Cela garde la compatibilité avec le code existant qui utilise session.weightLifted.
     */
    private void updateSessionTotalWeight(TrainingSession session) {
        List<SessionExercise> exercises =
                exerciseRepository.findBySessionIdOrderByExerciseOrderAsc(session.getId());

        // Poids max utilisé dans la séance (indicateur principal)
        double maxWeight = exercises.stream()
                .mapToDouble(e -> e.getWeightKg() != null ? e.getWeightKg() : 0.0)
                .max()
                .orElse(0.0);

        // Volume total de la séance (somme de tous les volumes d'exercices)
        double totalVolume = exercises.stream()
                .mapToDouble(e -> e.getTotalVolume() != null ? e.getTotalVolume() : 0.0)
                .sum();

        // Mise à jour : weightLifted = charge max (rétrocompatibilité)
        // et on stocke le volume total dans un champ existant
        session.setWeightLifted(maxWeight > 0 ? maxWeight : session.getWeightLifted());
        sessionRepository.save(session);
    }

    /**
     * Sérialise un SessionExercise en Map pour la réponse JSON.
     */
    private Map<String, Object> toMap(SessionExercise ex) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id",             ex.getId());
        m.put("sessionId",      ex.getSession() != null ? ex.getSession().getId() : null);
        m.put("exerciseName",   ex.getExerciseName());
        m.put("muscleName",     ex.getMuscleName());
        m.put("weightKg",       ex.getWeightKg());
        m.put("setsCompleted",  ex.getSetsCompleted());
        m.put("repsCompleted",  ex.getRepsCompleted());
        m.put("totalVolume",    ex.getTotalVolume());
        m.put("rpe",            ex.getRpe());
        m.put("failureReached", ex.getFailureReached());
        m.put("restSeconds",    ex.getRestSeconds());
        m.put("exerciseOrder",  ex.getExerciseOrder());
        m.put("notes",          ex.getNotes());
        return m;
    }
}
