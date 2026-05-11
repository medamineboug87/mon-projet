package com.example.project_backend.Controller;

import com.example.project_backend.Entity.Exercise;
import com.example.project_backend.Repository.ExerciseRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.text.Normalizer;
import java.util.List;
import java.util.Map;

@RestController
@CrossOrigin
public class ExerciseController {

    private final ExerciseRepository exerciseRepository;

    public ExerciseController(ExerciseRepository exerciseRepository) {
        this.exerciseRepository = exerciseRepository;
    }

    // ════════════════════════════════════
    // ROUTES MEMBRES (lecture seule)
    // ════════════════════════════════════

    // ── GET exercices par muscle ──
    @GetMapping("/exercises/muscle/{muscleName}")
    public ResponseEntity<List<Exercise>> getByMuscle(
            @PathVariable String muscleName) {

        List<Exercise> results = exerciseRepository.findByMuscleNameIgnoreCase(muscleName);

        if (results.isEmpty()) {
            results = exerciseRepository.findByMuscleNameFlexible(muscleName);
        }

        if (results.isEmpty()) {
            String normalized = normalize(muscleName);
            results = exerciseRepository.findAll().stream()
                    .filter(e -> normalize(e.getMuscleName()).equalsIgnoreCase(normalized)
                            || normalize(e.getMuscleName()).contains(normalized.toLowerCase()))
                    .toList();
        }

        return ResponseEntity.ok(results);
    }

    // ── GET tous les exercices ──
    @GetMapping("/exercises")
    public ResponseEntity<List<Exercise>> getAllExercises() {
        return ResponseEntity.ok(exerciseRepository.findAll());
    }

    // ── GET exercice par ID ──
    @GetMapping("/exercises/{id}")
    public ResponseEntity<?> getById(@PathVariable Long id) {
        return exerciseRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ════════════════════════════════════
    // ROUTES ADMIN (CRUD complet)
    // ════════════════════════════════════

    // ── CREATE ──
    @PostMapping("/admin/exercises")
    public ResponseEntity<?> createExercise(@RequestBody Exercise exercise) {
        try {
            if (exercise.getName() == null || exercise.getName().isBlank())
                return ResponseEntity.badRequest().body(Map.of("error", "Le nom est requis"));
            if (exercise.getMuscleName() == null || exercise.getMuscleName().isBlank())
                return ResponseEntity.badRequest().body(Map.of("error", "Le muscle est requis"));

            // Valider l'URL vidéo si fournie
            if (exercise.getVideoUrl() != null && !exercise.getVideoUrl().isBlank()) {
                String url = exercise.getVideoUrl().trim();
                if (!url.startsWith("http://") && !url.startsWith("https://")) {
                    return ResponseEntity.badRequest()
                            .body(Map.of("error", "L'URL vidéo doit commencer par http:// ou https://"));
                }
                exercise.setVideoUrl(url);
            }

            return ResponseEntity.ok(exerciseRepository.save(exercise));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── UPDATE ──
    @PutMapping("/admin/exercises/{id}")
    public ResponseEntity<?> updateExercise(@PathVariable Long id,
                                            @RequestBody Exercise updated) {
        try {
            Exercise existing = exerciseRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Exercice introuvable"));

            if (updated.getName() != null) existing.setName(updated.getName());
            if (updated.getMuscleName() != null) existing.setMuscleName(updated.getMuscleName());
            if (updated.getSets() != null) existing.setSets(updated.getSets());
            if (updated.getReps() != null) existing.setReps(updated.getReps());
            if (updated.getSecondaryMuscles() != null) existing.setSecondaryMuscles(updated.getSecondaryMuscles());
            if (updated.getDescription() != null) existing.setDescription(updated.getDescription());
            if (updated.getDifficulty() != null) existing.setDifficulty(updated.getDifficulty());
            if (updated.getRecoveryHours() > 0) existing.setRecoveryHours(updated.getRecoveryHours());

            // ── Champ videoUrl ──
            // null = ne pas modifier | "" = effacer | "https://..." = mettre à jour
            if (updated.getVideoUrl() != null) {
                String url = updated.getVideoUrl().trim();
                if (url.isBlank()) {
                    existing.setVideoUrl(null);
                } else if (url.startsWith("http://") || url.startsWith("https://")) {
                    existing.setVideoUrl(url);
                } else {
                    return ResponseEntity.badRequest()
                            .body(Map.of("error", "L'URL vidéo doit commencer par http:// ou https://"));
                }
            }

            return ResponseEntity.ok(exerciseRepository.save(existing));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── DELETE ──
    @DeleteMapping("/admin/exercises/{id}")
    public ResponseEntity<?> deleteExercise(@PathVariable Long id) {
        try {
            exerciseRepository.deleteById(id);
            return ResponseEntity.ok(Map.of("message", "Exercice supprimé"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ── GET ALL (admin) ──
    @GetMapping("/admin/exercises")
    public ResponseEntity<List<Exercise>> getAllExercisesAdmin() {
        return ResponseEntity.ok(exerciseRepository.findAll());
    }

    // ── GET exercices par muscle (admin) ──
    @GetMapping("/admin/exercises/muscle/{muscleName}")
    public ResponseEntity<List<Exercise>> getByMuscleAdmin(@PathVariable String muscleName) {
        List<Exercise> results = exerciseRepository.findByMuscleNameIgnoreCase(muscleName);
        if (results.isEmpty()) {
            results = exerciseRepository.findByMuscleNameFlexible(muscleName);
        }
        return ResponseEntity.ok(results);
    }

    // ════════════════════════════════════
    // HELPER — normalisation Unicode
    // ════════════════════════════════════
    private static String normalize(String input) {
        if (input == null) return "";
        return Normalizer.normalize(input, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toLowerCase()
                .trim();
    }
}