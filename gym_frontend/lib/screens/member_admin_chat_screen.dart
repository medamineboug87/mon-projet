// lib/screens/member_admin_chat_screen.dart
// ✅ CORRIGÉ : version mobile-first
// - Gestion du clavier avec MediaQuery.viewInsets.bottom
// - SafeArea ajouté
// - Hauteur minimale des cibles tactiles : 44px

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';

const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kRed = Color(0xFFE53935);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class MemberAdminChatScreen extends StatefulWidget {
  const MemberAdminChatScreen({super.key});

  @override
  State<MemberAdminChatScreen> createState() => _MemberAdminChatScreenState();
}

class _MemberAdminChatScreenState extends State<MemberAdminChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<dynamic> _messages = [];
  bool _isLoading = true;
  String? _memberUsername;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _memberUsername = await AuthService.getUsername();
    await _loadMessages();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _loadMessages(quiet: true);
    });
  }

  Future<void> _loadMessages({bool quiet = false}) async {
    if (!quiet) setState(() => _isLoading = true);
    final msgs = await MessageService.getMemberAdminConversation();
    if (mounted) {
      setState(() {
        _messages = msgs;
        if (!quiet) _isLoading = false;
      });
      _scrollToBottom();
    }
    await MessageService.markAdminMessagesAsRead();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    final success = await MessageService.sendMessageToAdmin(content);
    if (mounted) {
      if (success) {
        await _loadMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors de l'envoi"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: _kRed,
              child: Icon(
                Icons.admin_panel_settings,
                color: _kSurface,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Support - Administration',
              style: TextStyle(color: _kText, fontSize: 18),
            ),
            const SizedBox(width: 8),
            if (_pollingTimer?.isActive == true)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _kGreen,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        backgroundColor: _kSurf2,
        iconTheme: const IconThemeData(color: _kText),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _kText),
            onPressed: () => _loadMessages(quiet: false),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kGreen),
                    )
                  : _messages.isEmpty
                  ? _buildEmptyScreen()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (_, index) =>
                          _buildMessageBubble(_messages[index]),
                    ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.support_agent, size: 60, color: _kBorder),
          const SizedBox(height: 16),
          const Text(
            'Aucun message avec l\'administration',
            style: TextStyle(color: _kTextSub, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Envoyez un message, nous vous répondrons rapidement',
            style: TextStyle(color: _kTextSub, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final senderUsername = message['sender']?['username'] ?? '';
    final isMe = senderUsername == _memberUsername;
    final bool isUnread = message['isRead'] == false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Stack(
              clipBehavior: Clip.none,
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: _kRed,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 14,
                    color: _kSurface,
                  ),
                ),
                if (isUnread)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _kGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: _kSurface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? _kGreen : _kSurf2,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: (!isMe && isUnread)
                        ? Border.all(
                            color: _kGreen.withValues(alpha: 0.5),
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: Text(
                    message['content'] ?? '',
                    style: const TextStyle(color: _kText, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message['sentAt']),
                      style: const TextStyle(color: _kTextSub, fontSize: 11),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isUnread ? Icons.done : Icons.done_all,
                        size: 12,
                        color: isUnread ? _kTextSub : _kGreen,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: _kGreen,
              child: Icon(Icons.person, size: 16, color: _kSurface),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ CORRECTION CLAVIER : MediaQuery.viewInsets.bottom
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: _kSurf2,
        border: Border(top: BorderSide(color: _kBorder, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: _kText),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Envoyer un message à l\'administration...',
                hintStyle: const TextStyle(color: _kTextSub),
                filled: true,
                fillColor: _kSurf2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // ✅ Cible tactile 44x44 minimum
          SizedBox(
            width: 44,
            height: 44,
            child: CircleAvatar(
              backgroundColor: _kRed,
              child: IconButton(
                icon: const Icon(Icons.send, color: _kSurface, size: 20),
                onPressed: _sendMessage,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null) return '';
    try {
      final dt = DateTime.parse(dateTime);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inDays > 0) {
        return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      return '';
    }
  }
}
