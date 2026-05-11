package com.example.project_backend.Entity;

import jakarta.persistence.*;

@Entity
@Table(name = "exercises")
public class Exercise {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String muscleName;
    private String name;
    private String sets;
    private String reps;
    private String secondaryMuscles;
    private String description;
    private String difficulty; // Débutant, Intermédiaire, Avancé
    private int recoveryHours;

    @Column(length = 500)
    private String videoUrl; // URL de la vidéo de démonstration (YouTube, etc.)

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getMuscleName() { return muscleName; }
    public void setMuscleName(String muscleName) { this.muscleName = muscleName; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getSets() { return sets; }
    public void setSets(String sets) { this.sets = sets; }
    public String getReps() { return reps; }
    public void setReps(String reps) { this.reps = reps; }
    public String getSecondaryMuscles() { return secondaryMuscles; }
    public void setSecondaryMuscles(String secondaryMuscles) { this.secondaryMuscles = secondaryMuscles; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getDifficulty() { return difficulty; }
    public void setDifficulty(String difficulty) { this.difficulty = difficulty; }
    public int getRecoveryHours() { return recoveryHours; }
    public void setRecoveryHours(int recoveryHours) { this.recoveryHours = recoveryHours; }
    public String getVideoUrl() { return videoUrl; }
    public void setVideoUrl(String videoUrl) { this.videoUrl = videoUrl; }
}