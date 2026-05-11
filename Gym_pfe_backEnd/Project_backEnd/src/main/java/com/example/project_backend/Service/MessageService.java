package com.example.project_backend.Service;

import com.example.project_backend.Entity.Member;
import com.example.project_backend.Entity.Message;
import com.example.project_backend.Entity.Role;
import com.example.project_backend.Entity.User;
import com.example.project_backend.Repository.MemberRepository;
import com.example.project_backend.Repository.MessageRepository;
import com.example.project_backend.Repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class MessageService {

    private final MessageRepository messageRepository;
    private final UserRepository    userRepository;
    private final MemberRepository  memberRepository;

    public MessageService(MessageRepository messageRepository,
                          UserRepository userRepository,
                          MemberRepository memberRepository) {
        this.messageRepository = messageRepository;
        this.userRepository    = userRepository;
        this.memberRepository  = memberRepository;
    }

    // ════════════════════════════════════════════════════════
    // MESSAGES MEMBRE ↔ COACH  (avec member_id)
    // ════════════════════════════════════════════════════════

    public Message sendMessage(String senderUsername,
                               String receiverUsername,
                               Long memberId,
                               String content) {

        User sender   = findUser(senderUsername);
        User receiver = findUser(receiverUsername);
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new RuntimeException("Member not found"));

        Message message = new Message();
        message.setSender(sender);
        message.setReceiver(receiver);
        message.setMember(member);
        message.setContent(content);
        message.setIsRead(false);

        return messageRepository.save(message);
    }

    public List<Message> getMemberMessages(Long memberId) {
        return messageRepository.findByMemberIdOrderBySentAtAsc(memberId);
    }

    public void markAsRead(Long memberId, String username) {
        User user = findUser(username);
        List<Message> unread = messageRepository
                .findByReceiverIdAndIsReadFalse(user.getId());

        for (Message msg : unread) {
            // Sécurité null : messages admin n'ont pas de member
            if (msg.getMember() != null &&
                    msg.getMember().getId().equals(memberId)) {
                msg.setIsRead(true);
                messageRepository.save(msg);
            }
        }
    }

    // Compteur global (toutes sources confondues)
    public long countUnreadMessages(String username) {
        User user = findUser(username);
        return messageRepository.countByReceiverIdAndIsReadFalse(user.getId());
    }

    // ── Compteur séparé : messages non lus du coach uniquement ──
    public long countUnreadFromCoach(String username) {
        User user = findUser(username);
        return messageRepository.countUnreadFromCoach(user.getId());
    }

    // ── Compteur séparé : messages non lus de l'admin uniquement ──
    public long countUnreadFromAdmin(String username) {
        User user = findUser(username);
        return messageRepository.countUnreadFromAdmin(user.getId());
    }

    // ════════════════════════════════════════════════════════
    // MESSAGES ADMIN (sans member_id)
    // ════════════════════════════════════════════════════════

    public Message sendAdminMessage(String senderUsername,
                                    String receiverUsername,
                                    String content) {
        User sender   = findUser(senderUsername);
        User receiver = findUser(receiverUsername);

        Message message = new Message();
        message.setSender(sender);
        message.setReceiver(receiver);
        message.setMember(null); // pas de membre lié pour les messages admin
        message.setContent(content);
        message.setIsRead(false);

        return messageRepository.save(message);
    }

    public int broadcastToMembers(String adminUsername, String content) {
        User admin = findUser(adminUsername);
        List<User> members = userRepository.findAll().stream()
                .filter(u -> u.getRole() == Role.MEMBER)
                .toList();

        for (User member : members) {
            Message msg = new Message();
            msg.setSender(admin);
            msg.setReceiver(member);
            msg.setMember(null);
            msg.setContent("[📢 Annonce] " + content);
            msg.setIsRead(false);
            messageRepository.save(msg);
        }
        return members.size();
    }

    public int broadcastToCoaches(String adminUsername, String content) {
        User admin = findUser(adminUsername);
        List<User> coaches = userRepository.findAll().stream()
                .filter(u -> u.getRole() == Role.COACH)
                .toList();

        for (User coach : coaches) {
            Message msg = new Message();
            msg.setSender(admin);
            msg.setReceiver(coach);
            msg.setMember(null);
            msg.setContent("[📢 Annonce] " + content);
            msg.setIsRead(false);
            messageRepository.save(msg);
        }
        return coaches.size();
    }

    public int broadcastToAll(String adminUsername, String content) {
        return broadcastToMembers(adminUsername, content)
                + broadcastToCoaches(adminUsername, content);
    }

    public List<Message> getAdminConversationWithUser(Long userId) {
        return messageRepository.findAdminConversationWithUser(userId);
    }

    public void markAdminMessagesAsRead(String username) {
        User user = findUser(username);
        List<Message> unread = messageRepository
                .findByReceiverIdAndIsReadFalse(user.getId());

        for (Message msg : unread) {
            if (msg.getMember() == null) { // message admin = pas de member lié
                msg.setIsRead(true);
                messageRepository.save(msg);
            }
        }
    }

    // ════════════════════════════════════════════════════════
    // HELPER
    // ════════════════════════════════════════════════════════

    private User findUser(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() ->
                        new RuntimeException("User not found: " + username));
    }
}