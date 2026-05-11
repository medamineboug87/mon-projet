package com.example.project_backend.DTO;
import jakarta.validation.constraints.NotBlank;

public class LoginRequest {
    @NotBlank
    private String identifier;

    public String getIdentifier() {
        return identifier;
    }

    public void setIdentifier(String identifier) {
        this.identifier = identifier;
    }

    @NotBlank
    private String password;



    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }
}
