package com.example.project_backend.Security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.security.Key;
import java.util.Date;

@Service
public class JwtService {

    // ✅ FIX #11 : clé lue depuis application.properties (plus de hardcode)
    @Value("${jwt.secret}")
    private String secret;

    private Key getKey() {
        // Assure que la clé fait au moins 32 caractères (256 bits pour HS256)
        byte[] keyBytes = secret.getBytes();
        if (keyBytes.length < 32) {
            throw new IllegalStateException("jwt.secret doit faire au moins 32 caractères");
        }

        return Keys.hmacShaKeyFor(keyBytes);
    }

    // Générer token (expiration 24h au lieu de 1h pour éviter les déconnexions fréquentes)
    public String generateToken(String username, String role) {
        return Jwts.builder()
                .setSubject(username)
                .claim("role", role)
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + 1000L * 60 * 60 * 24)) // 24h
                .signWith(getKey(), SignatureAlgorithm.HS256)
                .compact();
    }

    // Extraire username
    public String extractUsername(String token) {
        return getClaims(token).getSubject();
    }

    // Extraire role
    public String extractRole(String token) {
        return (String) getClaims(token).get("role");
    }

    // Vérifier si le token est expiré
    public boolean isTokenExpired(String token) {
        try {
            return getClaims(token).getExpiration().before(new Date());
        } catch (Exception e) {
            return true;
        }
    }

    // Parser le token
    private Claims getClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(getKey())
                .build()
                .parseClaimsJws(token)
                .getBody();
    }
}