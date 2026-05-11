package com.example.project_backend.Service;

import com.example.project_backend.Entity.Member;
import com.example.project_backend.Entity.MemberProfile;
import com.example.project_backend.Repository.MemberProfileRepository;
import com.example.project_backend.Repository.MemberRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;

@Service
public class MemberProfileService {

    private final MemberProfileRepository profileRepository;
    private final MemberRepository memberRepository;

    public MemberProfileService(MemberProfileRepository profileRepository,
                                MemberRepository memberRepository) {
        this.profileRepository = profileRepository;
        this.memberRepository  = memberRepository;
    }

    // ── GET profil IA (crée un profil vide si inexistant) ──
    @Transactional
    public MemberProfile getOrCreateProfile(Long memberId) {
        return profileRepository.findByMemberId(memberId)
                .orElseGet(() -> {
                    Member member = memberRepository.findById(memberId)
                            .orElseThrow(() -> new RuntimeException("Member not found: " + memberId));
                    MemberProfile profile = new MemberProfile();
                    profile.setMember(member);
                    return profileRepository.save(profile);
                });
    }

    // ── GET profil (null si inexistant) ──
    public Optional<MemberProfile> getProfile(Long memberId) {
        return profileRepository.findByMemberId(memberId);
    }

    // ── CREATE ou UPDATE profil ──
    @Transactional
    public MemberProfile saveProfile(Long memberId, Map<String, Object> data) {
        MemberProfile profile = getOrCreateProfile(memberId);
        applyData(profile, data);
        profile.setUpdatedAt(LocalDateTime.now());
        return profileRepository.save(profile);
    }

    // ── DELETE profil ──
    @Transactional
    public void deleteProfile(Long memberId) {
        profileRepository.deleteByMemberId(memberId);
    }

    // ─────────────────────────────────────────────
    // HELPER : Applique les champs de la requête sur l'entité
    // ─────────────────────────────────────────────
    private void applyData(MemberProfile profile, Map<String, Object> data) {

        if (data.containsKey("primaryGoal") && data.get("primaryGoal") != null) {
            profile.setPrimaryGoal(
                    MemberProfile.FitnessGoal.valueOf((String) data.get("primaryGoal")));
        }
        if (data.containsKey("secondaryGoal")) {
            String sg = (String) data.get("secondaryGoal");
            profile.setSecondaryGoal(sg != null && !sg.isBlank()
                    ? MemberProfile.FitnessGoal.valueOf(sg) : null);
        }
        if (data.containsKey("selfDeclaredLevel") && data.get("selfDeclaredLevel") != null) {
            profile.setSelfDeclaredLevel(
                    MemberProfile.FitnessLevel.valueOf((String) data.get("selfDeclaredLevel")));
        }
        if (data.containsKey("yearsOfExperience") && data.get("yearsOfExperience") != null) {
            profile.setYearsOfExperience(((Number) data.get("yearsOfExperience")).intValue());
        }
        if (data.containsKey("medicalConditions")) {
            profile.setMedicalConditions((String) data.get("medicalConditions"));
        }
        if (data.containsKey("allergiesContraindications")) {
            profile.setAllergiesContraindications((String) data.get("allergiesContraindications"));
        }
        if (data.containsKey("currentMedications")) {
            profile.setCurrentMedications((String) data.get("currentMedications"));
        }
        if (data.containsKey("hasMedicalFollowUp") && data.get("hasMedicalFollowUp") != null) {
            profile.setHasMedicalFollowUp((Boolean) data.get("hasMedicalFollowUp"));
        }
        if (data.containsKey("medicalFollowUpDetail")) {
            profile.setMedicalFollowUpDetail((String) data.get("medicalFollowUpDetail"));
        }
        if (data.containsKey("injuryHistory")) {
            profile.setInjuryHistory((String) data.get("injuryHistory"));
        }
        if (data.containsKey("currentInjuries")) {
            profile.setCurrentInjuries((String) data.get("currentInjuries"));
        }
        if (data.containsKey("surgicalHistory")) {
            profile.setSurgicalHistory((String) data.get("surgicalHistory"));
        }
        if (data.containsKey("chronicPainZones")) {
            profile.setChronicPainZones((String) data.get("chronicPainZones"));
        }
        if (data.containsKey("chronicPainIntensity") && data.get("chronicPainIntensity") != null) {
            profile.setChronicPainIntensity(((Number) data.get("chronicPainIntensity")).intValue());
        }
        if (data.containsKey("avgSleepHours") && data.get("avgSleepHours") != null) {
            profile.setAvgSleepHours(((Number) data.get("avgSleepHours")).doubleValue());
        }
        if (data.containsKey("stressLevel") && data.get("stressLevel") != null) {
            profile.setStressLevel(((Number) data.get("stressLevel")).intValue());
        }
        if (data.containsKey("outsideGymActivity")) {
            profile.setOutsideGymActivity((String) data.get("outsideGymActivity"));
        }
        if (data.containsKey("dietType")) {
            profile.setDietType((String) data.get("dietType"));
        }
        if (data.containsKey("dailyWaterIntake") && data.get("dailyWaterIntake") != null) {
            profile.setDailyWaterIntake(((Number) data.get("dailyWaterIntake")).doubleValue());
        }
        if (data.containsKey("exerciseRestrictions")) {
            profile.setExerciseRestrictions((String) data.get("exerciseRestrictions"));
        }
    }

    // ─────────────────────────────────────────────
    // MÉTHODE UTILITAIRE : sérialiser en Map pour l'API et l'IA
    // Utilisée par AIService pour enrichir les prédictions
    // ─────────────────────────────────────────────
    public Map<String, Object> toMap(MemberProfile p) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id",                          p.getId());
        m.put("primaryGoal",                 p.getPrimaryGoal() != null ? p.getPrimaryGoal().name() : null);
        m.put("primaryGoalLabel",            goalLabel(p.getPrimaryGoal()));
        m.put("secondaryGoal",               p.getSecondaryGoal() != null ? p.getSecondaryGoal().name() : null);
        m.put("selfDeclaredLevel",           p.getSelfDeclaredLevel() != null ? p.getSelfDeclaredLevel().name() : null);
        m.put("selfDeclaredLevelLabel",      levelLabel(p.getSelfDeclaredLevel()));
        m.put("yearsOfExperience",           p.getYearsOfExperience());
        m.put("medicalConditions",           p.getMedicalConditions());
        m.put("allergiesContraindications",  p.getAllergiesContraindications());
        m.put("currentMedications",          p.getCurrentMedications());
        m.put("hasMedicalFollowUp",          p.getHasMedicalFollowUp());
        m.put("medicalFollowUpDetail",       p.getMedicalFollowUpDetail());
        m.put("injuryHistory",               p.getInjuryHistory());
        m.put("currentInjuries",             p.getCurrentInjuries());
        m.put("surgicalHistory",             p.getSurgicalHistory());
        m.put("chronicPainZones",            p.getChronicPainZones());
        m.put("chronicPainIntensity",        p.getChronicPainIntensity());
        m.put("avgSleepHours",               p.getAvgSleepHours());
        m.put("stressLevel",                 p.getStressLevel());
        m.put("outsideGymActivity",          p.getOutsideGymActivity());
        m.put("dietType",                    p.getDietType());
        m.put("dailyWaterIntake",            p.getDailyWaterIntake());
        m.put("exerciseRestrictions",        p.getExerciseRestrictions());
        m.put("isComplete",                  p.getIsComplete());
        m.put("createdAt",                   p.getCreatedAt());
        m.put("updatedAt",                   p.getUpdatedAt());

        // ── Champs calculés pour l'IA ──
        m.put("hasChroniPain",               hasChroniPain(p));
        m.put("hasCurrentInjury",            p.getCurrentInjuries() != null && !p.getCurrentInjuries().isBlank());
        m.put("hasSurgicalHistory",          p.getSurgicalHistory() != null && !p.getSurgicalHistory().isBlank());
        m.put("isHighStress",                p.getStressLevel() != null && p.getStressLevel() >= 7);
        m.put("isPoorSleeper",               p.getAvgSleepHours() != null && p.getAvgSleepHours() < 6.0);
        m.put("goalRiskMultiplier",          goalRiskMultiplier(p.getPrimaryGoal()));
        m.put("chronicPainRiskMultiplier",   chronicPainRiskMultiplier(p));
        m.put("recoveryMultiplier",          recoveryMultiplier(p));

        return m;
    }

    // ── Multiplicateur de risque selon l'objectif ──
    // Un objectif "performance" ou "muscle_gain" pousse à l'effort extrême → plus de risques
    public double goalRiskMultiplier(MemberProfile.FitnessGoal goal) {
        if (goal == null) return 1.0;
        return switch (goal) {
            case PERFORMANCE    -> 1.3;
            case MUSCLE_GAIN    -> 1.15;
            case ENDURANCE      -> 1.1;
            case REHABILITATION -> 0.7;  // Rééducation : on protège
            case WEIGHT_LOSS    -> 1.0;
            case TONING         -> 0.9;
            case GENERAL_FITNESS -> 1.0;
        };
    }

    // ── Multiplicateur de récupération selon style de vie ──
    // Mauvais sommeil + stress élevé = récupération ralentie
    public double recoveryMultiplier(MemberProfile p) {
        double mult = 1.0;
        if (p.getAvgSleepHours() != null && p.getAvgSleepHours() < 6.0) mult += 0.3;
        else if (p.getAvgSleepHours() != null && p.getAvgSleepHours() < 7.0) mult += 0.15;
        if (p.getStressLevel() != null && p.getStressLevel() >= 8) mult += 0.25;
        else if (p.getStressLevel() != null && p.getStressLevel() >= 6) mult += 0.1;
        return Math.min(2.0, mult);
    }

    // ── Multiplicateur de risque selon douleurs chroniques ──
    public double chronicPainRiskMultiplier(MemberProfile p) {
        if (!hasChroniPain(p)) return 1.0;
        int intensity = p.getChronicPainIntensity() != null ? p.getChronicPainIntensity() : 0;
        if (intensity >= 7) return 1.4;
        if (intensity >= 4) return 1.2;
        return 1.1;
    }

    private boolean hasChroniPain(MemberProfile p) {
        return p.getChronicPainZones() != null
                && !p.getChronicPainZones().isBlank()
                && !p.getChronicPainZones().equalsIgnoreCase("NONE");
    }

    private String goalLabel(MemberProfile.FitnessGoal g) {
        if (g == null) return "Non défini";
        return switch (g) {
            case WEIGHT_LOSS     -> "Perte de poids";
            case MUSCLE_GAIN     -> "Prise de masse";
            case ENDURANCE       -> "Endurance";
            case TONING          -> "Tonification";
            case GENERAL_FITNESS -> "Bien-être général";
            case REHABILITATION  -> "Rééducation";
            case PERFORMANCE     -> "Performance sportive";
        };
    }

    private String levelLabel(MemberProfile.FitnessLevel l) {
        if (l == null) return "Non défini";
        return switch (l) {
            case BEGINNER     -> "Débutant";
            case INTERMEDIATE -> "Intermédiaire";
            case ADVANCED     -> "Avancé";
            case ATHLETE      -> "Athlète";
        };
    }
}
