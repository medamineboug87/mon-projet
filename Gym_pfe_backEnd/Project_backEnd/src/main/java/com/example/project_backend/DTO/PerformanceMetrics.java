package com.example.project_backend.DTO;

public class PerformanceMetrics {

    private double bmi;
    private int sessionsPerWeek;
    private double averageIntensity;
    private double averageWeightLifted;
    private double performanceScore;
    private String injuryRisk;
    private String recommendation;

    public PerformanceMetrics(double bmi,
                              int sessionsPerWeek,
                              double averageIntensity,
                              double averageWeightLifted,
                              double performanceScore,
                              String injuryRisk,
                              String recommendation) {
        this.bmi = bmi;
        this.sessionsPerWeek = sessionsPerWeek;
        this.averageIntensity = averageIntensity;
        this.averageWeightLifted = averageWeightLifted;
        this.performanceScore = performanceScore;
        this.injuryRisk = injuryRisk;
        this.recommendation = recommendation;
    }

    public double getBmi() { return bmi; }
    public int getSessionsPerWeek() { return sessionsPerWeek; }
    public double getAverageIntensity() { return averageIntensity; }
    public double getAverageWeightLifted() { return averageWeightLifted; }
    public double getPerformanceScore() { return performanceScore; }
    public String getInjuryRisk() { return injuryRisk; }
    public String getRecommendation() { return recommendation; }
}
