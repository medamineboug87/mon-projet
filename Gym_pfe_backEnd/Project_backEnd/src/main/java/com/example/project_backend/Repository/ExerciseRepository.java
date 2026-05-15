package com.example.project_backend.Repository;

import com.example.project_backend.Entity.Exercise;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ExerciseRepository extends JpaRepository<Exercise, Long> {

    // Recherche exacte insensible à la casse
    List<Exercise> findByMuscleNameIgnoreCase(String muscleName);

    // ✅ NOUVEAU : Recherche d'un exercice par son nom (insensible à la casse)
    // Utilisé par l'endpoint /exercises/name/{exerciseName}
    // Pour récupérer la description et la vidéo dans le formulaire d'édition
    Optional<Exercise> findByNameIgnoreCase(String name);

    // ── FIX : recherche avec LIKE pour gérer les variations d'encodage ──
    @Query("SELECT e FROM Exercise e WHERE " +
            "LOWER(e.muscleName) = LOWER(:muscleName) OR " +
            "LOWER(e.muscleName) LIKE LOWER(CONCAT('%', :muscleName, '%'))")
    List<Exercise> findByMuscleNameFlexible(@Param("muscleName") String muscleName);

    void deleteByMuscleName(String muscleName);
}