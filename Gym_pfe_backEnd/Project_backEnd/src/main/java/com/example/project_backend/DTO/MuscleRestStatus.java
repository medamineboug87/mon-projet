package com.example.project_backend.DTO;

public class MuscleRestStatus {

    private String muscleName;
    private String muscleGroup;      // PUSH, PULL, LEGS, CORE
    private boolean isAvailable;     // peut-on le retravailler ?
    private int hoursRequired;       // temps total de récupération
    private int hoursElapsed;        // temps déjà écoulé
    private int hoursRemaining;      // hoursRequired - hoursElapsed
    private String status;           // READY, RECOVERING, CRITICAL
    private String lastWorkedDate;
    private int lastIntensity;
    private double lastVolume;

    public String getMuscleName() { return muscleName; }
    public void setMuscleName(String muscleName) { this.muscleName = muscleName; }

    public String getMuscleGroup() { return muscleGroup; }
    public void setMuscleGroup(String muscleGroup) { this.muscleGroup = muscleGroup; }

    public boolean isAvailable() { return isAvailable; }
    public void setAvailable(boolean available) { isAvailable = available; }

    public int getHoursRequired() { return hoursRequired; }
    public void setHoursRequired(int hoursRequired) { this.hoursRequired = hoursRequired; }

    public int getHoursElapsed() { return hoursElapsed; }
    public void setHoursElapsed(int hoursElapsed) { this.hoursElapsed = hoursElapsed; }

    public int getHoursRemaining() { return hoursRemaining; }
    public void setHoursRemaining(int hoursRemaining) { this.hoursRemaining = hoursRemaining; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getLastWorkedDate() { return lastWorkedDate; }
    public void setLastWorkedDate(String lastWorkedDate) { this.lastWorkedDate = lastWorkedDate; }

    public int getLastIntensity() { return lastIntensity; }
    public void setLastIntensity(int lastIntensity) { this.lastIntensity = lastIntensity; }

    public double getLastVolume() { return lastVolume; }
    public void setLastVolume(double lastVolume) { this.lastVolume = lastVolume; }
}
