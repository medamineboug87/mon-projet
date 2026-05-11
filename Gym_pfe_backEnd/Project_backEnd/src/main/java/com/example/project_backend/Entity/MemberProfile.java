package com.example.project_backend.Entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Profil médical et sportif étendu d'un membre.
 * Niveau 3 — Nouvelle entité (relation One-to-One avec Member).
 */
@Entity
@Table(name = "member_profiles")
public class MemberProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // ── Relation 1-1 avec Member ──
    @OneToOne
    @JoinColumn(name = "member_id", nullable = false, unique = true)
    private Member member;

    // ─────────────────────────────────────────────
    // OBJECTIF PRINCIPAL
    // Valeurs : WEIGHT_LOSS | MUSCLE_GAIN | ENDURANCE | TONING | GENERAL_FITNESS
    // ─────────────────────────────────────────────
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private FitnessGoal primaryGoal = FitnessGoal.GENERAL_FITNESS;

    // Objectif secondaire (optionnel)
    @Enumerated(EnumType.STRING)
    private FitnessGoal secondaryGoal;

    // ─────────────────────────────────────────────
    // NIVEAU DÉCLARÉ PAR LE MEMBRE
    // Valeurs : BEGINNER | INTERMEDIATE | ADVANCED | ATHLETE
    // ─────────────────────────────────────────────
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private FitnessLevel selfDeclaredLevel = FitnessLevel.BEGINNER;

    // Années d'expérience sportive déclarées
    private Integer yearsOfExperience = 0;

    // ─────────────────────────────────────────────
    // ANTÉCÉDENTS MÉDICAUX (texte libre + champs structurés)
    // ─────────────────────────────────────────────

    // Conditions médicales générales (ex: "diabète type 2, hypertension")
    @Column(length = 1000)
    private String medicalConditions;

    // Allergies ou contre-indications (ex: "allergie aux latex, asthme d'effort")
    @Column(length = 500)
    private String allergiesContraindications;

    // Médicaments en cours (optionnel, peut influencer l'effort)
    @Column(length = 500)
    private String currentMedications;

    // Suivi médical actif (cardiologue, kiné, etc.)
    private Boolean hasMedicalFollowUp = false;

    @Column(length = 200)
    private String medicalFollowUpDetail;

    // ─────────────────────────────────────────────
    // BLESSURES PASSÉES
    // ─────────────────────────────────────────────

    // Historique des blessures (ex: "entorse genou 2021, déchirure épaule droite 2023")
    @Column(length = 1000)
    private String injuryHistory;

    // Blessures actuelles / en cours de rééducation
    @Column(length = 500)
    private String currentInjuries;

    // Opérations chirurgicales liées au sport ou à la mobilité
    @Column(length = 500)
    private String surgicalHistory;

    // ─────────────────────────────────────────────
    // ZONES DE DOULEUR CHRONIQUE
    // Stockées comme liste de zones séparées par virgules
    // Valeurs possibles : NECK | LOWER_BACK | UPPER_BACK | LEFT_SHOULDER |
    //   RIGHT_SHOULDER | LEFT_KNEE | RIGHT_KNEE | LEFT_ANKLE | RIGHT_ANKLE |
    //   LEFT_HIP | RIGHT_HIP | LEFT_ELBOW | RIGHT_ELBOW | WRISTS | NONE
    // ─────────────────────────────────────────────
    @Column(length = 500)
    private String chronicPainZones; // ex: "LOWER_BACK,LEFT_KNEE"

    // Intensité moyenne de la douleur chronique (0-10, 0 = aucune)
    private Integer chronicPainIntensity = 0;

    // ─────────────────────────────────────────────
    // STYLE DE VIE & RÉCUPÉRATION
    // ─────────────────────────────────────────────

    // Heures de sommeil moyennes par nuit (influencent la récupération IA)
    private Double avgSleepHours = 7.0;

    // Niveau de stress chronique déclaré (1=très faible, 10=très élevé)
    private Integer stressLevel = 5;

    // Activité physique hors salle (ex: "marche quotidienne, vélo domicile-travail")
    @Column(length = 300)
    private String outsideGymActivity;

    // Régime alimentaire (ex: "omnivore", "végétarien", "keto")
    @Column(length = 100)
    private String dietType;

    // Hydratation (litres/jour) — influence la récupération
    private Double dailyWaterIntake = 1.5;

    // ─────────────────────────────────────────────
    // RESTRICTIONS D'EXERCICES
    // Exercices ou mouvements à éviter absolument (médical ou blessure)
    // ─────────────────────────────────────────────
    @Column(length = 500)
    private String exerciseRestrictions; // ex: "squats lourds, développé nuque"

    // ─────────────────────────────────────────────
    // MÉTADONNÉES
    // ─────────────────────────────────────────────
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Profil complet (true = toutes les infos importantes ont été remplies)
    private Boolean isComplete = false;

    @PrePersist
    public void prePersist() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDateTime.now();
        this.isComplete = computeIsComplete();
    }

    /**
     * Le profil est considéré "complet" si les champs essentiels sont renseignés.
     */
    private boolean computeIsComplete() {
        return primaryGoal != null
                && selfDeclaredLevel != null
                && chronicPainZones != null
                && avgSleepHours != null;
    }

    // ─────────────────────────────────────────────
    // ÉNUMÉRATIONS
    // ─────────────────────────────────────────────

    public enum FitnessGoal {
        WEIGHT_LOSS,        // Perte de poids
        MUSCLE_GAIN,        // Prise de masse musculaire
        ENDURANCE,          // Amélioration de l'endurance cardiovasculaire
        TONING,             // Tonification / remodelage corporel
        GENERAL_FITNESS,    // Bien-être général
        REHABILITATION,     // Rééducation / récupération post-blessure
        PERFORMANCE         // Performance sportive compétitive
    }

    public enum FitnessLevel {
        BEGINNER,       // Débutant (0-1 an d'expérience)
        INTERMEDIATE,   // Intermédiaire (1-3 ans)
        ADVANCED,       // Avancé (3-5 ans)
        ATHLETE         // Athlète / compétiteur (5+ ans)
    }

    // ─────────────────────────────────────────────
    // GETTERS & SETTERS
    // ─────────────────────────────────────────────

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Member getMember() { return member; }
    public void setMember(Member member) { this.member = member; }

    public FitnessGoal getPrimaryGoal() { return primaryGoal; }
    public void setPrimaryGoal(FitnessGoal primaryGoal) { this.primaryGoal = primaryGoal; }

    public FitnessGoal getSecondaryGoal() { return secondaryGoal; }
    public void setSecondaryGoal(FitnessGoal secondaryGoal) { this.secondaryGoal = secondaryGoal; }

    public FitnessLevel getSelfDeclaredLevel() { return selfDeclaredLevel; }
    public void setSelfDeclaredLevel(FitnessLevel selfDeclaredLevel) { this.selfDeclaredLevel = selfDeclaredLevel; }

    public Integer getYearsOfExperience() { return yearsOfExperience; }
    public void setYearsOfExperience(Integer yearsOfExperience) { this.yearsOfExperience = yearsOfExperience; }

    public String getMedicalConditions() { return medicalConditions; }
    public void setMedicalConditions(String medicalConditions) { this.medicalConditions = medicalConditions; }

    public String getAllergiesContraindications() { return allergiesContraindications; }
    public void setAllergiesContraindications(String allergiesContraindications) { this.allergiesContraindications = allergiesContraindications; }

    public String getCurrentMedications() { return currentMedications; }
    public void setCurrentMedications(String currentMedications) { this.currentMedications = currentMedications; }

    public Boolean getHasMedicalFollowUp() { return hasMedicalFollowUp; }
    public void setHasMedicalFollowUp(Boolean hasMedicalFollowUp) { this.hasMedicalFollowUp = hasMedicalFollowUp; }

    public String getMedicalFollowUpDetail() { return medicalFollowUpDetail; }
    public void setMedicalFollowUpDetail(String medicalFollowUpDetail) { this.medicalFollowUpDetail = medicalFollowUpDetail; }

    public String getInjuryHistory() { return injuryHistory; }
    public void setInjuryHistory(String injuryHistory) { this.injuryHistory = injuryHistory; }

    public String getCurrentInjuries() { return currentInjuries; }
    public void setCurrentInjuries(String currentInjuries) { this.currentInjuries = currentInjuries; }

    public String getSurgicalHistory() { return surgicalHistory; }
    public void setSurgicalHistory(String surgicalHistory) { this.surgicalHistory = surgicalHistory; }

    public String getChronicPainZones() { return chronicPainZones; }
    public void setChronicPainZones(String chronicPainZones) { this.chronicPainZones = chronicPainZones; }

    public Integer getChronicPainIntensity() { return chronicPainIntensity; }
    public void setChronicPainIntensity(Integer chronicPainIntensity) { this.chronicPainIntensity = chronicPainIntensity; }

    public Double getAvgSleepHours() { return avgSleepHours; }
    public void setAvgSleepHours(Double avgSleepHours) { this.avgSleepHours = avgSleepHours; }

    public Integer getStressLevel() { return stressLevel; }
    public void setStressLevel(Integer stressLevel) { this.stressLevel = stressLevel; }

    public String getOutsideGymActivity() { return outsideGymActivity; }
    public void setOutsideGymActivity(String outsideGymActivity) { this.outsideGymActivity = outsideGymActivity; }

    public String getDietType() { return dietType; }
    public void setDietType(String dietType) { this.dietType = dietType; }

    public Double getDailyWaterIntake() { return dailyWaterIntake; }
    public void setDailyWaterIntake(Double dailyWaterIntake) { this.dailyWaterIntake = dailyWaterIntake; }

    public String getExerciseRestrictions() { return exerciseRestrictions; }
    public void setExerciseRestrictions(String exerciseRestrictions) { this.exerciseRestrictions = exerciseRestrictions; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    public Boolean getIsComplete() { return isComplete; }
    public void setIsComplete(Boolean isComplete) { this.isComplete = isComplete; }
}
