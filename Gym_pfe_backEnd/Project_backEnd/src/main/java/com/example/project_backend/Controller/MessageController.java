package com.example.project_backend.Controller;

import com.example.project_backend.Entity.Message;
import com.example.project_backend.Entity.Role;
import com.example.project_backend.Entity.User;
import com.example.project_backend.Repository.MessageRepository;
import com.example.project_backend.Repository.UserRepository;
import com.example.project_backend.Service.MessageService;
import org.springframework.security.core.Authentication;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/messages")
@CrossOrigin(origins = "*")
public class MessageController {

    private final MessageService    messageService;
    private final UserRepository    userRepository;
    private final MessageRepository messageRepository;

    public MessageController(MessageService messageService,
                             UserRepository userRepository,
                             MessageRepository messageRepository) {
        this.messageService    = messageService;
        this.userRepository    = userRepository;
        this.messageRepository = messageRepository;
    }

    // ════════════════════════════════════════════════════════
    // MEMBRE ↔ COACH
    // ════════════════════════════════════════════════════════

    @PostMapping("/send")
    public ResponseEntity<Message> sendMessage(
            @RequestBody Map<String, Object> request) {

        String senderUsername   = (String) request.get("senderUsername");
        String receiverUsername = (String) request.get("receiverUsername");
        Long   memberId         = Long.valueOf(request.get("memberId").toString());
        String content          = (String) request.get("content");

        Message message = messageService.sendMessage(
                senderUsername, receiverUsername, memberId, content);
        return ResponseEntity.ok(message);
    }

    @GetMapping("/member/{memberId}")
    public ResponseEntity<List<Message>> getMemberMessages(
            @PathVariable Long memberId,
            Authentication authentication) {
        String username = authentication.getName();
        User currentUser = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        boolean isOwner = currentUser.getMember() != null
                && currentUser.getMember().getId().equals(memberId);
        boolean isAdminOrCoach = currentUser.getRole() == Role.ADMIN
                || currentUser.getRole() == Role.COACH;

        if (!isOwner && !isAdminOrCoach) {
            return ResponseEntity.status(403).build();
        }
        return ResponseEntity.ok(messageService.getMemberMessages(memberId));
    }

    @PostMapping("/member/{memberId}/read/{username}")
    public ResponseEntity<?> markAsRead(
            @PathVariable Long memberId,
            @PathVariable String username) {
        messageService.markAsRead(memberId, username);
        return ResponseEntity.ok(Map.of("message", "Messages marqués comme lus"));
    }

    // ── Compteur global (toutes sources) ──
    @GetMapping("/unread/{username}")
    public ResponseEntity<Map<String, Object>> countUnread(
            @PathVariable String username) {
        long count = messageService.countUnreadMessages(username);
        return ResponseEntity.ok(Map.of("unreadCount", count));
    }

    // ── Compteur messages non lus du COACH uniquement ──
    @GetMapping("/unread/coach/{username}")
    public ResponseEntity<Map<String, Object>> countUnreadFromCoach(
            @PathVariable String username) {
        long count = messageService.countUnreadFromCoach(username);
        return ResponseEntity.ok(Map.of("unreadCount", count));
    }

    // ── Compteur messages non lus de l'ADMIN uniquement ──
    @GetMapping("/unread/admin/{username}")
    public ResponseEntity<Map<String, Object>> countUnreadFromAdmin(
            @PathVariable String username) {
        long count = messageService.countUnreadFromAdmin(username);
        return ResponseEntity.ok(Map.of("unreadCount", count));
    }

    // ════════════════════════════════════════════════════════
    // ADMIN → UTILISATEUR SPÉCIFIQUE
    // ════════════════════════════════════════════════════════

    @PostMapping("/admin/send")
    public ResponseEntity<?> sendAdminMessage(
            @RequestBody Map<String, Object> request) {
        try {
            String adminUsername    = currentUsername();
            String receiverUsername = (String) request.get("receiverUsername");
            String content          = (String) request.get("content");

            if (receiverUsername == null || content == null || content.isBlank()) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "receiverUsername et content requis"));
            }

            Message msg = messageService.sendAdminMessage(
                    adminUsername, receiverUsername, content);
            return ResponseEntity.ok(msg);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/admin/broadcast")
    public ResponseEntity<?> broadcast(
            @RequestBody Map<String, Object> request) {
        try {
            String adminUsername = currentUsername();
            String target        = (String) request.get("target");
            String content       = (String) request.get("content");

            if (content == null || content.isBlank()) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "content requis"));
            }

            int sent = switch (target) {
                case "MEMBERS" -> messageService.broadcastToMembers(adminUsername, content);
                case "COACHES" -> messageService.broadcastToCoaches(adminUsername, content);
                case "ALL"     -> messageService.broadcastToAll(adminUsername, content);
                default -> throw new IllegalArgumentException(
                        "target invalide: " + target + " (MEMBERS | COACHES | ALL)");
            };

            return ResponseEntity.ok(Map.of(
                    "message", "Message envoyé à " + sent + " utilisateur(s)",
                    "sent", sent
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/admin/conversation/{userId}")
    public ResponseEntity<?> getAdminConversation(@PathVariable Long userId) {
        try {
            List<Message> messages = messageService.getAdminConversationWithUser(userId);
            return ResponseEntity.ok(messages);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/admin/read")
    public ResponseEntity<?> markAdminMessagesAsRead() {
        try {
            messageService.markAdminMessagesAsRead(currentUsername());
            return ResponseEntity.ok(Map.of("message", "Messages lus"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/admin/broadcast/history")
    public ResponseEntity<?> getBroadcastHistory() {
        try {
            return ResponseEntity.ok(messageRepository.findBroadcastMessages());
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ════════════════════════════════════════════════════════
    // MEMBRE → ADMIN
    // ════════════════════════════════════════════════════════

    @PostMapping("/member/send-to-admin")
    public ResponseEntity<?> sendMessageToAdmin(
            @RequestBody Map<String, Object> request) {
        try {
            String memberUsername = currentUsername();
            String content        = (String) request.get("content");

            if (content == null || content.isBlank()) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "content requis"));
            }

            User admin = userRepository.findAll().stream()
                    .filter(u -> u.getRole() == Role.ADMIN)
                    .findFirst()
                    .orElseThrow(() -> new RuntimeException("Aucun admin disponible"));

            Message msg = messageService.sendAdminMessage(
                    memberUsername, admin.getUsername(), content);
            return ResponseEntity.ok(msg);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/member/admin-conversation")
    public ResponseEntity<?> getMemberAdminConversation() {
        try {
            String memberUsername = currentUsername();
            User memberUser = userRepository.findByUsername(memberUsername)
                    .orElseThrow(() -> new RuntimeException("User not found"));

            List<Message> messages = messageService
                    .getAdminConversationWithUser(memberUser.getId());
            return ResponseEntity.ok(messages);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ════════════════════════════════════════════════════════
    // HELPER
    // ════════════════════════════════════════════════════════

    private String currentUsername() {
        return SecurityContextHolder.getContext()
                .getAuthentication().getName();
    }
}