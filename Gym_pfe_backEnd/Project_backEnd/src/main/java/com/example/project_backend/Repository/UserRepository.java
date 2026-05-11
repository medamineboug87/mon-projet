package com.example.project_backend.Repository;

import com.example.project_backend.Entity.Role;
import com.example.project_backend.Entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);
    boolean existsByUsername(String username);
    boolean existsByEmail(String email);
    boolean existsByPhone(String phone);

    // Login par email OU username OU téléphone
    @Query("SELECT u FROM User u WHERE u.username = :identifier OR u.email = :identifier OR u.phone = :identifier")
    Optional<User> findByIdentifier(String identifier);

    // Utilisé par AuthController pour trouver le coach assigné à un membre
    @Query("SELECT u FROM User u WHERE u.member.id = :memberId")
    Optional<User> findByMemberId(Long memberId);

    // Utilisé par AuthController pour trouver le premier coach disponible
    Optional<User> findFirstByRole(Role role);
}