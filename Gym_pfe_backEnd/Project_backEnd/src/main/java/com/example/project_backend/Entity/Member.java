package com.example.project_backend.Entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import java.time.LocalDate;
import java.util.List;

@Entity
@Table(name="members")
public class Member {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String fullName;
    private int age;
    private String gender;
    private String email;
    private String phone;

    // Getters & Setters
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }



    private double weight;
    private double height;
    private LocalDate registrationDate;

    // Un membre peut avoir plusieurs abonnements (historique)
    @OneToMany(mappedBy = "member", cascade = CascadeType.ALL)
    @JsonIgnore // pour éviter boucle infinie dans JSON/Swagger
    private List<Subscription> subscriptions;

    // Un membre peut avoir plusieurs séances
    @OneToMany(mappedBy = "member", cascade = CascadeType.ALL)
    @JsonIgnore
    private List<TrainingSession> sessions;

    // ===== Getters =====
    public Long getId() { return id; }
    public String getFullName() { return fullName; }
    public int getAge() { return age; }
    public double getWeight() { return weight; }
    public double getHeight() { return height; }
    public LocalDate getRegistrationDate() { return registrationDate; }
    public List<Subscription> getSubscriptions() { return subscriptions; }
    public List<TrainingSession> getSessions() { return sessions; }

    // ===== Setters =====
    public void setId(Long id) { this.id = id; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public void setAge(int age) { this.age = age; }
    public void setWeight(double weight) { this.weight = weight; }
    public void setHeight(double height) { this.height = height; }
    public void setRegistrationDate(LocalDate registrationDate) { this.registrationDate = registrationDate; }
    public void setSubscriptions(List<Subscription> subscriptions) { this.subscriptions = subscriptions; }
    public void setSessions(List<TrainingSession> sessions) { this.sessions = sessions; }
    public String getGender() {
        return gender;
    }

    public void setGender(String gender) {
        this.gender = gender;
    }
}