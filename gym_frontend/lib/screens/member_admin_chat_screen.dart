// lib/screens/member_admin_chat_screen.dart
// ✅ REDESIGN : version mobile-first épurée
// - Header simplifié avec avatar compact
// - Bulles de messages plus légères
// - Champ d'envoi arrondi et minimal
// - Timestamps discrets
// - Gestion clavier MediaQuery.viewInsets.bottom

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';

const Color _kBg = Color(0xFFF4F6FA);
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
          SnackBar(
            content: const Text("Erreur lors de l'envoi"),
            backgroundColor: _kRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
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
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kSurface,
      elevation: 0,
      titleSpacing: 0,
      iconTheme: const IconThemeData(color: _kText),
      title: Row(
        children: [
          // Avatar compact administration
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kRed.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kRed.withOpacity(0.25)),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: _kRed,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Support — Administration',
                style: TextStyle(
                  color: _kText,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              // Indicateur de connexion live
              if (_pollingTimer?.isActive == true)
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _kGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'En ligne',
                      style: TextStyle(color: _kGreen, fontSize: 10),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: _kTextSub, size: 20),
          onPressed: () => _loadMessages(quiet: false),
          tooltip: 'Actualiser',
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(0.5),
        child: Divider(height: 0.5, color: _kBorder),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _kSurf2,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              size: 30,
              color: _kTextSub,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Aucun message avec l'administration",
            style: TextStyle(
              color: _kText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Envoyez un message, nous vous répondrons rapidement',
            style: TextStyle(color: _kTextSub, fontSize: 12),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar admin (côté gauche)
          if (!isMe) ...[
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _kRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _kRed.withOpacity(0.25)),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 14,
                    color: _kRed,
                  ),
                ),
                if (isUnread)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
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

          // Bulle + timestamp
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Bulle de message
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    // Moi → vert, Admin → fond secondaire
                    color: isMe ? _kGreen : _kSurf2,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: (!isMe && isUnread)
                        ? Border.all(
                            color: _kGreen.withOpacity(0.4),
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: Text(
                    message['content'] ?? '',
                    style: TextStyle(
                      color: isMe ? Colors.white : _kText,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 3),

                // Timestamp + statut lu
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message['sentAt']),
                      style: const TextStyle(color: _kTextSub, fontSize: 10),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isUnread ? Icons.done_rounded : Icons.done_all_rounded,
                        size: 12,
                        color: isUnread ? _kTextSub : _kGreen,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Avatar moi (côté droit)
          if (isMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _kGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: _kGreen.withOpacity(0.25)),
              ),
              child: const Icon(Icons.person_rounded, size: 14, color: _kGreen),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ Barre d'envoi — arrondie et compacte
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: _kSurface,
        border: const Border(top: BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          // Champ de texte arrondi
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: _kText, fontSize: 14),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: "Envoyer un message à l'administration...",
                hintStyle: const TextStyle(color: _kTextSub, fontSize: 13),
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
          // Bouton envoi — cible tactile 44×44
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kRed,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
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
        return '${dt.day}/${dt.month} '
            '${dt.hour.toString().padLeft(2, '0')}:'
            '${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
