package com.example.project_backend.Repository;

import com.example.project_backend.Entity.Message;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Repository
public interface MessageRepository extends JpaRepository<Message, Long> {

    // ── Conversation membre ↔ coach (avec member_id) ──
    List<Message> findByMemberIdOrderBySentAtAsc(Long memberId);

    // ── Messages non lus pour un receiver ──
    List<Message> findByReceiverIdAndIsReadFalse(Long receiverId);

    // ── Compter tous les non lus (toutes sources) ──
    long countByReceiverIdAndIsReadFalse(Long receiverId);

    // ── Compter non lus venant du coach uniquement ──
    @Query("""
        SELECT COUNT(m) FROM Message m
        WHERE m.receiver.id = :receiverId
          AND m.isRead = false
          AND m.member IS NOT NULL
        """)
    long countUnreadFromCoach(Long receiverId);

    // ── Compter non lus venant de l'admin uniquement ──
    @Query("""
        SELECT COUNT(m) FROM Message m
        WHERE m.receiver.id = :receiverId
          AND m.isRead = false
          AND m.member IS NULL
        """)
    long countUnreadFromAdmin(Long receiverId);

    // ── Suppressions ──
    @Modifying
    @Transactional
    @Query("DELETE FROM Message m WHERE m.member.id = :memberId")
    void deleteByMemberId(Long memberId);

    @Modifying
    @Transactional
    @Query("DELETE FROM Message m WHERE m.sender.id = :senderId")
    void deleteBySenderId(Long senderId);

    @Modifying
    @Transactional
    @Query("DELETE FROM Message m WHERE m.receiver.id = :receiverId")
    void deleteByReceiverId(Long receiverId);

    // ── Messages admin ↔ user spécifique (sans member) ──
    @Query("""
        SELECT m FROM Message m
        WHERE m.member IS NULL
          AND (m.sender.id = :userId OR m.receiver.id = :userId)
        ORDER BY m.sentAt ASC
        """)
    List<Message> findAdminConversationWithUser(Long userId);

    // ── Historique broadcasts ──
    @Query("SELECT m FROM Message m WHERE m.content LIKE '[📢 Annonce]%' ORDER BY m.sentAt DESC")
    List<Message> findBroadcastMessages();
}