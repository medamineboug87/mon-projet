package com.example.project_backend.Entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "messages")
public class Message {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String content;

    private LocalDateTime sentAt;

    private Boolean isRead = false;

    // Expéditeur
    @ManyToOne
    @JoinColumn(name = "sender_id")
    private User sender;

    // Destinataire
    @ManyToOne
    @JoinColumn(name = "receiver_id")
    private User receiver;

    // Lié à quel membre (pour filtrer les messages d'un membre)
    @ManyToOne
    @JoinColumn(name = "member_id")
    private Member member;

    @PrePersist
    public void prePersist() {
        this.sentAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public LocalDateTime getSentAt() { return sentAt; }
    public void setSentAt(LocalDateTime sentAt) { this.sentAt = sentAt; }
    public Boolean getIsRead() { return isRead; }
    public void setIsRead(Boolean isRead) { this.isRead = isRead; }
    public User getSender() { return sender; }
    public void setSender(User sender) { this.sender = sender; }
    public User getReceiver() { return receiver; }
    public void setReceiver(User receiver) { this.receiver = receiver; }
    public Member getMember() { return member; }
    public void setMember(Member member) { this.member = member; }
}