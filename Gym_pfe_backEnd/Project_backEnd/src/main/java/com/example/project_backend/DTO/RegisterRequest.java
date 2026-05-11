package com.example.project_backend.DTO;

import com.example.project_backend.Entity.Role;

public class RegisterRequest {
    private String username;
    private String password;
    private Role role;
    private Long memberId;

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public Role getRole() { return role; }
    public void setRole(Role role) { this.role = role; }
    public Long getMemberId() { return memberId; }
    public void setMemberId(Long memberId) { this.memberId = memberId; }
}