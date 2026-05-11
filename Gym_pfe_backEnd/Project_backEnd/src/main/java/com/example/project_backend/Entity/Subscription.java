package com.example.project_backend.Entity;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

@Entity
@Table(name = "subscriptions")
public class Subscription {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String type;
    private double price;
    private int duration; // en mois
    private LocalDate startDate;
    private LocalDate endDate;

    private String status;
    private String paymentRef; // référence de paiement simulé

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    private Boolean autoRenew = true;

    @ManyToOne
    @JoinColumn(name = "member_id")
    private Member member;

    // ✅ FIX : null-safe — si endDate pas encore calculée, pas d'expiration
    public boolean isExpiringSoon() {
        if (endDate == null) return false;
        long days = ChronoUnit.DAYS.between(LocalDate.now(), endDate);
        return days >= 0 && days <= 7;
    }

    // ✅ FIX : null-safe
    public boolean isExpired() {
        if (endDate == null) return false;
        return LocalDate.now().isAfter(endDate);
    }

    public void renew() {
        if (endDate == null) {
            this.endDate = LocalDate.now().plusMonths(duration);
        } else {
            this.endDate = this.endDate.plusMonths(duration);
        }
        this.startDate = LocalDate.now();
        this.status = "ACTIVE";
    }

    // ===== Getters & Setters =====
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public double getPrice() { return price; }
    public void setPrice(double price) { this.price = price; }
    public int getDuration() { return duration; }
    public void setDuration(int duration) { this.duration = duration; }
    public LocalDate getStartDate() { return startDate; }
    public void setStartDate(LocalDate startDate) { this.startDate = startDate; }
    public LocalDate getEndDate() { return endDate; }
    public void setEndDate(LocalDate endDate) { this.endDate = endDate; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public Member getMember() { return member; }
    public void setMember(Member member) { this.member = member; }
    public String getPaymentRef() { return paymentRef; }
    public void setPaymentRef(String paymentRef) { this.paymentRef = paymentRef; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
    public Boolean getAutoRenew() { return autoRenew; }
    public void setAutoRenew(Boolean autoRenew) { this.autoRenew = autoRenew; }
}