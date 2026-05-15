package com.example.project_backend.Security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;

@Configuration
public class SecurityConfig {

    private final JwtFilter jwtFilter;

    public SecurityConfig(JwtFilter jwtFilter) {
        this.jwtFilter = jwtFilter;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {

        http
                .csrf(csrf -> csrf.disable())

                .cors(cors -> cors.configurationSource(request -> {
                    CorsConfiguration config = new CorsConfiguration();
                    config.addAllowedOriginPattern("*");
                    config.addAllowedHeader("*");
                    config.addAllowedMethod("*");
                    config.setAllowCredentials(false);
                    return config;
                }))

                .sessionManagement(session ->
                        session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                )

                .authorizeHttpRequests(auth -> auth
                        // ── Public (accessible sans authentification) ──
                        .requestMatchers("/auth/**").permitAll()
                        .requestMatchers("/admin/plans/active").permitAll()
                        .requestMatchers("/api/ai/health").permitAll()  // ✅ AJOUTER CETTE LIGNE
                        .requestMatchers("/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html").permitAll()

                        // ── Admin uniquement ──
                        .requestMatchers("/admin/**").hasRole("ADMIN")

                        // ── Coach et Admin ──
                        .requestMatchers("/coaches/**").hasAnyRole("COACH", "ADMIN")

                        // ── Membres authentifiés (MEMBER, COACH, ADMIN) ──
                        .requestMatchers("/members/**").authenticated()
                        .requestMatchers("/sessions/**").authenticated()
                        .requestMatchers("/subscriptions/**").authenticated()
                        .requestMatchers("/messages/**").authenticated()
                        .requestMatchers("/admin/subscriptions/**").hasRole("ADMIN")
                        .requestMatchers("/admin/exercises/**").hasRole("ADMIN")
                        .requestMatchers("/exercises/**").authenticated()
                        .requestMatchers("/payments/**").authenticated()
                        .requestMatchers("/api/ai/**").authenticated()  // ← sauf health

                        // ── Tout le reste nécessite une authentification ──
                        .anyRequest().authenticated()
                )

                .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }
}