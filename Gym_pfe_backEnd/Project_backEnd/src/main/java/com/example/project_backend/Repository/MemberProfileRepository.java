package com.example.project_backend.Repository;

import com.example.project_backend.Entity.MemberProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface MemberProfileRepository extends JpaRepository<MemberProfile, Long> {

    /** Trouver le profil IA d'un membre par son ID. */
    Optional<MemberProfile> findByMemberId(Long memberId);

    /** Vérifie si un profil existe déjà pour ce membre. */
    boolean existsByMemberId(Long memberId);

    /** Supprimer le profil quand le membre est supprimé. */
    void deleteByMemberId(Long memberId);
}
