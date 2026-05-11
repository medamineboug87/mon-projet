package com.example.project_backend.Entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;

@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String username;

    @Column(nullable = false)
    @JsonIgnore
    private String password;

    @Enumerated(EnumType.STRING)
    private Role role;

    @Column(unique = true)
    private String email;

    @Column(unique = true)
    private String phone;

    // Lien vers le membre (null si coach ou admin)
    @OneToOne
    @JoinColumn(name = "member_id")
    @JsonIgnore
    private Member member;

    // Lien vers le coach (null si membre ou admin)
    @OneToOne
    @JoinColumn(name = "coach_id")
    @JsonIgnore
    private Coach coach;

    // ── Getters & Setters ──
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public Role getRole() { return role; }
    public void setRole(Role role) { this.role = role; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    public Member getMember() { return member; }
    public void setMember(Member member) { this.member = member; }
    public Coach getCoach() { return coach; }
    public void setCoach(Coach coach) { this.coach = coach; }
}