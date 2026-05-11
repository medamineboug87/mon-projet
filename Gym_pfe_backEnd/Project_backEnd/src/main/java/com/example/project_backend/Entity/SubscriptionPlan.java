package com.example.project_backend.Entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "subscription_plans")
public class SubscriptionPlan {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String name; // ex: "BASIC", "AUTUMN", "VIP_SUMMER"

    @Column(nullable = false)
    private String displayName; // ex: "Basic", "Offre Automne", "VIP Été"

    private String description;

    @Column(nullable = false)
    private double price;

    @Column(nullable = false)
    private int duration; // en mois

    private boolean active = true; // peut être désactivé sans suppression

    private String color; // ex: "#FF5252" pour l'UI

    private String emoji; // ex: "🍂" pour l'UI

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @PrePersist
    public void prePersist() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    // ── Getters & Setters ──
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name.toUpperCase().replace(" ", "_"); }

    public String getDisplayName() { return displayName; }
    public void setDisplayName(String displayName) { this.displayName = displayName; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public double getPrice() { return price; }
    public void setPrice(double price) { this.price = price; }

    public int getDuration() { return duration; }
    public void setDuration(int duration) { this.duration = duration; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public String getColor() { return color; }
    public void setColor(String color) { this.color = color; }

    public String getEmoji() { return emoji; }
    public void setEmoji(String emoji) { this.emoji = emoji; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}