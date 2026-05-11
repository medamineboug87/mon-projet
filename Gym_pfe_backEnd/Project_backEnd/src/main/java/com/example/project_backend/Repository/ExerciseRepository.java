package com.example.project_backend.Repository;

import com.example.project_backend.Entity.Exercise;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ExerciseRepository extends JpaRepository<Exercise, Long> {

    // Recherche exacte insensible à la casse
    List<Exercise> findByMuscleNameIgnoreCase(String muscleName);

    // ── FIX : recherche avec LIKE pour gérer les variations d'encodage ──
    // Utilisé par l'endpoint /exercises/muscle/{muscleName}
    // Gère les cas où le nom du muscle est envoyé avec ou sans accents,
    // avec des espaces encodés (%20) ou des tirets (-).
    @Query("SELECT e FROM Exercise e WHERE " +
            "LOWER(e.muscleName) = LOWER(:muscleName) OR " +
            "LOWER(e.muscleName) LIKE LOWER(CONCAT('%', :muscleName, '%'))")
    List<Exercise> findByMuscleNameFlexible(@Param("muscleName") String muscleName);

    void deleteByMuscleName(String muscleName);
}